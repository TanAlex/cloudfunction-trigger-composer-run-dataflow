# README

This is a repo to use GCF (Cloud Function) to trigger a Cloud Composer airflow DAG to process data

Reference:
https://github.com/GoogleCloudPlatform/professional-services/tree/master/examples/cloud-composer-examples/composer_dataflow_examples

## Deployment folder

To deploy a new Cloud Composer cluster.   
Note: only us-west3 and 4 supports Composer, if you pick us-west1 or us-west2, you will get 502 error
```
cd deployment
./composer_setup.sh dev us-central1
```

To upload a DAG python file to new Composer
```
cd deployment
./upload_dag.sh --env dev --region us-central1 --dag composer_sample_dag --file ../dags/quickstart.py
```

To teardown/delete the cluster
```
cd deployment
./composer_teardown.sh dev
```

## Step to setup permissions for the trigger Cloud Function
https://cloud.google.com/composer/docs/how-to/using/triggering-with-gcf

Enable the Cloud Composer, Cloud Functions, and Identity and Access Management (IAM) APIs.

To authenticate to IAP, grant the Appspot Service Account (used by Cloud Functions) the Service Account Token Creator role on itself
```
gcloud services enable dataflow.googleapis.com
gcloud services enable cloudfunctions.googleapis.com
gcloud services enable composer.googleapis.com
gcloud services enable accesscontextmanager.googleapis.com

export PROJECT_ID=warm-actor-291222
gcloud iam service-accounts add-iam-policy-binding \
${PROJECT_ID}@appspot.gserviceaccount.com \
--member=serviceAccount:${PROJECT_ID}@appspot.gserviceaccount.com \
--role=roles/iam.serviceAccountTokenCreator
```
Use this script to get token
Ref: https://github.com/GoogleCloudPlatform/python-docs-samples/blob/master/composer/rest/get_client_id.py

```
### remember to change this to your gcp credential file location
export GOOGLE_APPLICATION_CREDENTIALS=/Users/tinglitan/_Code/_GCP/credentials.json
python deplopyment/get_client_id.py
```

### To test the gcs-trigger GCF (Cloud Function) locally
```
cd cloud-functions/gcs-trigger
pipenv install -r requirements.txt
pipenv shell
# these exports are also in the env.txt file
export PROJECT_ID=warm-actor-291222
export COMPOSER_NAME=gdo-composer-demo-dev
export GCS_BUCKET_NAME=gdo-composer-demo-dev-store
export COMPOSER_LOCATION=us-central1
export DAG_NAME=composer_sample_dag
python main.py
```
main.py should trigger that DAG in that Composer Environment


### To deploy the Cloud Function

```
export MY_BUCKET=gs://warm-actor-291222_cloudbuild/
export DAG_NAME=GcsToBigQueryTriggered
gcloud functions deploy gcs-trigger \
--source=cloud-functions/gcs-trigger \
--entry-point=function \
--runtime python37 \
--timeout=400 \
--trigger-resource $MY_BUCKET \
--trigger-event google.storage.object.finalize \
--set-env-vars PROJECT_ID=$PROJECT_ID,GCS_BUCKET_NAME=$GCS_BUCKET_NAME,\
COMPOSER_NAME=$COMPOSER_NAME,COMPOSER_LOCATION=$COMPOSER_LOCATION,\
DAG_NAME=$DAG_NAME
```

### once deployed, try to upload a file to trigger GCF then trigger DAG
gsutil cp data/userdata.csv gs://warm-actor-291222_cloudbuild/raw/userdata.csv 

### Create BigQuery schema and the table
```
pip3 install bigquery_schema_generator
generate-schema --input_format csv < data/userdata.csv > /tmp/file.schema.json

# modify the file.schema.json and save to data/userdata.schema.json
bq mk -t \
--schema data/userdata.schema.json \
--description "dataflow test table" \
--label env:dev \
warm-actor-291222:data_test.test2
```

### update simple_load_dag.py in dags directory and upload to Airflow Dag GCS directory
```
DAG_GCS_PATH=$(gcloud composer environments describe ${COMPOSER_NAME} --location ${COMPOSER_LOCATION} \
--format="value(config.dagGcsPrefix)")

gsutil cp dags/simple_load_dag.py gs://us-central1-gdo-composer-de-e7858097-bucket/dags/simple_load_dag.py
```