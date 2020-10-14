#!/usr/bin/env bash
set -eo pipefail
case $1 in
    dev|qa|prod)
        ;;
    *)
        echo "usage:   ./composer_setup.sh {dev|qa|prod} {REGION_LOCATION}" 1>&2
        echo "example: ./composer_setup.sh dev us-west1"
        exit 99
        ;;
esac

source ./composer_settings.sh ${1} $2

set -u

# create the Composer cluster
# --image-version=composer-1.8.4-airflow-1.9.0 \
gcloud composer environments create ${COMPOSER_NAME} \
    --location=${COMPOSER_LOCATION} \
    --airflow-configs=core-dags_are_paused_at_creation=True \
    --image-version=composer-1.12.2-airflow-1.10.10 \
    --disk-size=20GB \
    --python-version=3 \
    --node-count=3 \
    --labels env=${ENVIRONMENT}

COMPOSER_GCS_BUCKET_DATA_FOLDER=$(gcloud composer environments describe ${COMPOSER_NAME} --location ${COMPOSER_LOCATION} | grep 'dagGcsPrefix' | grep -Eo "\S+/")data

if [ "$COMPOSER_GCS_BUCKET_DATA_FOLDER" = "data" ];then
    echo "Composer Environment ${COMPOSER_NAME} may not created successful, cant get its GCS location"
    exit 1
fi

echo "Data folder is ${COMPOSER_GCS_BUCKET_DATA_FOLDER}"

# SAMPLE JSON files locations, you need to prepare them before these can copy them
# ENV_VARIABLES_JSON_NAME: airflow_env_variables_dev.json
# ENV_VARIABLES_JSON_GCS_LOCATION: gs://GDO-Composer-dev-store/credentials/airflow_env_variables_dev.json
# CREDENTIALS_JSON_NAME: service-account.json
# CREDENTIALS_JSON_LOCATION: gs://GDO-Composer-dev-store/credentials/service-account.json

# # Copy environment's variables file and service account credentials from our analytics GCS bucket
# gsutil cp ${ENV_VARIABLES_JSON_GCS_LOCATION} ${COMPOSER_GCS_BUCKET_DATA_FOLDER}
# gsutil cp ${CREDENTIALS_JSON_LOCATION} ${COMPOSER_GCS_BUCKET_DATA_FOLDER}

# echo "Importing environment variables from ${COMPOSER_INSTANCE_DATA_FOLDER}/${ENV_VARIABLES_JSON_NAME}..."

# # Import environment's variables file
# gcloud composer environments run ${COMPOSER_NAME} \
#     --location ${COMPOSER_LOCATION} variables -- \
#     -i ${COMPOSER_INSTANCE_DATA_FOLDER}/${ENV_VARIABLES_JSON_NAME}

# echo "Importing pypi packages from ./pypi_packages..."

# # Install PyPi packages from file
# gcloud composer environments update ${COMPOSER_NAME} \
#     --location ${COMPOSER_LOCATION} \
#     --update-pypi-packages-from-file=pypi_packages
# echo "Setting up bigquery_gdrive connection"

# gcloud composer environments run ${ENVIRONMENT} \
#     --location ${COMPOSER_LOCATION} connections -- --add \
#     --conn_id=bigquery_gdrive --conn_type=google_cloud_platform \
#     --conn_extra <<EXTRA '{"extra__google_cloud_platform__project": "our-project",
# "extra__google_cloud_platform__key_path": "/home/airflow/gcs/data/service-account.json",
# "extra__google_cloud_platform__scope": "https://www.googleapis.com/auth/bigquery,https://www.googleapis.com/auth/drive,https://www.googleapis.com/auth/cloud-platform"}'
# EXTRA
# echo "Done"
