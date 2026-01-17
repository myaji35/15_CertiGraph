import { test, expect, Page } from '@playwright/test';

// BMad 테스트 181-220: 결제 시스템

const API_BASE = 'http://localhost:8015/api/v1';
const FRONTEND_URL = 'http://localhost:3000';

// Helper functions
async function loginAsUser(page: Page) {
  await page.goto(`${FRONTEND_URL}/login`);
  await page.fill('[name="email"]', 'test@example.com');
  await page.fill('[name="password"]', 'Test1234!');
  await page.click('button[type="submit"]');
  await page.waitForURL(`${FRONTEND_URL}/dashboard`);
}

test.describe('BMad 결제 시스템 테스트', () => {
  test.beforeEach(async ({ page }) => {
    await page.goto(FRONTEND_URL);
  });

  // 가격 플랜
  test('181. 가격 플랜 표시', async ({ page }) => {
    await page.goto(`${FRONTEND_URL}/pricing`);

    const pricingPlans = page.locator('.pricing-plan');
    await expect(pricingPlans).toHaveCount(3); // Free, Pro, Premium

    // Check each plan has required info
    for (const plan of await pricingPlans.all()) {
      await expect(plan.locator('.plan-name')).toBeVisible();
      await expect(plan.locator('.plan-price')).toBeVisible();
      await expect(plan.locator('.plan-features')).toBeVisible();
    }
  });

  test('182. 무료 플랜 제한 사항', async ({ page }) => {
    await loginAsUser(page);
    await page.goto(`${FRONTEND_URL}/dashboard`);

    // Try to access premium feature
    await page.click('button:has-text("AI 분석")');

    const upgradePrompt = page.locator('.upgrade-prompt');
    await expect(upgradePrompt).toBeVisible();
    await expect(upgradePrompt).toContainText(/프리미엄.*업그레이드/i);
  });

  test('183. 플랜 비교표', async ({ page }) => {
    await page.goto(`${FRONTEND_URL}/pricing`);

    await page.click('button:has-text("플랜 비교")');

    const comparisonTable = page.locator('.plan-comparison-table');
    await expect(comparisonTable).toBeVisible();
    await expect(comparisonTable.locator('th')).toContainText(['Free', 'Pro', 'Premium']);
  });

  test('184. 플랜 업그레이드 프로세스', async ({ page }) => {
    await loginAsUser(page);
    await page.goto(`${FRONTEND_URL}/pricing`);

    await page.click('.pricing-plan:has-text("Pro") button:has-text("선택")');

    await expect(page).toHaveURL(/\/checkout/);
    await expect(page.locator('.selected-plan')).toContainText('Pro');
  });

  test('185. 플랜 다운그레이드 경고', async ({ page }) => {
    await loginAsUser(page);
    await page.goto(`${FRONTEND_URL}/account/subscription`);

    // Assume user has Pro plan
    await page.click('button:has-text("Free로 변경")');

    const warningDialog = page.locator('.downgrade-warning');
    await expect(warningDialog).toBeVisible();
    await expect(warningDialog).toContainText(/기능.*제한/i);
  });

  // Toss Payments 결제
  test('186. Toss Payments 결제창 호출', async ({ page }) => {
    await loginAsUser(page);
    await page.goto(`${FRONTEND_URL}/checkout`);

    await page.selectOption('[name="plan"]', 'pro');
    await page.click('button:has-text("결제하기")');

    // Check Toss Payments iframe loads
    await expect(page.frameLocator('#toss-payments-iframe')).toBeVisible({ timeout: 10000 });
  });

  test('187. 카드 결제 정보 입력', async ({ page }) => {
    await loginAsUser(page);
    await page.goto(`${FRONTEND_URL}/checkout`);

    const tossFrame = page.frameLocator('#toss-payments-iframe');

    // Fill card details
    await tossFrame.locator('[name="cardNumber"]').fill('1234-5678-9012-3456');
    await tossFrame.locator('[name="expiryDate"]').fill('12/25');
    await tossFrame.locator('[name="cvv"]').fill('123');

    await expect(tossFrame.locator('.payment-ready')).toBeVisible();
  });

  test('188. 간편결제 옵션', async ({ page }) => {
    await loginAsUser(page);
    await page.goto(`${FRONTEND_URL}/checkout`);

    const paymentMethods = page.locator('.payment-methods');

    await expect(paymentMethods.locator('button:has-text("카카오페이")')).toBeVisible();
    await expect(paymentMethods.locator('button:has-text("네이버페이")')).toBeVisible();
    await expect(paymentMethods.locator('button:has-text("토스페이")')).toBeVisible();
  });

  test('189. 결제 검증 프로세스', async ({ page }) => {
    await loginAsUser(page);
    await page.goto(`${FRONTEND_URL}/checkout`);

    // Mock payment completion
    await page.evaluate(() => {
      window.postMessage({ type: 'PAYMENT_SUCCESS', paymentKey: 'test-key-123' }, '*');
    });

    await expect(page.locator('.payment-verification')).toBeVisible();
    await expect(page).toHaveURL(/\/payment\/verify/);
  });

  test('190. 결제 실패 처리', async ({ page }) => {
    await loginAsUser(page);
    await page.goto(`${FRONTEND_URL}/checkout`);

    // Mock payment failure
    await page.evaluate(() => {
      window.postMessage({ type: 'PAYMENT_FAILED', error: '잔액 부족' }, '*');
    });

    const errorMessage = page.locator('.payment-error');
    await expect(errorMessage).toBeVisible();
    await expect(errorMessage).toContainText('잔액 부족');
  });

  // 구독 관리
  test('191. 구독 상태 확인', async ({ page }) => {
    await loginAsUser(page);
    await page.goto(`${FRONTEND_URL}/account/subscription`);

    const subscriptionInfo = page.locator('.subscription-info');
    await expect(subscriptionInfo.locator('.current-plan')).toBeVisible();
    await expect(subscriptionInfo.locator('.billing-cycle')).toBeVisible();
    await expect(subscriptionInfo.locator('.next-payment-date')).toBeVisible();
  });

  test('192. 자동 결제 설정', async ({ page }) => {
    await loginAsUser(page);
    await page.goto(`${FRONTEND_URL}/account/billing`);

    await page.check('[name="auto-renewal"]');
    await page.click('button:has-text("저장")');

    await expect(page.locator('.auto-renewal-status')).toContainText('활성화');
  });

  test('193. 결제 수단 변경', async ({ page }) => {
    await loginAsUser(page);
    await page.goto(`${FRONTEND_URL}/account/payment-methods`);

    await page.click('button:has-text("결제 수단 변경")');

    await page.fill('[name="new-card-number"]', '9876-5432-1098-7654');
    await page.click('button:has-text("변경")');

    await expect(page.locator('.payment-method-updated')).toBeVisible();
  });

  test('194. 구독 일시정지', async ({ page }) => {
    await loginAsUser(page);
    await page.goto(`${FRONTEND_URL}/account/subscription`);

    await page.click('button:has-text("구독 일시정지")');

    const pauseDialog = page.locator('.pause-subscription-dialog');
    await pauseDialog.selectOption('[name="pause-duration"]', '1-month');
    await pauseDialog.locator('button:has-text("확인")').click();

    await expect(page.locator('.subscription-status')).toContainText('일시정지');
  });

  test('195. 구독 취소 프로세스', async ({ page }) => {
    await loginAsUser(page);
    await page.goto(`${FRONTEND_URL}/account/subscription`);

    await page.click('button:has-text("구독 취소")');

    const cancelDialog = page.locator('.cancel-subscription-dialog');
    await expect(cancelDialog).toBeVisible();

    await cancelDialog.locator('[name="cancel-reason"]').selectOption('too-expensive');
    await cancelDialog.locator('button:has-text("취소 확인")').click();

    await expect(page.locator('.subscription-cancelled')).toBeVisible();
  });

  // 결제 내역
  test('196. 결제 내역 조회', async ({ page }) => {
    await loginAsUser(page);
    await page.goto(`${FRONTEND_URL}/account/billing-history`);

    const billingHistory = page.locator('.billing-history-table');
    await expect(billingHistory).toBeVisible();

    const transactions = billingHistory.locator('.transaction-row');
    for (const transaction of await transactions.all()) {
      await expect(transaction.locator('.transaction-date')).toBeVisible();
      await expect(transaction.locator('.transaction-amount')).toBeVisible();
      await expect(transaction.locator('.transaction-status')).toBeVisible();
    }
  });

  test('197. 영수증 다운로드', async ({ page }) => {
    await loginAsUser(page);
    await page.goto(`${FRONTEND_URL}/account/billing-history`);

    const firstTransaction = page.locator('.transaction-row').first();

    const downloadPromise = page.waitForEvent('download');
    await firstTransaction.locator('button:has-text("영수증")').click();

    const download = await downloadPromise;
    expect(download.suggestedFilename()).toMatch(/receipt.*\.pdf$/i);
  });

  test('198. 세금계산서 발행', async ({ page }) => {
    await loginAsUser(page);
    await page.goto(`${FRONTEND_URL}/account/billing-history`);

    await page.locator('.transaction-row').first().locator('button:has-text("세금계산서")').click();

    const taxInvoiceDialog = page.locator('.tax-invoice-dialog');
    await taxInvoiceDialog.fill('[name="business-number"]', '123-45-67890');
    await taxInvoiceDialog.fill('[name="company-name"]', '테스트 회사');
    await taxInvoiceDialog.locator('button:has-text("발행 요청")').click();

    await expect(page.locator('.tax-invoice-requested')).toBeVisible();
  });

  test('199. 결제 내역 필터링', async ({ page }) => {
    await loginAsUser(page);
    await page.goto(`${FRONTEND_URL}/account/billing-history`);

    await page.selectOption('[name="year"]', '2024');
    await page.selectOption('[name="month"]', '11');

    const transactions = page.locator('.transaction-row');
    for (const transaction of await transactions.all()) {
      const date = await transaction.locator('.transaction-date').textContent();
      expect(date).toContain('2024-11');
    }
  });

  test('200. 환불 요청', async ({ page }) => {
    await loginAsUser(page);
    await page.goto(`${FRONTEND_URL}/account/billing-history`);

    await page.locator('.transaction-row').first().locator('button:has-text("환불")').click();

    const refundDialog = page.locator('.refund-dialog');
    await refundDialog.fill('[name="refund-reason"]', '서비스 불만족');
    await refundDialog.locator('button:has-text("환불 요청")').click();

    await expect(page.locator('.refund-requested')).toBeVisible();
  });

  // 프로모션 및 쿠폰
  test('201. 프로모션 코드 적용', async ({ page }) => {
    await loginAsUser(page);
    await page.goto(`${FRONTEND_URL}/checkout`);

    await page.fill('[name="promo-code"]', 'WELCOME50');
    await page.click('button:has-text("적용")');

    const discount = page.locator('.discount-applied');
    await expect(discount).toBeVisible();
    await expect(discount).toContainText('50%');
  });

  test('202. 쿠폰 유효성 검증', async ({ page }) => {
    await loginAsUser(page);
    await page.goto(`${FRONTEND_URL}/checkout`);

    await page.fill('[name="promo-code"]', 'EXPIRED123');
    await page.click('button:has-text("적용")');

    await expect(page.locator('.promo-error')).toContainText(/만료|유효하지/i);
  });

  test('203. 추천인 할인', async ({ page }) => {
    await loginAsUser(page);
    await page.goto(`${FRONTEND_URL}/checkout`);

    await page.fill('[name="referral-code"]', 'FRIEND123');
    await page.click('button:has-text("추천인 코드 적용")');

    await expect(page.locator('.referral-discount')).toBeVisible();
    await expect(page.locator('.referral-discount')).toContainText('20% 할인');
  });

  test('204. 번들 할인', async ({ page }) => {
    await loginAsUser(page);
    await page.goto(`${FRONTEND_URL}/pricing`);

    await page.click('button:has-text("연간 결제")');

    const bundleDiscount = page.locator('.bundle-discount');
    await expect(bundleDiscount).toBeVisible();
    await expect(bundleDiscount).toContainText(/2개월 무료/i);
  });

  test('205. 학생 할인 인증', async ({ page }) => {
    await loginAsUser(page);
    await page.goto(`${FRONTEND_URL}/student-verification`);

    await page.fill('[name="school-email"]', 'student@university.ac.kr');
    await page.click('button:has-text("인증 메일 발송")');

    await expect(page.locator('.verification-sent')).toBeVisible();
  });

  // 결제 보안
  test('206. PCI DSS 준수 확인', async ({ page }) => {
    await page.goto(`${FRONTEND_URL}/checkout`);

    // Check for security badges
    await expect(page.locator('.pci-dss-badge')).toBeVisible();
    await expect(page.locator('.ssl-secure-badge')).toBeVisible();
  });

  test('207. 카드 정보 마스킹', async ({ page }) => {
    await loginAsUser(page);
    await page.goto(`${FRONTEND_URL}/account/payment-methods`);

    const cardInfo = page.locator('.saved-card');
    const cardNumber = await cardInfo.locator('.card-number').textContent();

    // Check if card number is masked
    expect(cardNumber).toMatch(/\*{4,12}\d{4}$/);
  });

  test('208. 3D Secure 인증', async ({ page }) => {
    await loginAsUser(page);
    await page.goto(`${FRONTEND_URL}/checkout`);

    await page.click('button:has-text("결제하기")');

    // Check for 3D Secure iframe
    await expect(page.frameLocator('#3ds-iframe')).toBeVisible({ timeout: 10000 });
  });

  test('209. 중복 결제 방지', async ({ page }) => {
    await loginAsUser(page);
    await page.goto(`${FRONTEND_URL}/checkout`);

    // Double click payment button
    await page.dblclick('button:has-text("결제하기")');

    await expect(page.locator('.duplicate-payment-warning')).toBeVisible();
  });

  test('210. 결제 타임아웃 처리', async ({ page }) => {
    await loginAsUser(page);
    await page.goto(`${FRONTEND_URL}/checkout`);

    // Wait for session timeout
    await page.waitForTimeout(15 * 60 * 1000); // 15 minutes

    await page.click('button:has-text("결제하기")');

    await expect(page.locator('.session-expired')).toBeVisible();
  });

  // 기업 계정
  test('211. 기업 계정 등록', async ({ page }) => {
    await page.goto(`${FRONTEND_URL}/enterprise/register`);

    await page.fill('[name="company-name"]', '테스트 기업');
    await page.fill('[name="business-number"]', '123-45-67890');
    await page.fill('[name="contact-email"]', 'admin@company.com');
    await page.fill('[name="employee-count"]', '50');

    await page.click('button:has-text("등록")');

    await expect(page.locator('.enterprise-registration-complete')).toBeVisible();
  });

  test('212. 기업 라이선스 관리', async ({ page }) => {
    await loginAsUser(page);
    await page.goto(`${FRONTEND_URL}/enterprise/licenses`);

    const licenseManagement = page.locator('.license-management');
    await expect(licenseManagement.locator('.total-licenses')).toBeVisible();
    await expect(licenseManagement.locator('.used-licenses')).toBeVisible();
    await expect(licenseManagement.locator('.available-licenses')).toBeVisible();
  });

  test('213. 기업 사용자 초대', async ({ page }) => {
    await loginAsUser(page);
    await page.goto(`${FRONTEND_URL}/enterprise/users`);

    await page.click('button:has-text("사용자 초대")');

    await page.fill('[name="invite-emails"]', 'user1@company.com, user2@company.com');
    await page.selectOption('[name="role"]', 'member');
    await page.click('button:has-text("초대 발송")');

    await expect(page.locator('.invitations-sent')).toContainText('2명');
  });

  test('214. 기업 결제 관리자 설정', async ({ page }) => {
    await loginAsUser(page);
    await page.goto(`${FRONTEND_URL}/enterprise/billing`);

    await page.fill('[name="billing-admin-email"]', 'finance@company.com');
    await page.click('button:has-text("관리자 설정")');

    await expect(page.locator('.billing-admin-updated')).toBeVisible();
  });

  test('215. 기업 사용량 리포트', async ({ page }) => {
    await loginAsUser(page);
    await page.goto(`${FRONTEND_URL}/enterprise/reports`);

    const usageReport = page.locator('.usage-report');
    await expect(usageReport.locator('.monthly-usage-chart')).toBeVisible();
    await expect(usageReport.locator('.user-activity-table')).toBeVisible();

    const downloadPromise = page.waitForEvent('download');
    await page.click('button:has-text("리포트 다운로드")');

    const download = await downloadPromise;
    expect(download.suggestedFilename()).toMatch(/usage-report.*\.xlsx$/i);
  });

  // 결제 알림
  test('216. 결제 성공 알림', async ({ page }) => {
    await loginAsUser(page);

    // Mock payment success
    await page.evaluate(() => {
      window.postMessage({ type: 'PAYMENT_SUCCESS', amount: 50000 }, '*');
    });

    const notification = page.locator('.payment-notification');
    await expect(notification).toBeVisible();
    await expect(notification).toContainText(/결제.*성공/i);
  });

  test('217. 구독 만료 임박 알림', async ({ page }) => {
    await loginAsUser(page);
    await page.goto(`${FRONTEND_URL}/dashboard`);

    // Mock subscription expiry warning
    await page.evaluate(() => {
      window.mockSubscriptionDaysLeft = 3;
    });

    const expiryWarning = page.locator('.subscription-expiry-warning');
    await expect(expiryWarning).toBeVisible();
    await expect(expiryWarning).toContainText(/3일.*만료/i);
  });

  test('218. 자동 결제 실패 알림', async ({ page }) => {
    await loginAsUser(page);

    // Mock auto-payment failure
    await page.evaluate(() => {
      window.postMessage({ type: 'AUTO_PAYMENT_FAILED' }, '*');
    });

    const failureAlert = page.locator('.auto-payment-failure');
    await expect(failureAlert).toBeVisible();
    await expect(failureAlert).toContainText(/자동 결제.*실패/i);
  });

  test('219. 가격 변경 사전 공지', async ({ page }) => {
    await loginAsUser(page);
    await page.goto(`${FRONTEND_URL}/notifications`);

    const priceChangeNotice = page.locator('.price-change-notice');
    await expect(priceChangeNotice).toBeVisible();
    await expect(priceChangeNotice).toContainText(/가격.*변경/i);
  });

  test('220. 환불 완료 알림', async ({ page }) => {
    await loginAsUser(page);

    // Mock refund completion
    await page.evaluate(() => {
      window.postMessage({ type: 'REFUND_COMPLETED', amount: 30000 }, '*');
    });

    const refundNotification = page.locator('.refund-notification');
    await expect(refundNotification).toBeVisible();
    await expect(refundNotification).toContainText(/환불.*완료/i);
  });
});

// Payment error handling
test.describe('결제 오류 처리', () => {
  test('E01. 네트워크 오류 처리', async ({ page }) => {
    await loginAsUser(page);

    await page.route('**/api/v1/payments/**', route => {
      route.abort('internetdisconnected');
    });

    await page.goto(`${FRONTEND_URL}/checkout`);
    await page.click('button:has-text("결제하기")');

    await expect(page.locator('.network-error')).toContainText(/네트워크.*오류/i);
  });

  test('E02. 결제 게이트웨이 오류', async ({ page }) => {
    await loginAsUser(page);

    await page.route('**/toss/payments/**', route => {
      route.fulfill({
        status: 503,
        body: JSON.stringify({ error: 'Gateway unavailable' })
      });
    });

    await page.goto(`${FRONTEND_URL}/checkout`);
    await page.click('button:has-text("결제하기")');

    await expect(page.locator('.gateway-error')).toContainText(/일시적.*오류/i);
  });

  test('E03. 잘못된 카드 정보 처리', async ({ page }) => {
    await loginAsUser(page);
    await page.goto(`${FRONTEND_URL}/checkout`);

    const tossFrame = page.frameLocator('#toss-payments-iframe');

    await tossFrame.locator('[name="cardNumber"]').fill('0000-0000-0000-0000');
    await tossFrame.locator('[name="expiryDate"]').fill('13/25'); // Invalid month

    await page.click('button:has-text("결제하기")');

    await expect(tossFrame.locator('.card-error')).toContainText(/유효하지 않은/i);
  });
});