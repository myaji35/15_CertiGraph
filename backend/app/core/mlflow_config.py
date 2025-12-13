"""MLflow configuration and utilities for AI tutor tracking and monitoring."""

import os
from typing import Optional, Dict, Any, List
from datetime import datetime
import mlflow
from mlflow.entities import RunStatus
from app.core.config import get_settings


class MLflowTracker:
    """
    MLflow tracking manager for ExamsGraph AI tutor system.

    Handles:
    - GraphRAG path tracing (Scenario A)
    - Prompt experimentation (Scenario B)
    - Feedback loop logging (Scenario C)
    - Cost monitoring (Scenario D)
    """

    def __init__(self):
        settings = get_settings()
        self.mlflow_uri = os.getenv("MLFLOW_TRACKING_URI", "http://mlflow:5000")
        mlflow.set_tracking_uri(self.mlflow_uri)

    def start_experiment(self, experiment_name: str) -> str:
        """Create or get existing MLflow experiment."""
        try:
            experiment = mlflow.get_experiment_by_name(experiment_name)
            if experiment is None:
                experiment_id = mlflow.create_experiment(experiment_name)
            else:
                experiment_id = experiment.experiment_id
            mlflow.set_experiment(experiment_name)
            return experiment_id
        except Exception as e:
            print(f"Error creating experiment: {e}")
            return None

    # =========================================================================
    # Scenario A: GraphRAG Path Tracing (지식 그래프 탐색 경로 추적)
    # =========================================================================

    def trace_graph_exploration(
        self,
        user_id: str,
        question_id: str,
        wrong_concept: str,
        graph_path: List[Dict[str, Any]],
        retrieval_params: Dict[str, Any],
        final_explanation: str
    ) -> str:
        """
        GraphRAG의 지식 그래프 탐색 경로를 MLflow에 기록합니다.

        Args:
            user_id: 사용자 ID
            question_id: 문제 ID
            wrong_concept: 틀린 개념
            graph_path: 그래프 탐색 경로 [{"node": "정규화", "relation": "포함", "next_node": "제1정규형"}, ...]
            retrieval_params: 탐색 파라미터 {"depth": 3, "similarity_threshold": 0.7, ...}
            final_explanation: 최종 생성된 설명

        Returns:
            MLflow run_id
        """
        experiment_id = self.start_experiment("GraphRAG_Path_Tracing")

        with mlflow.start_run(experiment_id=experiment_id, run_name=f"graph_trace_{question_id}") as run:
            # Log parameters
            mlflow.log_params({
                "user_id": user_id,
                "question_id": question_id,
                "wrong_concept": wrong_concept,
                **retrieval_params  # depth, threshold 등
            })

            # Log graph path as JSON artifact
            import json
            path_json = json.dumps(graph_path, indent=2, ensure_ascii=False)
            mlflow.log_text(path_json, "graph_exploration_path.json")

            # Log metrics
            mlflow.log_metrics({
                "path_length": len(graph_path),
                "exploration_depth": retrieval_params.get("depth", 0),
                "similarity_threshold": retrieval_params.get("similarity_threshold", 0.0),
            })

            # Log final explanation as artifact
            mlflow.log_text(final_explanation, "final_explanation.txt")

            # Add tags for filtering
            mlflow.set_tags({
                "scenario": "graph_rag_tracing",
                "wrong_concept": wrong_concept,
                "status": "success"
            })

            return run.info.run_id

    # =========================================================================
    # Scenario B: Prompt Experimentation (프롬프트 비교 실험)
    # =========================================================================

    def compare_prompts(
        self,
        question_id: str,
        user_answer: str,
        correct_answer: str,
        prompt_variants: Dict[str, str],  # {"v1_strict": "엄격한...", "v2_friendly": "친절한..."}
        generated_responses: Dict[str, str]  # {"v1_strict": "응답1", "v2_friendly": "응답2"}
    ) -> List[str]:
        """
        여러 프롬프트 버전의 결과를 비교하기 위해 MLflow에 기록합니다.

        Args:
            question_id: 문제 ID
            user_answer: 사용자의 오답
            correct_answer: 정답
            prompt_variants: 프롬프트 버전들
            generated_responses: 각 프롬프트로 생성된 응답

        Returns:
            List of run_ids for each prompt variant
        """
        experiment_id = self.start_experiment("Prompt_Experimentation")
        run_ids = []

        for variant_name, prompt_text in prompt_variants.items():
            with mlflow.start_run(
                experiment_id=experiment_id,
                run_name=f"prompt_{variant_name}_{question_id}"
            ) as run:
                # Log parameters
                mlflow.log_params({
                    "question_id": question_id,
                    "prompt_variant": variant_name,
                    "user_answer": user_answer,
                    "correct_answer": correct_answer,
                })

                # Log prompt as artifact
                mlflow.log_text(prompt_text, f"prompt_{variant_name}.txt")

                # Log generated response
                response = generated_responses.get(variant_name, "")
                mlflow.log_text(response, f"response_{variant_name}.txt")

                # Log metrics (can be manually rated later)
                mlflow.log_metrics({
                    "response_length": len(response),
                    "prompt_length": len(prompt_text),
                })

                # Tags for comparison
                mlflow.set_tags({
                    "scenario": "prompt_comparison",
                    "variant": variant_name,
                    "question_id": question_id,
                })

                run_ids.append(run.info.run_id)

        return run_ids

    # =========================================================================
    # Scenario C: Feedback Loop (사용자 피드백 수집)
    # =========================================================================

    def log_user_feedback(
        self,
        session_id: str,
        user_id: str,
        question_id: str,
        ai_explanation: str,
        user_feedback: str,  # "thumbs_up", "thumbs_down", "followup_question"
        followup_text: Optional[str] = None,
        understanding_score: Optional[int] = None  # 1-5
    ) -> str:
        """
        사용자의 AI 튜터 피드백을 MLflow에 기록합니다.

        Args:
            session_id: 학습 세션 ID
            user_id: 사용자 ID
            question_id: 문제 ID
            ai_explanation: AI가 제공한 설명
            user_feedback: 피드백 타입
            followup_text: 추가 질문 텍스트
            understanding_score: 이해도 점수

        Returns:
            MLflow run_id
        """
        experiment_id = self.start_experiment("User_Feedback_Loop")

        with mlflow.start_run(experiment_id=experiment_id, run_name=f"feedback_{session_id}") as run:
            # Log parameters
            mlflow.log_params({
                "session_id": session_id,
                "user_id": user_id,
                "question_id": question_id,
                "feedback_type": user_feedback,
            })

            # Log explanation and followup
            mlflow.log_text(ai_explanation, "ai_explanation.txt")
            if followup_text:
                mlflow.log_text(followup_text, "user_followup.txt")

            # Log metrics
            metrics = {}
            if understanding_score:
                metrics["understanding_score"] = understanding_score
            if user_feedback == "thumbs_down":
                metrics["satisfaction"] = 0
            elif user_feedback == "thumbs_up":
                metrics["satisfaction"] = 1

            if metrics:
                mlflow.log_metrics(metrics)

            # Tags for filtering failed explanations
            tags = {
                "scenario": "feedback_loop",
                "feedback": user_feedback,
                "question_id": question_id,
            }

            # Mark for review if negative feedback
            if user_feedback in ["thumbs_down", "followup_question"]:
                tags["status"] = "review_needed"
            else:
                tags["status"] = "satisfactory"

            mlflow.set_tags(tags)

            return run.info.run_id

    # =========================================================================
    # Scenario D: Cost Monitoring (비용 및 모델 라우팅)
    # =========================================================================

    def log_llm_call(
        self,
        user_id: str,
        task_type: str,  # "simple_greeting", "concept_explanation", "complex_reasoning"
        model_name: str,  # "gpt-4o", "gpt-4o-mini"
        input_tokens: int,
        output_tokens: int,
        estimated_cost: float,
        latency_ms: float,
        response_quality: Optional[str] = None
    ) -> str:
        """
        LLM 호출 비용 및 성능을 MLflow에 기록합니다.

        Args:
            user_id: 사용자 ID
            task_type: 작업 유형
            model_name: 사용된 모델
            input_tokens: 입력 토큰 수
            output_tokens: 출력 토큰 수
            estimated_cost: 예상 비용 (USD)
            latency_ms: 응답 지연 시간 (밀리초)
            response_quality: 응답 품질 ("good", "acceptable", "poor")

        Returns:
            MLflow run_id
        """
        experiment_id = self.start_experiment("LLM_Cost_Monitoring")

        with mlflow.start_run(
            experiment_id=experiment_id,
            run_name=f"llm_call_{model_name}_{task_type}"
        ) as run:
            # Log parameters
            mlflow.log_params({
                "user_id": user_id,
                "task_type": task_type,
                "model_name": model_name,
            })

            # Log metrics
            mlflow.log_metrics({
                "input_tokens": input_tokens,
                "output_tokens": output_tokens,
                "total_tokens": input_tokens + output_tokens,
                "estimated_cost_usd": estimated_cost,
                "latency_ms": latency_ms,
            })

            # Tags
            tags = {
                "scenario": "cost_monitoring",
                "task_type": task_type,
                "model": model_name,
            }

            if response_quality:
                tags["quality"] = response_quality

            mlflow.set_tags(tags)

            return run.info.run_id

    # =========================================================================
    # Analytics & Reporting
    # =========================================================================

    def get_top_failed_concepts(self, limit: int = 5) -> List[Dict[str, Any]]:
        """
        사용자가 가장 이해하기 어려워하는 개념 TOP N을 반환합니다.

        Returns:
            [{"concept": "정규화", "failure_count": 15}, ...]
        """
        # MLflow search API를 사용하여 review_needed 태그가 있는 run들을 조회
        from mlflow.tracking import MlflowClient
        client = MlflowClient()

        experiment = mlflow.get_experiment_by_name("User_Feedback_Loop")
        if not experiment:
            return []

        # Filter runs with review_needed status
        runs = client.search_runs(
            experiment_ids=[experiment.experiment_id],
            filter_string="tags.status = 'review_needed'",
            max_results=1000
        )

        # Count by question_id (could be enhanced to map to concepts)
        concept_counts = {}
        for run in runs:
            question_id = run.data.params.get("question_id", "unknown")
            concept_counts[question_id] = concept_counts.get(question_id, 0) + 1

        # Sort and return top N
        top_concepts = sorted(
            [{"concept": k, "failure_count": v} for k, v in concept_counts.items()],
            key=lambda x: x["failure_count"],
            reverse=True
        )[:limit]

        return top_concepts

    def get_average_cost_per_user(self, user_id: Optional[str] = None) -> float:
        """
        사용자 1명당 평균 LLM 비용을 계산합니다.

        Args:
            user_id: 특정 사용자 ID (None이면 전체 평균)

        Returns:
            Average cost in USD
        """
        from mlflow.tracking import MlflowClient
        client = MlflowClient()

        experiment = mlflow.get_experiment_by_name("LLM_Cost_Monitoring")
        if not experiment:
            return 0.0

        filter_string = ""
        if user_id:
            filter_string = f"params.user_id = '{user_id}'"

        runs = client.search_runs(
            experiment_ids=[experiment.experiment_id],
            filter_string=filter_string,
            max_results=10000
        )

        if not runs:
            return 0.0

        total_cost = sum(
            float(run.data.metrics.get("estimated_cost_usd", 0))
            for run in runs
        )

        if user_id:
            return total_cost  # Total cost for specific user
        else:
            # Average across all users
            unique_users = set(run.data.params.get("user_id") for run in runs)
            return total_cost / len(unique_users) if unique_users else 0.0


# Singleton instance
mlflow_tracker = MLflowTracker()
