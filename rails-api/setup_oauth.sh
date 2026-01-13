#!/bin/bash

echo "🔧 Google OAuth 2.0 설정 도우미"
echo "================================"
echo ""
echo "이 스크립트는 Google OAuth 설정을 도와드립니다."
echo ""
echo "📋 다음 단계를 따라주세요:"
echo ""
echo "1. Google Cloud Console 열기:"
echo "   https://console.cloud.google.com/"
echo ""
echo "2. 새 프로젝트 생성 또는 선택"
echo ""
echo "3. OAuth 동의 화면 설정:"
echo "   - APIs 및 서비스 > OAuth 동의 화면"
echo "   - 외부(External) 선택"
echo "   - 앱 이름: ExamsGraph"
echo ""
echo "4. OAuth 2.0 클라이언트 ID 생성:"
echo "   - APIs 및 서비스 > 사용자 인증 정보"
echo "   - '+ 사용자 인증 정보 만들기' > OAuth 클라이언트 ID"
echo "   - 웹 애플리케이션 선택"
echo "   - 승인된 리디렉션 URI 추가:"
echo "     http://localhost:3000/users/auth/google_oauth2/callback"
echo ""
echo "5. 생성된 자격 증명을 입력해주세요:"
echo ""

read -p "Google Client ID (xxxx.apps.googleusercontent.com): " client_id
read -p "Google Client Secret: " client_secret

# .env 파일 생성
cat > .env << EOF
# Google OAuth2 Configuration
GOOGLE_CLIENT_ID=$client_id
GOOGLE_CLIENT_SECRET=$client_secret

# Rails Configuration
RAILS_ENV=development
EOF

echo ""
echo "✅ .env 파일이 생성되었습니다!"
echo ""
echo "📝 .env 파일 내용:"
cat .env
echo ""
echo "🚀 이제 Rails 서버를 재시작하세요:"
echo "   rails server"
echo ""
echo "✨ 완료되었습니다!"