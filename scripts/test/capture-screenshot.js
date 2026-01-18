const puppeteer = require('puppeteer');

(async () => {
  const browser = await puppeteer.launch({
    headless: false,  // 브라우저 창을 보이게 함
    defaultViewport: { width: 1920, height: 1080 }
  });

  const page = await browser.newPage();

  console.log('ExamsGraph 화면을 캡처합니다...');

  // 홈페이지
  await page.goto('http://localhost:3000');
  await new Promise(r => setTimeout(r, 3000));
  await page.screenshot({
    path: 'examsgraph-home.png',
    fullPage: true
  });
  console.log('✅ 홈페이지 캡처 완료: examsgraph-home.png');

  // 로그인 페이지
  await page.goto('http://localhost:3000/sign-in');
  await new Promise(r => setTimeout(r, 2000));
  await page.screenshot({
    path: 'examsgraph-signin.png',
    fullPage: true
  });
  console.log('✅ 로그인 페이지 캡처 완료: examsgraph-signin.png');

  // 회원가입 페이지
  await page.goto('http://localhost:3000/sign-up');
  await new Promise(r => setTimeout(r, 2000));
  await page.screenshot({
    path: 'examsgraph-signup.png',
    fullPage: true
  });
  console.log('✅ 회원가입 페이지 캡처 완료: examsgraph-signup.png');

  console.log('\\n모든 스크린샷이 성공적으로 캡처되었습니다!');
  console.log('브라우저를 10초 후에 자동으로 닫습니다...');

  await new Promise(r => setTimeout(r, 10000));
  await browser.close();
})();