import requests

supabase_url = "https://ahtyeydsrndmqxlcaavm.supabase.co"
supabase_key = "sb_secret_RUgB-ojdJ4Uiyi_ZKY3GCg_1oMljnuu"

# Read SQL schema
with open('database_schema.sql', 'r') as f:
    sql_content = f.read()

# Split SQL into individual statements
statements = [s.strip() for s in sql_content.split(';') if s.strip() and not s.strip().startswith('--')]

print(f"Found {len(statements)} SQL statements")
print("=" * 60)

headers = {
    "apikey": supabase_key,
    "Authorization": f"Bearer {supabase_key}",
    "Content-Type": "application/json",
    "Prefer": "return=representation"
}

# Execute each statement
success_count = 0
for i, statement in enumerate(statements, 1):
    if not statement:
        continue
        
    print(f"\n[{i}/{len(statements)}] Executing statement...")
    
    # Use Supabase REST API to execute SQL
    response = requests.post(
        f"{supabase_url}/rest/v1/rpc/exec",
        headers=headers,
        json={"query": statement + ";"}
    )
    
    if response.ok:
        print(f"✓ Success")
        success_count += 1
    else:
        # Try query endpoint instead
        response = requests.post(
            f"{supabase_url}/rest/v1/rpc/query",
            headers=headers,
            json={"sql": statement + ";"}
        )
        
        if response.ok:
            print(f"✓ Success")
            success_count += 1
        else:
            print(f"✗ Error: {response.status_code}")
            print(f"  {response.text[:200]}")

print("\n" + "=" * 60)
print(f"Completed: {success_count}/{len(statements)} statements executed")
