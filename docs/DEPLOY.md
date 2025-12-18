# Deployment

## Automatic (Eric's updates)

GitHub workflow in `.github/workflows/update-catalog.yml`:
1. Rebuilds `catalog.db` from lilypond-lead-sheets
2. Uploads to S3
3. Deploys to Fly.io (rebuilds Docker image with fresh LilyPond source)
4. Clears S3 PDF cache

## Manual

```bash
# Rebuild catalog locally
python build_catalog.py --ranges-file lilypond-data/Wrappers/range-data.txt

# Upload and restart
aws s3 cp catalog.db s3://jazz-picker-pdfs/catalog.db
flyctl apps restart jazz-picker

# Full redeploy (if LilyPond source changed)
fly deploy
aws s3 rm s3://jazz-picker-pdfs/generated/ --recursive
```

## Verification

```bash
curl -s https://jazz-picker.fly.dev/api/v2/catalog | jq '.total'
```
