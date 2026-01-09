"""Certification calendar API endpoints."""

from datetime import datetime, date
from typing import Optional, List
from fastapi import APIRouter, Query, HTTPException, Path
from pydantic import BaseModel

from app.models.certification import (
    Certification,
    CertificationListResponse,
    ExamSchedule,
    CertificationCategory,
    UserCertificationPreference
)
from app.services.data_loader import get_data_loader
# from app.core.auth import get_current_user_id  # TODO: implement auth

router = APIRouter(prefix="/certifications", tags=["certifications"])


class CertificationPreferenceRequest(BaseModel):
    certification_id: str
    target_exam_date: Optional[date] = None


@router.get("/", response_model=CertificationListResponse)
async def get_certifications(
    category: Optional[CertificationCategory] = Query(None, description="자격증 분류"),
    month: Optional[int] = Query(None, ge=1, le=12, description="시험 월"),
    year: Optional[int] = Query(None, ge=2024, le=2026, description="연도"),
):
    """
    자격증 목록 조회

    - category: 자격증 분류 필터 (national, national_professional, private, international)
    - month: 특정 월의 시험 일정이 있는 자격증만 필터링
    - year: 특정 연도 필터 (기본값: 2025)
    """
    year = year or 2025

    # DEV_MODE에서는 Mock 데이터 사용
    from app.core.config import get_settings
    settings = get_settings()

    if settings.dev_mode:
        # Mock 자격증 데이터
        all_certifications = [
            {
                "id": "cert-001",
                "name": "사회복지사 1급",
                "category": "national",
                "organization": "한국산업인력공단",
                "description": "사회복지 전문가 자격증",
                "level": "level_1",
                "exam_subjects": ["사회복지 실천론", "사회복지 정책론", "사회복지 법제론"],
                "passing_criteria": "각 과목 40점 이상, 전 과목 평균 60점 이상",
                "exam_fee": {"written": 25000},
                "website": "https://www.q-net.or.kr",
                "schedules_2025": [
                    {
                        "exam_type": "written",
                        "round": 25,
                        "application_start": date(2024, 12, 9),
                        "application_end": date(2024, 12, 13),
                        "exam_date": date(2025, 2, 8),
                        "result_date": date(2025, 3, 19),
                        "description": "제25회 사회복지사 1급 필기시험"
                    }
                ]
            },
            {
                "id": "cert-002",
                "name": "정보처리기사",
                "category": "national_professional",
                "organization": "한국산업인력공단",
                "description": "정보처리 전문가 자격증",
                "level": "engineer",
                "exam_subjects": ["소프트웨어 설계", "소프트웨어 개발", "데이터베이스 구축", "프로그래밍 언어 활용", "정보시스템 구축관리"],
                "passing_criteria": "과목당 40점 이상, 평균 60점 이상",
                "exam_fee": {"written": 19400, "practical": 22600},
                "website": "https://www.q-net.or.kr",
                "schedules_2025": [
                    {
                        "exam_type": "written",
                        "round": 1,
                        "application_start": date(2025, 1, 13),
                        "application_end": date(2025, 1, 16),
                        "exam_date": date(2025, 3, 15),
                        "result_date": date(2025, 3, 26),
                        "description": "제1회 정보처리기사 필기시험"
                    }
                ]
            },
            {
                "id": "cert-003",
                "name": "토익",
                "category": "private",
                "organization": "ETS",
                "description": "영어 능력 시험",
                "level": None,
                "exam_subjects": ["Listening", "Reading"],
                "passing_criteria": "990점 만점",
                "exam_fee": {"regular": 48000},
                "website": "https://www.toeic.co.kr",
                "schedules_2025": [
                    {
                        "exam_type": "written",
                        "round": 1,
                        "application_start": date(2025, 1, 6),
                        "application_end": date(2025, 1, 10),
                        "exam_date": date(2025, 1, 26),
                        "result_date": date(2025, 2, 5),
                        "description": "2025년 1월 토익 정기시험"
                    }
                ]
            }
        ]
    else:
        data_loader = get_data_loader()
        # 모든 자격증 데이터 가져오기
        all_certifications = data_loader.get_all_certifications()

    # 데이터를 dict에서 Certification 객체로 변환
    certifications = []
    for cert_data in all_certifications:
        # 일정을 ExamSchedule 객체로 변환
        schedules = []
        for sched in cert_data.get("schedules_2025", []):
            schedules.append(ExamSchedule(**sched))

        # Certification 객체 생성
        cert = Certification(
            id=cert_data["id"],
            name=cert_data["name"],
            category=cert_data["category"],
            level=cert_data.get("level"),
            organization=cert_data["organization"],
            description=cert_data.get("description"),
            exam_subjects=cert_data.get("exam_subjects", []),
            passing_criteria=cert_data.get("passing_criteria"),
            exam_fee=cert_data.get("exam_fee"),
            schedules_2025=schedules,
            website=cert_data.get("website")
        )

        # 카테고리 필터
        if category and cert.category != category:
            continue

        # 월 필터 - 해당 월에 시험이 있는 자격증만
        if month:
            has_exam_in_month = any(
                sched.exam_date.month == month
                for sched in cert.schedules_2025
            )
            if not has_exam_in_month:
                continue

        certifications.append(cert)

    return CertificationListResponse(
        certifications=certifications,
        total=len(certifications)
    )


# Sync certification data from public API - must come before dynamic routes
@router.get("/sync-from-api")
async def sync_certifications_from_api():
    """
    공공 API(data.go.kr)에서 자격증 시험 일정 동기화

    한국산업인력공단 API를 통해 최신 자격증 시험 일정을 가져옵니다.
    """
    from app.services.data_gov_api import DataGovAPIService

    try:
        api_service = DataGovAPIService()

        # 2025년 시험 일정 가져오기
        schedules = await api_service.get_exam_schedules(year="2025")

        # 데이터 저장 로직 (현재는 메모리에만 저장)
        # TODO: 실제 DB에 저장

        return {
            "success": True,
            "message": f"{len(schedules)}개의 시험 일정을 가져왔습니다",
            "data": {
                "count": len(schedules),
                "schedules": schedules[:10]  # 처음 10개만 반환 (샘플)
            }
        }

    except Exception as e:
        return {
            "success": False,
            "message": f"API 동기화 실패: {str(e)}",
            "data": None
        }


@router.get("/calendar/upcoming")
async def get_upcoming_exams(
    days: int = Query(30, ge=1, le=365, description="조회할 일수"),
):
    """
    향후 시험 일정 조회

    오늘부터 지정된 일수 내의 모든 시험 일정을 반환합니다.
    """
    data_loader = get_data_loader()
    upcoming_exams = data_loader.get_upcoming_exams(days)

    return {
        "total": len(upcoming_exams),
        "exams": upcoming_exams
    }


@router.get("/{certification_id}", response_model=Certification)
async def get_certification_detail(certification_id: str):
    """특정 자격증 상세 정보 조회"""

    data_loader = get_data_loader()
    cert_data = data_loader.get_certification_by_id(certification_id)

    if cert_data:
        # 일정을 ExamSchedule 객체로 변환
        schedules = []
        for sched in cert_data.get("schedules_2025", []):
            schedules.append(ExamSchedule(**sched))

        return Certification(
            id=cert_data["id"],
            name=cert_data["name"],
            category=cert_data["category"],
            level=cert_data.get("level"),
            organization=cert_data["organization"],
            description=cert_data.get("description"),
            exam_subjects=cert_data.get("exam_subjects", []),
            passing_criteria=cert_data.get("passing_criteria"),
            exam_fee=cert_data.get("exam_fee"),
            schedules_2025=schedules,
            website=cert_data.get("website")
        )

    raise HTTPException(status_code=404, detail="자격증을 찾을 수 없습니다")
    raise HTTPException(status_code=404, detail="자격증을 찾을 수 없습니다")


@router.get("/{certification_id}/nearest-exam-date")
async def get_nearest_exam_date(certification_id: str):
    """
    Get the nearest upcoming exam date for a certification.
    
    Returns:
        JSON with 'nearest_exam_date' (YYYY-MM-DD or None) and 'd_day' (int).
    """
    data_loader = get_data_loader()
    cert_data = data_loader.get_certification_by_id(certification_id)
    
    if not cert_data:
        raise HTTPException(status_code=404, detail="자격증을 찾을 수 없습니다")
        
    upcoming = data_loader.get_upcoming_exams(days=365)
    
    # Filter for this certification
    exams = [
        e for e in upcoming 
        if e["certification_id"] == certification_id 
        and e["exam_type"] == ExamType.WRITTEN  # Usually focus on Written exams for study sets
    ]
    
    if not exams:
        return {
            "nearest_exam_date": None,
            "d_day": None,
            "message": "향후 1년 내 예정된 필기 시험이 없습니다."
        }
        
    nearest = exams[0]
    
    return {
        "nearest_exam_date": nearest["exam_date"],
        "d_day": nearest["days_until"],
        "exam_round": nearest["round"],
        "description": f"제{nearest['round']}회 {nearest['exam_type']} 시험"
    }

@router.post("/preferences")
async def save_certification_preference(
    preference: CertificationPreferenceRequest,
    # user_id: str = Depends(get_current_user_id)  # TODO: implement auth
    user_id: str = "test_user_id"  # Temporary hardcoded value
):
    """
    사용자의 자격증 선택 저장

    사용자가 준비하고자 하는 자격증을 선택하면 저장합니다.
    """
    # 자격증 존재 확인
    data_loader = get_data_loader()
    cert_data = data_loader.get_certification_by_id(preference.certification_id)

    if not cert_data:
        raise HTTPException(status_code=404, detail="자격증을 찾을 수 없습니다")

    # TODO: 실제 데이터베이스에 저장
    # 현재는 메모리에만 저장 (개발용)
    preference_obj = UserCertificationPreference(
        user_id=user_id,
        certification_id=preference.certification_id,
        target_exam_date=preference.target_exam_date,
        created_at=datetime.now()
    )

    return {
        "message": "자격증 선택이 저장되었습니다",
        "preference": preference_obj
    }


@router.get("/calendar/{year}/{month}")
async def get_monthly_calendar(
    year: int = Path(..., ge=2024, le=2026),
    month: int = Path(..., ge=1, le=12)
):
    """
    월별 시험 달력 데이터 조회

    특정 연월의 모든 시험 일정을 달력 형태로 반환합니다.
    """
    data_loader = get_data_loader()
    all_certifications = data_loader.get_all_certifications()
    calendar_data = {}

    for cert_data in all_certifications:
        # 연도에 맞는 일정 키 선택
        schedule_key = f"schedules_{year}"
        schedules = cert_data.get(schedule_key, [])

        for sched in schedules:
            exam_date = sched["exam_date"]

            # 해당 연월의 시험인지 확인
            if exam_date.year == year and exam_date.month == month:
                day = exam_date.day

                if day not in calendar_data:
                    calendar_data[day] = []

                calendar_data[day].append({
                    "certification_id": cert_data["id"],
                    "certification_name": cert_data["name"],
                    "exam_type": sched["exam_type"],
                    "round": sched["round"],
                    "organization": cert_data["organization"]
                })

    return {
        "year": year,
        "month": month,
        "calendar": calendar_data
    }