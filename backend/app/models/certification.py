"""Certification exam calendar models."""

from enum import Enum
from datetime import date, datetime
from pydantic import BaseModel, Field
from typing import Optional, List


class ExamType(str, Enum):
    """시험 구분"""
    WRITTEN = "written"  # 필기
    PRACTICAL = "practical"  # 실기
    INTERVIEW = "interview"  # 면접


class CertificationCategory(str, Enum):
    """자격증 분류"""
    NATIONAL = "national"  # 국가기술자격
    NATIONAL_PROFESSIONAL = "national_professional"  # 국가전문자격
    PRIVATE = "private"  # 민간자격
    INTERNATIONAL = "international"  # 국제자격


class CertificationLevel(str, Enum):
    """자격증 등급"""
    TECHNICIAN = "technician"  # 기능사
    INDUSTRIAL_ENGINEER = "industrial_engineer"  # 산업기사
    ENGINEER = "engineer"  # 기사
    MASTER = "master"  # 기능장/기술사
    LEVEL_1 = "level_1"  # 1급
    LEVEL_2 = "level_2"  # 2급
    LEVEL_3 = "level_3"  # 3급
    SINGLE = "single"  # 단일등급


class ExamSchedule(BaseModel):
    """시험 일정"""
    exam_type: ExamType = Field(..., description="시험 구분")
    round: int = Field(..., description="회차")
    application_start: date = Field(..., description="접수 시작일")
    application_end: date = Field(..., description="접수 종료일")
    exam_date: date = Field(..., description="시험일")
    result_date: date = Field(..., description="합격 발표일")
    description: Optional[str] = Field(None, description="비고")


class Certification(BaseModel):
    """자격증 정보"""
    id: str = Field(..., description="자격증 ID")
    name: str = Field(..., description="자격증명")
    category: CertificationCategory = Field(..., description="자격증 분류")
    level: Optional[CertificationLevel] = Field(None, description="등급")
    organization: str = Field(..., description="시행기관")
    description: Optional[str] = Field(None, description="자격증 설명")
    exam_subjects: List[str] = Field(default_factory=list, description="시험 과목")
    passing_criteria: Optional[str] = Field(None, description="합격 기준")
    exam_fee: Optional[dict] = Field(None, description="응시료")
    schedules_2025: List[ExamSchedule] = Field(default_factory=list, description="2025년 시험 일정")
    website: Optional[str] = Field(None, description="관련 웹사이트")


class CertificationListResponse(BaseModel):
    """자격증 목록 응답"""
    certifications: List[Certification]
    total: int


class UserCertificationPreference(BaseModel):
    """사용자 자격증 선택 정보"""
    user_id: str
    certification_id: str
    target_exam_date: Optional[date] = None
    created_at: datetime


# 주요 자격증 데이터 (2025년 기준)
POPULAR_CERTIFICATIONS = [
    {
        "id": "social_worker_1",
        "name": "사회복지사 1급",
        "category": CertificationCategory.NATIONAL_PROFESSIONAL,
        "level": CertificationLevel.LEVEL_1,
        "organization": "한국사회복지사협회",
        "description": "사회복지 전문 인력 양성을 위한 국가전문자격",
        "exam_subjects": [
            "사회복지기초",
            "사회복지실천",
            "사회복지정책과 제도"
        ],
        "passing_criteria": "각 과목 40점 이상, 전체 평균 60점 이상",
        "exam_fee": {"written": 25000},
        "schedules_2025": [
            {
                "exam_type": ExamType.WRITTEN,
                "round": 23,
                "application_start": date(2024, 12, 2),
                "application_end": date(2024, 12, 6),
                "exam_date": date(2025, 1, 25),
                "result_date": date(2025, 3, 12)
            }
        ],
        "website": "https://www.welfare.net"
    },
    {
        "id": "info_processing_engineer",
        "name": "정보처리기사",
        "category": CertificationCategory.NATIONAL,
        "level": CertificationLevel.ENGINEER,
        "organization": "한국산업인력공단",
        "description": "정보시스템의 분석, 설계, 구현 및 운영 능력 평가",
        "exam_subjects": [
            "소프트웨어 설계",
            "소프트웨어 개발",
            "데이터베이스 구축",
            "프로그래밍 언어 활용",
            "정보시스템 구축관리"
        ],
        "passing_criteria": "필기: 과목당 40점 이상, 평균 60점 이상 / 실기: 60점 이상",
        "exam_fee": {"written": 19400, "practical": 22600},
        "schedules_2025": [
            {
                "exam_type": ExamType.WRITTEN,
                "round": 1,
                "application_start": date(2025, 1, 13),
                "application_end": date(2025, 1, 16),
                "exam_date": date(2025, 2, 15),
                "result_date": date(2025, 3, 5)
            },
            {
                "exam_type": ExamType.PRACTICAL,
                "round": 1,
                "application_start": date(2025, 3, 10),
                "application_end": date(2025, 3, 13),
                "exam_date": date(2025, 4, 12),
                "result_date": date(2025, 5, 7)
            },
            {
                "exam_type": ExamType.WRITTEN,
                "round": 2,
                "application_start": date(2025, 4, 14),
                "application_end": date(2025, 4, 17),
                "exam_date": date(2025, 5, 17),
                "result_date": date(2025, 6, 4)
            }
        ],
        "website": "https://www.q-net.or.kr"
    },
    {
        "id": "toeic",
        "name": "TOEIC",
        "category": CertificationCategory.INTERNATIONAL,
        "level": CertificationLevel.SINGLE,
        "organization": "한국TOEIC위원회",
        "description": "국제 비즈니스 영어 능력 평가",
        "exam_subjects": [
            "Listening Comprehension",
            "Reading Comprehension"
        ],
        "passing_criteria": "990점 만점 (기관별 요구 점수 상이)",
        "exam_fee": {"regular": 48000, "special": 53000},
        "schedules_2025": [
            {
                "exam_type": ExamType.WRITTEN,
                "round": 499,
                "application_start": date(2024, 12, 23),
                "application_end": date(2025, 1, 6),
                "exam_date": date(2025, 1, 12),
                "result_date": date(2025, 1, 22)
            },
            {
                "exam_type": ExamType.WRITTEN,
                "round": 500,
                "application_start": date(2025, 1, 6),
                "application_end": date(2025, 1, 20),
                "exam_date": date(2025, 1, 26),
                "result_date": date(2025, 2, 5)
            }
        ],
        "website": "https://www.toeic.co.kr"
    },
    {
        "id": "korean_history_1",
        "name": "한국사능력검정시험",
        "category": CertificationCategory.NATIONAL_PROFESSIONAL,
        "level": CertificationLevel.LEVEL_1,
        "organization": "국사편찬위원회",
        "description": "한국사에 대한 이해와 사고력 평가",
        "exam_subjects": [
            "전근대사",
            "근현대사"
        ],
        "passing_criteria": "1급: 80점 이상, 2급: 70점 이상, 3급: 60점 이상",
        "exam_fee": {"basic": 22000, "advanced": 32000},
        "schedules_2025": [
            {
                "exam_type": ExamType.WRITTEN,
                "round": 71,
                "application_start": date(2025, 1, 13),
                "application_end": date(2025, 1, 17),
                "exam_date": date(2025, 2, 8),
                "result_date": date(2025, 2, 19)
            },
            {
                "exam_type": ExamType.WRITTEN,
                "round": 72,
                "application_start": date(2025, 3, 24),
                "application_end": date(2025, 3, 28),
                "exam_date": date(2025, 4, 19),
                "result_date": date(2025, 4, 30)
            }
        ],
        "website": "https://www.historyexam.go.kr"
    },
    {
        "id": "sqld",
        "name": "SQLD (SQL개발자)",
        "category": CertificationCategory.NATIONAL_PROFESSIONAL,
        "level": CertificationLevel.SINGLE,
        "organization": "한국데이터산업진흥원",
        "description": "데이터베이스와 SQL에 대한 전문 지식 평가",
        "exam_subjects": [
            "데이터 모델링의 이해",
            "SQL 기본 및 활용"
        ],
        "passing_criteria": "총점 60점 이상 (100점 만점)",
        "exam_fee": {"written": 100000},
        "schedules_2025": [
            {
                "exam_type": ExamType.WRITTEN,
                "round": 52,
                "application_start": date(2025, 2, 3),
                "application_end": date(2025, 2, 7),
                "exam_date": date(2025, 3, 8),
                "result_date": date(2025, 4, 4)
            },
            {
                "exam_type": ExamType.WRITTEN,
                "round": 53,
                "application_start": date(2025, 4, 28),
                "application_end": date(2025, 5, 2),
                "exam_date": date(2025, 5, 31),
                "result_date": date(2025, 6, 27)
            }
        ],
        "website": "https://www.dataq.or.kr"
    },
    {
        "id": "computer_specialist_2",
        "name": "컴퓨터활용능력 2급",
        "category": CertificationCategory.NATIONAL,
        "level": CertificationLevel.LEVEL_2,
        "organization": "대한상공회의소",
        "description": "컴퓨터 활용 및 스프레드시트 실무 능력 평가",
        "exam_subjects": [
            "컴퓨터 일반",
            "스프레드시트 일반"
        ],
        "passing_criteria": "과목당 40점 이상, 평균 60점 이상",
        "exam_fee": {"written": 19000, "practical": 21000},
        "schedules_2025": [
            {
                "exam_type": ExamType.WRITTEN,
                "round": 1,
                "application_start": date(2025, 1, 6),
                "application_end": date(2025, 1, 10),
                "exam_date": date(2025, 1, 18),
                "result_date": date(2025, 1, 24)
            },
            {
                "exam_type": ExamType.PRACTICAL,
                "round": 1,
                "application_start": date(2025, 1, 27),
                "application_end": date(2025, 1, 31),
                "exam_date": date(2025, 2, 8),
                "result_date": date(2025, 2, 21)
            }
        ],
        "website": "https://license.korcham.net"
    },
    {
        "id": "cpa",
        "name": "공인회계사",
        "category": CertificationCategory.NATIONAL_PROFESSIONAL,
        "level": CertificationLevel.SINGLE,
        "organization": "금융감독원",
        "description": "회계·감사 전문가 자격",
        "exam_subjects": [
            "경영학",
            "경제원론",
            "상법",
            "세법개론",
            "회계학"
        ],
        "passing_criteria": "1차: 과목당 40점 이상, 평균 60점 이상",
        "exam_fee": {"written": 60000},
        "schedules_2025": [
            {
                "exam_type": ExamType.WRITTEN,
                "round": 60,
                "application_start": date(2025, 1, 6),
                "application_end": date(2025, 1, 10),
                "exam_date": date(2025, 2, 23),
                "result_date": date(2025, 4, 11)
            }
        ],
        "website": "https://www.kicpa.or.kr"
    },
    {
        "id": "nurse",
        "name": "간호사",
        "category": CertificationCategory.NATIONAL_PROFESSIONAL,
        "level": CertificationLevel.SINGLE,
        "organization": "한국보건의료인국가시험원",
        "description": "간호 전문 의료인력 자격",
        "exam_subjects": [
            "성인간호학",
            "여성건강간호학",
            "아동간호학",
            "정신간호학",
            "지역사회간호학",
            "간호관리학",
            "기본간호학"
        ],
        "passing_criteria": "전 과목 총점의 60% 이상, 각 과목 40% 이상",
        "exam_fee": {"written": 90000},
        "schedules_2025": [
            {
                "exam_type": ExamType.WRITTEN,
                "round": 65,
                "application_start": date(2024, 11, 25),
                "application_end": date(2024, 11, 29),
                "exam_date": date(2025, 1, 17),
                "result_date": date(2025, 2, 7)
            }
        ],
        "website": "https://www.kuksiwon.or.kr"
    },
    {
        "id": "fund_investment",
        "name": "펀드투자권유대행인",
        "category": CertificationCategory.NATIONAL_PROFESSIONAL,
        "level": CertificationLevel.SINGLE,
        "organization": "한국금융투자협회",
        "description": "펀드 판매 및 투자 권유 전문 자격",
        "exam_subjects": [
            "펀드투자",
            "투자권유"
        ],
        "passing_criteria": "과목당 40점 이상, 평균 60점 이상",
        "exam_fee": {"written": 40000},
        "schedules_2025": [
            {
                "exam_type": ExamType.WRITTEN,
                "round": 1,
                "application_start": date(2025, 1, 2),
                "application_end": date(2025, 1, 16),
                "exam_date": date(2025, 2, 1),
                "result_date": date(2025, 2, 14)
            },
            {
                "exam_type": ExamType.WRITTEN,
                "round": 2,
                "application_start": date(2025, 3, 3),
                "application_end": date(2025, 3, 17),
                "exam_date": date(2025, 4, 5),
                "result_date": date(2025, 4, 18)
            }
        ],
        "website": "https://license.kofia.or.kr"
    },
    {
        "id": "real_estate_agent",
        "name": "공인중개사",
        "category": CertificationCategory.NATIONAL_PROFESSIONAL,
        "level": CertificationLevel.SINGLE,
        "organization": "한국산업인력공단",
        "description": "부동산 중개업 전문 자격",
        "exam_subjects": [
            "부동산학개론",
            "민법 및 민사특별법",
            "공인중개사법령 및 실무",
            "부동산공법",
            "부동산공시법",
            "부동산세법"
        ],
        "passing_criteria": "1차/2차 각각 과목당 40점 이상, 평균 60점 이상",
        "exam_fee": {"written": 22000},
        "schedules_2025": [
            {
                "exam_type": ExamType.WRITTEN,
                "round": 35,
                "application_start": date(2025, 7, 28),
                "application_end": date(2025, 8, 1),
                "exam_date": date(2025, 10, 25),
                "result_date": date(2025, 12, 3)
            }
        ],
        "website": "https://www.q-net.or.kr"
    },
    {
        "id": "afpk",
        "name": "AFPK (재무설계사)",
        "category": CertificationCategory.PRIVATE,
        "level": CertificationLevel.SINGLE,
        "organization": "한국FPSB",
        "description": "개인재무설계 전문가 자격",
        "exam_subjects": [
            "재무설계 개론",
            "위험관리와 보험설계",
            "투자설계",
            "부동산설계",
            "은퇴설계",
            "세금설계"
        ],
        "passing_criteria": "과목당 40점 이상, 전체 평균 60점 이상",
        "exam_fee": {"written": 160000},
        "schedules_2025": [
            {
                "exam_type": ExamType.WRITTEN,
                "round": 1,
                "application_start": date(2025, 2, 3),
                "application_end": date(2025, 2, 14),
                "exam_date": date(2025, 3, 15),
                "result_date": date(2025, 4, 11)
            },
            {
                "exam_type": ExamType.WRITTEN,
                "round": 2,
                "application_start": date(2025, 5, 12),
                "application_end": date(2025, 5, 23),
                "exam_date": date(2025, 6, 21),
                "result_date": date(2025, 7, 18)
            }
        ],
        "website": "https://www.fpsbkorea.org"
    },
    {
        "id": "adsp",
        "name": "ADsP (데이터분석준전문가)",
        "category": CertificationCategory.NATIONAL_PROFESSIONAL,
        "level": CertificationLevel.SINGLE,
        "organization": "한국데이터산업진흥원",
        "description": "데이터 분석 준전문가 자격",
        "exam_subjects": [
            "데이터 이해",
            "데이터 분석 기획",
            "데이터 분석"
        ],
        "passing_criteria": "총점 60점 이상",
        "exam_fee": {"written": 80000},
        "schedules_2025": [
            {
                "exam_type": ExamType.WRITTEN,
                "round": 44,
                "application_start": date(2025, 2, 3),
                "application_end": date(2025, 2, 7),
                "exam_date": date(2025, 3, 8),
                "result_date": date(2025, 4, 4)
            },
            {
                "exam_type": ExamType.WRITTEN,
                "round": 45,
                "application_start": date(2025, 4, 28),
                "application_end": date(2025, 5, 2),
                "exam_date": date(2025, 5, 31),
                "result_date": date(2025, 6, 27)
            }
        ],
        "website": "https://www.dataq.or.kr"
    },
    {
        "id": "big_data_analyst",
        "name": "빅데이터분석기사",
        "category": CertificationCategory.NATIONAL,
        "level": CertificationLevel.ENGINEER,
        "organization": "한국데이터산업진흥원",
        "description": "빅데이터 분석 전문가 자격",
        "exam_subjects": [
            "빅데이터 분석 기획",
            "빅데이터 탐색",
            "빅데이터 모델링",
            "빅데이터 결과 해석"
        ],
        "passing_criteria": "필기/실기 각각 60점 이상",
        "exam_fee": {"written": 60000, "practical": 80000},
        "schedules_2025": [
            {
                "exam_type": ExamType.WRITTEN,
                "round": 5,
                "application_start": date(2025, 3, 10),
                "application_end": date(2025, 3, 14),
                "exam_date": date(2025, 4, 12),
                "result_date": date(2025, 5, 2)
            },
            {
                "exam_type": ExamType.PRACTICAL,
                "round": 5,
                "application_start": date(2025, 5, 12),
                "application_end": date(2025, 5, 16),
                "exam_date": date(2025, 6, 14),
                "result_date": date(2025, 7, 11)
            }
        ],
        "website": "https://www.dataq.or.kr"
    },
    {
        "id": "aws_saa",
        "name": "AWS Solutions Architect - Associate",
        "category": CertificationCategory.INTERNATIONAL,
        "level": CertificationLevel.SINGLE,
        "organization": "Amazon Web Services",
        "description": "AWS 클라우드 설계 전문가 인증",
        "exam_subjects": [
            "보안 아키텍처 설계",
            "복원력 있는 아키텍처 설계",
            "고성능 아키텍처 설계",
            "비용 최적화 아키텍처 설계"
        ],
        "passing_criteria": "720점 이상 (1000점 만점)",
        "exam_fee": {"written": 150000},
        "schedules_2025": [
            {
                "exam_type": ExamType.WRITTEN,
                "round": 0,
                "application_start": date(2025, 1, 1),
                "application_end": date(2025, 12, 31),
                "exam_date": date(2025, 12, 31),
                "result_date": date(2025, 12, 31),
                "description": "상시 응시 가능"
            }
        ],
        "website": "https://aws.amazon.com/certification"
    }
]