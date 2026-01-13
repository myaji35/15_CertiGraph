// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"

// Turbo 호환 이벤트 핸들러 설정
document.addEventListener('turbo:load', () => {
  console.log('Turbo loaded - initializing event handlers');

  // PDF 업로드 버튼 처리
  const fileInput = document.getElementById('pdf-upload');
  const uploadBtn = document.getElementById('upload-pdf-btn');

  if (uploadBtn && fileInput) {
    uploadBtn.addEventListener('click', (e) => {
      e.preventDefault();
      fileInput.click();
    });

    fileInput.addEventListener('change', (e) => {
      if (e.target.files.length > 0) {
        const file = e.target.files[0];
        console.log('Selected file:', file.name);
        // 파일 업로드 처리
        uploadPDF(file);
      }
    });
  }

  // 시험 답안 선택 처리
  const answerRadios = document.querySelectorAll('input[type="radio"][name^="answer_"]');
  answerRadios.forEach(radio => {
    radio.addEventListener('change', (e) => {
      const questionId = e.target.dataset.questionId;
      const answer = e.target.value;
      console.log(`Question ${questionId}: Selected answer ${answer}`);

      // 답안 저장
      saveAnswer(questionId, answer);

      // 진행률 업데이트
      updateProgress();
    });
  });

  // 시험 제출 버튼
  const submitBtn = document.getElementById('submit-test');
  if (submitBtn) {
    submitBtn.addEventListener('click', (e) => {
      if (!confirm('시험을 제출하시겠습니까? 제출 후에는 수정할 수 없습니다.')) {
        e.preventDefault();
      }
    });
  }

  // 타이머 시작 (시험 페이지에서만)
  if (document.querySelector('.test-timer')) {
    startTestTimer();
  }
});

// 파일 업로드 함수
function uploadPDF(file) {
  const formData = new FormData();
  formData.append('study_material[pdf]', file);

  const csrfToken = document.querySelector('meta[name="csrf-token"]').content;

  fetch('/study_materials', {
    method: 'POST',
    headers: {
      'X-CSRF-Token': csrfToken
    },
    body: formData
  })
  .then(response => response.json())
  .then(data => {
    if (data.success) {
      // Turbo를 사용하여 페이지 새로고침
      Turbo.visit(window.location.href);
    } else {
      alert('업로드 실패: ' + data.error);
    }
  })
  .catch(error => {
    console.error('Upload error:', error);
    alert('업로드 중 오류가 발생했습니다.');
  });
}

// 답안 저장 함수
function saveAnswer(questionId, answer) {
  const csrfToken = document.querySelector('meta[name="csrf-token"]').content;
  const sessionId = document.querySelector('[data-session-id]')?.dataset.sessionId;

  if (!sessionId) return;

  fetch(`/test_sessions/${sessionId}/save_answer`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'X-CSRF-Token': csrfToken
    },
    body: JSON.stringify({
      question_id: questionId,
      answer: answer
    })
  })
  .then(response => response.json())
  .then(data => {
    console.log('Answer saved:', data);
  })
  .catch(error => {
    console.error('Save error:', error);
  });
}

// 진행률 업데이트
function updateProgress() {
  const totalQuestions = document.querySelectorAll('.question-card').length;
  const answeredQuestions = document.querySelectorAll('input[type="radio"]:checked').length;
  const progressBar = document.querySelector('.progress-bar');
  const progressText = document.querySelector('.progress-text');

  if (progressBar && progressText) {
    const percentage = Math.round((answeredQuestions / totalQuestions) * 100);
    progressBar.style.width = `${percentage}%`;
    progressText.textContent = `${answeredQuestions}/${totalQuestions} 문제 완료`;
  }
}

// 타이머 기능
function startTestTimer() {
  const timerElement = document.querySelector('.test-timer');
  const timeLimit = parseInt(timerElement?.dataset.timeLimit || 60);
  let remainingTime = timeLimit * 60; // 분을 초로 변환

  const updateTimer = () => {
    const hours = Math.floor(remainingTime / 3600);
    const minutes = Math.floor((remainingTime % 3600) / 60);
    const seconds = remainingTime % 60;

    const display = hours > 0
      ? `${hours}시간 ${minutes}분 ${seconds}초`
      : `${minutes}분 ${seconds}초`;

    if (timerElement) {
      timerElement.textContent = `남은 시간: ${display}`;

      // 10분 남았을 때 경고
      if (remainingTime === 600) {
        alert('시험 종료까지 10분 남았습니다.');
        timerElement.classList.add('text-red-600', 'font-bold');
      }

      // 시간 초과 시 자동 제출
      if (remainingTime <= 0) {
        alert('시험 시간이 종료되었습니다. 자동으로 제출됩니다.');
        document.getElementById('submit-test')?.click();
        return;
      }
    }

    remainingTime--;
  };

  // 1초마다 타이머 업데이트
  updateTimer();
  setInterval(updateTimer, 1000);
}
