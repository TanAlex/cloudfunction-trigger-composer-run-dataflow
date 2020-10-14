#!/usr/bin/env bash
set -exo pipefail

source ./composer_settings.sh ${1} ${2}

set -u

COMPOSER_GCS_BUCKET=$(gcloud composer environments describe ${COMPOSER_NAME} --location ${COMPOSER_LOCATION} | grep 'dagGcsPrefix' | grep -Eo "\S+/")
COMPOSER_GCS_BUCKET_DATA_FOLDER=${COMPOSER_GCS_BUCKET}data

# Export variables file to composer instance
gcloud composer environments run ${COMPOSER_NAME} \
    --location ${COMPOSER_LOCATION} variables -- \
    -e ${COMPOSER_INSTANCE_DATA_FOLDER}/${ENV_VARIABLES_JSON_NAME} \

# Overwrite saved environment's variables file in analytics GCS bucket
gsutil cp ${COMPOSER_GCS_BUCKET_DATA_FOLDER}/${ENV_VARIABLES_JSON_NAME} ${ENV_VARIABLES_JSON_GCS_LOCATION}

gcloud composer environments delete ${COMPOSER_NAME} \
    --location=${COMPOSER_LOCATION} \
    --quiet

# Remove GCS bucket as it doesn't get cleaned up when the Composer instance gets deleted
# gsutil -m rm -r ${COMPOSER_GCS_BUCKET}
gsutil rm -r ${COMPOSER_GCS_BUCKET}