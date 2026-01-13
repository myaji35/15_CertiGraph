const puppeteer = require('puppeteer');

(async () => {
  const browser = await puppeteer.launch({
    headless: false,  // 브라우저 창을 보이게 함
    defaultViewport: { width: 1920, height: 1080 }
  });

  const page = await browser.newPage();

  console.log('🧠 ExamsGraph Rails 최종 화면을 캡처합니다...');
  console.log('='.repeat(50));

  // 홈페이지
  await page.goto('http://localhost:3000');
  await new Promise(r => setTimeout(r, 3000));
  await page.screenshot({
    path: 'examsgraph-final-home.png',
    fullPage: true
  });
  console.log('✅ 홈페이지 캡처 완료: examsgraph-final-home.png');

  // 로그인 페이지
  await page.goto('http://localhost:3000/signin');
  await new Promise(r => setTimeout(r, 2000));
  await page.screenshot({
    path: 'examsgraph-final-signin.png',
    fullPage: true
  });
  console.log('✅ 로그인 페이지 캡처 완료: examsgraph-final-signin.png');

  // 회원가입 페이지
  await page.goto('http://localhost:3000/signup');
  await new Promise(r => setTimeout(r, 2000));
  await page.screenshot({
    path: 'examsgraph-final-signup.png',
    fullPage: true
  });
  console.log('✅ 회원가입 페이지 캡처 완료: examsgraph-final-signup.png');

  console.log('='.repeat(50));
  console.log('🎉 모든 ExamsGraph 스크린샷이 성공적으로 캡처되었습니다!');
  console.log('💡 브랜딩 변경 완료: CertiGraph → ExamsGraph');
  console.log('🧠 메인 아이콘 적용 완료');
  console.log('='.repeat(50));
  console.log('브라우저를 10초 후에 자동으로 닫습니다...');

  await new Promise(r => setTimeout(r, 10000));
  await browser.close();
})();