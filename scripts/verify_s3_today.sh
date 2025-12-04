#!/usr/bin/env bash
set -euo pipefail

BUCKET="$1"

echo "S3 Contents (all):"
aws s3 ls "s3://${BUCKET}/" --recursive || { echo "aws s3 ls failed"; exit 1; }

echo
echo "📅 Verifying today's folder exists..."

TODAY=$(date +%Y%m%d)

# List top-level prefixes (folders)
PREFIXES=$(aws s3 ls "s3://${BUCKET}/" | awk '{print $2}')

echo "${PREFIXES}"

if echo "${PREFIXES}" | grep -q "^${TODAY}-"; then
  echo "✅ Found folder for today (${TODAY}-) in bucket ${BUCKET}"
else
  echo "❌ No folder for today (${TODAY}-) found in bucket ${BUCKET}"
  exit 1
fi

