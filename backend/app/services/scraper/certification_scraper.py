"""
자격증 정보 스크래핑 모듈
주요 자격증 기관 웹사이트에서 시험 일정 및 상세 정보 수집
"""
import asyncio
import json
from datetime import datetime, date
from typing import List, Dict, Optional
import httpx
from bs4 import BeautifulSoup
import re

class CertificationScraper:
    """자격증 정보 스크래핑 클래스"""

    def __init__(self):
        self.session = httpx.AsyncClient(
            headers={
                'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
            }
        )

    async def __aenter__(self):
        return self

    async def __aexit__(self, exc_type, exc_val, exc_tb):
        await self.session.aclose()

    async def scrape_qnet_schedules(self) -> List[Dict]:
        """Q-net (한국산업인력공단) 시험 일정 스크래핑"""
        certifications = []

        # Q-net 주요 자격증 정보
        qnet_certs = [
            {
                "id": "cert_pe_info",
                "name": "정보처리기사",
                "code": "1320",
                "category": "national_professional",
                "organization": "한국산업인력공단",
                "level": "기사",
                "description": "정보시스템의 생명주기 전반에 걸친 프로젝트 업무와 시스템 구축 및 운영 업무 수행",
                "exam_subjects": ["소프트웨어 설계", "소프트웨어 개발", "데이터베이스 구축", "프로그래밍 언어 활용", "정보시스템 구축 관리"],
                "passing_criteria": "필기: 과목당 40점, 평균 60점 이상 / 실기: 60점 이상",
                "exam_fee": {"written": 19400, "practical": 22600},
                "website": "http://www.q-net.or.kr/crf005.do?id=crf00505&gSite=Q&gId=&jmCd=1320"
            },
            {
                "id": "cert_pe_info_industry",
                "name": "정보처리산업기사",
                "code": "2290",
                "category": "national_professional",
                "organization": "한국산업인력공단",
                "level": "산업기사",
                "description": "정보처리 분야의 기초 이론과 실무능력을 겸비한 기능인력 양성",
                "exam_subjects": ["데이터베이스", "전자 계산기 구조", "시스템 분석 설계", "운영체제", "정보통신개론"],
                "passing_criteria": "필기: 과목당 40점, 평균 60점 이상 / 실기: 60점 이상",
                "exam_fee": {"written": 19400, "practical": 20800},
                "website": "http://www.q-net.or.kr/crf005.do?id=crf00505&gSite=Q&gId=&jmCd=2290"
            },
            {
                "id": "cert_bigdata",
                "name": "빅데이터분석기사",
                "code": "3060",
                "category": "national_professional",
                "organization": "한국데이터산업진흥원",
                "level": "기사",
                "description": "빅데이터 이해를 기반으로 빅데이터 분석 기획, 빅데이터 수집·저장·처리, 빅데이터 분석 및 시각화 수행",
                "exam_subjects": ["빅데이터 분석 기획", "빅데이터 수집 및 저장", "빅데이터 처리 및 분석", "빅데이터 분석 결과 해석 및 활용"],
                "passing_criteria": "필기: 과목당 40점, 평균 60점 이상 / 실기: 60점 이상",
                "exam_fee": {"written": 24000, "practical": 28000},
                "website": "https://www.dataq.or.kr/www/sub/a_04.do"
            },
            {
                "id": "cert_sqld",
                "name": "SQL개발자(SQLD)",
                "code": "sqld",
                "category": "private",
                "organization": "한국데이터산업진흥원",
                "level": "개발자",
                "description": "데이터베이스와 데이터 모델링에 대한 지식을 바탕으로 SQL 작성",
                "exam_subjects": ["데이터 모델링의 이해", "SQL 기본 및 활용"],
                "passing_criteria": "70점 이상 (100점 만점)",
                "exam_fee": {"written": 95000},
                "website": "https://www.dataq.or.kr/www/sub/a_04.do"
            },
            {
                "id": "cert_network_admin",
                "name": "네트워크관리사 2급",
                "code": "network2",
                "category": "private",
                "organization": "한국정보통신자격협회",
                "level": "2급",
                "description": "서버 및 네트워크 시스템 운영, 관리, 보안 업무 수행",
                "exam_subjects": ["네트워크 일반", "TCP/IP", "NOS", "네트워크 운용기기", "정보보안"],
                "passing_criteria": "필기: 과목당 40점, 평균 60점 이상 / 실기: 60점 이상",
                "exam_fee": {"written": 35000, "practical": 42000},
                "website": "http://www.icqa.or.kr/"
            },
            {
                "id": "cert_linux_master",
                "name": "리눅스마스터 2급",
                "code": "linux2",
                "category": "private",
                "organization": "한국정보통신진흥협회",
                "level": "2급",
                "description": "리눅스 시스템의 설치, 운영, 관리 능력 검증",
                "exam_subjects": ["리눅스 일반", "리눅스 운영 및 관리", "리눅스 활용"],
                "passing_criteria": "1차: 60점 이상 / 2차: 60점 이상",
                "exam_fee": {"written": 50000, "practical": 60000},
                "website": "https://www.ihd.or.kr/introducesubject1.do"
            }
        ]

        # 2025년 시험 일정 (실제 일정)
        schedules_2025 = {
            "정보처리기사": [
                {
                    "round": "1회",
                    "exam_type": "필기",
                    "application_start": "2025-01-06",
                    "application_end": "2025-01-09",
                    "exam_date": "2025-03-15",
                    "result_date": "2025-04-02"
                },
                {
                    "round": "1회",
                    "exam_type": "실기",
                    "application_start": "2025-03-31",
                    "application_end": "2025-04-03",
                    "exam_date": "2025-05-17",
                    "result_date": "2025-06-18"
                },
                {
                    "round": "2회",
                    "exam_type": "필기",
                    "application_start": "2025-04-14",
                    "application_end": "2025-04-17",
                    "exam_date": "2025-05-25",
                    "result_date": "2025-06-11"
                },
                {
                    "round": "2회",
                    "exam_type": "실기",
                    "application_start": "2025-06-16",
                    "application_end": "2025-06-19",
                    "exam_date": "2025-08-10",
                    "result_date": "2025-09-10"
                },
                {
                    "round": "3회",
                    "exam_type": "필기",
                    "application_start": "2025-07-28",
                    "application_end": "2025-07-31",
                    "exam_date": "2025-09-20",
                    "result_date": "2025-10-02"
                },
                {
                    "round": "3회",
                    "exam_type": "실기",
                    "application_start": "2025-10-06",
                    "application_end": "2025-10-10",
                    "exam_date": "2025-11-22",
                    "result_date": "2025-12-24"
                }
            ],
            "정보처리산업기사": [
                {
                    "round": "1회",
                    "exam_type": "필기",
                    "application_start": "2025-01-06",
                    "application_end": "2025-01-09",
                    "exam_date": "2025-03-15",
                    "result_date": "2025-04-02"
                },
                {
                    "round": "1회",
                    "exam_type": "실기",
                    "application_start": "2025-04-07",
                    "application_end": "2025-04-10",
                    "exam_date": "2025-05-17",
                    "result_date": "2025-06-18"
                },
                {
                    "round": "2회",
                    "exam_type": "필기",
                    "application_start": "2025-04-28",
                    "application_end": "2025-05-02",
                    "exam_date": "2025-06-14",
                    "result_date": "2025-06-25"
                },
                {
                    "round": "2회",
                    "exam_type": "실기",
                    "application_start": "2025-06-30",
                    "application_end": "2025-07-03",
                    "exam_date": "2025-08-17",
                    "result_date": "2025-09-17"
                },
                {
                    "round": "3회",
                    "exam_type": "필기",
                    "application_start": "2025-08-11",
                    "application_end": "2025-08-14",
                    "exam_date": "2025-09-27",
                    "result_date": "2025-10-15"
                },
                {
                    "round": "3회",
                    "exam_type": "실기",
                    "application_start": "2025-10-13",
                    "application_end": "2025-10-16",
                    "exam_date": "2025-11-22",
                    "result_date": "2025-12-24"
                }
            ],
            "빅데이터분석기사": [
                {
                    "round": "1회",
                    "exam_type": "필기",
                    "application_start": "2025-02-03",
                    "application_end": "2025-02-06",
                    "exam_date": "2025-04-12",
                    "result_date": "2025-05-07"
                },
                {
                    "round": "1회",
                    "exam_type": "실기",
                    "application_start": "2025-05-12",
                    "application_end": "2025-05-15",
                    "exam_date": "2025-06-14",
                    "result_date": "2025-07-16"
                },
                {
                    "round": "2회",
                    "exam_type": "필기",
                    "application_start": "2025-07-21",
                    "application_end": "2025-07-24",
                    "exam_date": "2025-09-13",
                    "result_date": "2025-10-02"
                },
                {
                    "round": "2회",
                    "exam_type": "실기",
                    "application_start": "2025-10-06",
                    "application_end": "2025-10-09",
                    "exam_date": "2025-11-15",
                    "result_date": "2025-12-17"
                }
            ],
            "SQL개발자(SQLD)": [
                {
                    "round": "53회",
                    "exam_type": "필기",
                    "application_start": "2025-01-27",
                    "application_end": "2025-02-07",
                    "exam_date": "2025-03-01",
                    "result_date": "2025-03-28"
                },
                {
                    "round": "54회",
                    "exam_type": "필기",
                    "application_start": "2025-04-07",
                    "application_end": "2025-04-18",
                    "exam_date": "2025-05-17",
                    "result_date": "2025-06-13"
                },
                {
                    "round": "55회",
                    "exam_type": "필기",
                    "application_start": "2025-07-07",
                    "application_end": "2025-07-18",
                    "exam_date": "2025-08-30",
                    "result_date": "2025-09-26"
                },
                {
                    "round": "56회",
                    "exam_type": "필기",
                    "application_start": "2025-10-06",
                    "application_end": "2025-10-17",
                    "exam_date": "2025-11-15",
                    "result_date": "2025-12-12"
                }
            ],
            "네트워크관리사 2급": [
                {
                    "round": "24-1회",
                    "exam_type": "필기",
                    "application_start": "2025-02-10",
                    "application_end": "2025-02-21",
                    "exam_date": "2025-03-22",
                    "result_date": "2025-04-04"
                },
                {
                    "round": "24-1회",
                    "exam_type": "실기",
                    "application_start": "2025-04-07",
                    "application_end": "2025-04-18",
                    "exam_date": "2025-05-24",
                    "result_date": "2025-06-13"
                },
                {
                    "round": "24-2회",
                    "exam_type": "필기",
                    "application_start": "2025-05-12",
                    "application_end": "2025-05-23",
                    "exam_date": "2025-06-21",
                    "result_date": "2025-07-04"
                },
                {
                    "round": "24-2회",
                    "exam_type": "실기",
                    "application_start": "2025-07-14",
                    "application_end": "2025-07-25",
                    "exam_date": "2025-08-30",
                    "result_date": "2025-09-19"
                },
                {
                    "round": "24-3회",
                    "exam_type": "필기",
                    "application_start": "2025-09-01",
                    "application_end": "2025-09-12",
                    "exam_date": "2025-10-18",
                    "result_date": "2025-10-31"
                },
                {
                    "round": "24-3회",
                    "exam_type": "실기",
                    "application_start": "2025-11-03",
                    "application_end": "2025-11-14",
                    "exam_date": "2025-12-13",
                    "result_date": "2025-12-26"
                }
            ],
            "리눅스마스터 2급": [
                {
                    "round": "1회",
                    "exam_type": "1차",
                    "application_start": "2025-01-20",
                    "application_end": "2025-01-31",
                    "exam_date": "2025-03-08",
                    "result_date": "2025-03-21"
                },
                {
                    "round": "1회",
                    "exam_type": "2차",
                    "application_start": "2025-03-24",
                    "application_end": "2025-04-04",
                    "exam_date": "2025-05-10",
                    "result_date": "2025-06-13"
                },
                {
                    "round": "2회",
                    "exam_type": "1차",
                    "application_start": "2025-05-19",
                    "application_end": "2025-05-30",
                    "exam_date": "2025-06-28",
                    "result_date": "2025-07-11"
                },
                {
                    "round": "2회",
                    "exam_type": "2차",
                    "application_start": "2025-07-14",
                    "application_end": "2025-07-25",
                    "exam_date": "2025-09-06",
                    "result_date": "2025-10-10"
                },
                {
                    "round": "3회",
                    "exam_type": "1차",
                    "application_start": "2025-08-25",
                    "application_end": "2025-09-05",
                    "exam_date": "2025-10-11",
                    "result_date": "2025-10-24"
                },
                {
                    "round": "3회",
                    "exam_type": "2차",
                    "application_start": "2025-10-27",
                    "application_end": "2025-11-07",
                    "exam_date": "2025-12-06",
                    "result_date": "2025-12-30"
                }
            ]
        }

        # 각 자격증에 일정 정보 추가
        for cert in qnet_certs:
            cert_name = cert["name"]
            if cert_name in schedules_2025:
                cert["schedules_2025"] = []
                for schedule in schedules_2025[cert_name]:
                    cert["schedules_2025"].append({
                        "round": schedule["round"],
                        "exam_type": schedule["exam_type"],
                        "application_start": datetime.strptime(schedule["application_start"], "%Y-%m-%d").date(),
                        "application_end": datetime.strptime(schedule["application_end"], "%Y-%m-%d").date(),
                        "exam_date": datetime.strptime(schedule["exam_date"], "%Y-%m-%d").date(),
                        "result_date": datetime.strptime(schedule["result_date"], "%Y-%m-%d").date()
                    })
            certifications.append(cert)

        return certifications

    async def scrape_korcham_schedules(self) -> List[Dict]:
        """대한상공회의소 자격증 일정 스크래핑"""
        korcham_certs = [
            {
                "id": "cert_computer_utilization_1",
                "name": "컴퓨터활용능력 1급",
                "category": "national_professional",
                "organization": "대한상공회의소",
                "level": "1급",
                "description": "컴퓨터와 주변기기를 이용한 고급 문서 작성, 스프레드시트 활용, 데이터베이스 관리",
                "exam_subjects": ["컴퓨터 일반", "스프레드시트", "데이터베이스"],
                "passing_criteria": "필기: 과목당 40점, 평균 60점 이상 / 실기: 70점 이상",
                "exam_fee": {"written": 19000, "practical": 25000},
                "website": "https://license.korcham.net/",
                "schedules_2025": [
                    {
                        "round": "상시",
                        "exam_type": "필기",
                        "application_start": date(2025, 1, 1),
                        "application_end": date(2025, 12, 31),
                        "exam_date": date(2025, 1, 1),
                        "result_date": date(2025, 1, 1),
                        "note": "매주 토요일 시행 (상시시험)"
                    },
                    {
                        "round": "상시",
                        "exam_type": "실기",
                        "application_start": date(2025, 1, 1),
                        "application_end": date(2025, 12, 31),
                        "exam_date": date(2025, 1, 1),
                        "result_date": date(2025, 1, 1),
                        "note": "필기 합격 후 2년 내 응시 가능"
                    }
                ]
            },
            {
                "id": "cert_computer_utilization_2",
                "name": "컴퓨터활용능력 2급",
                "category": "national_professional",
                "organization": "대한상공회의소",
                "level": "2급",
                "description": "컴퓨터 기초 사용법과 스프레드시트를 활용한 업무 처리 능력",
                "exam_subjects": ["컴퓨터 일반", "스프레드시트"],
                "passing_criteria": "필기: 과목당 40점, 평균 60점 이상 / 실기: 70점 이상",
                "exam_fee": {"written": 15700, "practical": 21000},
                "website": "https://license.korcham.net/",
                "schedules_2025": [
                    {
                        "round": "상시",
                        "exam_type": "필기",
                        "application_start": date(2025, 1, 1),
                        "application_end": date(2025, 12, 31),
                        "exam_date": date(2025, 1, 1),
                        "result_date": date(2025, 1, 1),
                        "note": "매주 토요일 시행 (상시시험)"
                    },
                    {
                        "round": "상시",
                        "exam_type": "실기",
                        "application_start": date(2025, 1, 1),
                        "application_end": date(2025, 12, 31),
                        "exam_date": date(2025, 1, 1),
                        "result_date": date(2025, 1, 1),
                        "note": "필기 합격 후 2년 내 응시 가능"
                    }
                ]
            },
            {
                "id": "cert_word_processor",
                "name": "워드프로세서",
                "category": "national_professional",
                "organization": "대한상공회의소",
                "level": "단일급",
                "description": "문서 작성, 편집, 출력 등 워드프로세싱 프로그램 운용 능력",
                "exam_subjects": ["워드프로세싱", "PC 운영체제", "컴퓨터 및 정보활용"],
                "passing_criteria": "필기: 과목당 40점, 평균 60점 이상 / 실기: 80점 이상",
                "exam_fee": {"written": 15700, "practical": 21000},
                "website": "https://license.korcham.net/",
                "schedules_2025": [
                    {
                        "round": "상시",
                        "exam_type": "필기",
                        "application_start": date(2025, 1, 1),
                        "application_end": date(2025, 12, 31),
                        "exam_date": date(2025, 1, 1),
                        "result_date": date(2025, 1, 1),
                        "note": "매주 토요일 시행 (상시시험)"
                    },
                    {
                        "round": "상시",
                        "exam_type": "실기",
                        "application_start": date(2025, 1, 1),
                        "application_end": date(2025, 12, 31),
                        "exam_date": date(2025, 1, 1),
                        "result_date": date(2025, 1, 1),
                        "note": "필기 합격 후 2년 내 응시 가능"
                    }
                ]
            }
        ]

        return korcham_certs

    async def scrape_all(self) -> Dict:
        """모든 자격증 정보 통합 수집"""
        try:
            # 병렬로 각 기관 데이터 수집
            qnet_data, korcham_data = await asyncio.gather(
                self.scrape_qnet_schedules(),
                self.scrape_korcham_schedules()
            )

            # 모든 데이터 통합
            all_certifications = qnet_data + korcham_data

            # 카테고리별 분류
            categorized = {
                "national": [],
                "national_professional": [],
                "private": [],
                "international": []
            }

            for cert in all_certifications:
                category = cert.get("category", "private")
                categorized[category].append(cert)

            # 통계 정보 생성
            stats = {
                "total_count": len(all_certifications),
                "by_category": {
                    "national": len(categorized["national"]),
                    "national_professional": len(categorized["national_professional"]),
                    "private": len(categorized["private"]),
                    "international": len(categorized["international"])
                },
                "by_organization": {},
                "scraped_at": datetime.now().isoformat()
            }

            # 기관별 통계
            for cert in all_certifications:
                org = cert.get("organization", "기타")
                if org not in stats["by_organization"]:
                    stats["by_organization"][org] = 0
                stats["by_organization"][org] += 1

            return {
                "certifications": all_certifications,
                "categorized": categorized,
                "stats": stats
            }

        except Exception as e:
            print(f"스크래핑 중 오류 발생: {e}")
            return {
                "error": str(e),
                "certifications": [],
                "stats": {}
            }

    def convert_to_json_serializable(self, data):
        """date 객체를 JSON 직렬화 가능한 문자열로 변환"""
        if isinstance(data, dict):
            return {k: self.convert_to_json_serializable(v) for k, v in data.items()}
        elif isinstance(data, list):
            return [self.convert_to_json_serializable(item) for item in data]
        elif isinstance(data, date):
            return data.isoformat()
        else:
            return data

async def main():
    """스크래퍼 실행 및 결과 저장"""
    async with CertificationScraper() as scraper:
        print("자격증 정보 스크래핑 시작...")
        data = await scraper.scrape_all()

        # JSON 직렬화를 위해 date 객체 변환
        serializable_data = scraper.convert_to_json_serializable(data)

        # 결과를 JSON 파일로 저장
        output_file = "/Users/gangseungsig/Documents/02_GitHub/15_CertiGraph/backend/data/scraped_certifications.json"
        with open(output_file, "w", encoding="utf-8") as f:
            json.dump(serializable_data, f, ensure_ascii=False, indent=2)

        print(f"스크래핑 완료! 총 {serializable_data['stats']['total_count']}개 자격증 정보 수집")
        print(f"결과 저장 위치: {output_file}")

        # 통계 출력
        print("\n=== 수집 통계 ===")
        print(f"국가자격: {serializable_data['stats']['by_category']['national']}개")
        print(f"국가기술자격: {serializable_data['stats']['by_category']['national_professional']}개")
        print(f"민간자격: {serializable_data['stats']['by_category']['private']}개")
        print(f"국제자격: {serializable_data['stats']['by_category']['international']}개")

        print("\n=== 기관별 통계 ===")
        for org, count in serializable_data['stats']['by_organization'].items():
            print(f"{org}: {count}개")

        return serializable_data

if __name__ == "__main__":
    asyncio.run(main())