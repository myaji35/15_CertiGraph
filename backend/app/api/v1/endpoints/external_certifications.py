"""
외부 자격증 데이터 API 엔드포인트
한국산업인력공단 등 공공 API 연동
"""

from fastapi import APIRouter, HTTPException, Query
from typing import List, Dict, Optional
import os
from app.services.external_api.hrdkorea import HRDKoreaAPI, ExamSchedule

router = APIRouter()

@router.get("/hrdkorea/schedules")
async def get_hrdkorea_schedules(
    year: int = Query(2025, description="조회할 연도")
) -> Dict:
    """
    한국산업인력공단 시험 일정 조회

    Returns:
        국가기술자격 시험 일정 정보
    """
    api_key = os.getenv("HRDKOREA_API_KEY")

    if not api_key:
        # 개발 환경에서는 mock 데이터 반환
        return {
            "message": "API 키가 설정되지 않았습니다. 환경 변수를 설정해주세요.",
            "example": "export HRDKOREA_API_KEY='your-api-key'",
            "mock_data": [
                {
                    "exam_name": "정보처리기사",
                    "exam_type": "필기",
                    "receipt_start": "2025-01-06",
                    "receipt_end": "2025-01-09",
                    "exam_date": "2025-03-15",
                    "result_date": "2025-04-02"
                },
                {
                    "exam_name": "정보처리기사",
                    "exam_type": "실기",
                    "receipt_start": "2025-03-31",
                    "receipt_end": "2025-04-03",
                    "exam_date": "2025-05-17",
                    "result_date": "2025-06-18"
                },
                {
                    "exam_name": "빅데이터분석기사",
                    "exam_type": "필기",
                    "receipt_start": "2025-02-03",
                    "receipt_end": "2025-02-06",
                    "exam_date": "2025-04-12",
                    "result_date": "2025-05-07"
                }
            ]
        }

    api = HRDKoreaAPI(api_key)

    try:
        schedules = await api.get_exam_schedules(year)
        return {
            "year": year,
            "total": len(schedules),
            "schedules": [s.dict() for s in schedules]
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        await api.close()

@router.get("/hrdkorea/qualifications")
async def get_hrdkorea_qualifications() -> Dict:
    """
    한국산업인력공단 자격증 종목 목록 조회

    Returns:
        국가기술자격 종목 정보
    """
    api_key = os.getenv("HRDKOREA_API_KEY")

    if not api_key:
        # 개발 환경에서는 mock 데이터 반환
        return {
            "message": "API 키가 설정되지 않았습니다. 환경 변수를 설정해주세요.",
            "example": "export HRDKOREA_API_KEY='your-api-key'",
            "mock_data": [
                {
                    "name": "정보처리기사",
                    "series": "기사",
                    "category": "정보통신",
                    "institution": "한국산업인력공단"
                },
                {
                    "name": "컴퓨터활용능력 1급",
                    "series": "1급",
                    "category": "사무",
                    "institution": "대한상공회의소"
                },
                {
                    "name": "빅데이터분석기사",
                    "series": "기사",
                    "category": "정보통신",
                    "institution": "한국데이터산업진흥원"
                }
            ]
        }

    api = HRDKoreaAPI(api_key)

    try:
        qualifications = await api.get_qualification_list()
        return {
            "total": len(qualifications),
            "qualifications": qualifications
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
    finally:
        await api.close()

@router.get("/sync")
async def sync_external_data():
    """
    외부 API 데이터와 내부 DB 동기화

    Returns:
        동기화 결과
    """
    # TODO: 외부 API에서 가져온 데이터를 내부 DB에 저장하는 로직 구현
    return {
        "message": "동기화 기능은 추후 구현 예정입니다.",
        "description": "외부 API 데이터를 주기적으로 가져와 내부 DB를 업데이트합니다."
    }