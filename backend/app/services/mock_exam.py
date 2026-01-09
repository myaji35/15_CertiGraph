"""Mock exam service layer."""

import uuid
import re
from datetime import datetime, timedelta
from typing import List, Optional, Dict, Any
from app.models.mock_exam import (
    MockExamMode,
    ExamSession,
    MockExamSession,
    MockExamStartResponse,
    CutoffStatus,
    CutoffResult,
    SessionResult,
    MockExamSubmitResponse,
    MockExamResultDetail,
    PastExamInfo,
)
from app.repositories import StudySetRepository
from app.repositories.question import QuestionRepository
from app.services.test_engine.session import TestSessionService


class MockExamService:
    """Service for managing mock exams."""

    def __init__(self):
        self.study_set_repo = StudySetRepository()
        self.question_repo = QuestionRepository()
        self.test_service = TestSessionService()
        # In-memory storage for mock exam sessions (should be replaced with DB in production)
        self._exam_sessions: Dict[str, dict] = {}

    async def start_mock_exam(
        self,
        user_id: str,
        mode: MockExamMode,
        exam_year: Optional[int] = None,
        exam_round: Optional[int] = None,
        session_number: Optional[ExamSession] = None,
        time_limit_enabled: bool = True,
    ) -> MockExamStartResponse:
        """Start a new mock exam session."""

        exam_id = str(uuid.uuid4())
        sessions = []

        if mode == MockExamMode.PAST_EXAM:
            # Load past exam questions from uploaded study sets
            # Instead of requiring exact year/round match, find by name
            all_study_sets = await self.study_set_repo.get_all()

            # Find study sets that match the pattern or year
            matching_sets = []
            if exam_year:
                # Find sets with year in name or metadata
                for s in all_study_sets:
                    if (s.get("exam_year") == exam_year or
                        str(exam_year) in s.get("name", "") or
                        f"제{exam_round}회" in s.get("name", "")):
                        matching_sets.append(s)

            # If no matching sets, use the first available set with questions
            if not matching_sets:
                matching_sets = [s for s in all_study_sets if s.get("question_count", 0) > 0]

            if not matching_sets:
                raise ValueError("No study sets with questions available")

            # Use the first matching set
            study_set = matching_sets[0]
            questions = await self.question_repo.get_by_study_set(study_set["id"])

            # Divide questions into sessions (if more than 50 questions, split into multiple sessions)
            total_q = len(questions)
            if total_q > 100:
                # Split into 3 sessions
                q_per_session = total_q // 3
                for i in range(3):
                    start = i * q_per_session
                    end = (i + 1) * q_per_session if i < 2 else total_q
                    session_questions = questions[start:end]
                    sessions.append(MockExamSession(
                        session_number=i + 1,
                        session_name=f"{i + 1}교시",
                        questions=session_questions,
                        time_limit_minutes=60 if time_limit_enabled else 0,
                        total_questions=len(session_questions),
                    ))
            else:
                # Single session for smaller sets
                sessions.append(MockExamSession(
                    session_number=1,
                    session_name=study_set.get("name", "1교시"),
                    questions=questions,
                    time_limit_minutes=60 if time_limit_enabled else 0,
                    total_questions=len(questions),
                ))

        elif mode == MockExamMode.MOCK_FULL:
            # Full mock exam with sample questions (3 sessions)
            for i in range(1, 4):
                # Get sample questions for each session
                questions = await self._get_sample_questions_for_session(i)
                sessions.append(MockExamSession(
                    session_number=i,
                    session_name=f"{i}교시",
                    questions=questions,
                    time_limit_minutes=60 if time_limit_enabled else 0,
                    total_questions=len(questions),
                ))

        elif mode == MockExamMode.MOCK_SESSION:
            # Single session mock
            if not session_number or session_number == ExamSession.ALL_SESSIONS:
                session_number = ExamSession.SESSION_1

            session_num = int(session_number.value.split("_")[1])
            questions = await self._get_sample_questions_for_session(session_num)
            sessions.append(MockExamSession(
                session_number=session_num,
                session_name=f"{session_num}교시",
                questions=questions,
                time_limit_minutes=60 if time_limit_enabled else 0,
                total_questions=len(questions),
            ))

        total_time = sum(s.time_limit_minutes for s in sessions)

        # Store exam session data
        self._exam_sessions[exam_id] = {
            "user_id": user_id,
            "mode": mode,
            "exam_year": exam_year,
            "exam_round": exam_round,
            "sessions": sessions,
            "started_at": datetime.now(),
            "answers": {},
            "completed_sessions": [],
        }

        return MockExamStartResponse(
            exam_id=exam_id,
            mode=mode,
            sessions=sessions,
            total_time_minutes=total_time,
            exam_year=exam_year,
            exam_round=exam_round,
            started_at=datetime.now(),
        )

    async def submit_mock_exam(
        self,
        exam_id: str,
        user_id: str,
        session_number: Optional[int],
        answers: List[dict],
    ) -> MockExamSubmitResponse:
        """Submit mock exam answers and calculate results."""

        if exam_id not in self._exam_sessions:
            raise ValueError("Invalid exam_id")

        exam_data = self._exam_sessions[exam_id]

        if exam_data["user_id"] != user_id:
            raise ValueError("Unauthorized access to exam")

        # Store answers
        if session_number:
            exam_data["answers"][session_number] = answers
            exam_data["completed_sessions"].append(session_number)
        else:
            # All sessions submitted at once
            for answer in answers:
                session_num = self._get_session_for_question(answer["question_id"], exam_data["sessions"])
                if session_num not in exam_data["answers"]:
                    exam_data["answers"][session_num] = []
                exam_data["answers"][session_num].append(answer)
            exam_data["completed_sessions"] = [s.session_number for s in exam_data["sessions"]]

        # Check if all sessions are completed
        all_completed = len(exam_data["completed_sessions"]) == len(exam_data["sessions"])

        if all_completed or session_number is None:
            # Calculate cutoff results
            cutoff_result = await self.calculate_cutoff(exam_id, user_id)

            # Determine next session
            next_session = None
            if not all_completed:
                for session in exam_data["sessions"]:
                    if session.session_number not in exam_data["completed_sessions"]:
                        next_session = session.session_number
                        break

            time_taken = int((datetime.now() - exam_data["started_at"]).total_seconds())

            return MockExamSubmitResponse(
                exam_id=exam_id,
                cutoff_result=cutoff_result,
                completed_at=datetime.now(),
                time_taken_seconds=time_taken,
                next_session=next_session,
            )

        # Return partial result for session-by-session mode
        return MockExamSubmitResponse(
            exam_id=exam_id,
            cutoff_result=await self.calculate_cutoff(exam_id, user_id),
            completed_at=datetime.now(),
            time_taken_seconds=int((datetime.now() - exam_data["started_at"]).total_seconds()),
            next_session=self._get_next_session(exam_data),
        )

    async def calculate_cutoff(self, exam_id: str, user_id: str) -> CutoffResult:
        """Calculate cutoff (과락) status for the exam."""

        if exam_id not in self._exam_sessions:
            raise ValueError("Invalid exam_id")

        exam_data = self._exam_sessions[exam_id]

        if exam_data["user_id"] != user_id:
            raise ValueError("Unauthorized access to exam")

        session_results = []
        total_score = 0
        total_questions = 0
        cutoff_sessions = []

        for session in exam_data["sessions"]:
            session_answers = exam_data["answers"].get(session.session_number, [])

            # Calculate score for this session
            correct = 0
            for answer in session_answers:
                question_id = answer["question_id"]
                selected_option = answer["selected_option"]
                # Find the question and check if answer is correct
                for q in session.questions:
                    if q["id"] == question_id:
                        if q.get("correct_answer") == selected_option:
                            correct += 1
                        break

            score = correct
            total = session.total_questions
            percentage = (score / total * 100) if total > 0 else 0
            is_cutoff = percentage < 40  # 40% 미만이면 과락

            if is_cutoff:
                cutoff_sessions.append(session.session_number)

            session_results.append(SessionResult(
                session_number=session.session_number,
                session_name=session.session_name,
                score=score,
                total=total,
                percentage=percentage,
                is_cutoff=is_cutoff,
                time_taken_seconds=3600,  # Default 60 minutes per session
            ))

            total_score += score
            total_questions += total

        overall_percentage = (total_score / total_questions * 100) if total_questions > 0 else 0
        pass_criteria_met = overall_percentage >= 60
        cutoff_criteria_met = len(cutoff_sessions) == 0

        # Determine overall status
        if not cutoff_criteria_met:
            overall_status = CutoffStatus.CUTOFF
            recommendation = f"과락 과목이 {len(cutoff_sessions)}개 있습니다. 해당 과목을 집중적으로 학습하세요."
        elif not pass_criteria_met:
            overall_status = CutoffStatus.FAIL
            recommendation = f"전체 평균이 {overall_percentage:.1f}%로 합격 기준(60%)에 미달합니다. 전반적인 학습이 필요합니다."
        else:
            overall_status = CutoffStatus.PASS
            recommendation = f"축하합니다! 모든 합격 기준을 충족했습니다. 평균 {overall_percentage:.1f}%"

        return CutoffResult(
            overall_status=overall_status,
            overall_score=total_score,
            overall_total=total_questions,
            overall_percentage=overall_percentage,
            session_results=session_results,
            cutoff_sessions=cutoff_sessions,
            pass_criteria_met=pass_criteria_met,
            cutoff_criteria_met=cutoff_criteria_met,
            recommendation=recommendation,
        )

    async def get_past_exams(self, user_id: str) -> List[PastExamInfo]:
        """Get list of available past exams."""

        # Get all study sets (not just user's) to show all available past exams
        all_study_sets = await self.study_set_repo.get_all()

        # Filter for study sets that have questions
        study_sets = [s for s in all_study_sets if s.get("question_count", 0) > 0]

        # Check if the study set name contains year/round info (e.g., "2026" or "제23회")
        # Also group regular study sets as available exams
        exams_list = []

        # Group by exam metadata if available
        exams_dict = {}

        for study_set in study_sets:
            # Try to extract year/round from name if not in metadata
            name = study_set.get("name", "")
            exam_year = study_set.get("exam_year")
            exam_round = study_set.get("exam_round")

            # If no metadata, try to extract from name
            if not exam_year:
                # Check for year patterns in name (e.g., "2026")
                import re
                year_match = re.search(r"20\d{2}", name)
                if year_match:
                    exam_year = int(year_match.group())

            if not exam_round:
                # Check for round patterns (e.g., "제23회")
                round_match = re.search(r"제(\d+)회", name)
                if round_match:
                    exam_round = int(round_match.group(1))

            # Create exam info regardless of metadata
            exam_info = PastExamInfo(
                exam_year=exam_year or 2024,  # Default year
                exam_round=exam_round or 0,    # 0 means not specified
                exam_name=name,
                total_questions=study_set.get("question_count", 0),
                available_sessions=[1, 2, 3] if study_set.get("question_count", 0) >= 100 else [1],
                tags=study_set.get("tags", []),
                created_at=study_set.get("created_at", datetime.now()),
            )
            exams_list.append(exam_info)

        # Remove duplicates and sort
        unique_exams = {}
        for exam in exams_list:
            key = exam.exam_name  # Use name as unique key
            if key not in unique_exams:
                unique_exams[key] = exam

        # Convert to list
        exams = list(unique_exams.values())

        # Sort by year and round (most recent first), then by name
        exams.sort(key=lambda x: (-x.exam_year, -x.exam_round, x.exam_name))

        return exams

    async def get_exam_result(self, exam_id: str, user_id: str) -> MockExamResultDetail:
        """Get detailed exam result for review."""

        if exam_id not in self._exam_sessions:
            raise ValueError("Invalid exam_id")

        exam_data = self._exam_sessions[exam_id]

        if exam_data["user_id"] != user_id:
            raise ValueError("Unauthorized access to exam")

        cutoff_result = await self.calculate_cutoff(exam_id, user_id)

        # Organize questions by session
        questions_by_session = {}
        for session in exam_data["sessions"]:
            session_answers = exam_data["answers"].get(session.session_number, [])
            question_results = []

            for question in session.questions:
                answer = next((a for a in session_answers if a["question_id"] == question["id"]), None)
                question_results.append({
                    "question": question,
                    "selected_answer": answer["selected_option"] if answer else None,
                    "is_correct": answer and answer["selected_option"] == question.get("correct_answer"),
                })

            questions_by_session[session.session_number] = question_results

        # Analyze weak topics
        weak_topics = self._analyze_weak_topics(questions_by_session)

        # Generate study recommendations
        study_recommendations = self._generate_recommendations(cutoff_result, weak_topics)

        return MockExamResultDetail(
            exam_id=exam_id,
            mode=exam_data["mode"],
            exam_year=exam_data.get("exam_year"),
            exam_round=exam_data.get("exam_round"),
            started_at=exam_data["started_at"],
            completed_at=datetime.now(),
            cutoff_result=cutoff_result,
            questions_by_session=questions_by_session,
            weak_topics=weak_topics,
            study_recommendations=study_recommendations,
        )

    # Helper methods

    async def _get_exam_study_sets(self, exam_year: int, exam_round: int) -> List[dict]:
        """Get study sets for a specific exam."""
        # Query the database for study sets with matching exam_year and exam_round
        all_sets = await self.study_set_repo.get_all()

        # Filter for matching exam
        matching_sets = [
            s for s in all_sets
            if s.get("exam_year") == exam_year and s.get("exam_round") == exam_round
        ]

        return matching_sets

    async def _get_sample_questions_for_session(self, session_number: int) -> List[dict]:
        """Get sample questions for a mock session."""
        # Get questions from available study sets
        all_study_sets = await self.study_set_repo.get_all()

        # Filter sets with questions
        sets_with_questions = [s for s in all_study_sets if s.get("question_count", 0) > 0]

        if not sets_with_questions:
            # Return empty if no questions available
            return []

        # Get questions from the first available set
        study_set = sets_with_questions[0]
        all_questions = await self.question_repo.get_by_study_set(study_set["id"])

        # Return a subset of questions for this session
        # For mock exams, we'll return up to 50 questions per session
        max_questions = 50
        start_index = (session_number - 1) * max_questions
        end_index = min(start_index + max_questions, len(all_questions))

        if start_index >= len(all_questions):
            # If we don't have enough questions for this session, wrap around
            return all_questions[:max_questions]

        return all_questions[start_index:end_index]

    def _get_session_for_question(self, question_id: str, sessions: List[MockExamSession]) -> int:
        """Determine which session a question belongs to."""
        for session in sessions:
            for question in session.questions:
                if question["id"] == question_id:
                    return session.session_number
        return 1  # Default to session 1

    def _get_next_session(self, exam_data: dict) -> Optional[int]:
        """Get the next uncompleted session number."""
        for session in exam_data["sessions"]:
            if session.session_number not in exam_data["completed_sessions"]:
                return session.session_number
        return None

    def _analyze_weak_topics(self, questions_by_session: dict) -> List[str]:
        """Analyze and identify weak topics based on incorrect answers."""
        weak_topics = []
        # This would analyze incorrect answers and identify patterns
        # For now, returning sample weak topics
        for session_num, questions in questions_by_session.items():
            incorrect_count = sum(1 for q in questions if not q.get("is_correct", False))
            if incorrect_count > len(questions) * 0.4:  # More than 40% incorrect
                weak_topics.append(f"{session_num}교시 전반")
        return weak_topics

    def _generate_recommendations(self, cutoff_result: CutoffResult, weak_topics: List[str]) -> List[str]:
        """Generate personalized study recommendations."""
        recommendations = []

        if cutoff_result.overall_status == CutoffStatus.CUTOFF:
            recommendations.append("과락 과목을 우선적으로 학습하세요.")
            for session_num in cutoff_result.cutoff_sessions:
                recommendations.append(f"{session_num}교시 집중 학습이 필요합니다.")

        elif cutoff_result.overall_status == CutoffStatus.FAIL:
            recommendations.append("전체적인 기초 학습이 필요합니다.")
            recommendations.append("매일 꾸준히 학습 시간을 확보하세요.")

        else:
            recommendations.append("합격 수준입니다! 실수하지 않도록 복습하세요.")
            if weak_topics:
                recommendations.append(f"약점 보완: {', '.join(weak_topics)}")

        return recommendations