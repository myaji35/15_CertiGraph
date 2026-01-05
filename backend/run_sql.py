#!/usr/bin/env python3
import json
import urllib.request
import urllib.error

# Read SQL file
with open('database_schema.sql', 'r') as f:
    sql_content = f.read()

# Prepare request
url = 'https://api.supabase.com/v1/projects/ahtyeydsrndmqxlcaavm/database/query'
headers = {
    'apikey': 'sb_secret_RUgB-ojdJ4Uiyi_ZKY3GCg_1oMljnuu',
    'Authorization': 'Bearer sb_secret_RUgB-ojdJ4Uiyi_ZKY3GCg_1oMljnuu',
    'Content-Type': 'application/json'
}
data = json.dumps({'query': sql_content}).encode('utf-8')

# Make request
req = urllib.request.Request(url, data=data, headers=headers, method='POST')

try:
    with urllib.request.urlopen(req) as response:
        result = json.loads(response.read().decode('utf-8'))
        print("✅ Success!")
        print(json.dumps(result, indent=2))
except urllib.error.HTTPError as e:
    print(f"❌ HTTP Error {e.code}")
    print(e.read().decode('utf-8'))
except Exception as e:
    print(f"❌ Error: {e}")
