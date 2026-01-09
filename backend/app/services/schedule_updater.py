"""
자격증 시험 일정 자동 업데이트 서비스
매월 공공 API를 통해 최신 시험일정을 조회하고 DB에 업데이트
"""
import asyncio
from datetime import datetime, timedelta
from typing import List, Dict, Optional
import logging
from apscheduler.schedulers.asyncio import AsyncIOScheduler
from apscheduler.triggers.cron import CronTrigger

from app.services.data_gov_api import DataGovAPIService
from app.services.external_api.hrdkorea import HRDKoreaAPI
from app.services.scraper.certification_scraper import CertificationScraper

logger = logging.getLogger(__name__)


class CertificationScheduleUpdater:
    """자격증 시험일정 자동 업데이트 클래스"""

    def __init__(self):
        self.scheduler = AsyncIOScheduler()
        self.data_gov_api = DataGovAPIService()
        self.hrd_korea_api = HRDKoreaAPI()

        # 업데이트 대상 자격증 코드 매핑
        self.cert_mapping = {
            # Q-net 자격증
            "1320": "정보처리기사",
            "2290": "정보처리산업기사",
            "3060": "빅데이터분석기사",
            # 데이터 자격증
            "sqld": "SQL개발자(SQLD)",
            "adsp": "데이터분석준전문가",
            "adp": "데이터분석전문가",
            # 기타 자격증
            "linux2": "리눅스마스터 2급",
            "network2": "네트워크관리사 2급"
        }

    async def fetch_qnet_schedules(self, year: int, month: int) -> List[Dict]:
        """Q-net (공공데이터포털) API로 국가기술자격 일정 조회"""
        try:
            # 해당 월의 시작일과 종료일 계산
            start_date = f"{year}{month:02d}01"

            # 다음 달 첫날 - 1일 = 해당 월 마지막 날
            if month == 12:
                end_date = f"{year}1231"
            else:
                next_month = datetime(year, month + 1, 1)
                last_day = next_month - timedelta(days=1)
                end_date = last_day.strftime("%Y%m%d")

            schedules = []

            # 국가기술자격 (T 타입) 조회
            result = await self.data_gov_api.get_exam_schedule(
                impl_year=str(year),
                impl_seq="1",  # 회차는 1,2,3으로 순회 필요
                qual_type="T"
            )

            if result and "body" in result and "items" in result["body"]:
                items = result["body"]["items"]
                if isinstance(items, dict):
                    items = [items]  # 단일 항목을 리스트로 변환

                for item in items:
                    schedules.append({
                        "cert_code": item.get("jmCd"),
                        "cert_name": item.get("jmNm"),
                        "round": f"{item.get('implSeq')}회",
                        "exam_type": "필기" if item.get("examSeNm") == "필기" else "실기",
                        "application_start": self._parse_date(item.get("docRegStartDt")),
                        "application_end": self._parse_date(item.get("docRegEndDt")),
                        "exam_date": self._parse_date(item.get("docExamStartDt")),
                        "result_date": self._parse_date(item.get("docPassDt")),
                        "source": "data.go.kr",
                        "updated_at": datetime.now()
                    })

            logger.info(f"Q-net API: {len(schedules)}개 일정 조회 완료 ({year}-{month:02d})")
            return schedules

        except Exception as e:
            logger.error(f"Q-net API 조회 실패: {e}")
            return []

    async def fetch_dataq_schedules(self, year: int, month: int) -> List[Dict]:
        """데이터자격검정(SQLD, ADP 등) 일정 조회"""
        try:
            # 데이터자격검정은 별도 API가 없으므로 하드코딩된 일정 사용
            # 실제로는 웹 스크래핑 또는 별도 API 구현 필요
            schedules = []

            # SQLD는 보통 2, 5, 8, 11월에 시행
            sqld_months = [2, 5, 8, 11]
            if month in sqld_months:
                quarter = sqld_months.index(month) + 1
                round_num = 53 + (year - 2025) * 4 + quarter  # 2025년 53회부터 시작

                schedules.append({
                    "cert_code": "sqld",
                    "cert_name": "SQL개발자(SQLD)",
                    "round": f"{round_num}회",
                    "exam_type": "필기",
                    "application_start": datetime(year, month, 1),
                    "application_end": datetime(year, month, 12),
                    "exam_date": datetime(year, month, 20),
                    "result_date": datetime(year, month + 1, 15) if month < 12 else datetime(year + 1, 1, 15),
                    "source": "dataq.or.kr",
                    "updated_at": datetime.now()
                })

            logger.info(f"DataQ: {len(schedules)}개 일정 조회 완료 ({year}-{month:02d})")
            return schedules

        except Exception as e:
            logger.error(f"DataQ 일정 조회 실패: {e}")
            return []

    async def fetch_hrdkorea_schedules(self, year: int, month: int) -> List[Dict]:
        """HRD Korea API로 자격증 일정 조회"""
        try:
            schedules = []

            # 주요 자격증 코드로 순회 조회
            for cert_code in ["1320", "2290", "3060"]:  # 정보처리기사, 산업기사, 빅데이터
                result = await self.hrd_korea_api.get_exam_schedule(
                    jm_cd=cert_code,
                    impl_yy=str(year)
                )

                if result:
                    # XML 파싱하여 schedules에 추가
                    # 실제 구현 필요
                    pass

            logger.info(f"HRD Korea API: {len(schedules)}개 일정 조회 완료 ({year}-{month:02d})")
            return schedules

        except Exception as e:
            logger.error(f"HRD Korea API 조회 실패: {e}")
            return []

    async def update_schedules(self, year: int = None, month: int = None):
        """
        모든 소스에서 시험일정을 조회하여 업데이트

        Args:
            year: 조회할 연도 (기본값: 현재 연도)
            month: 조회할 월 (기본값: 현재 월)
        """
        if year is None:
            year = datetime.now().year
        if month is None:
            month = datetime.now().month

        logger.info(f"시험일정 업데이트 시작: {year}년 {month}월")

        try:
            # 병렬로 모든 소스 조회
            qnet_schedules, dataq_schedules, hrd_schedules = await asyncio.gather(
                self.fetch_qnet_schedules(year, month),
                self.fetch_dataq_schedules(year, month),
                self.fetch_hrdkorea_schedules(year, month),
                return_exceptions=True
            )

            # 예외 처리
            all_schedules = []
            for schedules in [qnet_schedules, dataq_schedules, hrd_schedules]:
                if isinstance(schedules, Exception):
                    logger.error(f"일정 조회 중 오류: {schedules}")
                else:
                    all_schedules.extend(schedules)

            # 중복 제거 (cert_code + round + exam_type 조합으로)
            unique_schedules = {}
            for schedule in all_schedules:
                key = f"{schedule['cert_code']}_{schedule['round']}_{schedule['exam_type']}"
                if key not in unique_schedules:
                    unique_schedules[key] = schedule

            final_schedules = list(unique_schedules.values())

            # DB에 저장 (실제 DB 구현 필요)
            await self._save_to_database(final_schedules)

            logger.info(f"시험일정 업데이트 완료: 총 {len(final_schedules)}개 일정")
            return final_schedules

        except Exception as e:
            logger.error(f"시험일정 업데이트 실패: {e}")
            raise

    async def _save_to_database(self, schedules: List[Dict]):
        """DB에 일정 저장 (Placeholder)"""
        # TODO: Supabase 또는 PostgreSQL에 저장하는 로직 구현
        # 1. 기존 일정 조회
        # 2. 변경사항 감지 (날짜 변경, 신규 추가 등)
        # 3. UPSERT 수행
        logger.info(f"DB 저장: {len(schedules)}개 일정 (구현 예정)")
        pass

    def _parse_date(self, date_str: Optional[str]) -> Optional[datetime]:
        """날짜 문자열을 datetime 객체로 변환"""
        if not date_str:
            return None
        try:
            # YYYYMMDD 형식
            if len(date_str) == 8:
                return datetime.strptime(date_str, "%Y%m%d")
            # YYYY-MM-DD 형식
            elif len(date_str) == 10:
                return datetime.strptime(date_str, "%Y-%m-%d")
            else:
                return None
        except Exception as e:
            logger.warning(f"날짜 파싱 실패: {date_str}, 오류: {e}")
            return None

    def start_scheduler(self):
        """
        스케줄러 시작
        매월 1일 오전 2시에 다음 달 일정 업데이트
        """
        # 매월 1일 오전 2시 실행
        self.scheduler.add_job(
            self._monthly_update_job,
            trigger=CronTrigger(day=1, hour=2, minute=0),
            id="monthly_schedule_update",
            name="월간 시험일정 업데이트",
            replace_existing=True
        )

        # 매주 일요일 오전 3시 - 현재 월 일정 재확인
        self.scheduler.add_job(
            self._weekly_update_job,
            trigger=CronTrigger(day_of_week="sun", hour=3, minute=0),
            id="weekly_schedule_check",
            name="주간 시험일정 확인",
            replace_existing=True
        )

        self.scheduler.start()
        logger.info("시험일정 자동 업데이트 스케줄러 시작")

    async def _monthly_update_job(self):
        """매월 실행되는 업데이트 작업"""
        now = datetime.now()
        # 다음 달 일정 조회
        next_month = now.month + 1 if now.month < 12 else 1
        next_year = now.year if now.month < 12 else now.year + 1

        logger.info(f"월간 업데이트 작업 시작: {next_year}년 {next_month}월")
        await self.update_schedules(year=next_year, month=next_month)

    async def _weekly_update_job(self):
        """매주 실행되는 확인 작업"""
        now = datetime.now()
        logger.info(f"주간 확인 작업 시작: {now.year}년 {now.month}월")
        await self.update_schedules(year=now.year, month=now.month)

    def stop_scheduler(self):
        """스케줄러 중지"""
        self.scheduler.shutdown()
        logger.info("시험일정 자동 업데이트 스케줄러 중지")


# 전역 인스턴스
schedule_updater = CertificationScheduleUpdater()


async def init_schedule_updater():
    """앱 시작 시 스케줄러 초기화"""
    schedule_updater.start_scheduler()
    logger.info("시험일정 업데이트 서비스 초기화 완료")


async def shutdown_schedule_updater():
    """앱 종료 시 스케줄러 정리"""
    schedule_updater.stop_scheduler()
    logger.info("시험일정 업데이트 서비스 종료")
