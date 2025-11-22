# S3 Setup Guide for Eric

Quick guide to set up AWS S3 and sync PDFs.

## One-Time Setup (15 minutes)

### 1. Install AWS CLI

**macOS:**
```bash
brew install awscli
```

**Linux:**
```bash
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
```

### 2. Configure AWS Credentials

You'll need:
- AWS Access Key ID
- AWS Secret Access Key

(Nico can provide these, or you can create your own in AWS Console)

```bash
aws configure
# Enter Access Key ID
# Enter Secret Access Key
# Region: us-east-1
# Output format: json
```

### 3. Create S3 Bucket (First time only)

```bash
aws s3 mb s3://jazz-picker-pdfs
```

### 4. Test the Sync Script (Dry Run)

```bash
./sync_pdfs_to_s3.sh --dryrun
```

This shows what would be uploaded without actually uploading anything.

### 5. Do the First Upload

```bash
./sync_pdfs_to_s3.sh
```

This will upload all PDFs from:
- Alto Voice/
- Baritone Voice/
- Standard/
- Midi/
- Others/

**Note:** First sync might take 5-10 minutes to upload ~2GB. Subsequent syncs are much faster (only changed files).

---

## Regular Workflow (After Initial Setup)

After you compile PDFs, run these commands:

```bash
# 1. Compile PDFs (your existing process)
# ... your compilation script ...

# 2. Update catalog
python3 build_catalog.py

# 3. Sync to S3
./sync_pdfs_to_s3.sh

# 4. Commit changes (optional)
git add catalog.json
git commit -m "Update catalog with new songs"
git push
```

---

## Troubleshooting

**"AWS CLI not found"**
- Install it: `brew install awscli`

**"Credentials not configured"**
- Run: `aws configure`
- Ask Nico for access keys

**"Bucket does not exist"**
- Create it: `aws s3 mb s3://jazz-picker-pdfs`

**"Access Denied"**
- Check your AWS credentials
- Make sure you have S3 write permissions

**Want to see what changed?**
```bash
./sync_pdfs_to_s3.sh --dryrun
```

---

## Cost

- Storage: $0.023/GB = ~$0.05/month for 2GB
- Uploads: Free
- Downloads: $0.09/GB (but we use CloudFront which is cheaper)

**Total: Less than $1/month**

---

## Advanced Options

**Use different bucket:**
```bash
./sync_pdfs_to_s3.sh --bucket my-other-bucket
```

**Manual sync of single directory:**
```bash
aws s3 sync "Alto Voice/" s3://jazz-picker-pdfs/Alto-Voice/ \
  --include "*.pdf" --exclude "*"
```

**List what's in S3:**
```bash
aws s3 ls s3://jazz-picker-pdfs/ --recursive --human-readable
```

**Delete everything (be careful!):**
```bash
aws s3 rm s3://jazz-picker-pdfs/ --recursive
```
