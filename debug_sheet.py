"""Debug: apa isi Dashboard sheet?"""
import json, os

token_path = r"C:\Users\shafnats\AppData\Local\hermes\google_token.json"
os.environ["GOOGLE_TOKEN_JSON"] = open(token_path).read()

from google.oauth2.credentials import Credentials
from googleapiclient.discovery import build

creds = Credentials.from_authorized_user_info(json.loads(os.environ["GOOGLE_TOKEN_JSON"]))
sheets = build("sheets", "v4", credentials=creds, cache_discovery=False)

sid = "1HwKPfiKPR7iZDQJU_8VtI1KIYOgk--JedW4vTPC4ASg"

rows = sheets.spreadsheets().values().get(
    spreadsheetId=sid,
    range="'Dashboard'!B2:E5"
).execute().get("values", [])

print("Dashboard rows (B2:E5):")
for i, r in enumerate(rows):
    print(f"  Row {i}: {json.dumps(r)}")

rows2 = sheets.spreadsheets().values().get(
    spreadsheetId=sid,
    range="'Dashboard'!B7:C12"
).execute().get("values", [])

print("\nRingkasan biaya rows (B7:C12):")
for i, r in enumerate(rows2):
    print(f"  Row {i}: {json.dumps(r)}")
