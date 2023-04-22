#!/bin/sh
export BUCKET_NAME="%%BUCKET_NAME%%"
export S3_ENDPOINT_URL="%%S3_ENDPOINT_URL%%"
aws s3 mb --endpoint-url=$S3_ENDPOINT_URL s3://$BUCKET_NAME
