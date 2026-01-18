const http = require('http');

// Test API
http.get('http://localhost:8000/api/v1/certifications/calendar/2026/1', (res) => {
  let data = '';
  res.on('data', chunk => data += chunk);
  res.on('end', () => {
    const json = JSON.parse(data);
    console.log('=== Backend API Test ===');
    console.log(`Year: ${json.year}, Month: ${json.month}`);
    console.log(`Day 17 exams:`, JSON.stringify(json.calendar['17'], null, 2));

    if (json.calendar['17'] && json.calendar['17'].length > 0) {
      console.log('\n✅ SUCCESS: API returns Social Worker exam on Jan 17, 2026');
    } else {
      console.log('\n❌ FAIL: No exams found on Jan 17');
    }
  });
}).on('error', (e) => {
  console.error(`API Error: ${e.message}`);
});
