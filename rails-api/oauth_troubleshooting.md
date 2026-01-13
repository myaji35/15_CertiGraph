# OAuth 문제 해결 가이드

## 🔴 문제: redirect_uri_mismatch 오류가 계속 발생

## ✅ 해결 시나리오들:

### 시나리오 1: **브라우저 캐시 문제**
1. 시크릿/프라이빗 모드로 테스트
2. 또는 다른 브라우저로 테스트 (Chrome → Safari)

### 시나리오 2: **잘못된 Client ID**
현재 .env의 Client ID:
- `273058247956-nv6jple4jksd97iil16buf6ite6sjf5h`

Google Console의 "ExamsGraph Rails" Client ID와 다를 수 있음

### 시나리오 3: **새 OAuth 클라이언트 생성** (가장 확실)

1. Google Cloud Console 접속
2. "사용자 인증 정보" 페이지
3. **"+ 사용자 인증 정보 만들기"** → **"OAuth 클라이언트 ID"**
4. 설정:
   - 애플리케이션 유형: **웹 애플리케이션**
   - 이름: `ExamsGraph-Rails-New`
   - 승인된 JavaScript 원본:
     ```
     http://localhost:3000
     ```
   - 승인된 리디렉션 URI:
     ```
     http://localhost:3000/users/auth/google_oauth2/callback
     ```
5. **"만들기"** 클릭
6. 새로운 Client ID와 Secret 복사
7. .env 파일 업데이트

### 시나리오 4: **다른 클라이언트 사용**
목록에 있는 다른 OAuth 클라이언트 중 하나 사용:
- `towninhub` (1074121262664-0s8...)
- `townin.net` (1074121262664-p3u...)

이 클라이언트들의 JSON 다운로드 후 Client Secret 확인

### 시나리오 5: **Devise/OmniAuth 설정 문제**
```ruby
# config/initializers/omniauth.rb 확인
Rails.application.config.middleware.use OmniAuth::Builder do
  provider :google_oauth2,
    ENV['GOOGLE_CLIENT_ID'],
    ENV['GOOGLE_CLIENT_SECRET'],
    {
      scope: 'email,profile',
      prompt: 'select_account',
      skip_jwt: true  # 추가해보기
    }
end
```

## 🎯 즉시 시도해볼 것:

1. **시크릿 모드로 테스트**
   - Chrome: Cmd+Shift+N
   - Safari: Cmd+Shift+N

2. **환경변수 확인**
   ```bash
   echo $GOOGLE_CLIENT_ID
   echo $GOOGLE_CLIENT_SECRET
   ```

3. **Rails 콘솔에서 확인**
   ```bash
   rails console
   > ENV['GOOGLE_CLIENT_ID']
   > ENV['GOOGLE_CLIENT_SECRET']
   ```

4. **새 OAuth 클라이언트 생성** (가장 확실한 방법)