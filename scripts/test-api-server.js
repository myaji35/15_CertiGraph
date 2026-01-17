const express = require('express');
const cors = require('cors');

const app = express();
const PORT = 8015;

// Middleware
app.use(cors());
app.use(express.json());

// In-memory store for user data (would normally be a database)
const users = {};

// Middleware to extract user from token (for testing purposes)
const authenticateToken = (req, res, next) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];

  if (!token) {
    return res.status(401).json({ error: 'No token provided' });
  }

  // For testing, we'll just accept any token
  req.user = { token };
  next();
};

// Endpoint: Get marketing status for current user
app.get('/api/users/marketing-status', authenticateToken, (req, res) => {
  const token = req.user.token;

  // In a real app, you'd look up the user from the database
  // For now, return false (user did not agree to marketing)
  const user = users[token] || {};

  res.json({
    marketingAgreed: user.marketingAgreed || false,
    user_id: user.user_id
  });
});

// Endpoint: Set marketing status (for testing)
app.post('/api/users/marketing-status', authenticateToken, (req, res) => {
  const token = req.user.token;
  const { marketingAgreed } = req.body;

  users[token] = {
    ...users[token],
    marketingAgreed: marketingAgreed || false
  };

  res.json({
    marketingAgreed: users[token].marketingAgreed,
    message: 'Marketing preference updated'
  });
});

// Health check
app.get('/health', (req, res) => {
  res.json({ status: 'ok' });
});

// Start server
app.listen(PORT, () => {
  console.log(`Test API server running on http://localhost:${PORT}`);
  console.log('Available endpoints:');
  console.log('  GET /api/users/marketing-status');
  console.log('  POST /api/users/marketing-status');
  console.log('  GET /health');
});
