"""
자격증 데이터 로더 서비스
스크래핑된 데이터와 기존 데이터를 통합 관리
"""
import json
import os
from datetime import date, datetime
from typing import List, Dict, Optional
from pathlib import Path

from app.models.certification import (
    CertificationCategory, CertificationLevel, ExamType, POPULAR_CERTIFICATIONS
)


class CertificationDataLoader:
    """자격증 데이터 로더 클래스"""

    def __init__(self):
        self.data_dir = Path(__file__).parent.parent.parent / "data"
        self.scraped_data_file = self.data_dir / "scraped_certifications.json"
        self._certifications = []
        self._load_data()

    def _convert_category(self, category_str: str) -> CertificationCategory:
        """카테고리 문자열을 Enum으로 변환"""
        mapping = {
            "national": CertificationCategory.NATIONAL,
            "national_professional": CertificationCategory.NATIONAL_PROFESSIONAL,
            "private": CertificationCategory.PRIVATE,
            "international": CertificationCategory.INTERNATIONAL
        }
        return mapping.get(category_str, CertificationCategory.PRIVATE)

    def _convert_level(self, level_str: Optional[str]) -> Optional[CertificationLevel]:
        """레벨 문자열을 Enum으로 변환"""
        if not level_str:
            return None

        mapping = {
            "기사": CertificationLevel.ENGINEER,
            "산업기사": CertificationLevel.INDUSTRIAL_ENGINEER,
            "기능사": CertificationLevel.TECHNICIAN,
            "1급": CertificationLevel.LEVEL_1,
            "2급": CertificationLevel.LEVEL_2,
            "3급": CertificationLevel.LEVEL_3,
            "단일급": CertificationLevel.SINGLE,
            "개발자": CertificationLevel.SINGLE,
        }
        return mapping.get(level_str, CertificationLevel.SINGLE)

    def _convert_exam_type(self, exam_type_str: str) -> ExamType:
        """시험 타입 문자열을 Enum으로 변환"""
        mapping = {
            "필기": ExamType.WRITTEN,
            "실기": ExamType.PRACTICAL,
            "면접": ExamType.INTERVIEW,
            "written": ExamType.WRITTEN,
            "practical": ExamType.PRACTICAL,
            "1차": ExamType.WRITTEN,
            "2차": ExamType.PRACTICAL,
        }
        return mapping.get(exam_type_str.lower(), ExamType.WRITTEN)

    def _parse_date(self, date_str: str) -> date:
        """날짜 문자열을 date 객체로 변환"""
        if isinstance(date_str, date):
            return date_str
        try:
            return datetime.strptime(date_str, "%Y-%m-%d").date()
        except:
            return date.today()

    def _load_scraped_data(self) -> List[Dict]:
        """스크래핑된 데이터 로드"""
        certifications = []

        if self.scraped_data_file.exists():
            try:
                with open(self.scraped_data_file, "r", encoding="utf-8") as f:
                    data = json.load(f)

                for cert in data.get("certifications", []):
                    # 스크래핑된 데이터를 기존 형식으로 변환
                    converted_cert = {
                        "id": cert.get("id", ""),
                        "name": cert.get("name", ""),
                        "category": self._convert_category(cert.get("category", "private")),
                        "level": self._convert_level(cert.get("level")),
                        "organization": cert.get("organization", ""),
                        "description": cert.get("description", ""),
                        "exam_subjects": cert.get("exam_subjects", []),
                        "passing_criteria": cert.get("passing_criteria", ""),
                        "exam_fee": cert.get("exam_fee", {}),
                        "schedules_2025": [],
                        "website": cert.get("website", "")
                    }

                    # 일정 변환
                    for schedule in cert.get("schedules_2025", []):
                        try:
                            round_value = schedule.get("round", "1")
                            # round 값을 숫자로 변환 시도
                            if isinstance(round_value, str):
                                # "53회", "24-1회" 같은 형식 처리
                                round_num = ''.join(filter(str.isdigit, round_value.split('-')[0]))
                                round_num = int(round_num) if round_num else 1
                            else:
                                round_num = int(round_value)

                            converted_schedule = {
                                "exam_type": self._convert_exam_type(schedule.get("exam_type", "필기")),
                                "round": round_num,
                                "application_start": self._parse_date(schedule.get("application_start")),
                                "application_end": self._parse_date(schedule.get("application_end")),
                                "exam_date": self._parse_date(schedule.get("exam_date")),
                                "result_date": self._parse_date(schedule.get("result_date"))
                            }

                            if schedule.get("note"):
                                converted_schedule["description"] = schedule["note"]

                            converted_cert["schedules_2025"].append(converted_schedule)
                        except Exception as e:
                            print(f"일정 변환 오류: {e}")
                            continue

                    certifications.append(converted_cert)

            except Exception as e:
                print(f"스크래핑 데이터 로드 오류: {e}")

        return certifications

    def _load_data(self):
        """모든 데이터 로드 및 통합"""
        # 기존 하드코딩된 데이터
        self._certifications = list(POPULAR_CERTIFICATIONS)

        # 스크래핑된 데이터 추가
        scraped_certs = self._load_scraped_data()

        # 중복 제거 (ID 기준)
        existing_ids = {cert["id"] for cert in self._certifications}

        for cert in scraped_certs:
            if cert["id"] not in existing_ids:
                self._certifications.append(cert)
                existing_ids.add(cert["id"])

    def get_all_certifications(self) -> List[Dict]:
        """모든 자격증 데이터 반환"""
        return self._certifications

    def get_certification_by_id(self, cert_id: str) -> Optional[Dict]:
        """ID로 특정 자격증 조회"""
        for cert in self._certifications:
            if cert["id"] == cert_id:
                return cert
        return None

    def get_certifications_by_category(self, category: CertificationCategory) -> List[Dict]:
        """카테고리별 자격증 조회"""
        return [
            cert for cert in self._certifications
            if cert["category"] == category
        ]

    def get_certifications_by_month(self, month: int, year: int = 2025) -> List[Dict]:
        """특정 월에 시험이 있는 자격증 조회"""
        result = []
        for cert in self._certifications:
            has_exam = any(
                schedule["exam_date"].month == month
                for schedule in cert.get("schedules_2025", [])
                if isinstance(schedule.get("exam_date"), date)
            )
            if has_exam:
                result.append(cert)
        return result

    def get_upcoming_exams(self, days: int = 30) -> List[Dict]:
        """다가오는 시험 일정 조회"""
        from datetime import timedelta

        today = date.today()
        end_date = today + timedelta(days=days)
        upcoming = []

        for cert in self._certifications:
            for schedule in cert.get("schedules_2025", []):
                exam_date = schedule.get("exam_date")
                if isinstance(exam_date, date) and today <= exam_date <= end_date:
                    upcoming.append({
                        "certification_id": cert["id"],
                        "certification_name": cert["name"],
                        "organization": cert["organization"],
                        "exam_type": schedule["exam_type"],
                        "round": schedule["round"],
                        "exam_date": exam_date,
                        "application_start": schedule["application_start"],
                        "application_end": schedule["application_end"],
                        "result_date": schedule["result_date"],
                        "days_until": (exam_date - today).days,
                        "is_application_open": (
                            isinstance(schedule["application_start"], date) and
                            isinstance(schedule["application_end"], date) and
                            schedule["application_start"] <= today <= schedule["application_end"]
                        )
                    })

        # 날짜순 정렬
        upcoming.sort(key=lambda x: x["exam_date"])
        return upcoming

    def refresh_data(self):
        """데이터 새로고침"""
        self._certifications = []
        self._load_data()


# 싱글톤 인스턴스
_data_loader = None

def get_data_loader() -> CertificationDataLoader:
    """데이터 로더 인스턴스 반환"""
    global _data_loader
    if _data_loader is None:
        _data_loader = CertificationDataLoader()
    return _data_loader