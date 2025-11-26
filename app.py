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
CORS(app, origins=[
    "http://localhost:5173",
    "http://localhost:5174",
    "https://*.vercel.app",
    "https://jazz-picker.vercel.app",
])

# Constants for validation
MAX_LIMIT = 200
VALID_INSTRUMENTS = {'All', 'C', 'Bb', 'Eb', 'Bass'}
VALID_RANGES = {'All', 'Alto/Mezzo/Soprano', 'Baritone/Tenor/Bass', 'Standard'}

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
    range_filter = request.args.get('range', 'All')

    # Validate filters
    if instrument_filter not in VALID_INSTRUMENTS:
        return jsonify({'error': f'Invalid instrument. Must be one of: {", ".join(VALID_INSTRUMENTS)}'}), 400

    if range_filter not in VALID_RANGES:
        return jsonify({'error': f'Invalid range. Must be one of: {", ".join(VALID_RANGES)}'}), 400
    
    # Filter songs
    filtered_songs = []
    for title, data in catalog_data['songs'].items():
        # 1. Filter by Search Query
        if query and query not in title.lower():
            continue

        # Calculate available instruments and ranges for MATCHING variations only
        instruments = set()
        ranges = set()
        matching_variations = 0

        for var in data['variations']:
            v_type = var['variation_type']

            # Check if this variation matches the requested filters
            match_instrument = False
            if instrument_filter == 'All':
                match_instrument = True
            elif instrument_filter == 'C' and 'Standard' in v_type:
                match_instrument = True
            elif instrument_filter == 'Bb' and 'Bb Instrument' in v_type:
                match_instrument = True
            elif instrument_filter == 'Eb' and 'Eb Instrument' in v_type:
                match_instrument = True
            elif instrument_filter == 'Bass' and v_type == 'Bass':
                match_instrument = True

            match_range = False
            if range_filter == 'All':
                match_range = True
            elif range_filter == 'Alto/Mezzo/Soprano' and 'Alto' in v_type:
                match_range = True
            elif range_filter == 'Baritone/Tenor/Bass' and 'Baritone' in v_type:
                match_range = True
            elif range_filter == 'Standard' and 'Standard' in v_type:
                match_range = True

            # Only add instruments/ranges for variations that match BOTH filters
            if match_instrument and match_range:
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

                # Add range category for this MATCHING variation
                if 'Alto' in v_type:
                    ranges.add('Alto/Mezzo/Soprano')
                elif 'Baritone' in v_type:
                    ranges.add('Baritone/Tenor/Bass')
                elif 'Standard' in v_type:
                    ranges.add('Standard')

        # Only include song if it has at least one variation matching the filters
        if matching_variations > 0:
            filtered_songs.append({
                'title': title,
                'variation_count': matching_variations,
                'available_instruments': sorted(list(instruments)),
                'available_ranges': sorted(list(ranges))
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
        'range': range_filter
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


def catalog_path_to_s3_key(pdf_path: str) -> str:
    """Convert catalog pdf_path to S3 key."""
    # "../Alto Voice/Song - Key" → "Alto-Voice/Song - Key.pdf"
    path = pdf_path.replace('../', '')
    # Replace spaces with hyphens in folder names only (not filenames)
    parts = path.split('/')
    if len(parts) > 1:
        # Replace spaces with hyphens in folder parts
        parts[:-1] = [part.replace(' ', '-') for part in parts[:-1]]
        path = '/'.join(parts)
    return f"{path}.pdf"


@app.route('/pdf/<path:filename>')
@requires_auth
def serve_pdf(filename):
    """Serve a PDF file via S3 presigned URL or local fallback."""
    if catalog_data is None:
        load_catalog()

    if not catalog_data:
        return jsonify({'error': 'Catalog not loaded'}), 500

    # Validate filename format (must end with .ly)
    if not filename or not filename.endswith('.ly'):
        return jsonify({'error': 'Invalid filename format. Must end with .ly'}), 400

    # Security: Prevent directory traversal
    if '..' in filename or filename.startswith('/'):
        return jsonify({'error': 'Invalid filename'}), 400

    # Find variation in catalog
    variation = None
    for song_data in catalog_data['songs'].values():
        for var in song_data['variations']:
            if var['filename'] == filename:
                variation = var
                break
        if variation:
            break

    if not variation:
        return jsonify({'error': 'Variation not found in catalog'}), 404

    # Create cache key from filename
    cache_key = filename.replace('.ly', '.pdf')
    cache_path = CACHE_DIR / cache_key

    # Try S3 presigned URL first (production)
    if s3_client:
        try:
            s3_key = catalog_path_to_s3_key(variation['pdf_path'])

            # Generate presigned URL (15 min expiry)
            url = s3_client.generate_presigned_url(
                'get_object',
                Params={
                    'Bucket': S3_BUCKET,
                    'Key': s3_key
                },
                ExpiresIn=900  # 15 minutes
            )

            response = make_response(jsonify({
                'url': url,
                'expires_at': (datetime.utcnow() + timedelta(minutes=15)).isoformat() + 'Z',
                'source': 's3',
                'size_bytes': None  # Could add HEAD request to get size
            }))

            # Cache for 10 minutes (shorter than URL expiry)
            return add_cache_headers(response, max_age=600)
        except ClientError as e:
            # S3 object not found, fall through to local sources
            print(f"⚠️  S3 error for {s3_key}: {e}")
            pass

    # Fallback 1: Check local cache
    if cache_path.exists():
        return send_file(cache_path, mimetype='application/pdf')

    # Fallback 2: Try Dropbox symlinks (local development only)
    pdf_path_relative = variation['pdf_path']
    if pdf_path_relative.startswith('../'):
        pdf_path_relative = pdf_path_relative[3:]  # Remove "../"

    dropbox_path = Path(pdf_path_relative + '.pdf')
    if dropbox_path.exists():
        # Copy to cache for future requests
        import shutil
        cache_path.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(dropbox_path, cache_path)
        return send_file(cache_path, mimetype='application/pdf')

    # If PDF doesn't exist, compile it
    try:
        # Run lilypond in the Wrappers directory
        result = subprocess.run(
            ['lilypond', filename],
            cwd=WRAPPERS_DIR,
            capture_output=True,
            text=True,
            timeout=60  # Increased to 60 seconds
        )

        if result.returncode != 0:
            # Extract the most relevant error lines
            stderr_lines = result.stderr.split('\n')
            error_summary = []

            # Get first few errors
            for line in stderr_lines:
                if 'error:' in line.lower():
                    error_summary.append(line.strip())
                    if len(error_summary) >= 5:
                        break

            error_text = '\n'.join(error_summary) if error_summary else result.stderr[:500]

            return jsonify({
                'error': 'LilyPond compilation failed',
                'details': error_text,
                'hint': 'This usually means you need LilyPond 2.25 (development version). Check: lilypond --version'
            }), 500

        # Move the generated PDF to cache
        generated_pdf = Path(WRAPPERS_DIR) / filename.replace('.ly', '.pdf')

        if not generated_pdf.exists():
            return jsonify({'error': 'PDF not generated'}), 500

        # Move to cache
        import shutil
        cache_path.parent.mkdir(parents=True, exist_ok=True)
        shutil.move(str(generated_pdf), str(cache_path))

        # Clean up MIDI file if it exists
        midi_file = Path(WRAPPERS_DIR) / filename.replace('.ly', '.midi')
        if midi_file.exists():
            midi_file.unlink()  # Delete MIDI for now

        return send_file(cache_path, mimetype='application/pdf')

    except subprocess.TimeoutExpired:
        return jsonify({'error': 'Compilation timed out'}), 500
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@app.route('/api/check-pdf/<path:filename>')
@requires_auth
def check_pdf(filename):
    """Check if a PDF exists without compiling."""
    variation = None
    for song_data in catalog_data['songs'].values():
        for var in song_data['variations']:
            if var['filename'] == filename:
                variation = var
                break
        if variation:
            break

    if not variation:
        return jsonify({'exists': False, 'error': 'Variation not found'})

    # Resolve path consistently with serve_pdf
    pdf_path_relative = variation['pdf_path']
    if pdf_path_relative.startswith('../'):
        pdf_path_relative = pdf_path_relative[3:]  # Remove "../"

    pdf_path = Path(pdf_path_relative).resolve()
    pdf_path = Path(str(pdf_path) + '.pdf')
    return jsonify({'exists': pdf_path.exists(), 'path': str(pdf_path)})


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
