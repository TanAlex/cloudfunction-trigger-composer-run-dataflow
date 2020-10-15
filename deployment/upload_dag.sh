#!/usr/bin/env bash

set -eo pipefail
print_help() {
    echo "usage:  ./upload_dag.sh --env {dev|qa|prod} --region <REGION> --dag <DAG_NAME> --file <dag_file_name>" 1>&2
    echo "sample: ./upload_dag.sh --env dev --region us-west3 --dag composer_sample_dag --file ../dags/quickstart.py"
    echo "    or: ./upload_dag.sh --env dev --region us-west3 --file ../dags/quickstart.py"
}

ARG="$#"
if [[ $ARG -eq 0 ]]; then
  print_help
  exit
fi
export DAG_NAME=composer_sample_dag
export ENVIRONMENT=dev
export REGION=us-central1

while test -n "$1"; do                                                                                                                                                                                     
   case "$1" in                                                                                                                                                                                            
        --env)
            ENVIRONMENT=$2
            shift
            ;;
        --region)
            REGION=$2
            shift
            ;;
        --dag)
            DAG_NAME=$2
            shift
            ;;
        --file)
            DAG_FILE=$2
            shift
            ;;
       *)
            print_help
            exit
            ;;
   esac
    shift
done

case $ENVIRONMENT in
    dev|qa|prod)
        ;;
    *)
        print_help
        echo "$ENVIRONMENT is not valid"
        exit 99
        ;;
esac

# if [ -z "${DAG_NAME}" ]; then
#     print_help
#     echo "ERROR: DAG_NAME:${DAG_NAME} is empty"
#     exit 99
# fi

if [ ! -f ${DAG_FILE} ]; then
    echo "ERROR: DAG_FILE: ${DAG_FILE} doesn't exist"
    exit 99
fi

source ./composer_settings.sh ${ENVIRONMENT} ${REGION}

echo "Uploading dag file ${DAG_FILE} to Cloud Composer..."
# this is to load individual DAG file, we can use gsutil rsync instead
# gcloud composer environments storage dags import \
#   --environment ${COMPOSER_NAME}  --location ${COMPOSER_LOCATION} \
#   --source ${DAG_FILE}

DAG_GCS_PATH=$(gcloud composer environments describe ${COMPOSER_NAME} --location ${COMPOSER_LOCATION} \
--format="value(config.dagGcsPrefix)")

# dry-run using -n option
# gsutil -m rsync -r -d -n ../dags ${DAG_GCS_PATH}

gsutil cp "${DAG_FILE}" "${DAG_GCS_PATH}/${DAG_FILE}"

if [ $? -eq 0 ] && [ "${DAG_NAME}" != "" ]; then 
    # Try to start the job
    # Need to wait for 30 seconds before calling
    if [ "$COMPOSER_NAME" = "" ] || [ "${COMPOSER_LOCATION}" = "" ]; then
        echo "{COMPOSER_LOCATION} and {COMPOSER_NAME} ENV variables need to be defined"
    else
        echo "Wait for 20 seconds before trigger DAG_NAME: ${DAG_NAME}"
        sleep 20
        echo "Executing DAG_NAME: ${DAG_NAME} on Cloud Composer (${COMPOSER_NAME})..."
        gcloud composer environments run ${COMPOSER_NAME} \
        --location ${COMPOSER_LOCATION} trigger_dag -- ${DAG_NAME}
    fi
fi