#!/bin/sh
export BUCKET_NAME="%%BUCKET_NAME%%"
export OBJECT_NAME="%%OBJECT_NAME%%"
export S3_ENDPOINT_URL="%%S3_ENDPOINT_URL%%"
aws s3 rm --endpoint-url=$S3_ENDPOINT_URL s3://$BUCKET_NAME/$OBJECT_NAME
