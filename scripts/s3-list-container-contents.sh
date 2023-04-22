#!/bin/sh
export S3_ENDPOINT_URL="%%S3_ENDPOINT_URL%%"
export BUCKET_NAME="%%BUCKET_NAME%%"
aws s3 ls s3://$BUCKET_NAME --endpoint-url=$S3_ENDPOINT_URL | awk '{print $4;}' 
