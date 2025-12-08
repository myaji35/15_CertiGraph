"""
한국산업인력공단(큐넷) Open API 연동 서비스
data.go.kr의 공공 API를 통해 자격증 시험 일정을 가져옵니다.
"""
import httpx
import json
from datetime import datetime
from typing import List, Dict, Optional
import xml.etree.ElementTree as ET
from urllib.parse import urlencode, unquote

class DataGovAPIService:
    """한국산업인력공단 Open API 서비스"""

    def __init__(self):
        # API 키는 환경변수에서 가져오거나, 직접 설정
        # 실제 사용시에는 data.go.kr에서 발급받은 API 키를 사용해야 합니다
        # URL-encoded key needs to be decoded
        self.api_key = unquote("Fp%2F4WVioB7bIOpSNIyVppjLfZCOlNtFTrFzVOm138SVfBs7tf9l3DXabIror0XfhXvTUWKcXPc59xKmtxiuq1Q%3D%3D")

        # API 엔드포인트
        self.exam_schedule_url = "http://apis.data.go.kr/B490007/qualExamSchd/getQualExamSchdList"
        self.cert_info_url = "http://apis.data.go.kr/B490007/qualPassrate/getQualPassrateList"

    async def get_exam_schedules(self, year: str = "2025") -> List[Dict]:
        """
        자격증 시험 일정 조회

        Args:
            year: 조회년도

        Returns:
            시험 일정 리스트
        """
        schedules = []

        # 자격구분 코드 (qualgbCd)
        # T: 국가기술자격, S: 국가전문자격
        qual_types = ["T", "S"]

        async with httpx.AsyncClient() as client:
            for qual_type in qual_types:
                try:
                    # 먼저 전체 데이터를 가져와서 총 개수 확인
                    params = {
                        "serviceKey": self.api_key,
                        "numOfRows": "50",  # Maximum allowed by API
                        "pageNo": "1",
                        "dataFormat": "json",
                        "implYy": year,
                        "qualgbCd": qual_type
                    }

                    response = await client.get(
                        self.exam_schedule_url,
                        params=params,
                        timeout=10.0
                    )

                    print(f"API Response for {qual_type}: Status={response.status_code}")

                    if response.status_code == 200:
                        try:
                            data = response.json()
                            print(f"Response data keys: {data.keys() if isinstance(data, dict) else 'Not a dict'}")

                            # Check if there's an error in the header
                            if "header" in data:
                                header = data["header"]
                                if header.get("resultCode") != "00":
                                    print(f"API Error: {header.get('resultMsg', 'Unknown error')}")
                                    continue
                        except:
                            # Try parsing as XML if JSON fails
                            print(f"Failed to parse as JSON, response text: {response.text[:500]}")
                            continue

                        # Parse the response body directly
                        if "body" in data:
                            body = data["body"]
                            items = body.get("items", [])
                            total_count = body.get("totalCount", 0)

                            print(f"Found {len(items)} items for qualification type {qual_type}, total: {total_count}")

                            # Process first page
                            for item in items:
                                schedule = self._parse_schedule_item(item)
                                if schedule:
                                    schedules.append(schedule)

                            # Fetch additional pages if needed
                            if total_count > 50:
                                num_pages = (total_count + 49) // 50  # Round up
                                for page in range(2, min(num_pages + 1, 5)):  # Limit to 4 more pages
                                    params["pageNo"] = str(page)
                                    response = await client.get(
                                        self.exam_schedule_url,
                                        params=params,
                                        timeout=10.0
                                    )
                                    if response.status_code == 200:
                                        page_data = response.json()
                                        if "body" in page_data:
                                            page_items = page_data["body"].get("items", [])
                                            for item in page_items:
                                                schedule = self._parse_schedule_item(item)
                                                if schedule:
                                                    schedules.append(schedule)

                except Exception as e:
                    print(f"Error fetching schedule for qualification type {qual_type}: {e}")
                    continue

        return schedules

    def _parse_schedule_item(self, item: Dict) -> Optional[Dict]:
        """
        API 응답 항목을 파싱하여 일정 정보 추출

        Args:
            item: API 응답 항목

        Returns:
            파싱된 일정 정보
        """
        try:
            # Parse description to extract certification name
            description = item.get("description", "")
            cert_name = ""
            if description:
                # Extract certification name from description
                # Format: "국가기술자격 기능사 (2025년도 제107회)" -> "기능사"
                parts = description.split("(")[0].strip().split()
                if len(parts) >= 2:
                    cert_name = " ".join(parts[1:])

            return {
                "cert_name": cert_name or item.get("qualgbNm", ""),  # 자격증명
                "cert_code": f"{item.get('qualgbCd', '')}-{item.get('implSeq', '')}",  # 자격구분-회차
                "exam_type": item.get("qualgbNm", ""),  # 자격구분
                "round": item.get("implSeq", ""),  # 회차
                "year": item.get("implYy", ""),  # 연도
                "description": item.get("description", ""),  # 전체 설명
                "doc_reg_start": self._parse_date(item.get("docRegStartDt")),  # 필기접수시작
                "doc_reg_end": self._parse_date(item.get("docRegEndDt")),  # 필기접수종료
                "doc_exam_start": self._parse_date(item.get("docExamStartDt")),  # 필기시험시작
                "doc_exam_end": self._parse_date(item.get("docExamEndDt")),  # 필기시험종료
                "doc_pass_date": self._parse_date(item.get("docPassDt")),  # 필기합격발표
                "prac_reg_start": self._parse_date(item.get("pracRegStartDt")),  # 실기접수시작
                "prac_reg_end": self._parse_date(item.get("pracRegEndDt")),  # 실기접수종료
                "prac_exam_start": self._parse_date(item.get("pracExamStartDt")),  # 실기시험시작
                "prac_exam_end": self._parse_date(item.get("pracExamEndDt")),  # 실기시험종료
                "prac_pass_date": self._parse_date(item.get("pracPassDt")),  # 실기합격발표
            }
        except Exception as e:
            print(f"Error parsing schedule item: {e}")
            return None

    def _parse_date(self, date_str: Optional[str]) -> Optional[str]:
        """날짜 문자열 파싱"""
        if not date_str or date_str == "-":
            return None

        try:
            # yyyyMMdd 형식을 yyyy-MM-dd로 변환
            if len(date_str) == 8 and date_str.isdigit():
                return f"{date_str[:4]}-{date_str[4:6]}-{date_str[6:8]}"
            return date_str
        except:
            return None

    async def get_certification_info(self, cert_code: str) -> Optional[Dict]:
        """
        자격증 상세 정보 조회

        Args:
            cert_code: 자격증 코드

        Returns:
            자격증 상세 정보
        """
        async with httpx.AsyncClient() as client:
            try:
                params = {
                    "serviceKey": self.api_key,
                    "numOfRows": "1",
                    "pageNo": "1",
                    "dataFormat": "json",
                    "jmcd": cert_code
                }

                response = await client.get(
                    self.cert_info_url,
                    params=params,
                    timeout=10.0
                )

                if response.status_code == 200:
                    data = response.json()

                    if "response" in data and "body" in data["response"]:
                        items = data["response"]["body"].get("items", [])
                        if items and len(items) > 0:
                            return self._parse_cert_info(items[0])

            except Exception as e:
                print(f"Error fetching cert info for {cert_code}: {e}")

        return None

    def _parse_cert_info(self, item: Dict) -> Dict:
        """
        자격증 정보 파싱

        Args:
            item: API 응답 항목

        Returns:
            파싱된 자격증 정보
        """
        return {
            "cert_name": item.get("jmfldnm", ""),
            "cert_code": item.get("jmcd", ""),
            "series_name": item.get("seriesnm", ""),  # 계열명
            "pass_rate": item.get("passrate", ""),  # 합격률
            "trend": item.get("trend", ""),  # 동향
            "career": item.get("career", ""),  # 진로 및 전망
            "job_info": item.get("jobinfo", ""),  # 직무내용
        }