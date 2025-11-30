#!/usr/bin/env python3
"""
Jazz Picker - A web interface for browsing Eric's lilypond lead sheets.
"""

from flask import Flask, render_template, jsonify, request, send_file, send_from_directory, make_response
from flask_cors import CORS
import json
import subprocess
import os
import socket
from pathlib import Path
from datetime import datetime, timedelta
from functools import wraps, lru_cache
import boto3
from botocore.exceptions import ClientError
import sys
import hashlib

app = Flask(__name__)

# Enable CORS for frontend domains
CORS(app, resources={r"/*": {"origins": "*"}})

# Constants for validation
MAX_LIMIT = 200
VALID_INSTRUMENTS = {'All', 'C', 'Bb', 'Eb', 'Bass'}

# Load catalog
CATALOG_FILE = 'catalog.json'
catalog_data = None
catalog_etag = None  # ETag for catalog version
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


def load_catalog():
    """Load the catalog from JSON file or S3."""
    global catalog_data, catalog_etag

    # Try S3 first if enabled
    if USE_S3 and s3_client:
        try:
            print(f"⬇️  Fetching catalog from S3 ({S3_BUCKET})...")
            response = s3_client.get_object(Bucket=S3_BUCKET, Key=CATALOG_FILE)
            catalog_data = json.loads(response['Body'].read().decode('utf-8'))
            print(f"✅ Loaded catalog from S3 ({catalog_data['metadata']['total_songs']} songs)")

            # Generate ETag from catalog metadata (timestamp + total songs)
            etag_source = f"{catalog_data['metadata']['generated']}-{catalog_data['metadata']['total_songs']}"
            catalog_etag = hashlib.md5(etag_source.encode()).hexdigest()

            return catalog_data
        except Exception as e:
            print(f"⚠️  Could not load catalog from S3: {e}")
            print("   Falling back to local file...")

    # Fallback to local file
    try:
        with open(CATALOG_FILE, 'r', encoding='utf-8') as f:
            catalog_data = json.load(f)
        print(f"✅ Loaded catalog from local file ({catalog_data['metadata']['total_songs']} songs)")

        # Generate ETag from catalog metadata
        etag_source = f"{catalog_data['metadata']['generated']}-{catalog_data['metadata']['total_songs']}"
        catalog_etag = hashlib.md5(etag_source.encode()).hexdigest()
    except FileNotFoundError:
        print("❌ Catalog not found locally or on S3.")
        catalog_data = None
        catalog_etag = None

    return catalog_data


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
    if catalog_data is None:
        load_catalog()

    total_songs = catalog_data['metadata']['total_songs'] if catalog_data else 0
    total_variations = catalog_data['metadata']['total_files'] if catalog_data else 0

    return jsonify({
        'name': 'Jazz Picker API',
        'version': '2.0',
        'description': 'Browse and search Eric\'s jazz lead sheet collection',
        'catalog': {
            'total_songs': total_songs,
            'total_variations': total_variations,
            'loaded': catalog_data is not None
        },
        'endpoints': {
            'health': '/health',
            'songs_v2': '/api/v2/songs?limit=20&offset=0&instrument=All&range=All',
            'song_details': '/api/v2/songs/{title}',
            'pdf': '/pdf/{filename}',
            'search': '/api/songs/search?q={query}'
        },
        'frontend': 'https://jazz-picker.pages.dev (or your deployment URL)'
    })


@app.route('/health')
def health():
    """Health check endpoint for deployment platforms."""
    health_status = {
        'status': 'healthy',
        'catalog_loaded': catalog_data is not None,
        's3_enabled': USE_S3,
        's3_configured': s3_client is not None
    }

    if catalog_data:
        health_status['total_songs'] = catalog_data['metadata']['total_songs']
        health_status['total_variations'] = catalog_data['metadata']['total_files']

    return jsonify(health_status), 200


@app.route('/api/songs')
@requires_auth
def get_songs():
    """API endpoint to get all songs (Legacy v1)."""
    if catalog_data is None:
        load_catalog()
        
    if not catalog_data:
        return jsonify([])

    # Convert songs dict to sorted list
    songs_list = [
        {
            'title': title,
            **data
        }
        for title, data in catalog_data['songs'].items()
    ]

    # Sort alphabetically
    songs_list.sort(key=lambda x: x['title'])

    return jsonify(songs_list)


@app.route('/api/v2/songs')
@requires_auth
def get_songs_v2():
    """API v2: Get paginated, slim song list."""
    if catalog_data is None:
        load_catalog()

    if not catalog_data:
        return jsonify({'error': 'Catalog not loaded', 'songs': [], 'total': 0}), 500

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

    query = request.args.get('q', '').lower()
    instrument_filter = request.args.get('instrument', 'All')

    # Validate filters
    if instrument_filter not in VALID_INSTRUMENTS:
        return jsonify({'error': f'Invalid instrument. Must be one of: {", ".join(VALID_INSTRUMENTS)}'}), 400
    
    # Filter songs
    filtered_songs = []
    for title, data in catalog_data['songs'].items():
        # 1. Filter by Search Query
        if query and query not in title.lower():
            continue

        # Calculate available instruments for MATCHING variations only
        instruments = set()
        matching_variations = 0

        for var in data['variations']:
            v_type = var['variation_type']

            # Check if this variation matches the instrument filter
            match_instrument = False
            if instrument_filter == 'All':
                match_instrument = True
            elif instrument_filter == 'C' and ('Standard' in v_type or 'Alto' in v_type or 'Baritone' in v_type):
                match_instrument = True
            elif instrument_filter == 'Bb' and 'Bb Instrument' in v_type:
                match_instrument = True
            elif instrument_filter == 'Eb' and 'Eb Instrument' in v_type:
                match_instrument = True
            elif instrument_filter == 'Bass' and v_type == 'Bass':
                match_instrument = True

            if match_instrument:
                matching_variations += 1

                # Add instrument category for this MATCHING variation
                if 'Standard' in v_type:
                    instruments.add('C')
                if 'Bb Instrument' in v_type:
                    instruments.add('Bb')
                if 'Eb Instrument' in v_type:
                    instruments.add('Eb')
                if v_type == 'Bass':
                    instruments.add('Bass')

        # Only include song if it has at least one variation matching the filter
        if matching_variations > 0:
            filtered_songs.append({
                'title': title,
                'variation_count': matching_variations,
                'available_instruments': sorted(list(instruments)),
            })

    # Sort alphabetically
    filtered_songs.sort(key=lambda x: x['title'])
    
    # Paginate
    total = len(filtered_songs)
    paginated_songs = filtered_songs[offset : offset + limit]

    # Check ETag - if client has current version, return 304
    if check_etag(catalog_etag):
        return make_response('', 304)

    # Create response with caching headers
    response = make_response(jsonify({
        'songs': paginated_songs,
        'total': total,
        'limit': limit,
        'offset': offset,
        'instrument': instrument_filter,
    }))

    # Add caching headers (5 minutes for song lists)
    return add_cache_headers(response, max_age=300, etag=catalog_etag)


@app.route('/api/songs/search')
@requires_auth
def search_songs():
    """API endpoint to search songs by title."""
    if catalog_data is None:
        load_catalog()
        
    if not catalog_data:
        return jsonify([])

    query = request.args.get('q', '').lower()
    variation_filter = request.args.get('variation', None)

    if not query and not variation_filter:
        return jsonify([])

    results = []
    for title, data in catalog_data['songs'].items():
        # Filter by title
        if query and query not in title.lower():
            continue

        # Filter by variation type if specified
        variations = data['variations']
        if variation_filter:
            variations = [v for v in variations if v['variation_type'] == variation_filter]

        if variations:
            results.append({
                'title': title,
                'core_files': data['core_files'],
                'variations': variations
            })

    # Sort results
    results.sort(key=lambda x: x['title'])

    return jsonify(results)


@app.route('/api/song/<path:song_title>')
@requires_auth
def get_song(song_title):
    """API endpoint to get a specific song's details (Legacy v1)."""
    if catalog_data is None:
        load_catalog()
        
    if not catalog_data:
        return jsonify({'error': 'Catalog not loaded'}), 500

    if song_title in catalog_data['songs']:
        return jsonify({
            'title': song_title,
            **catalog_data['songs'][song_title]
        })
    else:
        return jsonify({'error': 'Song not found'}), 404


@app.route('/api/v2/songs/<path:song_title>')
@requires_auth
def get_song_v2(song_title):
    """API v2: Get specific song details."""
    if catalog_data is None:
        load_catalog()

    if not catalog_data:
        return jsonify({'error': 'Catalog not loaded'}), 500

    if song_title in catalog_data['songs']:
        # Check ETag - if client has current version, return 304
        if check_etag(catalog_etag):
            return make_response('', 304)

        song_data = catalog_data['songs'][song_title]

        # Transform variations for v2
        variations = []
        for var in song_data['variations']:
            variations.append({
                'id': var.get('filename', '').replace('.ly', ''),  # Use filename as ID
                'display_name': var.get('display_name', ''),
                'key': var.get('key', ''),
                'instrument': var.get('instrument', ''),
                'variation_type': var.get('variation_type', ''),
                'filename': var.get('filename', '')
            })

        response = make_response(jsonify({
            'title': song_title,
            'variations': variations
        }))

        # Add caching headers (10 minutes for song details)
        return add_cache_headers(response, max_age=600, etag=catalog_etag)
    else:
        return jsonify({'error': 'Song not found'}), 404


# LilyPond generation constants
LILYPOND_DATA_DIR = Path('lilypond-data')
GENERATED_DIR = LILYPOND_DATA_DIR / 'Generated'  # Inside lilypond-data for correct relative paths
VALID_KEYS = {'c', 'cs', 'df', 'd', 'ds', 'ef', 'e', 'f', 'fs', 'gf', 'g', 'gs', 'af', 'a', 'as', 'bf', 'b'}
VALID_CLEFS = {'treble', 'bass'}


def slugify(text):
    """Convert text to a safe filename slug."""
    import re
    text = text.lower()
    text = re.sub(r'[^\w\s-]', '', text)
    text = re.sub(r'[\s_-]+', '-', text)
    return text.strip('-')


def generate_wrapper_content(core_file, target_key, clef, instrument_label):
    """Generate LilyPond wrapper file content."""
    return f'''%% -*- Mode: LilyPond -*-

\\version "2.24.0"

\\include "english.ly"

instrument = "{instrument_label}"
whatKey = {target_key}
whatClef = "{clef}"

\\include "../Core/{core_file}"
'''


@app.route('/api/v2/generate', methods=['POST'])
@requires_auth
def generate_pdf():
    """
    Generate a PDF for any song in any key.

    Request body:
    {
        "song": "502 Blues",      // Song title
        "key": "c",               // Target key (LilyPond notation)
        "clef": "treble"          // "treble" or "bass"
    }

    Returns:
    {
        "url": "https://s3.../generated/502-blues-c-treble.pdf",
        "cached": true/false,
        "generation_time_ms": 2340
    }
    """
    import time
    start_time = time.time()

    if catalog_data is None:
        load_catalog()

    if not catalog_data:
        return jsonify({'error': 'Catalog not loaded'}), 500

    # Parse request
    data = request.get_json()
    if not data:
        return jsonify({'error': 'Request body must be JSON'}), 400

    song_title = data.get('song')
    target_key = data.get('key', '').lower()
    clef = data.get('clef', 'treble').lower()

    # Validate inputs
    if not song_title:
        return jsonify({'error': 'Missing required field: song'}), 400

    if not target_key:
        return jsonify({'error': 'Missing required field: key'}), 400

    if target_key not in VALID_KEYS:
        return jsonify({'error': f'Invalid key. Must be one of: {", ".join(sorted(VALID_KEYS))}'}), 400

    if clef not in VALID_CLEFS:
        return jsonify({'error': f'Invalid clef. Must be one of: {", ".join(VALID_CLEFS)}'}), 400

    # Look up song in catalog
    if song_title not in catalog_data['songs']:
        return jsonify({'error': f'Song not found: {song_title}'}), 404

    song_data = catalog_data['songs'][song_title]
    core_files = song_data.get('core_files', [])

    if not core_files:
        return jsonify({'error': f'No core file found for song: {song_title}'}), 500

    # Use the first core file (most songs have exactly one)
    core_file = core_files[0]

    # Generate S3 key for this variation
    slug = slugify(song_title)
    s3_key = f"generated/{slug}-{target_key}-{clef}.pdf"

    # Check if already cached in S3
    if s3_client:
        try:
            s3_client.head_object(Bucket=S3_BUCKET, Key=s3_key)
            # Already exists - return presigned URL
            url = s3_client.generate_presigned_url(
                'get_object',
                Params={'Bucket': S3_BUCKET, 'Key': s3_key},
                ExpiresIn=900
            )
            generation_time = int((time.time() - start_time) * 1000)
            return jsonify({
                'url': url,
                'cached': True,
                'generation_time_ms': generation_time
            })
        except ClientError as e:
            if e.response['Error']['Code'] != '404':
                print(f"⚠️  S3 error checking cache: {e}")
            # Not cached, continue to generate

    # Create generated directory if needed
    GENERATED_DIR.mkdir(parents=True, exist_ok=True)

    # Generate wrapper file
    instrument_label = f"{target_key.upper()} Key ({clef})"
    wrapper_content = generate_wrapper_content(core_file, target_key, clef, instrument_label)

    wrapper_filename = f"{slug}-{target_key}-{clef}.ly"
    wrapper_path = GENERATED_DIR / wrapper_filename
    pdf_path = GENERATED_DIR / f"{slug}-{target_key}-{clef}.pdf"

    try:
        # Write wrapper file
        with open(wrapper_path, 'w') as f:
            f.write(wrapper_content)

        # Run LilyPond from lilypond-data directory so includes resolve correctly
        result = subprocess.run(
            ['lilypond', '-o', f'Generated/{slug}-{target_key}-{clef}', f'Generated/{wrapper_filename}'],
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

        # Upload to S3 if available
        if s3_client:
            try:
                s3_client.upload_file(
                    str(pdf_path),
                    S3_BUCKET,
                    s3_key,
                    ExtraArgs={'ContentType': 'application/pdf'}
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
                return jsonify({
                    'url': url,
                    'cached': False,
                    'generation_time_ms': generation_time
                })
            except Exception as e:
                print(f"⚠️  Failed to upload to S3: {e}")
                # Fall through to local file serving

        # No S3 - serve from local file (development mode)
        generation_time = int((time.time() - start_time) * 1000)
        return jsonify({
            'url': f'/generated/{pdf_path.name}',
            'cached': False,
            'generation_time_ms': generation_time,
            'note': 'Local file (S3 not available)'
        })

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

    # Validate catalog loading
    try:
        load_catalog()
        if catalog_data is None:
            errors.append("Catalog failed to load from both S3 and local file")
        elif 'metadata' not in catalog_data or 'songs' not in catalog_data:
            errors.append("Catalog structure is invalid (missing metadata or songs)")
        else:
            print(f"✅ Loaded catalog with {catalog_data['metadata']['total_songs']} songs")
    except FileNotFoundError:
        errors.append(f"{CATALOG_FILE} not found. Run build_catalog.py first!")
    except Exception as e:
        errors.append(f"Failed to load catalog: {e}")

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


if __name__ == '__main__':
    # Validate configuration before starting
    validate_startup()

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
