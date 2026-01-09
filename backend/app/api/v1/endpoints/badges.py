"""Badge generation API endpoints."""

from fastapi import APIRouter, Query, HTTPException, Path
from fastapi.responses import Response
from typing import Literal

from app.services.badge_generator import badge_generator, BadgeStyle, BadgeTheme
from app.config.badge_config import get_badge_config

router = APIRouter(prefix="/badges", tags=["badges"])


@router.get("/certification/{cert_id}")
async def generate_certification_badge(
    cert_id: str = Path(..., description="자격증 ID"),
    year: int = Query(..., ge=1900, le=2100, description="취득년도"),
    style: BadgeStyle = Query("flat", description="뱃지 스타일 (flat, flat-square, for-the-badge, plastic)"),
    theme: BadgeTheme = Query("default", description="테마 (default, dark, light)"),
    logo: bool = Query(True, description="아이콘 표시 여부"),
    label: str = Query(None, description="커스텀 라벨 (없으면 기본 약칭 사용)"),
):
    """
    자격증 뱃지 SVG 생성 API

    GitHub README, 블로그 등에 임베드할 수 있는 자격증 뱃지를 동적으로 생성합니다.

    ## 사용 예시

    **Markdown:**
    ```markdown
    ![정보처리기사](https://certigraph.com/api/v1/badges/certification/cert_pe_info?year=2024&style=flat)
    ```

    **HTML:**
    ```html
    <img src="https://certigraph.com/api/v1/badges/certification/cert_pe_info?year=2024&style=for-the-badge" alt="정보처리기사" />
    ```

    ## 파라미터 설명

    - **style**: 뱃지 디자인 스타일
      - `flat`: 기본 플랫 디자인 (Shields.io 스타일)
      - `flat-square`: 각진 플랫 디자인
      - `for-the-badge`: 큰 사이즈, 대문자 스타일
      - `plastic`: 광택 효과가 있는 플라스틱 스타일

    - **theme**: 색상 테마
      - `default`: 기본 테마 (흰색 텍스트)
      - `dark`: 다크 모드 (회색 텍스트)
      - `light`: 라이트 모드 (어두운 텍스트)

    - **logo**: 자격증 아이콘(이모지) 표시 여부

    - **label**: 커스텀 라벨 지정 (기본값은 자격증 약칭)
    """
    try:
        # 뱃지 설정 확인 (존재하지 않는 자격증 ID면 KeyError 발생)
        config = get_badge_config(cert_id)

        # SVG 뱃지 생성
        svg_content = badge_generator.generate_badge(
            cert_id=cert_id,
            year=year,
            style=style,
            theme=theme,
            show_logo=logo,
            custom_label=label,
        )

        # SVG 응답 반환 (캐싱 헤더 포함)
        return Response(
            content=svg_content,
            media_type="image/svg+xml",
            headers={
                "Cache-Control": "public, max-age=86400",  # 1일 캐싱
                "Content-Type": "image/svg+xml; charset=utf-8",
            },
        )

    except KeyError as e:
        raise HTTPException(
            status_code=404,
            detail=f"자격증을 찾을 수 없습니다: {cert_id}",
        )
    except ValueError as e:
        raise HTTPException(
            status_code=400,
            detail=f"잘못된 파라미터: {str(e)}",
        )
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"뱃지 생성 실패: {str(e)}",
        )


@router.get("/certification/{cert_id}/code")
async def get_badge_embed_code(
    cert_id: str = Path(..., description="자격증 ID"),
    year: int = Query(..., ge=1900, le=2100, description="취득년도"),
    style: BadgeStyle = Query("flat", description="뱃지 스타일"),
    theme: BadgeTheme = Query("default", description="테마"),
    format: Literal["markdown", "html"] = Query("markdown", description="출력 형식 (markdown 또는 html)"),
    base_url: str = Query("https://certigraph.com", description="베이스 URL"),
):
    """
    뱃지 임베드 코드 생성

    Markdown 또는 HTML 형식의 임베드 코드를 생성합니다.

    ## 응답 예시

    **Markdown:**
    ```json
    {
      "format": "markdown",
      "code": "[![정보처리기사](https://certigraph.com/api/v1/badges/certification/cert_pe_info?year=2024&style=flat)](https://certigraph.com/certifications/cert_pe_info)"
    }
    ```

    **HTML:**
    ```json
    {
      "format": "html",
      "code": "<a href=\"https://certigraph.com/certifications/cert_pe_info\"><img src=\"https://certigraph.com/api/v1/badges/certification/cert_pe_info?year=2024&style=flat\" alt=\"정보처리기사 (2024)\" /></a>"
    }
    ```
    """
    try:
        # 뱃지 설정 확인
        config = get_badge_config(cert_id)

        # 임베드 코드 생성
        if format == "markdown":
            code = badge_generator.generate_markdown_code(
                cert_id=cert_id,
                year=year,
                style=style,
                theme=theme,
                base_url=base_url,
            )
        else:  # html
            code = badge_generator.generate_html_code(
                cert_id=cert_id,
                year=year,
                style=style,
                theme=theme,
                base_url=base_url,
            )

        return {
            "format": format,
            "code": code,
            "badge_url": f"{base_url}/api/v1/badges/certification/{cert_id}?year={year}&style={style}&theme={theme}",
            "profile_url": f"{base_url}/certifications/{cert_id}",
        }

    except KeyError:
        raise HTTPException(
            status_code=404,
            detail=f"자격증을 찾을 수 없습니다: {cert_id}",
        )


@router.get("/available-certifications")
async def get_available_badge_certifications():
    """
    뱃지 생성이 가능한 자격증 목록 조회

    모든 자격증의 ID, 이름, 아이콘, 카테고리 정보를 반환합니다.
    """
    from app.config.badge_config import get_all_badge_configs

    configs = get_all_badge_configs()

    certifications = []
    for cert_id, config in configs.items():
        certifications.append({
            "id": cert_id,
            "name": config["display_name"],
            "short_name": config["short_name"],
            "icon": config["icon"],
            "category": config["category"],
            "color": config["color"],
        })

    return {
        "total": len(certifications),
        "certifications": certifications,
    }
