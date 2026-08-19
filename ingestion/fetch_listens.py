from dotenv import load_dotenv
from datetime import datetime, timezone
import os
import requests 
import time
import json
import logging

load_dotenv()  # Load environment variables from .env file

logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(message)s")

USERNAME = os.environ["LISTENBRAINZ_USERNAME"]
TOKEN = os.environ["LISTENBRAINZ_TOKEN"]
URL = f"https://api.listenbrainz.org/1/user/{USERNAME}/listens"

PAGE_SIZE = 1000
OUTPUT_PATH = "data/listen_raw.jsonl"

MAX_ATTEMPS = 3

def throttle(response):
    remaining = int(response.headers.get("X-RateLimit-Remaining", 0))
    reset_in = int(response.headers.get("X-RateLimit-Reset-In", 10))

    logging.info("Requests remaining : %s ; Quota reset in : %s seconds", remaining, reset_in)

    if remaining <= 1 : 
        time.sleep(reset_in + 1)  

def fetch_page(session, cursor):

    params = {
        "count": PAGE_SIZE,
        "max_ts": cursor
    }

    for attempts in range(1,MAX_ATTEMPS + 1):
        try :
            response = session.get(URL, params=params, timeout=(10, 60))
            response.raise_for_status()  
            throttle(response)
            return response.json()['payload']
        
        except (requests.exceptions.Timeout, requests.exceptions.ConnectionError) as e:
            logging.warning("Timeout error on attempt %s: %s", attempts, e)
            if attempts == MAX_ATTEMPS:
                raise
            time.sleep(2**attempts)  # Wait before retrying 
            
def read_timestamp(ts): 
    """convert ts into readable format"""
    return datetime.fromtimestamp(ts, timezone.utc).strftime("%Y-%m-%d %H:%M")

def main():
    
    headers = {
        "Authorization": f"Token {TOKEN}"
    }

    session = requests.Session()
    session.headers.update(headers)

    cursor = None

    iteration = 1

    with open(OUTPUT_PATH, "w") as f:

        while True : 

            payload = fetch_page(session, cursor)

            if iteration == 1:
                target_oldest_ts = payload['oldest_listen_ts']

            listens = payload['listens']

            if not listens:
                break

            logging.info("Page %s : %s listens", iteration, len(listens))

            for listen in listens:
                json.dump(listen, f)
                f.write("\n")

            prev_cursor = cursor
            cursor = min(listen['listened_at'] for listen in listens) + 1

            if prev_cursor is not None and cursor >= prev_cursor:
                break

            logging.info("Cursor state : %s / %s", read_timestamp(cursor), read_timestamp(target_oldest_ts))

            iteration += 1


if __name__ == "__main__":
    main()