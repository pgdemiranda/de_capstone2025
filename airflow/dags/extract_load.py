import logging
import os
from datetime import datetime, timedelta

import requests
from bs4 import BeautifulSoup
from google.cloud import storage

from airflow import DAG
from airflow.operators.python_operator import PythonOperator
from airflow.utils.dates import days_ago

# env variables
GCP_BUCKET = os.getenv("GCP_BUCKET")
PROJECT_ID = os.getenv("PROJECT_ID")
DATASET_URL = os.getenv("ANEEL_DATASET_URL")

storage_client = storage.Client.from_service_account_json(os.getenv("GOOGLE_APPLICATION_CREDENTIALS"))


logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

def extract_links():
    response = requests.get(DATASET_URL)
    soup = BeautifulSoup(response.text, "html.parser")
    current_year = datetime.now().year
    links = [
        link["href"]
        for link in soup.find_all("a", href=True)
        if "download/componentes-tarifarias-" in link["href"]
        and link["href"].endswith(".csv")
    ]
    return links, current_year


def extract_and_load_to_gcs():
    links, current_year = extract_links()
    bucket = storage_client.bucket(GCP_BUCKET)

    for link in links:
        file_name = link.split("/")[-1]
        blob = bucket.blob(f"aneel/{file_name}")
        is_current_year = str(current_year) in file_name

        if not is_current_year and blob.exists():
            logger.info(
                f"{file_name} file is already inside {GCP_BUCKET}. Skipping download."
            )
            continue

        response = requests.get(link)
        if response.status_code == 200:
            blob.upload_from_string(response.content, content_type="text/csv")
            logger.info(f"{file_name} file sent to {GCP_BUCKET} successfully.")
        else:
            logger.error(f"Error downloading file: {link}")


default_args = {
    "owner": "airflow",
    "start_date": days_ago(1),
    "retries": 3,
    "retry_delay": timedelta(minutes=5),
}

with DAG(
    "extract_and_load",
    default_args=default_args,
    description="Extract CSV files from ANEEL, and load to GCP Bucket",
    schedule_interval="0 22 * * 5",
    catchup=False,
    tags=['aneel', 'gcs']
) as dag:
    download_upload_gcs = PythonOperator(
        task_id="extract_and_load_to_gcs",
        python_callable=extract_and_load_to_gcs,
    )

    download_upload_gcs