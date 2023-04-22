#!/bin/sh
export BUCKET_NAME="%%BUCKET_NAME%%"
export OBJECT_NAME="%%OBJECT_NAME%%"
export S3_ENDPOINT_URL="%%S3_ENDPOINT_URL%%"
#See: https://awscli.amazonaws.com/v2/documentation/api/latest/reference/s3api/put-object.html
s3 put $BUCKET_NAME/$OBJECT_NAME filename="%%INPUT_FILE%%" %%METADATA_PROPERTIES%%
