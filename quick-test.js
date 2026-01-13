const puppeteer = require('puppeteer');

(async () => {
  let testResults = [];
  const browser = await puppeteer.launch({ headless: true });
  const page = await browser.newPage();

  console.log('\n🧪 ExamsGraph Rails 빠른 테스트 시작...\n');
  console.log('=' .repeat(50));

  // 테스트 1: 홈페이지 로드
  try {
    await page.goto('http://localhost:3000', { waitUntil: 'networkidle2', timeout: 10000 });
    const title = await page.title();
    if (title.includes('ExamsGraph')) {
      testResults.push('✅ 테스트 1: 홈페이지 로드 성공');
    } else {
      testResults.push(`❌ 테스트 1: 타이틀이 잘못됨 - "${title}"`);
    }
  } catch (error) {
    testResults.push(`❌ 테스트 1: 홈페이지 로드 실패 - ${error.message}`);
  }

  // 테스트 2: 메인 텍스트 확인
  try {
    const mainText = await page.$eval('body', el => el.textContent);
    if (mainText.includes('기출문제 PDF를 업로드하면')) {
      testResults.push('✅ 테스트 2: 메인 텍스트 확인');
    } else {
      testResults.push('❌ 테스트 2: 메인 텍스트 없음');
    }
  } catch (error) {
    testResults.push(`❌ 테스트 2: ${error.message}`);
  }

  // 테스트 3: 로그인 페이지 접근
  try {
    await page.goto('http://localhost:3000/signin', { waitUntil: 'networkidle2', timeout: 10000 });
    const loginText = await page.$eval('body', el => el.textContent);
    if (loginText.includes('로그인') || loginText.includes('ExamsGraph')) {
      testResults.push('✅ 테스트 3: 로그인 페이지 접근 성공');
    } else {
      testResults.push('❌ 테스트 3: 로그인 페이지 텍스트 문제');
    }
  } catch (error) {
    testResults.push(`❌ 테스트 3: 로그인 페이지 로드 실패 - ${error.message}`);
  }

  // 테스트 4: 회원가입 페이지 접근
  try {
    await page.goto('http://localhost:3000/signup', { waitUntil: 'networkidle2', timeout: 10000 });
    const signupText = await page.$eval('body', el => el.textContent);
    if (signupText.includes('회원가입') || signupText.includes('ExamsGraph')) {
      testResults.push('✅ 테스트 4: 회원가입 페이지 접근 성공');
    } else {
      testResults.push('❌ 테스트 4: 회원가입 페이지 텍스트 문제');
    }
  } catch (error) {
    testResults.push(`❌ 테스트 4: 회원가입 페이지 로드 실패 - ${error.message}`);
  }

  // 테스트 5: 아이콘 확인
  try {
    await page.goto('http://localhost:3000', { waitUntil: 'networkidle2', timeout: 10000 });
    const iconElement = await page.$('.bg-blue-600.rounded-full');
    if (iconElement) {
      const iconText = await page.evaluate(el => el.textContent, iconElement);
      if (iconText && iconText.includes('🧠')) {
        testResults.push('✅ 테스트 5: 메인 아이콘 (🧠) 표시 확인');
      } else {
        testResults.push('❌ 테스트 5: 아이콘 텍스트 문제');
      }
    } else {
      testResults.push('❌ 테스트 5: 아이콘 요소를 찾을 수 없음');
    }
  } catch (error) {
    testResults.push(`❌ 테스트 5: 아이콘 확인 실패 - ${error.message}`);
  }

  await browser.close();

  // 결과 출력
  console.log('\n📊 테스트 결과:\n');
  testResults.forEach(result => console.log(result));

  const successCount = testResults.filter(r => r.includes('✅')).length;
  const failCount = testResults.filter(r => r.includes('❌')).length;

  console.log('\n' + '=' .repeat(50));
  console.log(`\n총 ${testResults.length}개 테스트 중:`);
  console.log(`✅ 성공: ${successCount}개`);
  console.log(`❌ 실패: ${failCount}개`);
  console.log(`📈 성공률: ${Math.round(successCount / testResults.length * 100)}%\n`);

  // 실패한 테스트가 있으면 버그 정보 출력
  if (failCount > 0) {
    console.log('🔧 발견된 버그:');
    testResults.filter(r => r.includes('❌')).forEach(bug => {
      console.log(`  - ${bug.replace('❌ ', '')}`);
    });
  }
})();