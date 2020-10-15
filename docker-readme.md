# README
https://github.com/tuanavu/airflow-tutorial/blob/master/docker-compose.yml
```
docker-compose up -d
```
webserver starts at
http://localhost:8080

To shut it down
```
docker-compose down
```
### Note: here is how to install google SDK and setup auth
```
echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
cat /etc/apt/sources.list.d/google-cloud-sdk.list
apt-get install apt-transport-https ca-certificates gnupg
curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key --keyring /usr/share/keyrings/cloud.google.gpg add -
curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -

apt-get update && apt-get install google-cloud-sdk

gcloud auth login
gcloud config set project warm-actor-291222
gsutil ls
```