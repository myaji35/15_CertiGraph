#!/bin/bash

echo "📂 Downloads 폴더에서 Google OAuth JSON 파일 찾기..."
echo ""

# Downloads 폴더에서 최근 다운로드한 client_secret JSON 파일 찾기
JSON_FILE=$(ls -t ~/Downloads/client_secret*.json 2>/dev/null | head -1)

if [ -z "$JSON_FILE" ]; then
    JSON_FILE=$(ls -t ~/Downloads/*1074121262664*.json 2>/dev/null | head -1)
fi

if [ -f "$JSON_FILE" ]; then
    echo "✅ JSON 파일 발견: $JSON_FILE"
    echo ""
    echo "📋 OAuth 정보:"
    echo "-------------------"

    # JSON 파일에서 정보 추출
    CLIENT_ID=$(grep -o '"client_id":"[^"]*' "$JSON_FILE" | cut -d'"' -f4)
    CLIENT_SECRET=$(grep -o '"client_secret":"[^"]*' "$JSON_FILE" | cut -d'"' -f4)

    echo "Client ID: $CLIENT_ID"
    echo "Client Secret: $CLIENT_SECRET"
    echo ""

    # .env 파일 업데이트
    echo "💾 .env 파일 업데이트 중..."
    cat > .env << EOF
# Google OAuth2 Configuration
GOOGLE_CLIENT_ID=$CLIENT_ID
GOOGLE_CLIENT_SECRET=$CLIENT_SECRET
EOF

    echo "✅ .env 파일이 업데이트되었습니다!"
    echo ""
    cat .env
else
    echo "❌ JSON 파일을 찾을 수 없습니다."
    echo ""
    echo "📥 다음 단계를 따라주세요:"
    echo "1. Google Cloud Console에서 OAuth 클라이언트 옆 다운로드 버튼(⬇️) 클릭"
    echo "2. JSON 파일 다운로드"
    echo "3. 이 스크립트를 다시 실행"
fi