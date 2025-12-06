from fastapi import HTTPException, status
from typing import Any


class AppException(HTTPException):
    """Base application exception with structured error response."""

    def __init__(
        self,
        status_code: int,
        code: str,
        message: str,
        details: dict[str, Any] | None = None,
    ):
        self.code = code
        self.message = message
        self.details = details
        super().__init__(
            status_code=status_code,
            detail={
                "error": {
                    "code": code,
                    "message": message,
                    **({"details": details} if details else {}),
                }
            },
        )


# Authentication Errors
class AuthMissingTokenError(AppException):
    def __init__(self):
        super().__init__(
            status_code=status.HTTP_401_UNAUTHORIZED,
            code="AUTH_MISSING_TOKEN",
            message="인증 토큰이 필요합니다.",
        )


class AuthInvalidTokenError(AppException):
    def __init__(self):
        super().__init__(
            status_code=status.HTTP_401_UNAUTHORIZED,
            code="AUTH_INVALID_TOKEN",
            message="유효하지 않은 인증 토큰입니다.",
        )


class AuthExpiredTokenError(AppException):
    def __init__(self):
        super().__init__(
            status_code=status.HTTP_401_UNAUTHORIZED,
            code="AUTH_EXPIRED",
            message="인증 토큰이 만료되었습니다.",
        )


# Resource Errors
class ResourceNotFoundError(AppException):
    def __init__(self, resource: str, resource_id: str):
        super().__init__(
            status_code=status.HTTP_404_NOT_FOUND,
            code="RESOURCE_NOT_FOUND",
            message=f"{resource}을(를) 찾을 수 없습니다.",
            details={"resource": resource, "id": resource_id},
        )


# Validation Errors
class ValidationFormatError(AppException):
    def __init__(self, message: str, field: str | None = None):
        super().__init__(
            status_code=status.HTTP_400_BAD_REQUEST,
            code="VALIDATION_FORMAT",
            message=message,
            details={"field": field} if field else None,
        )


class ValidationRequiredError(AppException):
    def __init__(self, field: str):
        super().__init__(
            status_code=status.HTTP_400_BAD_REQUEST,
            code="VALIDATION_REQUIRED",
            message=f"{field}은(는) 필수 항목입니다.",
            details={"field": field},
        )


# External Service Errors
class ExternalUpstageError(AppException):
    def __init__(self, message: str = "Upstage API 오류가 발생했습니다."):
        super().__init__(
            status_code=status.HTTP_502_BAD_GATEWAY,
            code="EXTERNAL_UPSTAGE_ERROR",
            message=message,
        )


class ExternalOpenAILimitError(AppException):
    def __init__(self):
        super().__init__(
            status_code=status.HTTP_429_TOO_MANY_REQUESTS,
            code="EXTERNAL_OPENAI_LIMIT",
            message="OpenAI API 호출 한도에 도달했습니다. 잠시 후 다시 시도해주세요.",
        )


# File Upload Errors
class FileTooLargeError(AppException):
    def __init__(self, max_size_mb: int = 50):
        super().__init__(
            status_code=status.HTTP_400_BAD_REQUEST,
            code="FILE_TOO_LARGE",
            message=f"파일 크기는 {max_size_mb}MB 이하여야 합니다.",
        )


class InvalidFileTypeError(AppException):
    def __init__(self, allowed_types: str = "PDF"):
        super().__init__(
            status_code=status.HTTP_400_BAD_REQUEST,
            code="VALIDATION_FORMAT",
            message=f"{allowed_types} 파일만 업로드 가능합니다.",
        )


class RateLimitError(AppException):
    def __init__(self, message: str = "요청 한도를 초과했습니다. 잠시 후 다시 시도해주세요."):
        super().__init__(
            status_code=status.HTTP_429_TOO_MANY_REQUESTS,
            code="RATE_LIMIT_EXCEEDED",
            message=message,
        )


# Server Errors
class ServerInternalError(AppException):
    def __init__(self, message: str = "서버 내부 오류가 발생했습니다."):
        super().__init__(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            code="SERVER_INTERNAL_ERROR",
            message=message,
        )
