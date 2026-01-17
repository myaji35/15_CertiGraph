const http = require('http');
const fs = require('fs');
const path = require('path');

const PORT = 8080;
const MOCK_DATA_PATH = path.join(__dirname, 'mock-exam-data.json');

// Helper to send JSON responses
const sendJSON = (res, statusCode, data) => {
  res.setHeader('Content-Type', 'application/json');
  // Allow CORS for testing purposes
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');
  res.writeHead(statusCode);
  res.end(JSON.stringify(data));
};

// Load mock data from file
let mockExamData;
try {
  mockExamData = JSON.parse(fs.readFileSync(MOCK_DATA_PATH, 'utf8'));
  console.log('✅ Mock exam data loaded successfully.');
} catch (error) {
  console.error('❌ Error loading mock exam data:', error);
  process.exit(1);
}

const server = http.createServer((req, res) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    sendJSON(res, 204, null);
    return;
  }

  console.log(`[${new Date().toISOString()}] Received ${req.method} request for ${req.url}`);

  // --- Endpoint: Start Test ---
  if (req.method === 'POST' && req.url === '/v1/tests/start') {
    console.log('🚀 Handling POST /v1/tests/start');
    sendJSON(res, 201, mockExamData);
    return;
  }

  // --- Endpoint: Submit Test ---
  if (req.method === 'POST' && req.url.startsWith('/v1/tests/submit')) {
    console.log('📝 Handling POST /v1/tests/submit');
    let body = '';
    req.on('data', chunk => {
      body += chunk.toString();
    });
    req.on('end', () => {
      try {
        const submission = JSON.parse(body);
        const answers = submission.answers || [];
        
        let score = 0;
        const resultsByQuestion = {};

        // Grade the submission
        mockExamData.questions.forEach(q => {
          const userAnswer = answers.find(a => a.question_id === q.id);
          if (userAnswer) {
            const isCorrect = userAnswer.selected_option === q.correct_option_index;
            if (isCorrect) {
              score++;
            }
            resultsByQuestion[q.id] = {
              is_correct: isCorrect,
              user_selected: userAnswer.selected_option,
              correct_option: q.correct_option_index
            };
          }
        });

        const result = {
          session_id: submission.session_id || 'mock-session-123',
          score: score,
          total: mockExamData.questions.length,
          percentage: (score / mockExamData.questions.length) * 100,
          time_taken_seconds: 1500, // Mock value
          results: resultsByQuestion
        };
        
        sendJSON(res, 200, { data: result });

      } catch (e) {
        console.error('Error processing submission:', e);
        sendJSON(res, 400, { error: 'Invalid request body' });
      }
    });
    return;
  }
  
  // --- Endpoint: Get Test Result ---
  if (req.method === 'GET' && req.url.match(/^\/v1\/tests\/result\/mock-session-123\/?$/)) {
      console.log('📊 Handling GET /v1/tests/result/mock-session-123');
      
      // Create a mock result based on some predefined answers
      const score = 2;
      const total = mockExamData.questions.length;
      const percentage = (score / total) * 100;

      const mockResult = {
          session_id: "mock-session-123",
          study_set_name: mockExamData.study_set_name,
          score,
          total,
          percentage,
          time_taken_seconds: 1834,
          completed_at: new Date().toISOString(),
          questions: mockExamData.questions.map((q, i) => ({
              ...q,
              user_selected: i < 2 ? q.correct_option_index : (q.correct_option_index + 1) % 5, // First 2 correct, last one wrong
              is_correct: i < 2,
              explanation: `이 문제의 정답은 ${q.correct_option_index + 1}번 입니다. ${i < 2 ? '맞히셨습니다!' : '다시 확인해보세요.'}`
          }))
      };
      
      sendJSON(res, 200, { data: mockResult });
      return;
  }


  // --- Not Found ---
  console.log(`❌ Route not found: ${req.method} ${req.url}`);
  sendJSON(res, 404, { error: 'Not Found' });
});

server.listen(PORT, () => {
  console.log(`🚀 Mock Exam API server running on http://localhost:${PORT}`);
  console.log('Available endpoints:');
  console.log('  POST /v1/tests/start');
  console.log('  POST /v1/tests/submit');
  console.log('  GET /v1/tests/result/mock-session-123');
});
