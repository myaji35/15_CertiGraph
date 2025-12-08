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
        for sched in cert_data.get("schedules_2025", []):
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