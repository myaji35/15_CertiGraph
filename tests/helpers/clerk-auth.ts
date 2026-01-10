import { Page } from '@playwright/test';

const FRONTEND_URL = process.env.FRONTEND_URL || 'http://localhost:3030';

/**
 * Clerk 인증을 사용하여 로그인
 * @param page Playwright Page 객체
 * @param email 사용자 이메일
 * @param password 사용자 비밀번호
 */
export async function loginWithClerk(page: Page, email: string = 'test@example.com', password: string = 'Test1234!') {
    // Clerk 로그인 페이지로 이동
    await page.goto(`${FRONTEND_URL}/sign-in`);

    // 페이지 로드 대기
    await page.waitForLoadState('domcontentloaded');

    try {
        // Clerk 이메일 입력 필드 (identifier)
        const emailInput = page.locator('.cl-formFieldInput[name="identifier"]');
        await emailInput.waitFor({ timeout: 10000 });
        await emailInput.fill(email);

        // 비밀번호 입력 필드
        const passwordInput = page.locator('.cl-formFieldInput[name="password"]');
        await passwordInput.waitFor({ timeout: 5000 });
        await passwordInput.fill(password);

        // 로그인 버튼 클릭
        const loginButton = page.locator('.cl-formButtonPrimary');
        await loginButton.click();

        // 대시보드 로드 대기
        await page.waitForURL(/\/dashboard/, { timeout: 15000 });

        console.log('✓ Clerk 로그인 성공');
    } catch (error) {
        console.error('❌ Clerk 로그인 실패:', error);

        // 스크린샷 저장
        await page.screenshot({ path: 'test-results/clerk-login-failed.png' });

        throw new Error(`Clerk 로그인 실패: ${error}`);
    }
}

/**
 * 레거시 로그인 함수 (이메일/비밀번호 폼)
 * Clerk 마이그레이션 전 코드와의 호환성을 위해 유지
 * @deprecated loginWithClerk 사용 권장
 */
export async function loginAsUser(page: Page, email: string = 'test@example.com', password: string = 'Test1234!') {
    console.warn('⚠️ loginAsUser는 deprecated되었습니다. loginWithClerk를 사용하세요.');
    return loginWithClerk(page, email, password);
}

/**
 * 로그아웃
 */
export async function logout(page: Page) {
    try {
        // Clerk UserButton 클릭
        const userButton = page.locator('.cl-userButtonTrigger');
        await userButton.click();

        // Sign out 버튼 클릭
        const signOutButton = page.locator('button:has-text("Sign out"), button:has-text("로그아웃")');
        await signOutButton.click();

        // 로그인 페이지로 리다이렉트 대기
        await page.waitForURL(/\/sign-in/, { timeout: 10000 });

        console.log('✓ 로그아웃 성공');
    } catch (error) {
        console.error('❌ 로그아웃 실패:', error);
        throw error;
    }
}

/**
 * 현재 로그인 상태 확인
 */
export async function isLoggedIn(page: Page): Promise<boolean> {
    try {
        // Clerk UserButton이 있으면 로그인 상태
        const userButton = page.locator('.cl-userButtonTrigger');
        return await userButton.isVisible({ timeout: 3000 });
    } catch {
        return false;
    }
}
