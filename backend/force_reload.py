import urllib.request
import json

url = "https://ahtyeydsrndmqxlcaavm.supabase.co/rest/v1/user_profiles?select=clerk_id&limit=1"
headers = {
    "apikey": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFodHlleWRzcm5kbXF4bGNhYXZtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzM5OTIzNTMsImV4cCI6MjA0OTU2ODM1M30.jsjUTOEKm47LyR6WnDk2D5FCQxLfzLiSDkBf5i3oGj0",
    "Authorization": "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFodHlleWRzcm5kbXF4bGNhYXZtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzM5OTIzNTMsImV4cCI6MjA0OTU2ODM1M30.jsjUTOEKm47LyR6WnDk2D5FCQxLfzLiSDkBf5i3oGj0"
}

req = urllib.request.Request(url, headers=headers)

try:
    with urllib.request.urlopen(req) as response:
        data = response.read().decode('utf-8')
        print(f"✅ Success! Schema cache refreshed.")
        print(f"Response: {data}")
except urllib.error.HTTPError as e:
    print(f"Status: {e.code}")
    print(f"Response: {e.read().decode('utf-8')}")
