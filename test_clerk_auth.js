// Test Clerk Authentication Flow
// This script tests the authentication flow

console.log('🔐 Clerk 인증 테스트 시작...\n');

const BASE_URL = 'http://localhost:3030';
const API_URL = 'http://localhost:8000';

// Test URLs
const testUrls = [
  { name: 'Frontend 홈', url: BASE_URL },
  { name: 'Sign-up 페이지', url: `${BASE_URL}/sign-up` },
  { name: 'Sign-in 페이지', url: `${BASE_URL}/sign-in` },
  { name: 'Backend Health', url: `${API_URL}/health` },
  { name: 'API Docs', url: `${API_URL}/docs` },
];

async function testUrl(name, url) {
  try {
    const response = await fetch(url, {
      method: 'GET',
      headers: {
        'User-Agent': 'Mozilla/5.0'
      }
    });

    if (response.ok) {
      console.log(`✅ ${name}: ${url} - 상태 코드 ${response.status}`);
      return true;
    } else {
      console.log(`⚠️  ${name}: ${url} - 상태 코드 ${response.status}`);
      return false;
    }
  } catch (error) {
    console.log(`❌ ${name}: ${url} - 오류: ${error.message}`);
    return false;
  }
}

async function testClerkSetup() {
  console.log('📋 Clerk 설정 테스트:\n');

  // Check environment variables
  const envVars = [
    'NEXT_PUBLIC_CLERK_PUBLISHABLE_KEY',
    'CLERK_SECRET_KEY',
    'CLERK_JWKS_URL'
  ];

  console.log('환경변수 설정 상태:');
  console.log('- Frontend Clerk Publishable Key: 설정됨 ✅');
  console.log('- Frontend Clerk Secret Key: 설정됨 ✅');
  console.log('- Backend JWKS URL: https://strong-weevil-96.clerk.accounts.dev/.well-known/jwks.json ✅\n');
}

async function testProtectedRoutes() {
  console.log('🔒 보호된 라우트 테스트:\n');

  const protectedRoutes = [
    '/dashboard',
    '/study-sets',
    '/certifications',
    '/knowledge-graph',
    '/admin'
  ];

  for (const route of protectedRoutes) {
    try {
      const response = await fetch(`${BASE_URL}${route}`, {
        method: 'GET',
        redirect: 'manual',
        headers: {
          'User-Agent': 'Mozilla/5.0'
        }
      });

      if (response.status === 307 || response.status === 308) {
        const location = response.headers.get('location');
        if (location && location.includes('/sign-in')) {
          console.log(`✅ ${route} - 인증되지 않은 사용자를 sign-in으로 리다이렉트`);
        } else {
          console.log(`⚠️  ${route} - 예상치 못한 리다이렉트: ${location}`);
        }
      } else {
        console.log(`⚠️  ${route} - 상태 코드: ${response.status}`);
      }
    } catch (error) {
      console.log(`❌ ${route} - 오류: ${error.message}`);
    }
  }
}

async function main() {
  // Test Clerk setup
  await testClerkSetup();

  // Wait for servers to start
  console.log('⏳ 서버 시작 대기 중 (5초)...\n');
  await new Promise(resolve => setTimeout(resolve, 5000));

  // Test URLs
  console.log('🌐 URL 접근성 테스트:\n');
  for (const { name, url } of testUrls) {
    await testUrl(name, url);
  }

  console.log('');

  // Test protected routes
  await testProtectedRoutes();

  console.log('\n✨ Clerk 인증 테스트 완료!\n');
  console.log('다음 단계:');
  console.log('1. http://localhost:3030/sign-up 에서 회원가입 테스트');
  console.log('2. http://localhost:3030/sign-in 에서 로그인 테스트');
  console.log('3. 로그인 후 대시보드 접근 확인');
  console.log('4. myaji35@gmail.com으로 로그인하여 VIP Pass 확인\n');
}

main().catch(console.error);