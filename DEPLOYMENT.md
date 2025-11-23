# Deployment Guide

This guide covers deploying the Jazz Picker backend to Fly.io.

## Prerequisites

1. **Fly.io account**: Sign up at https://fly.io
2. **Fly CLI**: Install with `brew install flyctl` (Mac) or see https://fly.io/docs/hands-on/install-flyctl/
3. **AWS credentials**: For S3 access (if not already configured)

## Quick Deploy to Fly.io

### 1. Login to Fly.io

```bash
fly auth login
```

### 2. Create Fly.io App (First Time Only)

```bash
# In the project root directory
fly launch

# When prompted:
# - App name: jazz-picker (or your preferred name)
# - Region: iad (US East, same as S3)
# - Postgres database: No
# - Redis: No
# - Deploy now: No (we'll set secrets first)
```

This creates the app and uses the existing `fly.toml` configuration.

### 3. Set AWS Secrets

Your app needs AWS credentials to access S3:

```bash
# Set AWS credentials as secrets
fly secrets set AWS_ACCESS_KEY_ID=<your-key-id>
fly secrets set AWS_SECRET_ACCESS_KEY=<your-secret-key>

# Verify secrets are set (values will be redacted)
fly secrets list
```

### 4. Deploy

```bash
fly deploy
```

This will:
- Build the Docker image using `Dockerfile.prod`
- Deploy to Fly.io
- Start the app with health checks
- Set up HTTPS automatically

### 5. Verify Deployment

```bash
# Check app status
fly status

# View logs
fly logs

# Open in browser
fly open

# Test health endpoint
fly open /health

# Test API
fly open /api/v2/songs?limit=5
```

## Environment Variables

Set in `fly.toml` (public) or as secrets (private):

### Public (in fly.toml)
- `PORT`: 5001
- `USE_S3`: true
- `S3_REGION`: us-east-1
- `S3_BUCKET_NAME`: jazz-picker-pdfs

### Secrets (set with `fly secrets set`)
- `AWS_ACCESS_KEY_ID`: Your AWS access key
- `AWS_SECRET_ACCESS_KEY`: Your AWS secret key

## Updating the App

After making code changes:

```bash
# Deploy updated code
fly deploy

# Force rebuild
fly deploy --no-cache
```

## Monitoring

```bash
# View real-time logs
fly logs

# Check app status
fly status

# View app dashboard
fly dashboard
```

## Scaling

```bash
# Scale up memory (if needed)
fly scale memory 1024

# Scale to multiple regions (future)
fly regions add lax  # Los Angeles
fly regions add fra  # Frankfurt
```

## Troubleshooting

### App won't start

```bash
# Check logs for errors
fly logs

# Common issues:
# - Missing AWS secrets
# - catalog.json not in image
# - S3 permissions
```

### Health check failing

```bash
# Test health endpoint locally first
curl http://localhost:5001/health

# Check Fly.io health status
fly checks list
```

### S3 access denied

Ensure your AWS IAM user has:
- `s3:GetObject` permission on `jazz-picker-pdfs/*`
- `s3:ListBucket` permission on `jazz-picker-pdfs`

## Cost Estimation

**Fly.io Free Tier includes:**
- 3 shared-cpu-1x VMs (256MB RAM each)
- 160GB bandwidth/month

**This app uses:**
- 1 VM with 512MB RAM (within free tier if only app)
- Minimal bandwidth (PDFs served from S3)

**Estimated cost:** $0-5/month depending on usage

## Local Testing

Test the production Docker image locally before deploying:

```bash
# Build production image
docker build -f Dockerfile.prod -t jazz-picker-prod .

# Run with environment variables
docker run -p 5001:5001 \
  -e AWS_ACCESS_KEY_ID=<your-key> \
  -e AWS_SECRET_ACCESS_KEY=<your-secret> \
  jazz-picker-prod

# Test in browser
open http://localhost:5001/health
```

## Frontend Deployment

The React frontend should be deployed separately to a static hosting service:

- **Cloudflare Pages** (recommended): Free, fast CDN
- **Vercel**: Free tier, good DX
- **Netlify**: Free tier, easy setup

Update the frontend's API base URL to point to your Fly.io backend:

```typescript
// frontend/src/services/api.ts
const API_BASE = 'https://jazz-picker.fly.dev/api';
```

## Next Steps

After deployment:

1. **Custom domain** (optional):
   ```bash
   fly certs add yourdomain.com
   ```

2. **Set up frontend** deployment

3. **Monitor logs** for any errors

4. **Phase 2**: Add server-side LilyPond compilation
