from dotenv import load_dotenv
from datetime import datetime, timezone
from google.cloud import bigquery
import os
import requests 
import time
import json
import logging
import argparse

load_dotenv()  

logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")

PROJECT_ID = os.environ["GCP_PROJECT_ID"]
DATASET = os.environ["BQ_DATASET"]
REGION = os.environ["BQ_LOCATION"]

USER_AGENT = os.environ["USER_AGENT"]
MAX_ATTEMPTS = 3

# NOTE : SQL requests are expected to return a single 'mbid' column
CONFIGS = {
    "artist": {
        "endpoint": "artist",
        "inc": "tags+genres+artist-rels",
        "cache": "data/musicbrainz_artists_cache.jsonl",
        "table": "artists_musicbrainz",
        "name_field": "name",
        "sql": f"""
                    SELECT DISTINCT JSON_VALUE(artists) AS mbid
                    FROM `{PROJECT_ID}.{DATASET}.listens_personal`,
                    UNNEST(JSON_QUERY_ARRAY(payload.track_metadata.mbid_mapping.artist_mbids)) AS artists
                """,   
    },
    "release": {
        "endpoint": "release",
        "inc": "release-groups",
        "cache": "data/musicbrainz_releases_cache.jsonl",
        "table": "releases_musicbrainz",
        "name_field": "title",
        "sql": f"""
                    SELECT DISTINCT JSON_VALUE(payload.track_metadata.mbid_mapping.release_mbid) AS mbid
                    FROM `{PROJECT_ID}.{DATASET}.listens_personal`
                    WHERE JSON_VALUE(payload.track_metadata.mbid_mapping.release_mbid) IS NOT NULL
                """,
    },
}

def main():

    client = bigquery.Client(project=PROJECT_ID, location=REGION)

    parser = argparse.ArgumentParser(description="Ingestion MusicBrainz -> BigQuery raw.x_musicbrainz")
    parser.add_argument("--entity", choices=["artist", "release"], default="artist", help="Chose between fetching artists or releases data")
    args = parser.parse_args()

    entity_config = CONFIGS[args.entity]
    cache_path = entity_config["cache"]

    if os.path.exists(cache_path):
        with open(cache_path, "r") as f:
            cache = [json.loads(line) for line in f]
    else:
        cache = []

    unique_mbids_cache = {r["id"] for r in cache}

    query_job = client.query(entity_config["sql"])
    results = query_job.result()

    unique_mbids_bq = {row["mbid"] for row in results}
    new_mbids = unique_mbids_bq - unique_mbids_cache

    nb_entities_to_retrieve = len(new_mbids)

    logging.info("Unique artists in BigQuery : %d", len(unique_mbids_bq))
    logging.info("Unique artists in cache : %d", len(unique_mbids_cache))
    logging.info("Number of artists to retrieve : %d", nb_entities_to_retrieve)

    with open(cache_path, "a") as f:

        logging_counter = 0
        
        for mbid in new_mbids:
            url = f"https://musicbrainz.org/ws/2/{entity_config['endpoint']}/{mbid}?fmt=json&inc={entity_config['inc']}"
            for attempt in range(1, MAX_ATTEMPTS + 1):

                try:
                    response = requests.get(url, headers={"User-Agent": USER_AGENT}, timeout=(10, 30))
                    response.raise_for_status()

                    fetched_data = response.json()

                    row = {
                        "id": fetched_data.get("id"),
                        "name": fetched_data.get(entity_config["name_field"]),
                        "payload": fetched_data,
                        "_fetched_at": datetime.now(timezone.utc).isoformat()
                    }

                    json.dump(row, f)
                    f.write("\n")
                    f.flush()

                    logging_counter += 1
                    if logging_counter % 50 == 0:
                        logging.info("%d artists retrieved over %s", logging_counter, nb_entities_to_retrieve)

                    break  

                except requests.exceptions.HTTPError as e:
                    code = e.response.status_code

                    if code == 503 or code == 429:
                        logging.error("%s fetching %s. (attempt %s). Retry.", code, mbid, attempt)
                        if attempt == MAX_ATTEMPTS:
                            raise
                        time.sleep(15)  

                    elif code == 404:
                        logging.warning("%s fetching %s. Not found. Skip.", code, mbid)
                        break

                    else:
                        logging.error("%s fetching %s. Stop process.", code, mbid)
                        raise

                except (requests.exceptions.Timeout, requests.exceptions.ConnectionError) as e:
                    if attempt == MAX_ATTEMPTS:
                        logging.error("%s, on attempt %s. Skip.", e, attempt)
                        break
                    logging.warning("Error %s. (attempt %s). Retry.", e, attempt)
                    time.sleep(2 ** attempt)

            time.sleep(1)

    table_id = f"{PROJECT_ID}.{DATASET}.{entity_config['table']}"

    job_config = bigquery.LoadJobConfig(
        source_format=bigquery.SourceFormat.NEWLINE_DELIMITED_JSON,
        write_disposition=bigquery.WriteDisposition.WRITE_TRUNCATE,
        schema=[
            bigquery.SchemaField("id", "STRING"),
            bigquery.SchemaField("name", "STRING"),
            bigquery.SchemaField("payload", "JSON"),
            bigquery.SchemaField("_fetched_at", "TIMESTAMP")
        ],
    )

    with open(cache_path, "rb") as source_file:
        job = client.load_table_from_file(source_file, table_id, job_config=job_config)

    job.result()

    logging.info("SUCCESS:%s lines loaded into %s", job.output_rows, table_id)


if __name__ == "__main__":
    main()