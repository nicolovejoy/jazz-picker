#!/bin/bash
#
# sync_pdfs_to_s3.sh
#
# Sync compiled PDFs from Dropbox to S3 bucket
# Run this after compilation and catalog.json update
#

set -e  # Exit on error

# Configuration
S3_BUCKET="jazz-picker-pdfs"
DRYRUN=false

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --dryrun)
      DRYRUN=true
      shift
      ;;
    --bucket)
      S3_BUCKET="$2"
      shift 2
      ;;
    *)
      echo "Unknown option: $1"
      echo "Usage: $0 [--dryrun] [--bucket BUCKET_NAME]"
      exit 1
      ;;
  esac
done

# Set dryrun flag if requested
SYNC_FLAGS=""
if [ "$DRYRUN" = true ]; then
  SYNC_FLAGS="--dryrun"
  echo "🔍 DRY RUN MODE - No files will be uploaded"
  echo ""
fi

echo "🎵 Jazz Picker - PDF Sync to S3"
echo "================================"
echo "Bucket: s3://$S3_BUCKET"
echo ""

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo "❌ Error: AWS CLI not found. Please install it first:"
    echo "   brew install awscli"
    exit 1
fi

# Check if AWS credentials are configured
if ! aws sts get-caller-identity &> /dev/null; then
    echo "❌ Error: AWS credentials not configured. Please run:"
    echo "   aws configure"
    exit 1
fi

# Function to sync a directory
sync_directory() {
  local source_dir="$1"
  local dest_path="$2"

  if [ ! -d "$source_dir" ]; then
    echo "⚠️  Skipping $source_dir (not found)"
    return
  fi

  echo "📁 Syncing: $source_dir -> s3://$S3_BUCKET/$dest_path"

  aws s3 sync "$source_dir/" "s3://$S3_BUCKET/$dest_path/" \
    --exclude "*" \
    --include "*.pdf" \
    --delete \
    $SYNC_FLAGS

  if [ $? -eq 0 ]; then
    echo "   ✅ Done"
  else
    echo "   ❌ Failed"
  fi
  echo ""
}

# Sync all directories
echo "Starting sync..."
echo ""

sync_directory "Alto Voice" "Alto-Voice"
sync_directory "Baritone Voice" "Baritone-Voice"
sync_directory "Standard" "Standard"
sync_directory "Midi" "Midi"
sync_directory "Others" "Others"

echo "================================"
if [ "$DRYRUN" = true ]; then
  echo "✅ Dry run complete! Review the output above."
  echo "   To actually upload, run without --dryrun"
else
  echo "✅ All PDFs synced to S3!"
  echo ""
  echo "Next steps:"
  echo "1. Test the app to make sure PDFs load"
  echo "2. Commit catalog.json if updated"
fi
echo ""
