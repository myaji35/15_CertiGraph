# Google OAuth 2.0 설정 가이드

## 1. Google Cloud Console 접속
1. [Google Cloud Console](https://console.cloud.google.com/) 접속
2. Google 계정으로 로그인

## 2. 프로젝트 생성/선택
1. 상단 프로젝트 선택 드롭다운 클릭
2. "새 프로젝트" 클릭
3. 프로젝트 이름: "ExamsGraph" 입력
4. "만들기" 클릭

## 3. OAuth 동의 화면 구성
1. 왼쪽 메뉴에서 "APIs 및 서비스" > "OAuth 동의 화면" 클릭
2. User Type 선택:
   - **외부(External)** 선택 (모든 Google 사용자가 로그인 가능)
   - "만들기" 클릭
3. 앱 정보 입력:
   - 앱 이름: **ExamsGraph**
   - 사용자 지원 이메일: **your-email@gmail.com**
   - 앱 도메인: 비워두기 (개발 중)
   - 개발자 연락처 정보: **your-email@gmail.com**
4. "저장 후 계속" 클릭
5. 범위 설정:
   - "범위 추가 또는 삭제" 클릭
   - 다음 범위 선택:
     - `../auth/userinfo.email`
     - `../auth/userinfo.profile`
   - "업데이트" 클릭
   - "저장 후 계속" 클릭
6. 테스트 사용자:
   - 지금은 건너뛰기 (나중에 추가 가능)
   - "저장 후 계속" 클릭

## 4. OAuth 2.0 클라이언트 ID 생성
1. "APIs 및 서비스" > "사용자 인증 정보" 클릭
2. 상단의 "+ 사용자 인증 정보 만들기" 클릭
3. "OAuth 클라이언트 ID" 선택
4. 애플리케이션 유형: **웹 애플리케이션** 선택
5. 이름: **ExamsGraph Web Client** 입력
6. 승인된 JavaScript 원본:
   ```
   http://localhost:3000
   ```
7. 승인된 리디렉션 URI:
   ```
   http://localhost:3000/users/auth/google_oauth2/callback
   ```
8. "만들기" 클릭

## 5. 자격 증명 복사
생성 완료 팝업에서:
- **클라이언트 ID**: `xxxx.apps.googleusercontent.com` 형태
- **클라이언트 보안 비밀**: 긴 문자열

이 값들을 복사하여 저장하세요.

## 6. Rails 애플리케이션에 적용
`.env` 파일에 복사한 값들을 붙여넣기:
```
GOOGLE_CLIENT_ID=your-actual-client-id.apps.googleusercontent.com
GOOGLE_CLIENT_SECRET=your-actual-client-secret
```

## 7. 서버 재시작
```bash
# Rails 서버 재시작
rails server
```

## 문제 해결

### "401 오류: invalid_client" 발생 시:
1. 클라이언트 ID와 Secret이 정확히 복사되었는지 확인
2. `.env` 파일이 올바른 위치에 있는지 확인
3. 리디렉션 URI가 정확히 일치하는지 확인

### "리디렉션 URI 불일치" 오류 발생 시:
1. Google Cloud Console에서 리디렉션 URI 확인
2. 반드시 다음 형식으로 입력:
   ```
   http://localhost:3000/users/auth/google_oauth2/callback
   ```
3. 끝에 슬래시(`/`)가 없어야 함

### 테스트 모드 제한:
- OAuth 동의 화면이 "테스트" 상태일 경우, 100명의 테스트 사용자만 로그인 가능
- 프로덕션 전환을 위해서는 Google 검토 필요

## 프로덕션 배포 시
1. 프로덕션 도메인으로 리디렉션 URI 추가
2. OAuth 동의 화면을 "프로덕션"으로 전환
3. 필요시 Google 검토 요청