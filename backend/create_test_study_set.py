"""Create test study sets for development."""

import requests
import json

# API endpoint
url = "http://localhost:8000/api/v1/study-sets"

# Headers with test authorization
headers = {
    "Authorization": "Bearer test",
    "Content-Type": "application/json"
}

# Test study sets to create
study_sets = [
    {
        "name": "사회복지 실천론 기출문제",
        "certification_id": "cert-001",
        "description": "2024년 사회복지사 1급 실천론 기출문제집"
    },
    {
        "name": "사회복지 정책론 핵심정리",
        "certification_id": "cert-001",
        "description": "주요 개념과 이론 정리"
    },
    {
        "name": "사회복지 법제론 요약",
        "certification_id": "cert-001",
        "description": "관련 법령 및 제도 요약본"
    }
]

print("Creating test study sets...")
print("-" * 40)

for study_set in study_sets:
    try:
        response = requests.post(url, json=study_set, headers=headers)

        if response.status_code in [200, 201]:
            result = response.json()
            print(f"✅ Created: {study_set['name']}")
            print(f"   ID: {result['study_set']['id']}")
        else:
            print(f"❌ Failed to create: {study_set['name']}")
            print(f"   Status: {response.status_code}")
            print(f"   Error: {response.text}")
    except Exception as e:
        print(f"❌ Error creating {study_set['name']}: {e}")

    print("-" * 40)

# Now fetch all study sets
print("\nFetching all study sets...")
try:
    response = requests.get(url, headers=headers)
    if response.status_code == 200:
        result = response.json()
        print(f"\n📊 Total study sets: {result['total']}")

        if result['data']:
            print("\n📚 Study sets list:")
            for ss in result['data']:
                print(f"  - {ss['name']} (ID: {ss['id'][:8]}...)")
        else:
            print("\n⚠️ No study sets found")
    else:
        print(f"❌ Failed to fetch study sets: {response.status_code}")
except Exception as e:
    print(f"❌ Error fetching study sets: {e}")