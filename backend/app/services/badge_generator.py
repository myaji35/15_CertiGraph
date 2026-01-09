"""
SVG 자격증 뱃지 생성기
GitHub Profile README에 사용할 수 있는 자격증 뱃지를 동적으로 생성
"""
from typing import Literal, Optional
from urllib.parse import quote
import xml.etree.ElementTree as ET

from app.config.badge_config import get_badge_config, BadgeConfig


BadgeStyle = Literal["flat", "flat-square", "for-the-badge", "plastic", "simple"]
BadgeTheme = Literal["default", "dark", "light"]


class BadgeGenerator:
    """자격증 뱃지 SVG 생성기"""

    # 스타일별 기본 높이
    STYLE_HEIGHTS = {
        "flat": 20,
        "flat-square": 20,
        "for-the-badge": 28,
        "plastic": 18,
        "simple": 24,
    }

    # 테마별 색상
    THEME_COLORS = {
        "default": {
            "text": "#FFFFFF",
            "year_bg": "rgba(0,0,0,0.15)",
            "shadow": "rgba(0,0,0,0.1)",
        },
        "dark": {
            "text": "#E5E7EB",
            "year_bg": "rgba(0,0,0,0.3)",
            "shadow": "rgba(0,0,0,0.3)",
        },
        "light": {
            "text": "#1F2937",
            "year_bg": "rgba(255,255,255,0.3)",
            "shadow": "rgba(0,0,0,0.05)",
        },
    }

    def __init__(self):
        """뱃지 생성기 초기화"""
        pass

    def generate_badge(
        self,
        cert_id: str,
        year: int,
        style: BadgeStyle = "flat",
        theme: BadgeTheme = "default",
        show_logo: bool = True,
        custom_label: Optional[str] = None,
    ) -> str:
        """
        자격증 뱃지 SVG 생성

        Args:
            cert_id: 자격증 ID
            year: 취득년도
            style: 뱃지 스타일
            theme: 색상 테마
            show_logo: 로고 표시 여부
            custom_label: 커스텀 라벨 (None이면 short_name 사용)

        Returns:
            SVG 문자열
        """
        # 뱃지 설정 조회
        config = get_badge_config(cert_id)
        label = custom_label or config["short_name"]

        # 스타일에 따라 다른 생성 메서드 호출
        if style == "flat":
            return self._generate_flat_badge(config, label, year, theme, show_logo)
        elif style == "flat-square":
            return self._generate_flat_square_badge(config, label, year, theme, show_logo)
        elif style == "for-the-badge":
            return self._generate_for_the_badge(config, label, year, theme, show_logo)
        elif style == "plastic":
            return self._generate_plastic_badge(config, label, year, theme, show_logo)
        elif style == "simple":
            return self._generate_simple_badge(config, label, year, theme, show_logo)
        else:
            raise ValueError(f"Unsupported badge style: {style}")

    def _generate_flat_badge(
        self,
        config: BadgeConfig,
        label: str,
        year: int,
        theme: BadgeTheme,
        show_logo: bool,
    ) -> str:
        """Flat 스타일 뱃지 생성 (기본)"""
        height = 20
        radius = 3
        icon = config["icon"] if show_logo else ""
        bg_color = config["color"]
        theme_colors = self.THEME_COLORS[theme]

        # 텍스트 길이에 따라 너비 계산
        icon_width = 25 if icon else 0
        label_width = len(label) * 7 + 10
        year_width = 45

        total_width = icon_width + label_width + year_width

        svg = f'''<svg xmlns="http://www.w3.org/2000/svg" width="{total_width}" height="{height}" role="img" aria-label="{label} {year}">
  <title>{config["display_name"]} ({year}년 취득)</title>

  <!-- 배경 -->
  <linearGradient id="grad_{cert_id}" x1="0%" y1="0%" x2="0%" y2="100%">
    <stop offset="0%" style="stop-color:{bg_color};stop-opacity:1" />
    <stop offset="100%" style="stop-color:{self._darken_color(bg_color, 0.1)};stop-opacity:1" />
  </linearGradient>

  <rect width="{total_width}" height="{height}" fill="url(#grad_{cert_id})" rx="{radius}"/>

  <!-- 아이콘 -->'''

        if icon:
            svg += f'''
  <text x="12" y="15" font-size="14" fill="none" font-family="Apple Color Emoji,Segoe UI Emoji,Segoe UI Symbol">{icon}</text>'''

        svg += f'''

  <!-- 라벨 -->
  <text x="{icon_width + 5}" y="14" fill="{theme_colors["text"]}" font-family="Verdana,sans-serif" font-size="11" font-weight="600">{label}</text>

  <!-- 연도 배경 -->
  <rect x="{total_width - year_width}" y="0" width="{year_width}" height="{height}" fill="{theme_colors["year_bg"]}" rx="{radius}"/>

  <!-- 연도 -->
  <text x="{total_width - year_width + 22}" y="14" fill="{theme_colors["text"]}" font-family="Verdana,sans-serif" font-size="10">{year}</text>
</svg>'''

        return svg

    def _generate_flat_square_badge(
        self,
        config: BadgeConfig,
        label: str,
        year: int,
        theme: BadgeTheme,
        show_logo: bool,
    ) -> str:
        """Flat-Square 스타일 뱃지 생성 (모서리 각진 버전)"""
        # Flat과 동일하지만 radius=0
        svg = self._generate_flat_badge(config, label, year, theme, show_logo)
        # rx 속성을 0으로 변경
        return svg.replace('rx="3"', 'rx="0"')

    def _generate_for_the_badge(
        self,
        config: BadgeConfig,
        label: str,
        year: int,
        theme: BadgeTheme,
        show_logo: bool,
    ) -> str:
        """For-The-Badge 스타일 (큰 사이즈, 대문자)"""
        height = 28
        radius = 4
        icon = config["icon"] if show_logo else ""
        bg_color = config["color"]
        theme_colors = self.THEME_COLORS[theme]

        # 대문자 변환
        label_upper = label.upper()

        # 텍스트 길이에 따라 너비 계산
        icon_width = 35 if icon else 0
        label_width = len(label_upper) * 10 + 15
        year_width = 60

        total_width = icon_width + label_width + year_width

        svg = f'''<svg xmlns="http://www.w3.org/2000/svg" width="{total_width}" height="{height}" role="img" aria-label="{label} {year}">
  <title>{config["display_name"]} ({year}년 취득)</title>

  <!-- 배경 -->
  <rect width="{total_width}" height="{height}" fill="{bg_color}" rx="{radius}"/>

  <!-- 아이콘 -->'''

        if icon:
            svg += f'''
  <text x="17" y="19" font-size="18" fill="none" font-family="Apple Color Emoji,Segoe UI Emoji,Segoe UI Symbol">{icon}</text>'''

        svg += f'''

  <!-- 라벨 -->
  <text x="{icon_width + 8}" y="18" fill="{theme_colors["text"]}" font-family="Verdana,sans-serif" font-size="12" font-weight="700" letter-spacing="0.5">{label_upper}</text>

  <!-- 연도 배경 -->
  <rect x="{total_width - year_width}" y="0" width="{year_width}" height="{height}" fill="{theme_colors["year_bg"]}" rx="{radius}"/>

  <!-- 연도 -->
  <text x="{total_width - year_width + 30}" y="18" fill="{theme_colors["text"]}" font-family="Verdana,sans-serif" font-size="11" font-weight="600">{year}</text>
</svg>'''

        return svg

    def _generate_plastic_badge(
        self,
        config: BadgeConfig,
        label: str,
        year: int,
        theme: BadgeTheme,
        show_logo: bool,
    ) -> str:
        """Plastic 스타일 (광택 효과)"""
        height = 18
        radius = 4
        icon = config["icon"] if show_logo else ""
        bg_color = config["color"]
        theme_colors = self.THEME_COLORS[theme]

        # 텍스트 길이에 따라 너비 계산
        icon_width = 23 if icon else 0
        label_width = len(label) * 6 + 10
        year_width = 40

        total_width = icon_width + label_width + year_width

        svg = f'''<svg xmlns="http://www.w3.org/2000/svg" width="{total_width}" height="{height}" role="img" aria-label="{label} {year}">
  <title>{config["display_name"]} ({year}년 취득)</title>

  <defs>
    <linearGradient id="shine_{cert_id}" x1="0%" y1="0%" x2="0%" y2="100%">
      <stop offset="0%" style="stop-color:white;stop-opacity:0.3" />
      <stop offset="50%" style="stop-color:white;stop-opacity:0.1" />
      <stop offset="100%" style="stop-color:black;stop-opacity:0.1" />
    </linearGradient>
  </defs>

  <!-- 배경 -->
  <rect width="{total_width}" height="{height}" fill="{bg_color}" rx="{radius}"/>

  <!-- 광택 효과 -->
  <rect width="{total_width}" height="{height}" fill="url(#shine_{cert_id})" rx="{radius}"/>

  <!-- 아이콘 -->'''

        if icon:
            svg += f'''
  <text x="11" y="13" font-size="12" fill="none" font-family="Apple Color Emoji,Segoe UI Emoji,Segoe UI Symbol">{icon}</text>'''

        svg += f'''

  <!-- 라벨 -->
  <text x="{icon_width + 5}" y="13" fill="{theme_colors["text"]}" font-family="Verdana,sans-serif" font-size="10" font-weight="600">{label}</text>

  <!-- 연도 배경 -->
  <rect x="{total_width - year_width}" y="0" width="{year_width}" height="{height}" fill="{theme_colors["year_bg"]}" rx="{radius}"/>

  <!-- 연도 -->
  <text x="{total_width - year_width + 20}" y="13" fill="{theme_colors["text"]}" font-family="Verdana,sans-serif" font-size="9">{year}</text>
</svg>'''

        return svg

    def _generate_simple_badge(
        self,
        config: BadgeConfig,
        label: str,
        year: int,
        theme: BadgeTheme,
        show_logo: bool,
    ) -> str:
        """Simple 스타일 뱃지 생성 (Icon | Certification Name | Year)"""
        height = 24
        radius = 4
        icon = config["icon"] if show_logo else ""
        bg_color = config["color"]
        theme_colors = self.THEME_COLORS[theme]

        # Use display_name instead of short_name for full certification name
        cert_name = config["display_name"]

        # Calculate widths
        icon_width = 30 if icon else 0
        # Calculate text width more accurately (Korean chars ~8px, numbers ~6px)
        name_width = len(cert_name) * 9 + 10
        year_width = 50
        divider_width = 2

        total_width = icon_width + divider_width + name_width + divider_width + year_width

        svg = f'''<svg xmlns="http://www.w3.org/2000/svg" width="{total_width}" height="{height}" role="img" aria-label="{cert_name} {year}">
  <title>{cert_name} ({year}년 취득)</title>

  <!-- Background -->
  <rect width="{total_width}" height="{height}" fill="{bg_color}" rx="{radius}"/>
'''

        if icon:
            svg += f'''
  <!-- Icon -->
  <text x="15" y="17" font-size="16" fill="none" font-family="Apple Color Emoji,Segoe UI Emoji,Segoe UI Symbol">{icon}</text>

  <!-- First Divider -->
  <rect x="{icon_width}" y="4" width="{divider_width}" height="{height - 8}" fill="rgba(255,255,255,0.3)" rx="1"/>
'''

        name_x = icon_width + divider_width + 5
        divider2_x = name_x + name_width
        year_x = divider2_x + divider_width + 25

        svg += f'''
  <!-- Certification Name -->
  <text x="{name_x}" y="16" fill="{theme_colors["text"]}" font-family="Malgun Gothic,Apple SD Gothic Neo,sans-serif" font-size="11" font-weight="600">{cert_name}</text>

  <!-- Second Divider -->
  <rect x="{divider2_x}" y="4" width="{divider_width}" height="{height - 8}" fill="rgba(255,255,255,0.3)" rx="1"/>

  <!-- Year -->
  <text x="{year_x}" y="16" fill="{theme_colors["text"]}" font-family="Verdana,sans-serif" font-size="11" font-weight="600">{year}</text>
</svg>'''

        return svg

    def _darken_color(self, hex_color: str, factor: float = 0.1) -> str:
        """
        HEX 색상을 어둡게 만듦

        Args:
            hex_color: HEX 색상 코드 (#RRGGBB)
            factor: 어둡게 할 비율 (0.0 ~ 1.0)

        Returns:
            어두워진 HEX 색상 코드
        """
        # # 제거
        hex_color = hex_color.lstrip("#")

        # RGB 값 추출
        r = int(hex_color[0:2], 16)
        g = int(hex_color[2:4], 16)
        b = int(hex_color[4:6], 16)

        # 어둡게
        r = max(0, int(r * (1 - factor)))
        g = max(0, int(g * (1 - factor)))
        b = max(0, int(b * (1 - factor)))

        # 다시 HEX로 변환
        return f"#{r:02x}{g:02x}{b:02x}"

    def generate_markdown_code(
        self,
        cert_id: str,
        year: int,
        style: BadgeStyle = "flat",
        theme: BadgeTheme = "default",
        base_url: str = "https://certigraph.com",
    ) -> str:
        """
        Markdown 임베드 코드 생성

        Args:
            cert_id: 자격증 ID
            year: 취득년도
            style: 뱃지 스타일
            theme: 테마
            base_url: API 베이스 URL

        Returns:
            Markdown 코드
        """
        badge_url = f"{base_url}/api/v1/badges/certification/{cert_id}?year={year}&style={style}&theme={theme}"
        profile_url = f"{base_url}/certifications/{cert_id}"

        return f"[![{cert_id}]({badge_url})]({profile_url})"

    def generate_html_code(
        self,
        cert_id: str,
        year: int,
        style: BadgeStyle = "flat",
        theme: BadgeTheme = "default",
        base_url: str = "https://certigraph.com",
    ) -> str:
        """
        HTML 임베드 코드 생성

        Args:
            cert_id: 자격증 ID
            year: 취득년도
            style: 뱃지 스타일
            theme: 테마
            base_url: API 베이스 URL

        Returns:
            HTML 코드
        """
        badge_url = f"{base_url}/api/v1/badges/certification/{cert_id}?year={year}&style={style}&theme={theme}"
        profile_url = f"{base_url}/certifications/{cert_id}"
        config = get_badge_config(cert_id)
        alt_text = f"{config['display_name']} ({year})"

        return f'<a href="{profile_url}"><img src="{badge_url}" alt="{alt_text}" /></a>'


# 전역 인스턴스
badge_generator = BadgeGenerator()
