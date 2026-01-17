"""
전체 국가기술자격 시험일정 데이터 수집 스크립트

HRD Korea API를 통해 전체 자격증 목록과 시험일정을 가져와서 DB에 저장합니다.
"""

import asyncio
import os
import httpx
import xml.etree.ElementTree as ET
from datetime import datetime
from dotenv import load_dotenv

# 환경변수 로드
load_dotenv()


class SimpleHRDKoreaAPI:
    """간소화된 HRD Korea API 클라이언트"""

    BASE_URL = "https://openapi.q-net.or.kr/api/service/rest"

    def __init__(self, service_key: str):
        self.service_key = service_key
        self.client = httpx.AsyncClient(timeout=60.0)

    async def get_qualification_list(self):
        """자격증 종목 목록 조회"""
        endpoint = f"{self.BASE_URL}/InquiryQualInfo/getList"

        params = {
            "serviceKey": self.service_key,
            "numOfRows": "1000",
            "pageNo": "1"
        }

        try:
            response = await self.client.get(endpoint, params=params)
            response.raise_for_status()

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
            print(f"자격증 목록 API 호출 실패: {e}")
            import traceback
            traceback.print_exc()
            return []

    async def get_exam_schedules(self, year: int):
        """시험 일정 조회"""
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

            root = ET.fromstring(response.text)
            items = root.findall(".//item")

            schedules = []
            for item in items:
                schedule = {
                    "exam_name": self._get_text(item, "jmfldnm"),
                    "exam_type": self._get_text(item, "implplannm"),
                    "receipt_start": self._get_text(item, "docregstartdt"),
                    "receipt_end": self._get_text(item, "docregenddt"),
                    "exam_date": self._get_text(item, "docexamdt"),
                    "result_date": self._get_text(item, "docpassdt"),
                    "year": year
                }
                schedules.append(schedule)

            return schedules

        except Exception as e:
            print(f"{year}년 시험일정 API 호출 실패: {e}")
            return []

    def _get_text(self, element, tag: str) -> str:
        """XML 요소에서 텍스트 추출"""
        node = element.find(tag)
        return node.text if node is not None and node.text else ""

    async def close(self):
        """클라이언트 종료"""
        await self.client.aclose()


async def fetch_and_store_all_certifications():
    """전체 자격증 데이터 수집"""

    # 1. API 키 확인
    api_key = os.getenv("DATA_GOV_API_KEY") or os.getenv("HRDKOREA_API_KEY")
    if not api_key or api_key == "your_hrdkorea_key_here":
        print("❌ HRD Korea API 키가 설정되지 않았습니다.")
        print(".env 파일의 DATA_GOV_API_KEY 또는 HRDKOREA_API_KEY를 확인해주세요.")
        return

    print("=" * 80)
    print("국가기술자격 전체 데이터 수집 시작")
    print("=" * 80)

    api = SimpleHRDKoreaAPI(api_key)

    try:
        # 2. 전체 자격증 목록 조회
        print("\n[1/3] 전체 자격증 종목 목록 조회 중...")
        qualifications = await api.get_qualification_list()

        if not qualifications:
            print("❌ 자격증 목록을 가져오지 못했습니다.")
            print("   - API 키가 올바른지 확인")
            print("   - 공공데이터포털에서 API 승인 상태 확인")
            print("   - 네트워크 연결 확인")
            return

        print(f"✅ 총 {len(qualifications)}개 자격증 종목 발견")

        # 분류별 통계
        categories = {}
        for qual in qualifications:
            cat = qual.get("category", "기타")
            categories[cat] = categories.get(cat, 0) + 1

        print("\n📊 분류별 자격증 수:")
        for cat, count in sorted(categories.items(), key=lambda x: x[1], reverse=True)[:10]:
            print(f"  • {cat}: {count}개")

        # 3. 시험일정 조회
        print("\n[2/3] 시험일정 데이터 수집 중...")

        all_schedules = []
        for year in [2025, 2026]:
            print(f"\n  📅 {year}년 시험일정 조회 중...")
            schedules = await api.get_exam_schedules(year)

            if schedules:
                print(f"  ✅ {year}년: {len(schedules)}건의 시험일정 발견")
                all_schedules.extend(schedules)
            else:
                print(f"  ⚠️  {year}년: 시험일정 데이터 없음")

        # 4. 결과 저장 (JSON)
        print("\n[3/3] 결과를 JSON 파일로 저장 중...")

        import json

        output_data = {
            "collection_time": datetime.now().isoformat(),
            "total_certifications": len(qualifications),
            "total_schedules": len(all_schedules),
            "categories": categories,
            "certifications": qualifications,
            "schedules": all_schedules
        }

        output_file = "certification_data.json"
        with open(output_file, "w", encoding="utf-8") as f:
            json.dump(output_data, f, ensure_ascii=False, indent=2)

        print(f"✅ 데이터가 {output_file}에 저장되었습니다.")

        # 5. 최종 요약
        print("\n" + "=" * 80)
        print("📊 데이터 수집 완료 요약")
        print("=" * 80)
        print(f"✅ 자격증 종목: {len(qualifications)}개")
        print(f"✅ 시험일정: {len(all_schedules)}건")
        print(f"✅ 저장 파일: {output_file}")
        print(f"✅ 수집 시간: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        print("\n🎉 모든 데이터 수집이 완료되었습니다!")

        # 6. 시험일정 샘플 출력
        if all_schedules:
            print("\n📅 시험일정 샘플 (최근 10건):")
            for sched in all_schedules[:10]:
                print(f"  • {sched['exam_name']} ({sched['exam_type']}) - {sched['exam_date']}")

    except Exception as e:
        print(f"\n❌ 오류 발생: {e}")
        import traceback
        traceback.print_exc()

    finally:
        await api.close()


if __name__ == "__main__":
    print("""
    ╔══════════════════════════════════════════════════════════════════════╗
    ║                                                                      ║
    ║     국가기술자격 전체 데이터 수집 스크립트                          ║
    ║                                                                      ║
    ║  이 스크립트는 HRD Korea API를 통해 전체 자격증 목록과              ║
    ║  시험일정 데이터를 가져와서 JSON 파일로 저장합니다.                ║
    ║                                                                      ║
    ╚══════════════════════════════════════════════════════════════════════╝
    """)

    asyncio.run(fetch_and_store_all_certifications())
