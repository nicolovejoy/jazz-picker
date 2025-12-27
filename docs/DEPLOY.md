# Deployment

## Automatic (Eric's updates)

GitHub workflow in Eric's repo (`.github/workflows/update-catalog.yml`):
1. Rebuilds `catalog.db` from lilypond-lead-sheets + custom-charts
2. Uploads to S3
3. Deploys to Fly.io

Template lives in jazz-picker repo. Eric must sync changes manually.

## Cache Invalidation

PDF cache invalidation is automatic via `includeVersion` hash:
- `build_catalog.py` computes SHA256 of all Include/*.ily files
- Hash stored in catalog.db and in S3 PDF metadata
- On PDF request, backend compares hashes - regenerates if stale
- No manual cache clearing needed

## Manual

```bash
# Rebuild catalog with custom charts
python build_catalog.py --ranges-file lilypond-data/Wrappers/range-data.txt --custom-dir custom-charts

# Upload catalog and restart
aws s3 cp catalog.db s3://jazz-picker-pdfs/catalog.db
fly deploy
```

## Testing

```bash
python3 test_catalog.py  # Verifies standard + custom songs included
```

## Verification

```bash
curl -s https://jazz-picker.fly.dev/api/v2/catalog | jq '.total'
```
