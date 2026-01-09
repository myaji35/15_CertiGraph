// Manual VIP Pass Test Script
// Run this in the browser console while logged in as myaji35@gmail.com

async function testVIPPass() {
  console.log('🧪 Starting VIP Pass Manual Test');
  console.log('================================');

  // Test 1: Check if VIP box is visible
  console.log('\n📋 Test 1: VIP UI Elements');
  const vipBox = document.querySelector('*[class*="purple"]');
  const vipText = Array.from(document.querySelectorAll('*')).find(el =>
    el.textContent?.includes('👑 VIP 무료 이용권')
  );

  if (vipText) {
    console.log('✅ VIP 박스 표시됨');
    console.log('   텍스트:', vipText.textContent.trim());
  } else {
    console.log('❌ VIP 박스를 찾을 수 없음');
  }

  // Test 2: Check certification dropdown
  console.log('\n📋 Test 2: 자격증 선택 드롭다운');
  const select = document.querySelector('select');
  if (select) {
    console.log('✅ 드롭다운 존재함');
    console.log('   옵션 개수:', select.options.length);

    // List available options
    if (select.options.length > 1) {
      console.log('   사용 가능한 자격증:');
      Array.from(select.options).slice(1).forEach((opt, i) => {
        console.log(`     ${i + 1}. ${opt.text}`);
      });
    }
  } else {
    console.log('❌ 드롭다운을 찾을 수 없음');
  }

  // Test 3: Check button state
  console.log('\n📋 Test 3: 버튼 상태 확인');
  const submitButton = Array.from(document.querySelectorAll('button')).find(btn =>
    btn.textContent?.includes('문제집 만들기')
  );

  if (submitButton) {
    console.log('✅ 제출 버튼 존재함');
    console.log('   초기 상태:', submitButton.disabled ? '비활성화' : '활성화');
  } else {
    console.log('❌ 제출 버튼을 찾을 수 없음');
  }

  // Test 4: Test form interaction
  console.log('\n📋 Test 4: 폼 상호작용 테스트');

  const nameInput = document.querySelector('input[placeholder*="2024"]');
  if (nameInput) {
    // Fill name
    nameInput.value = '테스트 문제집';
    nameInput.dispatchEvent(new Event('input', { bubbles: true }));
    nameInput.dispatchEvent(new Event('change', { bubbles: true }));
    console.log('✅ 이름 입력: 테스트 문제집');

    // Check button state after name input
    await new Promise(resolve => setTimeout(resolve, 100));
    console.log('   이름 입력 후 버튼:', submitButton?.disabled ? '비활성화' : '활성화');

    // Select first certification if dropdown exists
    if (select && select.options.length > 1) {
      select.value = select.options[1].value;
      select.dispatchEvent(new Event('change', { bubbles: true }));
      console.log('✅ 자격증 선택:', select.options[1].text);

      // Check button state after certification selection
      await new Promise(resolve => setTimeout(resolve, 100));
      console.log('   자격증 선택 후 버튼:', submitButton?.disabled ? '비활성화' : '활성화');
    }
  } else {
    console.log('❌ 이름 입력 필드를 찾을 수 없음');
  }

  // Test 5: Check for error elements
  console.log('\n📋 Test 5: 오류 요소 확인');
  const purchaseButton = Array.from(document.querySelectorAll('button')).find(btn =>
    btn.textContent?.includes('이용권 구매')
  );

  if (purchaseButton) {
    console.log('❌ "이용권 구매하러 가기" 버튼이 표시됨 (VIP에게 표시되면 안됨)');
  } else {
    console.log('✅ "이용권 구매하러 가기" 버튼 없음 (정상)');
  }

  console.log('\n================================');
  console.log('📊 테스트 완료');

  // Test 6: API Call Test
  console.log('\n📋 Test 6: API 호출 테스트');
  console.log('   문제집 생성을 시도하려면 콘솔에서 createTestStudySet()을 실행하세요');
}

// Function to create a test study set
async function createTestStudySet() {
  console.log('\n🚀 문제집 생성 테스트 시작...');

  const nameInput = document.querySelector('input[placeholder*="2024"]');
  const select = document.querySelector('select');
  const submitButton = Array.from(document.querySelectorAll('button')).find(btn =>
    btn.textContent?.includes('문제집 만들기')
  );

  if (!nameInput || !select || !submitButton) {
    console.log('❌ 필요한 요소를 찾을 수 없습니다');
    return;
  }

  // Fill form
  nameInput.value = 'VIP 테스트 ' + new Date().getTime();
  nameInput.dispatchEvent(new Event('input', { bubbles: true }));

  if (select.options.length > 1) {
    select.value = select.options[1].value;
    select.dispatchEvent(new Event('change', { bubbles: true }));
  }

  await new Promise(resolve => setTimeout(resolve, 100));

  if (!submitButton.disabled) {
    console.log('✅ 버튼 활성화됨, 클릭 시도...');
    submitButton.click();

    // Monitor network request
    console.log('   API 응답을 기다리는 중...');
    console.log('   개발자 도구의 Network 탭을 확인하세요');
  } else {
    console.log('❌ 버튼이 여전히 비활성화됨');
  }
}

// Auto-run test
testVIPPass();