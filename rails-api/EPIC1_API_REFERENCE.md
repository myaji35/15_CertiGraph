# Epic 1: User Authentication - API Quick Reference

## Base URL
```
Development: http://localhost:3000
Production: https://your-domain.com
```

---

## Authentication Endpoints

### 1. Sign Up
```http
POST /signup
Content-Type: application/json

{
  "user": {
    "email": "user@example.com",
    "name": "John Doe",
    "password": "password123",
    "password_confirmation": "password123"
  }
}
```

### 2. Sign In
```http
POST /signin
Content-Type: application/json

{
  "user": {
    "email": "user@example.com",
    "password": "password123"
  }
}
```

### 3. Sign Out
```http
DELETE /logout
Authorization: Bearer {token}
```

### 4. Verify 2FA (During Login)
```http
POST /users/two_factor/verify_login
Content-Type: application/json

{
  "otp_code": "123456"
}
```

---

## OAuth Endpoints

### Google OAuth
```
GET /users/auth/google_oauth2
GET /users/auth/google_oauth2/callback (redirect)
```

### Kakao OAuth
```
GET /users/auth/kakao
GET /users/auth/kakao/callback (redirect)
```

### Naver OAuth
```
GET /users/auth/naver
GET /users/auth/naver/callback (redirect)
```

---

## Two-Factor Authentication

### Get 2FA Status
```http
GET /users/two_factor/status
Authorization: Bearer {token}
```

### Setup 2FA (Get QR Code)
```http
POST /users/two_factor/setup
Authorization: Bearer {token}
```

### Enable 2FA
```http
POST /users/two_factor/enable
Authorization: Bearer {token}
Content-Type: application/json

{
  "otp_code": "123456"
}
```

### Verify OTP
```http
POST /users/two_factor/verify
Authorization: Bearer {token}
Content-Type: application/json

{
  "otp_code": "123456"
}
```

### Disable 2FA
```http
DELETE /users/two_factor/disable
Authorization: Bearer {token}
Content-Type: application/json

{
  "otp_code": "123456",
  "password": "user-password"
}
```

### Regenerate Backup Codes
```http
POST /users/two_factor/backup_codes/regenerate
Authorization: Bearer {token}
Content-Type: application/json

{
  "otp_code": "123456"
}
```

### View Backup Codes
```http
GET /users/two_factor/backup_codes?otp_code=123456
Authorization: Bearer {token}
```

---

## Profile Management

### Get Profile
```http
GET /users/profile
Authorization: Bearer {token}
```

### Update Profile
```http
PATCH /users/profile
Authorization: Bearer {token}
Content-Type: application/json

{
  "name": "New Name",
  "bio": "My bio",
  "phone_number": "+821012345678"
}
```

### Upload Avatar
```http
POST /users/profile/upload_avatar
Authorization: Bearer {token}
Content-Type: multipart/form-data

avatar: <file>
```

### Delete Avatar
```http
DELETE /users/profile/delete_avatar
Authorization: Bearer {token}
```

### Get Login History
```http
GET /users/profile/login_history
Authorization: Bearer {token}
```

### Update Preferences
```http
PATCH /users/profile/update_preferences
Authorization: Bearer {token}
Content-Type: application/json

{
  "preferences": {
    "language": "ko",
    "theme": "dark",
    "timezone": "Asia/Seoul",
    "email_notifications": true
  }
}
```

### Update Notification Settings
```http
PATCH /users/profile/update_notification_settings
Authorization: Bearer {token}
Content-Type: application/json

{
  "notification_settings": {
    "email_login_alerts": true,
    "email_password_changes": true,
    "email_marketing": false,
    "push_notifications": true
  }
}
```

### Update Password
```http
PATCH /users/profile/update_password
Authorization: Bearer {token}
Content-Type: application/json

{
  "current_password": "old-password",
  "new_password": "new-password",
  "password_confirmation": "new-password"
}
```

### Deactivate Account
```http
POST /users/profile/deactivate_account
Authorization: Bearer {token}
Content-Type: application/json

{
  "password": "user-password"
}
```

### Reactivate Account
```http
POST /users/profile/reactivate_account
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "user-password"
}
```

### Request Account Deletion
```http
POST /users/profile/request_deletion
Authorization: Bearer {token}
Content-Type: application/json

{
  "password": "user-password"
}
```

### Cancel Account Deletion
```http
DELETE /users/profile/cancel_deletion
Authorization: Bearer {token}
```

---

## Session Management

### Get Active Sessions
```http
GET /users/sessions/active_sessions
Authorization: Bearer {token}
```

### Revoke All Sessions
```http
DELETE /users/sessions/revoke_all_sessions
Authorization: Bearer {token}
```

---

## Response Codes

### Success Responses
- `200 OK` - Request successful
- `201 Created` - Resource created successfully

### Error Responses
- `400 Bad Request` - Invalid request parameters
- `401 Unauthorized` - Authentication required or invalid credentials
- `403 Forbidden` - Insufficient permissions
- `404 Not Found` - Resource not found
- `422 Unprocessable Entity` - Validation errors
- `423 Locked` - Account locked due to failed attempts
- `500 Internal Server Error` - Server error

---

## Common Response Formats

### Success Response
```json
{
  "success": true,
  "message": "Operation completed successfully",
  "data": { ... }
}
```

### Error Response
```json
{
  "error": "Error message",
  "errors": ["Detailed error 1", "Detailed error 2"]
}
```

### User Object
```json
{
  "id": 1,
  "email": "user@example.com",
  "name": "John Doe",
  "display_name": "John Doe",
  "bio": "Software Developer",
  "phone_number": "+821012345678",
  "avatar_url": "https://...",
  "role": "free",
  "account_status": "active",
  "provider": "google_oauth2",
  "has_oauth": true,
  "has_password": true,
  "two_factor_enabled": true,
  "security_alerts_enabled": true,
  "preferences": {
    "language": "ko",
    "theme": "dark",
    "timezone": "Asia/Seoul"
  },
  "notification_settings": {
    "email_login_alerts": true,
    "email_password_changes": true
  },
  "created_at": "2026-01-15T10:00:00Z"
}
```

---

## Environment Variables Required

```bash
# Google OAuth
GOOGLE_CLIENT_ID=your-google-client-id
GOOGLE_CLIENT_SECRET=your-google-client-secret

# Kakao OAuth
KAKAO_CLIENT_ID=your-kakao-rest-api-key

# Naver OAuth
NAVER_CLIENT_ID=your-naver-client-id
NAVER_CLIENT_SECRET=your-naver-client-secret
```

---

## Testing with cURL

### Sign Up
```bash
curl -X POST http://localhost:3000/signup \
  -H "Content-Type: application/json" \
  -d '{
    "user": {
      "email": "test@example.com",
      "name": "Test User",
      "password": "password123",
      "password_confirmation": "password123"
    }
  }'
```

### Sign In
```bash
curl -X POST http://localhost:3000/signin \
  -H "Content-Type: application/json" \
  -d '{
    "user": {
      "email": "test@example.com",
      "password": "password123"
    }
  }'
```

### Get Profile
```bash
curl -X GET http://localhost:3000/users/profile \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
```

### Enable 2FA
```bash
# 1. Setup
curl -X POST http://localhost:3000/users/two_factor/setup \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"

# 2. Enable (after scanning QR code)
curl -X POST http://localhost:3000/users/two_factor/enable \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -H "Content-Type: application/json" \
  -d '{"otp_code": "123456"}'
```

---

## Rate Limiting

Currently not implemented, but recommended limits:
- Authentication endpoints: 5 requests per minute
- OAuth endpoints: 10 requests per minute
- Profile endpoints: 30 requests per minute
- 2FA verification: 5 requests per minute

---

## Security Notes

1. **Password Requirements**:
   - Minimum 6 characters
   - Maximum 128 characters

2. **Account Lockout**:
   - Triggered after 5 failed login attempts
   - Locked for 1 hour
   - Unlock via email or time-based strategy

3. **Session Timeout**:
   - 2 hours of inactivity
   - Automatically signs out

4. **2FA**:
   - Uses TOTP (Time-based One-Time Password)
   - 30-second time window
   - 10 backup codes generated
   - Backup codes are single-use

5. **OAuth**:
   - CSRF protection enabled
   - State parameter validation
   - Secure callback URLs only

---

## Support & Documentation

- **Devise**: https://github.com/heartcombo/devise
- **OmniAuth**: https://github.com/omniauth/omniauth
- **devise-two-factor**: https://github.com/tinfoil/devise-two-factor
- **RQRCode**: https://github.com/whomwah/rqrcode
