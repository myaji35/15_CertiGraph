"""MLflow tracking endpoints for AI tutor monitoring and analytics."""

from fastapi import APIRouter, Depends, HTTPException, status
from typing import List, Optional, Dict, Any
from pydantic import BaseModel
from datetime import datetime

from app.api.v1.deps import CurrentUser
from app.core.mlflow_config import mlflow_tracker


router = APIRouter()


# =========================================================================
# Request/Response Models
# =========================================================================

class GraphNode(BaseModel):
    """Knowledge graph node"""
    node: str
    relation: Optional[str] = None
    next_node: Optional[str] = None
    similarity_score: Optional[float] = None


class GraphExplorationRequest(BaseModel):
    """GraphRAG path tracing request"""
    question_id: str
    wrong_concept: str
    graph_path: List[Dict[str, Any]]
    retrieval_params: Dict[str, Any]  # {"depth": 3, "similarity_threshold": 0.7}
    final_explanation: str


class PromptComparisonRequest(BaseModel):
    """Prompt experimentation request"""
    question_id: str
    user_answer: str
    correct_answer: str
    prompt_variants: Dict[str, str]  # {"v1_strict": "...", "v2_friendly": "..."}
    generated_responses: Dict[str, str]


class UserFeedbackRequest(BaseModel):
    """User feedback logging request"""
    session_id: str
    question_id: str
    ai_explanation: str
    feedback_type: str  # "thumbs_up", "thumbs_down", "followup_question"
    followup_text: Optional[str] = None
    understanding_score: Optional[int] = None  # 1-5


class LLMCostRequest(BaseModel):
    """LLM cost tracking request"""
    task_type: str  # "simple_greeting", "concept_explanation", "complex_reasoning"
    model_name: str  # "gpt-4o", "gpt-4o-mini"
    input_tokens: int
    output_tokens: int
    estimated_cost: float
    latency_ms: float
    response_quality: Optional[str] = None


class TrackingResponse(BaseModel):
    """Generic tracking response"""
    run_id: str
    message: str


class AnalyticsResponse(BaseModel):
    """Analytics report response"""
    data: Any
    generated_at: datetime


# =========================================================================
# Scenario A: GraphRAG Path Tracing
# =========================================================================

@router.post("/trace-graph-exploration", response_model=TrackingResponse)
async def trace_graph_exploration(
    request: GraphExplorationRequest,
    current_user: CurrentUser
):
    """
    GraphRAG의 지식 그래프 탐색 경로를 추적합니다.

    **시나리오 A**: 개발자가 "왜 AI 튜터가 '정규화'에서 'SQL 문법'으로 갑자기 튀었는지"
    탐색 경로를 시각화하여 디버깅할 수 있습니다.
    """
    try:
        run_id = mlflow_tracker.trace_graph_exploration(
            user_id=current_user.clerk_id,
            question_id=request.question_id,
            wrong_concept=request.wrong_concept,
            graph_path=request.graph_path,
            retrieval_params=request.retrieval_params,
            final_explanation=request.final_explanation
        )

        return TrackingResponse(
            run_id=run_id,
            message=f"Graph exploration path tracked successfully. View at MLflow UI."
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to track graph exploration: {str(e)}"
        )


# =========================================================================
# Scenario B: Prompt Experimentation
# =========================================================================

@router.post("/compare-prompts", response_model=TrackingResponse)
async def compare_prompts(
    request: PromptComparisonRequest,
    current_user: CurrentUser
):
    """
    여러 프롬프트 버전을 비교 실험합니다.

    **시나리오 B**: "엄격한 선생님 톤 vs 친절한 코치 톤" 중 어느 것이
    수험생의 멘탈을 케어하면서도 학습 효과가 높은지 비교합니다.
    """
    try:
        run_ids = mlflow_tracker.compare_prompts(
            question_id=request.question_id,
            user_answer=request.user_answer,
            correct_answer=request.correct_answer,
            prompt_variants=request.prompt_variants,
            generated_responses=request.generated_responses
        )

        return TrackingResponse(
            run_id=",".join(run_ids),
            message=f"Prompt comparison tracked. {len(run_ids)} variants logged."
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to compare prompts: {str(e)}"
        )


# =========================================================================
# Scenario C: User Feedback Loop
# =========================================================================

@router.post("/log-user-feedback", response_model=TrackingResponse)
async def log_user_feedback(
    request: UserFeedbackRequest,
    current_user: CurrentUser
):
    """
    사용자의 AI 튜터 피드백을 수집합니다.

    **시나리오 C**: 학생이 "이해 안 돼요(👎)" 버튼을 누르면,
    해당 세션을 'review_needed' 태그로 저장하여 나중에
    "학생들이 가장 이해 못 한 개념 TOP 5"를 분석합니다.
    """
    try:
        run_id = mlflow_tracker.log_user_feedback(
            session_id=request.session_id,
            user_id=current_user.clerk_id,
            question_id=request.question_id,
            ai_explanation=request.ai_explanation,
            user_feedback=request.feedback_type,
            followup_text=request.followup_text,
            understanding_score=request.understanding_score
        )

        return TrackingResponse(
            run_id=run_id,
            message="User feedback logged successfully."
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to log user feedback: {str(e)}"
        )


# =========================================================================
# Scenario D: Cost Monitoring
# =========================================================================

@router.post("/log-llm-cost", response_model=TrackingResponse)
async def log_llm_cost(
    request: LLMCostRequest,
    current_user: CurrentUser
):
    """
    LLM 호출 비용 및 성능을 추적합니다.

    **시나리오 D**: "단순한 인사말에는 GPT-4o-mini,
    복잡한 개념 추론에는 GPT-4o"가 제대로 라우팅되는지 검증하고,
    사용자 1명당 평균 비용을 산출합니다.
    """
    try:
        run_id = mlflow_tracker.log_llm_call(
            user_id=current_user.clerk_id,
            task_type=request.task_type,
            model_name=request.model_name,
            input_tokens=request.input_tokens,
            output_tokens=request.output_tokens,
            estimated_cost=request.estimated_cost,
            latency_ms=request.latency_ms,
            response_quality=request.response_quality
        )

        return TrackingResponse(
            run_id=run_id,
            message="LLM cost logged successfully."
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to log LLM cost: {str(e)}"
        )


# =========================================================================
# Analytics & Reporting
# =========================================================================

@router.get("/analytics/top-failed-concepts", response_model=AnalyticsResponse)
async def get_top_failed_concepts(
    current_user: CurrentUser,
    limit: int = 5
):
    """
    학생들이 가장 이해하기 어려워하는 개념 TOP N을 반환합니다.

    **활용**: GraphRAG 지식 그래프에 "더 쉬운 설명 노드"를 추가할
    우선순위를 결정하는 데이터 근거를 제공합니다.
    """
    try:
        top_concepts = mlflow_tracker.get_top_failed_concepts(limit=limit)

        return AnalyticsResponse(
            data=top_concepts,
            generated_at=datetime.utcnow()
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to get analytics: {str(e)}"
        )


@router.get("/analytics/average-cost", response_model=AnalyticsResponse)
async def get_average_cost_per_user(
    current_user: CurrentUser,
    user_id: Optional[str] = None
):
    """
    사용자 1명당 평균 LLM 비용을 계산합니다.

    **활용**: 월 구독료 책정(₩10,000)이 LLM 비용을 커버할 수 있는지,
    서버 운영 예산을 어떻게 수립해야 하는지 정확한 근거를 제공합니다.
    """
    try:
        avg_cost = mlflow_tracker.get_average_cost_per_user(user_id=user_id)

        return AnalyticsResponse(
            data={
                "average_cost_usd": avg_cost,
                "average_cost_krw": avg_cost * 1300,  # Approximate USD to KRW
                "user_id": user_id or "all_users"
            },
            generated_at=datetime.utcnow()
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to calculate average cost: {str(e)}"
        )
