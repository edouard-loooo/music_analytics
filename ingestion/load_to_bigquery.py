from dotenv import load_dotenv
from datetime import datetime, timezone
from google.cloud import bigquery
import os
import json
import logging

load_dotenv()  # Load environment variables from .env file

logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")

PROJECT_ID = os.environ["GCP_PROJECT_ID"]
DATASET = os.environ["BQ_DATASET"]
REGION = os.environ["BQ_LOCATION"]

SOURCE_PATH = "data/listen_raw.jsonl"
INT_JSON_PATH = "data/listen_bq.jsonl"

def main():

    loaded_timestamp = datetime.now(timezone.utc).isoformat()

    with open(INT_JSON_PATH, "w") as i:

        with open(SOURCE_PATH, "r") as s:
            for line in s:
                listen = json.loads(line)
                row = {
                    "listened_at": datetime.fromtimestamp(listen["listened_at"], timezone.utc).isoformat(),     
                    "user_name": listen["user_name"],        
                    "recording_msid": listen["recording_msid"],  
                    "payload": listen,         
                    "source": "listenbrainz_api",          
                    "_loaded_at": loaded_timestamp       
                }
                
                json.dump(row, i)
                i.write("\n")


    client = bigquery.Client(project=PROJECT_ID, location=REGION)
    table_id = f"{PROJECT_ID}.{DATASET}.listens_personal"

    job_config = bigquery.LoadJobConfig(
        source_format=bigquery.SourceFormat.NEWLINE_DELIMITED_JSON,
        write_disposition = bigquery.WriteDisposition.WRITE_TRUNCATE,
        time_partitioning=bigquery.TimePartitioning(
                type_=bigquery.TimePartitioningType.DAY,
                field="listened_at", 
            ),
        schema=[
            bigquery.SchemaField("listened_at", "TIMESTAMP"),
            bigquery.SchemaField("user_name", "STRING"),
            bigquery.SchemaField("recording_msid", "STRING"),
            bigquery.SchemaField("payload", "JSON"),
            bigquery.SchemaField("source", "STRING"),
            bigquery.SchemaField("_loaded_at", "TIMESTAMP"),
        ],
    )

    with open(INT_JSON_PATH, "rb") as source_file:
        job = client.load_table_from_file(source_file, table_id, job_config=job_config)

    job.result()  # Wait for the job to complete

    logging.info("%s lignes chargées dans %s", job.output_rows, table_id)

if __name__ == "__main__":
    main()
