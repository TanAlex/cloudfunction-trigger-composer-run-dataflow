#!/usr/bin/env bash

# Name ame must start with a lowercase letter followed by up to 63 lowercase letters, 
# numbers, or hyphens, and cannot end with a hyphen
NAME_PREFIX=gdo-composer-demo
export ENVIRONMENT=$1
export COMPOSER_NAME="${NAME_PREFIX}-${ENVIRONMENT}"
export GCS_BUCKET_NAME="${COMPOSER_NAME}-store"
export COMPOSER_LOCATION=us-central1
case ${ENVIRONMENT} in
    dev|qa|prod)
        ;;
    *)
        echo "usage:   ./composer_settings.sh {dev|qa|prod} {REGION_LOCATION}" 1>&2
        echo "example: ./composer_settings.sh dev us-west1" 1>&2
        echo "default region is us-central1"
        exit 99
        ;;
esac

if [ "$2" != "" ]; then
    export COMPOSER_LOCATION=$2
fi

export COMPOSER_INSTANCE_DATA_FOLDER=/home/airflow/gcs/data

echo "Operating on environment ${COMPOSER_NAME}" 1>&2
export ENV_VARIABLES_JSON_NAME=airflow_env_variables_${ENVIRONMENT}.json
export ENV_VARIABLES_JSON_GCS_LOCATION=gs://${GCS_BUCKET_NAME}/credentials/${ENV_VARIABLES_JSON_NAME}

export CREDENTIALS_JSON_NAME=service-account.json
export CREDENTIALS_JSON_LOCATION=gs://${GCS_BUCKET_NAME}/credentials/${CREDENTIALS_JSON_NAME}

echo "COMPOSER_NAME: ${COMPOSER_NAME}"
echo "GCS_BUCKET_NAME: ${GCS_BUCKET_NAME}"
echo "COMPOSER_LOCATION: ${COMPOSER_LOCATION}"
echo "ENV_VARIABLES_JSON_NAME: ${ENV_VARIABLES_JSON_NAME}"
echo "ENV_VARIABLES_JSON_GCS_LOCATION: ${ENV_VARIABLES_JSON_GCS_LOCATION}"
echo "CREDENTIALS_JSON_NAME: ${CREDENTIALS_JSON_NAME}"
echo "CREDENTIALS_JSON_LOCATION: ${CREDENTIALS_JSON_LOCATION}"