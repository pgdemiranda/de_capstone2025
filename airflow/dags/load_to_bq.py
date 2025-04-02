import os
from datetime import datetime, timedelta

from google.cloud import bigquery

from airflow import DAG
from airflow.operators.python import PythonOperator
from airflow.utils.dates import days_ago

# env variables
GCP_BUCKET = os.getenv("GCP_BUCKET")
PROJECT_ID = os.getenv("PROJECT_ID")
BQ_DATASET = os.getenv("BQ_DATASET")
BQ_TABLE = os.getenv("BQ_TABLE")

default_args = {
    'owner': 'airflow',
    'retries': 1,
    'retry_delay': timedelta(minutes=5),
}

def load_to_bq(**kwargs):
    bq_client = bigquery.Client.from_service_account_json(os.getenv("GOOGLE_APPLICATION_CREDENTIALS"))
    
    table_ref = f"{PROJECT_ID}.{BQ_DATASET}.{BQ_TABLE}"
    table = bq_client.get_table(table_ref)
    
    job_config = bigquery.LoadJobConfig(
        schema=table.schema,
        source_format=bigquery.SourceFormat.CSV,
        skip_leading_rows=1,
        write_disposition="WRITE_TRUNCATE",
        field_delimiter=";",
        quote_character='"',
        allow_quoted_newlines=True,
        encoding="ISO-8859-1"
    )
    
    # Carrega todos os arquivos CSV de uma vez
    uri = f"gs://{GCP_BUCKET}/aneel/*.csv"
    
    load_job = bq_client.load_table_from_uri(
        uri,
        table_ref,
        job_config=job_config
    )
    
    load_job.result()
    print(f"Data Loaded! {load_job.output_rows} processed rows.")

default_args = {
    "owner": "airflow",
    "start_date": days_ago(1),
    "retries": 3,
    "retry_delay": timedelta(minutes=5),
}

with DAG(
    "load_data_bq",
    default_args=default_args,
    description="Load data from GCS files to BigQuery",
    schedule_interval="30 23 * * 5",
    catchup=False,
    tags=['aneel', 'bq'],
) as dag:
    load_task = PythonOperator(
        task_id='load_componentes_tarifarias',
        python_callable=load_to_bq,
    )

    load_task