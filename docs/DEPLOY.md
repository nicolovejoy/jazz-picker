# Deployment

## Automatic (Eric's updates)

GitHub workflow in Eric's repo (`.github/workflows/update-catalog.yml`):
1. Rebuilds `catalog.db` from lilypond-lead-sheets + custom-charts
2. Uploads to S3
3. Restarts Fly.io app
4. Clears standard PDF cache

Template lives in jazz-picker repo. Eric must sync changes manually.

## Manual

```bash
# Rebuild catalog with custom charts
python build_catalog.py --ranges-file lilypond-data/Wrappers/range-data.txt --custom-dir custom-charts

# Upload catalog and restart
aws s3 cp catalog.db s3://jazz-picker-pdfs/catalog.db
fly deploy

# Clear standard PDF cache (optional)
aws s3 rm s3://jazz-picker-pdfs/generated/ --recursive

# Clear custom PDF cache (optional)
aws s3 rm s3://jazz-picker-custom-pdfs/generated/ --recursive
```

## Testing

```bash
python3 test_catalog.py  # Verifies standard + custom songs included
```

## Verification

```bash
curl -s https://jazz-picker.fly.dev/api/v2/catalog | jq '.total'
```
