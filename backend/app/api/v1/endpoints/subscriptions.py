"""Subscription management endpoints."""

from fastapi import APIRouter, Depends, HTTPException, status
from typing import List
from datetime import datetime, date

from app.api.v1.deps import CurrentUser, get_supabase
from app.models.subscription import (
    SubscriptionCreate,
    SubscriptionResponse,
    UserSubscriptionsResponse,
    SubscriptionCheckResponse,
    CertificationWithSubscription
)

router = APIRouter()


@router.get("/my-subscriptions", response_model=UserSubscriptionsResponse)
async def get_my_subscriptions(
    current_user: CurrentUser,
    supabase=Depends(get_supabase)
):
    """사용자의 모든 구독 목록 조회"""

    # 디버깅: JWT Payload 전체 구조 출력
    import json
    print(f"[DEBUG] === JWT PAYLOAD FULL DUMP ===")
    print(f"[DEBUG] Clerk ID: {current_user.clerk_id}")
    print(f"[DEBUG] Email from ClerkUser: {current_user.email}")
    print(f"[DEBUG] Full JWT Payload: {json.dumps(current_user.raw_payload, indent=2)}")
    print(f"[DEBUG] === END JWT PAYLOAD ===")

    # Clerk JWT에서 이메일이 다른 필드에 있을 수 있으므로 여러 필드를 체크
    user_email = current_user.email or current_user.raw_payload.get("primary_email_address") or current_user.raw_payload.get("email_addresses", [{}])[0].get("email_address", None) if current_user.raw_payload.get("email_addresses") else None

    print(f"[DEBUG] Final extracted email: {user_email}")

    # 🎁 VIP 사용자 무료 패스 (Clerk ID로 체크)
    VIP_CLERK_IDS = ["user_36T9Qa8HsuaM1fMjTisw4frRH1Z"]  # myaji35@gmail.com

    # DEV_MODE에서는 모든 사용자를 VIP로 처리 (테스트용)
    from app.core.config import get_settings
    settings = get_settings()

    if current_user.clerk_id in VIP_CLERK_IDS or settings.dev_mode:
        from datetime import datetime, timedelta, date
        vip_subscription = SubscriptionResponse(
            id="vip-pass",
            clerk_user_id=current_user.clerk_id,
            certification_id="certi_001",  # 실제 자격증 ID 사용
            certification_name="VIP 무료 이용권",
            exam_date=date(2099, 12, 31),  # VIP는 만료일 없음을 표현
            subscription_start_date=datetime.now(),
            subscription_end_date=datetime.now() + timedelta(days=9999),
            days_remaining=9999,
            status="active",
            amount=0,
            created_at=datetime.now()
        )
        return UserSubscriptionsResponse(
            subscriptions=[vip_subscription],
            total_count=1
        )

    # 구독 목록 조회 (활성 구독만)
    try:
        response = supabase.rpc(
            'get_user_subscriptions',
            {'p_clerk_user_id': current_user.clerk_id}
        ).execute()
    except Exception as e:
        # Cloud SQL 마이그레이션 중 Supabase 함수가 없는 경우 빈 목록 반환
        print(f"Supabase RPC error (migration in progress): {e}")
        return UserSubscriptionsResponse(
            subscriptions=[],
            total_count=0
        )

    subscriptions = []
    for row in response.data:
        subscriptions.append(SubscriptionResponse(
            id=row['subscription_id'],
            clerk_user_id=current_user.clerk_id,
            certification_id=row['certification_id'],
            certification_name=row['certification_name'],
            exam_date=row['exam_date'],
            subscription_start_date=row.get('subscription_start_date', datetime.now()),
            subscription_end_date=row['subscription_end_date'],
            days_remaining=row['days_remaining'],
            status=row['status'],
            amount=10000,  # TODO: Get from subscription table
            created_at=row.get('created_at', datetime.now())
        ))

    return UserSubscriptionsResponse(
        subscriptions=subscriptions,
        total_count=len(subscriptions)
    )


@router.get("/check/{certification_id}", response_model=SubscriptionCheckResponse)
async def check_subscription(
    certification_id: str,
    current_user: CurrentUser,
    supabase=Depends(get_supabase)
):
    """특정 자격증에 대한 구독 여부 확인"""

    # 🎁 VIP 사용자 무료 패스 (Clerk ID로 체크)
    VIP_CLERK_IDS = ["user_36T9Qa8HsuaM1fMjTisw4frRH1Z"]  # myaji35@gmail.com

    # DEV_MODE에서는 모든 사용자를 VIP로 처리 (테스트용)
    from app.core.config import get_settings
    settings = get_settings()

    if current_user.clerk_id in VIP_CLERK_IDS or settings.dev_mode:
        from datetime import datetime, timedelta
        return SubscriptionCheckResponse(
            has_subscription=True,
            certification_id=certification_id,
            certification_name="VIP 무료 이용권",
            days_remaining=9999,
            subscription_end_date=datetime.now() + timedelta(days=9999)
        )

    # 구독 확인 함수 호출
    response = supabase.rpc(
        'has_active_subscription',
        {
            'p_clerk_user_id': current_user.clerk_id,
            'p_certification_id': certification_id
        }
    ).execute()

    has_subscription = response.data if response.data is not None else False

    if not has_subscription:
        return SubscriptionCheckResponse(has_subscription=False)

    # 구독 상세 정보 조회
    sub_response = supabase.table('subscriptions').select(
        'id, certification_id, certifications(name), subscription_end_date'
    ).eq('clerk_user_id', current_user.clerk_id).eq(
        'certification_id', certification_id
    ).eq('status', 'active').single().execute()

    if sub_response.data:
        days_remaining = (
            datetime.fromisoformat(sub_response.data['subscription_end_date']) - datetime.now()
        ).days

        return SubscriptionCheckResponse(
            has_subscription=True,
            certification_id=certification_id,
            certification_name=sub_response.data['certifications']['name'],
            days_remaining=days_remaining,
            subscription_end_date=datetime.fromisoformat(sub_response.data['subscription_end_date'])
        )

    return SubscriptionCheckResponse(has_subscription=False)


@router.post("/create", response_model=SubscriptionResponse, status_code=status.HTTP_201_CREATED)
async def create_subscription(
    subscription: SubscriptionCreate,
    current_user: CurrentUser,
    supabase=Depends(get_supabase)
):
    """구독 생성 (결제 완료 후 호출)"""

    # 자격증 존재 확인
    cert_response = supabase.table('certifications').select('id, name').eq(
        'id', subscription.certification_id
    ).single().execute()

    if not cert_response.data:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="자격증을 찾을 수 없습니다."
        )

    # 이미 활성 구독이 있는지 확인
    existing = supabase.table('subscriptions').select('id').eq(
        'clerk_user_id', current_user.clerk_id
    ).eq('certification_id', subscription.certification_id).eq(
        'status', 'active'
    ).execute()

    if existing.data:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="이미 해당 자격증에 대한 활성 구독이 있습니다."
        )

    # 구독 생성
    sub_data = {
        'clerk_user_id': current_user.clerk_id,
        'certification_id': subscription.certification_id,
        'exam_date': subscription.exam_date.isoformat(),
        'subscription_end_date': subscription.exam_date.isoformat(),
        'payment_key': subscription.payment_key,
        'order_id': subscription.order_id,
        'amount': subscription.amount,
        'status': 'active'
    }

    response = supabase.table('subscriptions').insert(sub_data).execute()

    if not response.data:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="구독 생성 실패"
        )

    created_sub = response.data[0]
    days_remaining = (subscription.exam_date - date.today()).days

    return SubscriptionResponse(
        id=created_sub['id'],
        clerk_user_id=current_user.clerk_id,
        certification_id=subscription.certification_id,
        certification_name=cert_response.data['name'],
        exam_date=subscription.exam_date,
        subscription_start_date=datetime.fromisoformat(created_sub['created_at']),
        subscription_end_date=datetime.combine(subscription.exam_date, datetime.min.time()),
        days_remaining=days_remaining,
        status=created_sub['status'],
        amount=subscription.amount,
        created_at=datetime.fromisoformat(created_sub['created_at'])
    )


@router.get("/certifications-with-status", response_model=List[CertificationWithSubscription])
async def get_certifications_with_subscription_status(
    current_user: CurrentUser,
    supabase=Depends(get_supabase)
):
    """모든 자격증 목록 + 사용자 구독 상태"""

    # 모든 자격증 조회
    certs_response = supabase.table('certifications').select('id, name').execute()

    # 사용자의 활성 구독 조회
    subs_response = supabase.table('subscriptions').select(
        'certification_id, subscription_end_date'
    ).eq('clerk_user_id', current_user.clerk_id).eq('status', 'active').execute()

    # 구독 매핑
    subscriptions_map = {
        sub['certification_id']: sub for sub in subs_response.data
    }

    result = []
    for cert in certs_response.data:
        cert_id = cert['id']
        is_subscribed = cert_id in subscriptions_map

        subscription_end_date = None
        days_remaining = None

        if is_subscribed:
            end_date_str = subscriptions_map[cert_id]['subscription_end_date']
            subscription_end_date = datetime.fromisoformat(end_date_str).date()
            days_remaining = (subscription_end_date - date.today()).days

        result.append(CertificationWithSubscription(
            id=cert_id,
            name=cert['name'],
            is_subscribed=is_subscribed,
            subscription_end_date=subscription_end_date,
            days_remaining=days_remaining
        ))

    return result


@router.delete("/{subscription_id}")
async def cancel_subscription(
    subscription_id: str,
    current_user: CurrentUser,
    supabase=Depends(get_supabase)
):
    """구독 취소"""

    # 구독 존재 및 소유권 확인
    sub_response = supabase.table('subscriptions').select('id, clerk_user_id').eq(
        'id', subscription_id
    ).single().execute()

    if not sub_response.data:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="구독을 찾을 수 없습니다."
        )

    if sub_response.data['clerk_user_id'] != current_user.clerk_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="구독을 취소할 권한이 없습니다."
        )

    # 상태를 'cancelled'로 변경
    supabase.table('subscriptions').update(
        {'status': 'cancelled'}
    ).eq('id', subscription_id).execute()

    return {"message": "구독이 취소되었습니다.", "subscription_id": subscription_id}
