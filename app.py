#!/usr/bin/env python3
"""
Jazz Picker - A web interface for browsing Eric's lilypond lead sheets.
"""

from flask import Flask, jsonify, request, send_from_directory, make_response
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

# Crop detector is optional - may not be available in all environments
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


@app.route('/api/v2/songs')
@requires_auth
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


def generate_wrapper_content(core_file, target_key, clef, instrument=""):
    """Generate LilyPond wrapper file content."""
    return f'''%% -*- Mode: LilyPond -*-

\\version "2.24.0"

\\include "english.ly"

instrument = "{instrument}"
whatKey = {target_key}
whatClef = "{clef}"

\\include "../Core/{core_file}"
'''


@app.route('/api/v2/songs/<path:song_title>/cached')
@requires_auth
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
def generate_pdf():
    """
    Generate a PDF for any song in any concert key.

    Request body:
    {
        "song": "502 Blues",           // Song title
        "concert_key": "eb",           // Concert key (what the audience hears)
        "transposition": "Bb",         // Instrument transposition: C, Bb, or Eb
        "clef": "treble",              // "treble" or "bass"
        "instrument_label": "Trumpet"  // Optional label for PDF subtitle
    }

    Returns:
    {
        "url": "https://s3.../502-blues-eb-Bb-treble.pdf",
        "cached": true/false,
        "generation_time_ms": 2340
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

    # Look up song in database
    core_files = db.get_core_files(song_title)
    if not core_files:
        return jsonify({'error': f'Song not found: {song_title}'}), 404

    # Use the first core file (most songs have exactly one)
    core_file = core_files[0]

    # Calculate written key for LilyPond
    written_key = concert_to_written(concert_key, transposition)

    # Generate S3 key: {slug}-{concert_key}-{transposition}-{clef}.pdf
    slug = slugify(song_title)
    s3_key = f"generated/{slug}-{concert_key}-{transposition}-{clef}.pdf"

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
                'generation_time_ms': generation_time
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
    wrapper_content = generate_wrapper_content(core_file, written_key, clef, instrument_label)

    # Local filename matches S3 key format
    file_base = f"{slug}-{concert_key}-{transposition}-{clef}"

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
                    'generation_time_ms': generation_time
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
