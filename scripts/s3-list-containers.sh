#!/bin/sh
export S3_ENDPOINT_URL="%%S3_ENDPOINT_URL%%"
aws s3 ls --endpoint-url=$S3_ENDPOINT_URL | cut -f 3 -d " "
