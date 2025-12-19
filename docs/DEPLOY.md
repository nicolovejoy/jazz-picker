# Deployment

## Automatic (Eric's updates)

GitHub workflow `.github/workflows/update-catalog.yml`:
1. Rebuilds `catalog.db` from lilypond-lead-sheets
2. Uploads to S3
3. Deploys to Fly.io
4. Clears standard PDF cache (not custom)

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

## Verification

```bash
curl -s https://jazz-picker.fly.dev/api/v2/catalog | jq '.total'
```
