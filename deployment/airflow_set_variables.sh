#!/usr/bin/env bash
set -eo pipefail
case $1 in
    dev|qa|prod)
        ;;
    *)
        echo "usage:   $0 {dev|qa|prod} {REGION_LOCATION}" 1>&2
        echo "example: $0 dev us-west1"
        exit 99
        ;;
esac

source ./composer_settings.sh ${1} ${2}

set -u
export PROJECT_ID=$(gcloud info --format='value(config.project)')
# cat <<EOF
# gcloud composer environments update ${COMPOSER_NAME} \
#   --location=${COMPOSER_LOCATION}\
#   --update-env-variables=^::^gcp_project=${PROJECT_ID}::\
# gcp_temp_location="gs://${GCS_BUCKET_NAME}/temp"::\
# gcs_completion_bucket="gs://${GCS_BUCKET_NAME}"::\
# input_field_names="state,gender,year,name,number,created_date"::\
# bq_output_table="data_test.test2"::\
# email="nobody@exmaple.com"
# EOF

# gcloud composer environments run ${COMPOSER_NAME} --location=${COMPOSER_LOCATION} variables -- --set gcp_project ${PROJECT_ID}
# gcloud composer environments run ${COMPOSER_NAME} --location=${COMPOSER_LOCATION} variables -- --set gcp_temp_location "gs://${GCS_BUCKET_NAME}/temp"
# gcloud composer environments run ${COMPOSER_NAME} --location=${COMPOSER_LOCATION} variables -- --set gcs_completion_bucket "gs://${GCS_BUCKET_NAME}"
# gcloud composer environments run ${COMPOSER_NAME} --location=${COMPOSER_LOCATION} variables -- --set input_field_names 'state,gender,year,name,number,created_date'
# gcloud composer environments run ${COMPOSER_NAME} --location=${COMPOSER_LOCATION} variables -- --set bq_output_table 'data_test.test2'
# gcloud composer environments run ${COMPOSER_NAME} --location=${COMPOSER_LOCATION} variables -- --set email 'nobody@exmaple.com'

cat ../dags/dataflow/env.json | envsubst > /tmp/env.json
gcloud composer environments storage data import --source=/tmp/env.json \
--environment=${COMPOSER_NAME} \
--location=${COMPOSER_LOCATION}

gcloud composer environments run ${COMPOSER_NAME} \
--location=${COMPOSER_LOCATION} variables -- --i /home/airflow/gcs/data/env.json

# {"bucket": "abc", "name": "xyz"}