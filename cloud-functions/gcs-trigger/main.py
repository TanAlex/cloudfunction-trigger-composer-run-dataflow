from google.auth.transport.requests import Request
from google.oauth2 import id_token
import google.auth
import google.auth.transport.requests
import requests
import six.moves.urllib.parse
import requests
import os

IAM_SCOPE = 'https://www.googleapis.com/auth/iam'
OAUTH_TOKEN_URI = 'https://www.googleapis.com/oauth2/v4/token'


def get_airflow_uri(project_id, location, composer_environment) -> str:
    # Authenticate with Google Cloud.
    # See: https://cloud.google.com/docs/authentication/getting-started
    credentials, _ = google.auth.default(
        scopes=['https://www.googleapis.com/auth/cloud-platform'])
    authed_session = google.auth.transport.requests.AuthorizedSession(
        credentials)
    environment_url = (
        'https://composer.googleapis.com/v1beta1/projects/{}/locations/{}'
        '/environments/{}').format(project_id, location, composer_environment)
    composer_response = authed_session.request('GET', environment_url)
    environment_data = composer_response.json()
    airflow_uri = environment_data['config']['airflowUri']
    return airflow_uri

def get_client_id(airflow_uri) -> str:
    # The Composer environment response does not include the IAP client ID.
    # Make a second, unauthenticated HTTP request to the web server to get the
    # redirect URI.
    redirect_response = requests.get(airflow_uri, allow_redirects=False)
    redirect_location = redirect_response.headers['location']

    # Extract the client_id query parameter from the redirect.
    parsed = six.moves.urllib.parse.urlparse(redirect_location)
    query_string = six.moves.urllib.parse.parse_qs(parsed.query)
    client_id = query_string['client_id'][0]
    print("client_id is: ")
    print(client_id)
    return client_id

def trigger_dag(data, context=None):
    """Makes a POST request to the Composer DAG Trigger API
    When called via Google Cloud Functions (GCF),
    data and context are Background function parameters.
    For more info, refer to
    https://cloud.google.com/functions/docs/writing/background#functions_background_parameters-python
    To call this function from a Python script, omit the ``context`` argument
    and pass in a non-null value for the ``data`` argument.
    """

    project_id = os.environ['PROJECT_ID']
    location = os.environ['COMPOSER_LOCATION']
    composer_environment = os.environ['COMPOSER_NAME']
    # The name of the DAG you wish to trigger
    dag_name = os.environ['DAG_NAME']

    airflow_uri = get_airflow_uri(project_id, location, composer_environment)
    client_id = get_client_id(airflow_uri)


    webserver_url = (
        airflow_uri
        + '/api/experimental/dags/'
        + dag_name
        + '/dag_runs'
    )
    print("webserver_url: {}".format(webserver_url))
    # Make a POST request to IAP which then Triggers the DAG
    response = make_iap_request(
        webserver_url, client_id, method='POST', json={"conf": data})
    print(response)


# This code is copied from
# https://github.com/GoogleCloudPlatform/python-docs-samples/blob/master/iap/make_iap_request.py
# START COPIED IAP CODE
def make_iap_request(url, client_id, method='GET', **kwargs):
    """Makes a request to an application protected by Identity-Aware Proxy.
    Args:
      url: The Identity-Aware Proxy-protected URL to fetch.
      client_id: The client ID used by Identity-Aware Proxy.
      method: The request method to use
              ('GET', 'OPTIONS', 'HEAD', 'POST', 'PUT', 'PATCH', 'DELETE')
      **kwargs: Any of the parameters defined for the request function:
                https://github.com/requests/requests/blob/master/requests/api.py
                If no timeout is provided, it is set to 90 by default.
    Returns:
      The page body, or raises an exception if the page couldn't be retrieved.
    """
    # Set the default timeout, if missing
    if 'timeout' not in kwargs:
        kwargs['timeout'] = 90

    # Obtain an OpenID Connect (OIDC) token from metadata server or using service
    # account.
    google_open_id_connect_token = id_token.fetch_id_token(Request(), client_id)

    # Fetch the Identity-Aware Proxy-protected URL, including an
    # Authorization header containing "Bearer " followed by a
    # Google-issued OpenID Connect token for the service account.
    resp = requests.request(
        method, url,
        headers={'Authorization': 'Bearer {}'.format(
            google_open_id_connect_token)}, **kwargs)
    if resp.status_code == 403:
        raise Exception('Service account does not have permission to '
                        'access the IAP-protected application.')
    elif resp.status_code != 200:
        raise Exception(
            'Bad response from application: {!r} / {!r} / {!r}'.format(
                resp.status_code, resp.headers, resp.text))
    else:
        return resp.text

def function(event, context):
    """Cloud Function to be triggered by Cloud Storage.
    Args:
        event (dict):  The dictionary with data specific to this type of event.
                       The `data` field contains a description of the event in
                       the Cloud Storage `object` format described here:
                       https://cloud.google.com/storage/docs/json_api/v1/objects#resource
        context (google.cloud.functions.Context): Metadata of triggering event.
    Returns:
        None; the output is written to Stackdriver Logging
    """

    print('Event ID: {}'.format(context.event_id))
    print('Event type: {}'.format(context.event_type))
    print('Bucket: {}'.format(event['bucket']))
    print('File: {}'.format(event['name']))
    print('Metageneration: {}'.format(event['metageneration']))
    print('Created: {}'.format(event['timeCreated']))
    print('Updated: {}'.format(event['updated']))
    gs_file_name = f"gs://{event['bucket']}/{event['name']}"
    print(f"bucket_name: {gs_file_name}")
    trigger_dag(event, context)

if __name__ == '__main__':
    data = {'gs_file_name': 'test_file'}
    trigger_dag(data, None)