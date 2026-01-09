"""
자격증 뱃지 설정
각 자격증별 아이콘, 색상, 표시명 등을 정의
"""
from typing import Dict, TypedDict


class BadgeConfig(TypedDict):
    """뱃지 설정 타입"""
    icon: str  # 이모지
    short_name: str  # 약칭
    display_name: str  # 전체 표시명
    category: str  # 카테고리
    color: str  # 배경색 (HEX)


# 카테고리별 색상 매핑
CATEGORY_COLORS = {
    "national": "#1E40AF",  # Blue-800 (국가자격)
    "national_professional": "#2563EB",  # Blue-600 (국가기술자격)
    "private": "#9333EA",  # Purple-600 (민간자격)
    "international": "#EA580C",  # Orange-600 (국제자격)
}

# 자격증별 뱃지 설정
CERTIFICATION_BADGES: Dict[str, BadgeConfig] = {
    "cert_pe_info": {
        "icon": "💻",
        "short_name": "정처기",
        "display_name": "정보처리기사",
        "category": "national_professional",
        "color": CATEGORY_COLORS["national_professional"],
    },
    "cert_pe_info_industry": {
        "icon": "🖥️",
        "short_name": "정처산기",
        "display_name": "정보처리산업기사",
        "category": "national_professional",
        "color": CATEGORY_COLORS["national_professional"],
    },
    "cert_bigdata": {
        "icon": "📊",
        "short_name": "빅분기",
        "display_name": "빅데이터분석기사",
        "category": "national_professional",
        "color": CATEGORY_COLORS["national_professional"],
    },
    "cert_sqld": {
        "icon": "🗄️",
        "short_name": "SQLD",
        "display_name": "SQL개발자",
        "category": "private",
        "color": CATEGORY_COLORS["private"],
    },
    "cert_sqlp": {
        "icon": "💾",
        "short_name": "SQLP",
        "display_name": "SQL전문가",
        "category": "private",
        "color": CATEGORY_COLORS["private"],
    },
    "cert_adsp": {
        "icon": "📈",
        "short_name": "ADsP",
        "display_name": "데이터분석준전문가",
        "category": "private",
        "color": CATEGORY_COLORS["private"],
    },
    "cert_adp": {
        "icon": "📉",
        "short_name": "ADP",
        "display_name": "데이터분석전문가",
        "category": "private",
        "color": CATEGORY_COLORS["private"],
    },
    "cert_network_admin": {
        "icon": "🌐",
        "short_name": "네관사2급",
        "display_name": "네트워크관리사2급",
        "category": "private",
        "color": CATEGORY_COLORS["private"],
    },
    "cert_linux_master": {
        "icon": "🐧",
        "short_name": "리마2급",
        "display_name": "리눅스마스터2급",
        "category": "private",
        "color": CATEGORY_COLORS["private"],
    },
    "cert_computer_utilization_1": {
        "icon": "📄",
        "short_name": "컴활1급",
        "display_name": "컴퓨터활용능력1급",
        "category": "national_professional",
        "color": CATEGORY_COLORS["national_professional"],
    },
    "cert_computer_utilization_2": {
        "icon": "📋",
        "short_name": "컴활2급",
        "display_name": "컴퓨터활용능력2급",
        "category": "national_professional",
        "color": CATEGORY_COLORS["national_professional"],
    },
    "cert_word_processor": {
        "icon": "📝",
        "short_name": "워드",
        "display_name": "워드프로세서",
        "category": "national_professional",
        "color": CATEGORY_COLORS["national_professional"],
    },
    "cert_aws_saa": {
        "icon": "☁️",
        "short_name": "AWS SAA",
        "display_name": "AWS Solutions Architect Associate",
        "category": "international",
        "color": CATEGORY_COLORS["international"],
    },
    "cert_aws_dev": {
        "icon": "⚙️",
        "short_name": "AWS DEV",
        "display_name": "AWS Developer Associate",
        "category": "international",
        "color": CATEGORY_COLORS["international"],
    },
    "cert_pmp": {
        "icon": "📊",
        "short_name": "PMP",
        "display_name": "Project Management Professional",
        "category": "international",
        "color": CATEGORY_COLORS["international"],
    },
    "cert_social_worker_1": {
        "icon": "🤝",
        "short_name": "사복1급",
        "display_name": "사회복지사1급",
        "category": "national",
        "color": CATEGORY_COLORS["national"],
    },
}


def get_badge_config(cert_id: str) -> BadgeConfig:
    """
    자격증 ID로 뱃지 설정 조회

    Args:
        cert_id: 자격증 ID

    Returns:
        BadgeConfig 객체

    Raises:
        KeyError: 존재하지 않는 자격증 ID
    """
    if cert_id not in CERTIFICATION_BADGES:
        raise KeyError(f"Badge configuration not found for certification: {cert_id}")

    return CERTIFICATION_BADGES[cert_id]


def get_all_badge_configs() -> Dict[str, BadgeConfig]:
    """모든 뱃지 설정 반환"""
    return CERTIFICATION_BADGES.copy()


def get_category_color(category: str) -> str:
    """
    카테고리별 색상 조회

    Args:
        category: 자격증 카테고리

    Returns:
        HEX 색상 코드

    Raises:
        KeyError: 존재하지 않는 카테고리
    """
    if category not in CATEGORY_COLORS:
        raise KeyError(f"Color not found for category: {category}")

    return CATEGORY_COLORS[category]
