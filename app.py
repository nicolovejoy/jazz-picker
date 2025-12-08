#!/usr/bin/env python3
"""
Jazz Picker - A web interface for browsing Eric's lilypond lead sheets.
"""

from flask import Flask, jsonify, request, send_from_directory, make_response, g
from flask_cors import CORS
import subprocess
import os
import sys
import socket
from pathlib import Path
from functools import wraps
import boto3
from botocore.exceptions import ClientError
import hashlib
import time

import db  # SQLite database module
import json

# Firebase Admin SDK (optional - for token verification)
try:
    import firebase_admin
    from firebase_admin import auth as firebase_auth
    FIREBASE_AVAILABLE = True
except ImportError:
    firebase_admin = None
    firebase_auth = None
    FIREBASE_AVAILABLE = False
    print("⚠️  firebase-admin not installed - token verification disabled")

# Crop detector is optional - may not be available in all environments
# Note: This try/except may be cruft now that Dockerfile includes crop_detector.py
# Kept for defensive coding in case of future deployment issues
try:
    from crop_detector import detect_bounds
    CROP_DETECTION_AVAILABLE = True
except ImportError:
    detect_bounds = None
    CROP_DETECTION_AVAILABLE = False
    print("⚠️  crop_detector not available - crop detection disabled")

app = Flask(__name__)

# Enable CORS for frontend domains
CORS(app, resources={r"/*": {"origins": "*"}})

# Constants for validation
MAX_LIMIT = 200

# Database
DB_FILE = 'catalog.db'
S3_DB_KEY = 'catalog.db'
db_etag = None  # ETag for catalog version

WRAPPERS_DIR = 'lilypond-data/Wrappers'
CACHE_DIR = Path('cache/pdfs')

# S3 Configuration
S3_BUCKET = os.getenv('S3_BUCKET_NAME', 'jazz-picker-pdfs')
S3_REGION = os.getenv('S3_REGION', 'us-east-1')
USE_S3 = os.getenv('USE_S3', 'true').lower() == 'true'

# Initialize S3 client if enabled
s3_client = None
if USE_S3:
    try:
        s3_client = boto3.client('s3', region_name=S3_REGION)
        print(f"✅ S3 client initialized (bucket: {S3_BUCKET}, region: {S3_REGION})")
    except Exception as e:
        print(f"⚠️  Warning: Could not initialize S3 client: {e}")
        print("   PDFs will be served from local cache/Dropbox only")
        s3_client = None

# Create cache directory on startup
CACHE_DIR.mkdir(parents=True, exist_ok=True)

# Firebase Admin initialization (optional - for token verification)
# Note: Token verification requires GOOGLE_APPLICATION_CREDENTIALS env var to be set
# On Fly.io without GCP credentials, we skip Firebase entirely to avoid repeated errors
FIREBASE_PROJECT_ID = os.getenv('FIREBASE_PROJECT_ID', 'jazz-picker')
GOOGLE_CREDS_PATH = os.getenv('GOOGLE_APPLICATION_CREDENTIALS', '')
firebase_app = None
firebase_credentials_valid = False  # Track if we can actually verify tokens

# Only initialize Firebase if credentials are explicitly configured
if FIREBASE_AVAILABLE and GOOGLE_CREDS_PATH:
    try:
        firebase_app = firebase_admin.initialize_app(options={
            'projectId': FIREBASE_PROJECT_ID
        })
        firebase_credentials_valid = True
        print(f"✅ Firebase Admin initialized (project: {FIREBASE_PROJECT_ID})")
    except Exception as e:
        print(f"⚠️  Firebase Admin init failed: {e}")
        print("   Token verification disabled")
elif FIREBASE_AVAILABLE:
    print("ℹ️  Firebase Admin available but GOOGLE_APPLICATION_CREDENTIALS not set - token verification disabled")

# Basic Auth Configuration
BASIC_AUTH_USERNAME = os.getenv('BASIC_AUTH_USERNAME', 'admin')
BASIC_AUTH_PASSWORD = os.getenv('BASIC_AUTH_PASSWORD', 'changeme')
REQUIRE_AUTH = os.getenv('REQUIRE_AUTH', 'false').lower() == 'true'


def check_auth(username, password):
    """Check if username/password combination is valid."""
    return username == BASIC_AUTH_USERNAME and password == BASIC_AUTH_PASSWORD


def authenticate():
    """Send 401 response that enables basic auth."""
    return jsonify({'error': 'Authentication required'}), 401, {
        'WWW-Authenticate': 'Basic realm="Jazz Picker API"'
    }


def requires_auth(f):
    """Decorator to require basic auth for a route."""
    @wraps(f)
    def decorated(*args, **kwargs):
        if not REQUIRE_AUTH:
            return f(*args, **kwargs)
        auth = request.authorization
        if not auth or not check_auth(auth.username, auth.password):
            return authenticate()
        return f(*args, **kwargs)
    return decorated


def verify_firebase_token(f):
    """
    Decorator to verify Firebase ID tokens (optional auth).

    - If valid token: sets g.firebase_uid and g.firebase_user
    - If no/invalid token: g.firebase_uid = None (allows unauthenticated)
    - Never blocks requests (iOS compatibility)
    - Skips verification entirely if credentials aren't configured
    """
    @wraps(f)
    def decorated(*args, **kwargs):
        g.firebase_uid = None
        g.firebase_user = None

        # Skip if Firebase credentials aren't available (avoids repeated failures)
        if not firebase_credentials_valid:
            return f(*args, **kwargs)

        auth_header = request.headers.get('Authorization', '')
        if not auth_header.startswith('Bearer '):
            return f(*args, **kwargs)

        token = auth_header[7:]  # Strip "Bearer "

        try:
            decoded = firebase_auth.verify_id_token(token)
            g.firebase_uid = decoded['uid']
            g.firebase_user = decoded  # Contains email, name, etc.
        except firebase_auth.InvalidIdTokenError:
            print("⚠️  Invalid Firebase token")
        except firebase_auth.ExpiredIdTokenError:
            print("⚠️  Expired Firebase token")
        except Exception as e:
            print(f"⚠️  Token verification failed: {e}")

        return f(*args, **kwargs)
    return decorated


# Error Handlers
@app.errorhandler(404)
def not_found(error):
    """Handle 404 errors."""
    return jsonify({
        'error': 'Not found',
        'message': 'The requested resource does not exist',
        'status': 404
    }), 404


@app.errorhandler(500)
def internal_error(error):
    """Handle 500 errors."""
    return jsonify({
        'error': 'Internal server error',
        'message': 'An unexpected error occurred',
        'status': 500
    }), 500


@app.errorhandler(400)
def bad_request(error):
    """Handle 400 errors."""
    return jsonify({
        'error': 'Bad request',
        'message': str(error),
        'status': 400
    }), 400


def init_catalog_db():
    """Initialize the catalog database, downloading from S3 if needed."""
    global db_etag

    db_path = Path(DB_FILE)

    # Try to download from S3 if enabled and file doesn't exist or is old
    if USE_S3 and s3_client:
        try:
            # Check if S3 has a newer version
            response = s3_client.head_object(Bucket=S3_BUCKET, Key=S3_DB_KEY)
            s3_etag = response.get('ETag', '').strip('"')

            # Download if local doesn't exist or ETags differ
            should_download = not db_path.exists()
            if db_path.exists() and s3_etag:
                local_mtime = db_path.stat().st_mtime
                local_etag = hashlib.md5(str(local_mtime).encode()).hexdigest()
                should_download = local_etag != s3_etag

            if should_download:
                print(f"⬇️  Downloading catalog.db from S3...")
                s3_client.download_file(S3_BUCKET, S3_DB_KEY, DB_FILE)
                print(f"✅ Downloaded catalog.db from S3")

        except ClientError as e:
            if e.response['Error']['Code'] == '404':
                print(f"⚠️  catalog.db not found in S3, using local file")
            else:
                print(f"⚠️  Could not check S3 for catalog.db: {e}")

    # Initialize the database
    try:
        song_count = db.init_db(db_path)
        print(f"✅ Loaded catalog database ({song_count} songs)")

        # Generate ETag from file modification time
        db_etag = hashlib.md5(str(db_path.stat().st_mtime).encode()).hexdigest()

    except FileNotFoundError:
        print("❌ catalog.db not found locally or on S3.")
        raise


def add_cache_headers(response, max_age=300, etag=None):
    """Add caching headers to a response."""
    # Add Cache-Control header
    response.headers['Cache-Control'] = f'public, max-age={max_age}'

    # Add ETag if provided
    if etag:
        response.headers['ETag'] = f'"{etag}"'

    return response


def check_etag(etag):
    """Check if client's ETag matches current catalog ETag."""
    if not etag:
        return False

    client_etag = request.headers.get('If-None-Match', '').strip('"')
    return client_etag == etag


def get_local_ip():
    """Get the local IP address of this machine."""
    try:
        # Create a socket to determine the local IP
        # This doesn't actually connect, just determines what IP would be used
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(("8.8.8.8", 80))
        ip = s.getsockname()[0]
        s.close()
        return ip
    except Exception:
        return "localhost"


@app.route('/')
def index():
    """API root - provides information about available endpoints."""
    total_songs = db.get_total_songs()

    return jsonify({
        'name': 'Jazz Picker API',
        'version': '2.0',
        'description': 'Browse and search Eric\'s jazz lead sheet collection',
        'catalog': {
            'total_songs': total_songs,
        },
        'endpoints': {
            'health': '/health',
            'songs_v2': '/api/v2/songs?limit=20&offset=0&q=',
            'cached_keys': '/api/v2/songs/{title}/cached',
            'generate': '/api/v2/generate',
            'setlists': '/api/v2/setlists',
            'setlist': '/api/v2/setlists/{id}',
        },
        'frontend': 'https://jazzpicker.pianohouseproject.org'
    })


@app.route('/health')
def health():
    """Health check endpoint for deployment platforms."""
    total_songs = db.get_total_songs()

    return jsonify({
        'status': 'healthy',
        'total_songs': total_songs,
        's3_enabled': USE_S3,
        's3_configured': s3_client is not None
    }), 200


@app.route('/api/v2/catalog')
@requires_auth
@verify_firebase_token
def get_catalog():
    """
    Get full catalog of song titles (lightweight, for navigation).
    Returns all songs sorted alphabetically - just titles and default keys.
    """
    # Check ETag - if client has current version, return 304
    if check_etag(db_etag):
        return make_response('', 304)

    songs = db.get_all_songs()

    response = make_response(jsonify({
        'songs': songs,
        'total': len(songs)
    }))

    # Cache for 5 minutes
    return add_cache_headers(response, max_age=300, etag=db_etag)


@app.route('/api/v2/songs')
@requires_auth
@verify_firebase_token
def get_songs_v2():
    """API v2: Get paginated, slim song list."""
    # Query parameters with validation
    try:
        limit = int(request.args.get('limit', 50))
        offset = int(request.args.get('offset', 0))
    except ValueError:
        return jsonify({'error': 'Invalid limit or offset parameter'}), 400

    # Validate limit
    if limit < 1 or limit > MAX_LIMIT:
        return jsonify({'error': f'Limit must be between 1 and {MAX_LIMIT}'}), 400

    # Validate offset
    if offset < 0:
        return jsonify({'error': 'Offset must be non-negative'}), 400

    query = request.args.get('q', '')

    # Query database
    songs, total = db.search_songs(query, limit, offset)

    # Check ETag - if client has current version, return 304
    if check_etag(db_etag):
        return make_response('', 304)

    # Create response with caching headers
    response = make_response(jsonify({
        'songs': songs,
        'total': total,
        'limit': limit,
        'offset': offset,
    }))

    # Add caching headers (5 minutes for song lists)
    return add_cache_headers(response, max_age=300, etag=db_etag)


# LilyPond generation constants
LILYPOND_DATA_DIR = Path('lilypond-data')
GENERATED_DIR = LILYPOND_DATA_DIR / 'Generated'  # Inside lilypond-data for correct relative paths
VALID_KEYS = {'c', 'cs', 'df', 'd', 'ds', 'ef', 'e', 'f', 'fs', 'gf', 'g', 'gs', 'af', 'a', 'as', 'bf', 'b'}
VALID_CLEFS = {'treble', 'bass'}
VALID_TRANSPOSITIONS = {'C', 'Bb', 'Eb'}

# Key list for transposition math (chromatic scale)
KEYS_CHROMATIC = ['c', 'cs', 'd', 'ef', 'e', 'f', 'fs', 'g', 'af', 'a', 'bf', 'b']

# Transposition intervals (semitones up from concert pitch to written pitch)
TRANSPOSITION_INTERVALS = {
    'C': 0,   # Concert pitch
    'Bb': 2,  # Up a major 2nd
    'Eb': 9,  # Up a major 6th
}

# Instrument definitions with written pitch ranges (MIDI note numbers)
# Range is None for instruments that don't need octave optimization
INSTRUMENTS = {
    'Trumpet':     {'transposition': 'Bb', 'clef': 'treble', 'range': (54, 84)},   # F#3-C6
    'Clarinet':    {'transposition': 'Bb', 'clef': 'treble', 'range': (52, 91)},   # E3-G6
    'Tenor Sax':   {'transposition': 'Bb', 'clef': 'treble', 'range': (58, 89)},   # Bb3-F6
    'Alto Sax':    {'transposition': 'Eb', 'clef': 'treble', 'range': (58, 89)},   # Bb3-F6
    'Soprano Sax': {'transposition': 'Bb', 'clef': 'treble', 'range': (58, 89)},   # Bb3-F6
    'Bari Sax':    {'transposition': 'Eb', 'clef': 'treble', 'range': (58, 89)},   # Bb3-F6
    'Trombone':    {'transposition': 'C',  'clef': 'bass',   'range': (40, 70)},   # E2-Bb4
    'Flute':       {'transposition': 'C',  'clef': 'treble', 'range': (60, 96)},   # C4-C7
    'Piano':       {'transposition': 'C',  'clef': 'treble', 'range': None},
    'Guitar':      {'transposition': 'C',  'clef': 'treble', 'range': None},
    'Bass':        {'transposition': 'C',  'clef': 'bass',   'range': None},
}


def get_key_offset(from_key, to_key):
    """
    Calculate semitone offset between two keys.
    Example: get_key_offset('c', 'ef') => 3
    """
    # Normalize keys
    from_key = from_key.lower().strip()
    to_key = to_key.lower().strip()

    # Handle enharmonic equivalents
    enharmonic_map = {'df': 'cs', 'gf': 'fs', 'ds': 'ef', 'as': 'bf', 'gs': 'af'}
    from_normalized = enharmonic_map.get(from_key, from_key)
    to_normalized = enharmonic_map.get(to_key, to_key)

    try:
        from_index = KEYS_CHROMATIC.index(from_normalized)
        to_index = KEYS_CHROMATIC.index(to_normalized)
    except ValueError:
        return 0  # Unknown key

    return (to_index - from_index) % 12


def calculate_optimal_octave(song_title, concert_key, instrument_label):
    """
    Calculate the optimal octave offset for a song/key/instrument combination.

    Returns an integer from -2 to +2, or 0 if calculation isn't possible.
    """
    # Check if instrument needs octave optimization
    instrument = INSTRUMENTS.get(instrument_label)
    if not instrument or instrument['range'] is None:
        return 0

    # Get song's note range and default key
    song_low, song_high = db.get_song_note_range(song_title)
    if song_low is None or song_high is None:
        return 0

    default_key, _ = db.get_song_default_key(song_title)

    # Calculate key offset (semitones from default to target concert key)
    key_offset = get_key_offset(default_key, concert_key)

    # Get instrument transposition offset
    trans_offset = TRANSPOSITION_INTERVALS.get(instrument['transposition'], 0)

    # Calculate written pitch range
    written_low = song_low + key_offset + trans_offset
    written_high = song_high + key_offset + trans_offset

    inst_low, inst_high = instrument['range']

    # Find best octave offset
    best_offset = 0
    best_score = -1

    for octave in [-2, -1, 0, 1, 2]:
        adj_low = written_low + (octave * 12)
        adj_high = written_high + (octave * 12)

        # Calculate overlap with instrument range
        overlap_low = max(adj_low, inst_low)
        overlap_high = min(adj_high, inst_high)

        if overlap_high >= overlap_low:
            overlap = overlap_high - overlap_low
            total = adj_high - adj_low
            score = overlap / total if total > 0 else 1.0
        else:
            score = 0

        if score > best_score:
            best_score = score
            best_offset = octave

    return best_offset


def concert_to_written(concert_key, transposition):
    """
    Convert concert key to written key for a given transposition.
    Example: concert_to_written('ef', 'Bb') => 'f'
    """
    # Normalize key
    key = concert_key.lower().strip()

    # Handle enharmonic equivalents for lookup
    enharmonic_map = {'df': 'cs', 'gf': 'fs', 'ds': 'ef', 'as': 'bf', 'gs': 'af'}
    normalized = enharmonic_map.get(key, key)

    try:
        concert_index = KEYS_CHROMATIC.index(normalized)
    except ValueError:
        return concert_key  # Unknown key, return as-is

    interval = TRANSPOSITION_INTERVALS.get(transposition, 0)
    written_index = (concert_index + interval) % 12

    return KEYS_CHROMATIC[written_index]


def slugify(text):
    """Convert text to a safe filename slug."""
    import re
    text = text.lower()
    text = re.sub(r'[^\w\s-]', '', text)
    text = re.sub(r'[\s_-]+', '-', text)
    return text.strip('-')


def generate_wrapper_content(core_file, target_key, clef, instrument="", octave_offset=0):
    """Generate LilyPond wrapper file content.

    Args:
        octave_offset: Integer from -2 to +2. Positive = up, negative = down.
                       LilyPond syntax: ' = up one octave, , = down one octave
    """
    # bassKey is always the key without octave modifier
    bass_key = target_key.rstrip(',')

    # For bass clef, whatKey starts one octave down
    what_key = f"{target_key}," if clef == "bass" else target_key

    # Apply octave offset: ' = up, , = down
    if octave_offset > 0:
        what_key += "'" * octave_offset
    elif octave_offset < 0:
        what_key += "," * abs(octave_offset)

    return f'''%% -*- Mode: LilyPond -*-

\\version "2.24.0"

\\include "english.ly"

instrument = "{instrument}"
whatKey = {what_key}
bassKey = {bass_key}
whatClef = "{clef}"

\\include "../Core/{core_file}"
'''


@app.route('/api/v2/cached-keys')
@requires_auth
@verify_firebase_token
def get_all_cached_keys():
    """
    Get all cached keys for all songs in a single request.

    Query params:
        transposition: C, Bb, or Eb (required)
        clef: treble or bass (default: treble)

    Returns:
    {
        "cached_keys": {
            "502-blues": ["a", "bf"],
            "autumn-leaves": ["g", "ef"],
            ...
        }
    }
    """
    # Get transposition from query params
    transposition = request.args.get('transposition', 'C')
    if transposition not in VALID_TRANSPOSITIONS:
        return jsonify({'error': f'Invalid transposition. Must be one of: {", ".join(VALID_TRANSPOSITIONS)}'}), 400

    clef = request.args.get('clef', 'treble')
    if clef not in VALID_CLEFS:
        clef = 'treble'

    cached_keys = {}

    if s3_client:
        try:
            # List all generated PDFs
            paginator = s3_client.get_paginator('list_objects_v2')
            pages = paginator.paginate(Bucket=S3_BUCKET, Prefix='generated/')

            for page in pages:
                for obj in page.get('Contents', []):
                    # Parse: generated/{slug}-{concert_key}-{transposition}-{clef}.pdf
                    key = obj['Key']
                    if not key.endswith('.pdf'):
                        continue

                    # Remove prefix and extension
                    filename = key.replace('generated/', '').replace('.pdf', '')

                    # Split from the end to handle song slugs with hyphens
                    parts = filename.rsplit('-', 3)
                    if len(parts) != 4:
                        continue

                    song_slug, concert_key, file_trans, file_clef = parts

                    # Filter by transposition and clef
                    if file_trans == transposition and file_clef == clef:
                        if song_slug not in cached_keys:
                            cached_keys[song_slug] = []
                        if concert_key not in cached_keys[song_slug]:
                            cached_keys[song_slug].append(concert_key)

        except ClientError as e:
            print(f"⚠️  Error listing cached keys: {e}")

    response = make_response(jsonify({
        'cached_keys': cached_keys,
        'transposition': transposition,
        'clef': clef
    }))

    # Cache for 5 minutes
    return add_cache_headers(response, max_age=300)


@app.route('/api/v2/songs/<path:song_title>/cached')
@requires_auth
@verify_firebase_token
def get_cached_keys(song_title):
    """
    Get list of cached concert keys for a song, filtered by transposition.

    Query params:
        transposition: C, Bb, or Eb (required)

    Returns:
    {
        "default_key": "g",              // Default concert key
        "cached_concert_keys": ["c", "g"]  // Concert keys cached for this transposition
    }
    """
    # Get transposition from query params
    transposition = request.args.get('transposition', 'C')
    if transposition not in VALID_TRANSPOSITIONS:
        return jsonify({'error': f'Invalid transposition. Must be one of: {", ".join(VALID_TRANSPOSITIONS)}'}), 400

    # Get clef based on transposition (bass clef for C+bass instruments handled by frontend)
    clef = request.args.get('clef', 'treble')
    if clef not in VALID_CLEFS:
        clef = 'treble'

    # Get default key from database
    default_key, _ = db.get_song_default_key(song_title)

    # Verify song exists
    if not db.song_exists(song_title):
        return jsonify({'error': f'Song not found: {song_title}'}), 404

    cached_concert_keys = []

    # Check S3 for cached versions matching this transposition
    if s3_client:
        slug = slugify(song_title)
        prefix = f"generated/{slug}-"

        try:
            response = s3_client.list_objects_v2(
                Bucket=S3_BUCKET,
                Prefix=prefix
            )

            for obj in response.get('Contents', []):
                # Parse from filename: {slug}-{concert_key}-{transposition}-{clef}.pdf
                filename = obj['Key'].replace(prefix, '').replace('.pdf', '')
                parts = filename.split('-')
                # Expected: [concert_key, transposition, clef]
                if len(parts) >= 3:
                    file_concert_key = parts[0]
                    file_transposition = parts[1]
                    file_clef = parts[2]

                    # Filter by transposition and clef
                    if file_transposition == transposition and file_clef == clef:
                        cached_concert_keys.append(file_concert_key)

        except ClientError as e:
            print(f"⚠️  Error listing cached keys: {e}")

    return jsonify({
        'default_key': default_key,
        'cached_concert_keys': cached_concert_keys
    })


@app.route('/api/v2/generate', methods=['POST'])
@requires_auth
@verify_firebase_token
def generate_pdf():
    """
    Generate a PDF for any song in any concert key.

    Request body:
    {
        "song": "502 Blues",           // Song title
        "concert_key": "eb",           // Concert key (what the audience hears)
        "transposition": "Bb",         // Instrument transposition: C, Bb, or Eb
        "clef": "treble",              // "treble" or "bass"
        "instrument_label": "Trumpet", // Optional label for PDF subtitle + auto-octave
        "octave_offset": 0             // Optional: -2 to +2 (auto-calculated if omitted)
    }

    Returns:
    {
        "url": "https://s3.../502-blues-eb-Bb-treble-0.pdf",
        "cached": true/false,
        "generation_time_ms": 2340,
        "octave_offset": 0             // The octave offset used (auto or provided)
    }
    """
    start_time = time.time()

    # Parse request
    data = request.get_json()
    if not data:
        return jsonify({'error': 'Request body must be JSON'}), 400

    song_title = data.get('song')
    concert_key = data.get('concert_key', '').lower()
    transposition = data.get('transposition', 'C')
    clef = data.get('clef', 'treble').lower()
    instrument_label = data.get('instrument_label', '').strip()
    octave_offset_provided = 'octave_offset' in data
    octave_offset = data.get('octave_offset', 0)

    # Validate inputs
    if not song_title:
        return jsonify({'error': 'Missing required field: song'}), 400

    if not concert_key:
        return jsonify({'error': 'Missing required field: concert_key'}), 400

    if concert_key not in VALID_KEYS:
        return jsonify({'error': f'Invalid concert_key. Must be one of: {", ".join(sorted(VALID_KEYS))}'}), 400

    if transposition not in VALID_TRANSPOSITIONS:
        return jsonify({'error': f'Invalid transposition. Must be one of: {", ".join(VALID_TRANSPOSITIONS)}'}), 400

    if clef not in VALID_CLEFS:
        return jsonify({'error': f'Invalid clef. Must be one of: {", ".join(VALID_CLEFS)}'}), 400

    # Validate octave_offset
    try:
        octave_offset = int(octave_offset)
    except (ValueError, TypeError):
        return jsonify({'error': 'octave_offset must be an integer'}), 400

    if octave_offset < -2 or octave_offset > 2:
        return jsonify({'error': 'octave_offset must be between -2 and 2'}), 400

    # Look up song in database
    core_files = db.get_core_files(song_title)
    if not core_files:
        return jsonify({'error': f'Song not found: {song_title}'}), 404

    # Use the first core file (most songs have exactly one)
    core_file = core_files[0]

    # Auto-calculate octave offset if not explicitly provided
    if not octave_offset_provided and instrument_label:
        octave_offset = calculate_optimal_octave(song_title, concert_key, instrument_label)

    # Calculate written key for LilyPond
    written_key = concert_to_written(concert_key, transposition)

    # Generate S3 key: {slug}-{concert_key}-{transposition}-{clef}-{octave}.pdf
    slug = slugify(song_title)
    s3_key = f"generated/{slug}-{concert_key}-{transposition}-{clef}-{octave_offset}.pdf"

    # Check if already cached in S3
    if s3_client:
        try:
            head_response = s3_client.head_object(Bucket=S3_BUCKET, Key=s3_key)
            # Already exists - return presigned URL with crop metadata
            url = s3_client.generate_presigned_url(
                'get_object',
                Params={'Bucket': S3_BUCKET, 'Key': s3_key},
                ExpiresIn=900
            )
            generation_time = int((time.time() - start_time) * 1000)

            # Retrieve crop metadata if available
            crop = None
            metadata = head_response.get('Metadata', {})
            if 'crop' in metadata:
                try:
                    crop = json.loads(metadata['crop'])
                except:
                    pass

            response_data = {
                'url': url,
                'cached': True,
                'generation_time_ms': generation_time,
                'octave_offset': octave_offset
            }
            if crop:
                response_data['crop'] = crop

            return jsonify(response_data)
        except ClientError as e:
            if e.response['Error']['Code'] != '404':
                print(f"⚠️  S3 error checking cache: {e}")
            # Not cached, continue to generate

    # Create generated directory if needed
    GENERATED_DIR.mkdir(parents=True, exist_ok=True)

    # Generate wrapper file (use written_key for LilyPond, instrument_label for subtitle)
    wrapper_content = generate_wrapper_content(core_file, written_key, clef, instrument_label, octave_offset)

    # Local filename matches S3 key format
    file_base = f"{slug}-{concert_key}-{transposition}-{clef}-{octave_offset}"

    wrapper_filename = f"{file_base}.ly"
    wrapper_path = GENERATED_DIR / wrapper_filename
    pdf_path = GENERATED_DIR / f"{file_base}.pdf"

    try:
        # Write wrapper file
        with open(wrapper_path, 'w') as f:
            f.write(wrapper_content)

        # Run LilyPond from lilypond-data directory so includes resolve correctly
        result = subprocess.run(
            ['lilypond', '-o', f'Generated/{file_base}', f'Generated/{wrapper_filename}'],
            cwd=str(LILYPOND_DATA_DIR),
            capture_output=True,
            text=True,
            timeout=60
        )

        # Check if PDF was created (LilyPond may return non-zero with warnings but still produce output)
        if not pdf_path.exists():
            # Actual failure - extract error lines
            stderr_lines = result.stderr.split('\n')
            error_summary = [line.strip() for line in stderr_lines if 'error:' in line.lower()][:5]
            error_text = '\n'.join(error_summary) if error_summary else result.stderr[:500]

            return jsonify({
                'error': 'LilyPond compilation failed',
                'details': error_text
            }), 500

        # Detect crop bounds before uploading (if available)
        crop = None
        if CROP_DETECTION_AVAILABLE:
            try:
                crop_bounds = detect_bounds(str(pdf_path))
                if crop_bounds:
                    crop = crop_bounds.to_dict()
            except Exception as e:
                print(f"⚠️  Crop detection failed: {e}")

        # Upload to S3 if available
        if s3_client:
            try:
                # Prepare metadata with crop bounds
                extra_args = {'ContentType': 'application/pdf'}
                if crop:
                    extra_args['Metadata'] = {'crop': json.dumps(crop)}

                s3_client.upload_file(
                    str(pdf_path),
                    S3_BUCKET,
                    s3_key,
                    ExtraArgs=extra_args
                )

                # Generate presigned URL
                url = s3_client.generate_presigned_url(
                    'get_object',
                    Params={'Bucket': S3_BUCKET, 'Key': s3_key},
                    ExpiresIn=900
                )

                # Clean up local files
                wrapper_path.unlink(missing_ok=True)
                pdf_path.unlink(missing_ok=True)

                generation_time = int((time.time() - start_time) * 1000)
                response_data = {
                    'url': url,
                    'cached': False,
                    'generation_time_ms': generation_time,
                    'octave_offset': octave_offset
                }
                if crop:
                    response_data['crop'] = crop

                return jsonify(response_data)
            except Exception as e:
                print(f"⚠️  Failed to upload to S3: {e}")
                # Fall through to local file serving

        # No S3 - serve from local file (development mode)
        generation_time = int((time.time() - start_time) * 1000)
        response_data = {
            'url': f'/generated/{pdf_path.name}',
            'cached': False,
            'generation_time_ms': generation_time,
            'octave_offset': octave_offset,
            'note': 'Local file (S3 not available)'
        }
        if crop:
            response_data['crop'] = crop

        return jsonify(response_data)

    except subprocess.TimeoutExpired:
        return jsonify({'error': 'LilyPond compilation timed out (60s limit)'}), 500
    except Exception as e:
        return jsonify({'error': f'Generation failed: {str(e)}'}), 500
    finally:
        # Clean up wrapper file
        if wrapper_path.exists():
            wrapper_path.unlink(missing_ok=True)


@app.route('/generated/<path:filename>')
def serve_generated(filename):
    """Serve locally generated PDFs (development mode only)."""
    return send_from_directory(str(GENERATED_DIR), filename, mimetype='application/pdf')


# =============================================================================
# Setlists API
# =============================================================================

@app.route('/api/v2/setlists', methods=['GET'])
@requires_auth
@verify_firebase_token
def list_setlists():
    """
    Get all setlists.

    Returns:
    {
        "setlists": [
            {
                "id": "uuid",
                "name": "Friday Gig",
                "created_at": "2025-12-04T...",
                "updated_at": "2025-12-04T...",
                "created_by_device": "uuid",
                "items": [
                    {"id": "uuid", "song_title": "502 Blues", "concert_key": "ef", "position": 0, "is_set_break": false, "octave_offset": 0},
                    ...
                ]
            },
            ...
        ]
    }
    """
    setlists = db.get_all_setlists()
    return jsonify({'setlists': setlists})


@app.route('/api/v2/setlists', methods=['POST'])
@requires_auth
@verify_firebase_token
def create_setlist():
    """
    Create a new setlist.

    Request body:
    {
        "name": "Friday Gig",
        "items": [
            {"song_title": "502 Blues", "concert_key": "ef", "is_set_break": false, "octave_offset": 0},
            {"song_title": "", "concert_key": "", "is_set_break": true}
        ]
    }

    Headers:
        X-Device-ID: Optional device UUID for attribution

    Returns: The created setlist
    """
    data = request.get_json()
    if not data:
        return jsonify({'error': 'Request body must be JSON'}), 400

    name = data.get('name')
    if not name:
        return jsonify({'error': 'Missing required field: name'}), 400

    items = data.get('items', [])
    device_id = request.headers.get('X-Device-ID')

    # Validate items structure (song_title and concert_key required unless is_set_break)
    for item in items:
        is_set_break = item.get('is_set_break', False)
        if not is_set_break:
            if 'song_title' not in item or 'concert_key' not in item:
                return jsonify({'error': 'Each item must have song_title and concert_key (unless is_set_break)'}), 400

    setlist = db.create_setlist(name=name, items=items, device_id=device_id)
    return jsonify(setlist), 201


@app.route('/api/v2/setlists/<setlist_id>', methods=['GET'])
@requires_auth
@verify_firebase_token
def get_setlist(setlist_id):
    """
    Get a single setlist by ID.

    Returns: The setlist, or 404 if not found
    """
    setlist = db.get_setlist(setlist_id)
    if not setlist:
        return jsonify({'error': 'Setlist not found'}), 404
    return jsonify(setlist)


@app.route('/api/v2/setlists/<setlist_id>', methods=['PUT'])
@requires_auth
@verify_firebase_token
def update_setlist(setlist_id):
    """
    Update a setlist.

    Request body (all fields optional):
    {
        "name": "New Name",
        "items": [
            {"song_title": "502 Blues", "concert_key": "ef", "is_set_break": false, "octave_offset": 0},
            ...
        ]
    }

    Note: If items is provided, it replaces ALL existing items.

    Returns: The updated setlist, or 404 if not found
    """
    data = request.get_json()
    if not data:
        return jsonify({'error': 'Request body must be JSON'}), 400

    name = data.get('name')
    items = data.get('items')

    # Validate items structure if provided (song_title and concert_key required unless is_set_break)
    if items is not None:
        for item in items:
            is_set_break = item.get('is_set_break', False)
            if not is_set_break:
                if 'song_title' not in item or 'concert_key' not in item:
                    return jsonify({'error': 'Each item must have song_title and concert_key (unless is_set_break)'}), 400

    setlist = db.update_setlist(setlist_id, name=name, items=items)
    if not setlist:
        return jsonify({'error': 'Setlist not found'}), 404

    return jsonify(setlist)


@app.route('/api/v2/setlists/<setlist_id>', methods=['DELETE'])
@requires_auth
@verify_firebase_token
def delete_setlist(setlist_id):
    """
    Delete a setlist (soft delete).

    Returns: 204 No Content on success, 404 if not found
    """
    deleted = db.delete_setlist(setlist_id)
    if not deleted:
        return jsonify({'error': 'Setlist not found'}), 404

    return '', 204


def validate_startup():
    """Validate required configuration on startup."""
    errors = []

    # Initialize catalog database
    try:
        init_catalog_db()
    except FileNotFoundError:
        errors.append(f"{DB_FILE} not found. Run build_catalog.py first!")
    except Exception as e:
        errors.append(f"Failed to load catalog database: {e}")

    # Initialize setlists database
    try:
        db.init_setlists_db()
        print("✅ Setlists database initialized")
    except Exception as e:
        errors.append(f"Failed to initialize setlists database: {e}")

    # Validate S3 configuration if enabled
    if USE_S3:
        if not s3_client:
            print("⚠️  Warning: S3 enabled but client initialization failed")
        else:
            # Test S3 connectivity
            try:
                s3_client.head_bucket(Bucket=S3_BUCKET)
                print(f"✅ S3 bucket '{S3_BUCKET}' is accessible")
            except ClientError as e:
                error_code = e.response['Error']['Code']
                if error_code == '404':
                    errors.append(f"S3 bucket '{S3_BUCKET}' does not exist")
                elif error_code == '403':
                    errors.append(f"No permission to access S3 bucket '{S3_BUCKET}'")
                else:
                    print(f"⚠️  Warning: Could not verify S3 bucket access: {e}")

    # Check for required environment variables in production
    if os.getenv('PORT'):  # Assume production if PORT env var is set
        if USE_S3 and not os.getenv('AWS_ACCESS_KEY_ID'):
            errors.append("AWS_ACCESS_KEY_ID not set (required when USE_S3=true in production)")
        if USE_S3 and not os.getenv('AWS_SECRET_ACCESS_KEY'):
            errors.append("AWS_SECRET_ACCESS_KEY not set (required when USE_S3=true in production)")

    if errors:
        print("\n❌ STARTUP VALIDATION FAILED:")
        for error in errors:
            print(f"   • {error}")
        print("\nCannot start server. Fix the errors above and try again.\n")
        sys.exit(1)


# Initialize database and validate configuration at module load time
# (needed for gunicorn which doesn't run __main__ block)
validate_startup()


if __name__ == '__main__':
    # Listen on all interfaces to allow iPad access on local network
    # Port 5001 (5000 is often used by AirPlay on macOS)
    PORT = 5001
    local_ip = get_local_ip()

    print("\n" + "="*70)
    print("🎵  JAZZ PICKER IS RUNNING!")
    print("="*70)
    print(f"\n📱 On this computer:")
    print(f"   → http://localhost:{PORT}")
    print(f"\n📱 From iPad/iPhone on same WiFi network:")
    print(f"   → http://{local_ip}:{PORT}")
    print(f"\n💡 Tip: Bookmark the iPad URL for quick access!")
    print("\n" + "="*70 + "\n")

    app.run(debug=True, host='0.0.0.0', port=PORT)
