#!/usr/bin/env python3
"""
API 엔드포인트 체크 스크립트
새 API 추가 후 실행하여 누락된 부분 확인
"""

import importlib
import inspect
from pathlib import Path

def check_endpoints():
    """Check if all endpoints are properly registered."""

    # 1. Check all endpoint files
    endpoints_dir = Path("app/api/v1/endpoints")
    endpoint_files = [f.stem for f in endpoints_dir.glob("*.py")
                     if not f.stem.startswith("__")]

    # 2. Check __init__.py imports
    with open("app/api/v1/endpoints/__init__.py", "r") as f:
        init_content = f.read()

    # 3. Check router.py includes
    with open("app/api/v1/router.py", "r") as f:
        router_content = f.read()

    missing = []
    for endpoint in endpoint_files:
        if endpoint not in ["__init__"]:
            # Check if imported in __init__.py
            if f"from .{endpoint} import" not in init_content:
                missing.append(f"❌ {endpoint}: Not imported in __init__.py")

            # Check if included in router
            router_name = f"{endpoint}_router"
            if router_name not in router_content:
                missing.append(f"❌ {endpoint}: Not included in router.py")

    if missing:
        print("⚠️  Missing registrations:")
        for item in missing:
            print(f"  {item}")
        return False
    else:
        print("✅ All endpoints properly registered!")
        return True

def check_repository_methods():
    """Check if repository has all required methods."""

    # Import repositories
    from app.repositories.mock_study_set import MockStudySetRepository
    from app.repositories.mock_study_material import MockStudyMaterialRepository
    from app.repositories.mock_question import MockQuestionRepository

    required_methods = {
        "MockStudySetRepository": [
            "create", "find_by_id", "find_all_by_user",
            "delete", "update_material_counts"
        ],
        "MockStudyMaterialRepository": [
            "create", "find_by_id", "find_by_study_set",
            "update_status", "delete", "count_by_study_set",
            "get_total_questions", "update_graphrag_status"
        ],
        "MockQuestionRepository": [
            "get_by_study_set", "get_by_material", "bulk_create",
            "get_by_id", "get_by_ids", "get_correct_answers"
        ]
    }

    missing = []

    for repo_name, methods in required_methods.items():
        repo_class = locals()[repo_name]
        for method in methods:
            if not hasattr(repo_class, method):
                missing.append(f"❌ {repo_name}.{method} is missing")

    if missing:
        print("\n⚠️  Missing repository methods:")
        for item in missing:
            print(f"  {item}")
        return False
    else:
        print("✅ All repository methods implemented!")
        return True

if __name__ == "__main__":
    print("🔍 Checking API setup...\n")

    endpoints_ok = check_endpoints()
    repos_ok = check_repository_methods()

    if endpoints_ok and repos_ok:
        print("\n✨ All checks passed! Your API is ready.")
    else:
        print("\n⚠️  Fix the issues above before testing.")