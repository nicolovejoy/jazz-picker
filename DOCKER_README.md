# Docker Setup for Jazz Picker

## Building and Running

### Option 1: Docker Compose (Recommended)
```bash
# Build and run
docker-compose up --build

# Run in background
docker-compose up -d

# Stop
docker-compose down
```

### Option 2: Docker directly
```bash
# Build image
docker build -t jazz-picker .

# Run container
docker run -p 5001:5001 -v $(pwd)/cache:/app/cache jazz-picker

# Run with live code reload (development)
docker run -p 5001:5001 \
  -v $(pwd)/cache:/app/cache \
  -v $(pwd)/lilypond-data:/app/lilypond-data \
  jazz-picker
```

## Testing the Setup

```bash
# Check if container is running
docker ps

# View logs
docker logs <container_id>

# Test PDF generation
curl http://localhost:5001/pdf/A%20Child%20Is%20Born%20-%20Ly%20-%20Db%20Alto%20Voice.ly -o test.pdf

# Check cache directory
ls -lh cache/pdfs/
```

## How It Works

1. **First Request**: Compiles PDF with LilyPond (~5 seconds) → saves to cache
2. **Subsequent Requests**: Serves from cache instantly
3. **Cache Persistence**: `cache/` directory mounted as volume, survives container restarts

## LilyPond Version

Currently using Ubuntu's LilyPond 2.24. To upgrade to 2.25:

1. Add PPA or build from source in Dockerfile
2. Or wait for 2.25 official release

## Deployment

This Docker setup works on:
- Railway.app (with persistent volumes)
- Fly.io (with volumes)
- Any cloud provider supporting Docker + persistent storage
