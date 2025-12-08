"""
한국산업인력공단 Open API 연동
국가기술자격 시험 일정 정보 조회
"""

import httpx
from typing import List, Dict, Optional
from datetime import datetime
import xml.etree.ElementTree as ET
from pydantic import BaseModel

class ExamSchedule(BaseModel):
    """시험 일정 정보"""
    exam_name: str  # 자격증명
    exam_type: str  # 시험 구분 (필기/실기)
    receipt_start: str  # 접수 시작일
    receipt_end: str  # 접수 마감일
    exam_date: str  # 시험일
    result_date: str  # 합격자 발표일

class HRDKoreaAPI:
    """한국산업인력공단 API 클라이언트"""

    BASE_URL = "https://openapi.q-net.or.kr/api/service/rest"

    def __init__(self, service_key: str):
        """
        Args:
            service_key: 공공데이터포털에서 발급받은 API 키
        """
        self.service_key = service_key
        self.client = httpx.AsyncClient(timeout=30.0)

    async def get_exam_schedules(self, year: int) -> List[ExamSchedule]:
        """
        연도별 국가기술자격 시험 일정 조회

        Args:
            year: 조회할 연도

        Returns:
            시험 일정 목록
        """
        endpoint = f"{self.BASE_URL}/InquiryTestDatesInfo/getTestDates"

        params = {
            "serviceKey": self.service_key,
            "baseYY": str(year),
            "numOfRows": "1000",
            "pageNo": "1"
        }

        try:
            response = await self.client.get(endpoint, params=params)
            response.raise_for_status()

            # XML 파싱
            root = ET.fromstring(response.text)
            items = root.findall(".//item")

            schedules = []
            for item in items:
                schedule = ExamSchedule(
                    exam_name=self._get_text(item, "jmfldnm"),
                    exam_type=self._get_text(item, "implplannm"),
                    receipt_start=self._get_text(item, "docregstartdt"),
                    receipt_end=self._get_text(item, "docregenddt"),
                    exam_date=self._get_text(item, "docexamdt"),
                    result_date=self._get_text(item, "docpassdt")
                )
                schedules.append(schedule)

            return schedules

        except Exception as e:
            print(f"API 호출 실패: {e}")
            return []

    async def get_qualification_list(self) -> List[Dict]:
        """
        국가기술자격 종목 목록 조회

        Returns:
            자격증 종목 목록
        """
        endpoint = f"{self.BASE_URL}/InquiryQualInfo/getList"

        params = {
            "serviceKey": self.service_key,
            "numOfRows": "1000",
            "pageNo": "1"
        }

        try:
            response = await self.client.get(endpoint, params=params)
            response.raise_for_status()

            # XML 파싱
            root = ET.fromstring(response.text)
            items = root.findall(".//item")

            qualifications = []
            for item in items:
                qual = {
                    "name": self._get_text(item, "jmfldnm"),
                    "series": self._get_text(item, "seriesnm"),
                    "category": self._get_text(item, "obligfldnm"),
                    "institution": self._get_text(item, "mdobligfldnm")
                }
                qualifications.append(qual)

            return qualifications

        except Exception as e:
            print(f"API 호출 실패: {e}")
            return []

    def _get_text(self, element, tag: str) -> str:
        """XML 요소에서 텍스트 추출"""
        node = element.find(tag)
        return node.text if node is not None and node.text else ""

    async def close(self):
        """클라이언트 종료"""
        await self.client.aclose()


# 사용 예시
async def fetch_realtime_certifications():
    """실시간 자격증 데이터 가져오기"""

    # API 키는 환경 변수로 관리
    import os
    api_key = os.getenv("HRDKOREA_API_KEY")

    if not api_key:
        print("API 키를 설정해주세요: export HRDKOREA_API_KEY='your-key'")
        return

    api = HRDKoreaAPI(api_key)

    # 2025년 시험 일정 조회
    schedules = await api.get_exam_schedules(2025)

    # 자격증 종목 목록 조회
    qualifications = await api.get_qualification_list()

    await api.close()

    return {
        "schedules": schedules,
        "qualifications": qualifications
    }