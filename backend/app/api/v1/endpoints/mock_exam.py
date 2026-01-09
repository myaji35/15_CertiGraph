"""Mock exam API endpoints."""

from fastapi import APIRouter, HTTPException
from typing import Any, List

from app.api.v1.deps import CurrentUser
from app.models.mock_exam import (
    MockExamStartRequest,
    MockExamStartResponse,
    MockExamSubmitRequest,
    MockExamSubmitResponse,
    MockExamResultDetail,
    PastExamListResponse,
    PastExamInfo,
)
from app.services.mock_exam import MockExamService


router = APIRouter(prefix="/mock-exam", tags=["mock-exam"])


@router.post("/start")
async def start_mock_exam(
    request: MockExamStartRequest,
    current_user: CurrentUser,
) -> dict[str, Any]:
    """
    실전 모의고사를 시작합니다.

    Modes:
    - mock_full: 전체 3교시 연속 응시 (180분)
    - mock_session: 교시별 개별 응시 (60분)
    - past_exam: 특정 연도/회차 기출문제
    """
    try:
        service = MockExamService()
        result = await service.start_mock_exam(
            user_id=current_user.clerk_id,
            mode=request.mode,
            exam_year=request.exam_year,
            exam_round=request.exam_round,
            session_number=request.session_number,
            time_limit_enabled=request.time_limit_enabled,
        )
        return {"data": result}
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"모의고사 시작 실패: {str(e)}")


@router.post("/submit")
async def submit_mock_exam(
    request: MockExamSubmitRequest,
    current_user: CurrentUser,
) -> dict[str, Any]:
    """
    모의고사 답안을 제출하고 과락 판정을 포함한 결과를 받습니다.

    교시별로 제출하거나 전체를 한 번에 제출할 수 있습니다.
    """
    try:
        service = MockExamService()
        result = await service.submit_mock_exam(
            exam_id=request.exam_id,
            user_id=current_user.clerk_id,
            session_number=request.session_number,
            answers=request.answers,
        )
        return {"data": result}
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"답안 제출 실패: {str(e)}")


@router.get("/past-exams")
async def get_past_exams(
    current_user: CurrentUser,
) -> dict[str, Any]:
    """
    사용 가능한 기출문제 목록을 조회합니다.

    연도별, 회차별로 그룹화된 기출문제 목록을 반환합니다.
    """
    try:
        service = MockExamService()
        exams = await service.get_past_exams(current_user.clerk_id)
        return {
            "data": PastExamListResponse(
                exams=exams,
                total=len(exams)
            )
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"기출문제 목록 조회 실패: {str(e)}")


@router.get("/{exam_id}/result")
async def get_mock_exam_result(
    exam_id: str,
    current_user: CurrentUser,
) -> dict[str, Any]:
    """
    모의고사 상세 결과를 조회합니다.

    과락 판정, 교시별 점수, 약점 분석, 학습 추천 사항을 포함합니다.
    """
    try:
        service = MockExamService()
        result = await service.get_exam_result(
            exam_id=exam_id,
            user_id=current_user.clerk_id,
        )
        return {"data": result}
    except ValueError as e:
        raise HTTPException(status_code=404, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"결과 조회 실패: {str(e)}")


@router.get("/{exam_id}/cutoff")
async def get_cutoff_status(
    exam_id: str,
    current_user: CurrentUser,
) -> dict[str, Any]:
    """
    모의고사의 과락 판정 결과를 조회합니다.

    실시간으로 과락 상태를 확인할 수 있습니다.
    """
    try:
        service = MockExamService()
        cutoff_result = await service.calculate_cutoff(
            exam_id=exam_id,
            user_id=current_user.clerk_id,
        )
        return {"data": cutoff_result}
    except ValueError as e:
        raise HTTPException(status_code=404, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"과락 판정 조회 실패: {str(e)}")