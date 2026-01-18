# Rails 개발 참고 가이드
# PRD에서 추출한 Rails 개발 시 주의사항
# Date: 2026-01-11

## 1. Tailwind CSS 버전 문제 (가장 중요!)

### ❌ 문제점
- `tailwindcss-rails` gem의 최신 버전(v4)은 Rails 8과 호환성 문제 발생
- 파일 경로 차이: Tailwind v3와 v4의 설정 파일 위치가 다름
- 동적 클래스 처리: PurgeCSS가 ERB 템플릿의 동적 클래스를 제거하는 문제

### ✅ 해결책
```ruby
# Gemfile - 반드시 v2.0 사용!
gem "tailwindcss-rails", "~> 2.0"  # v3를 사용하는 2.x 버전 명시
```

```javascript
// config/tailwind.config.js (올바른 위치 - config 폴더!)
module.exports = {
  content: [
    './public/*.html',
    './app/helpers/**/*.rb',
    './app/javascript/**/*.js',
    './app/views/**/*.{erb,haml,html,slim}'
  ],
  safelist: [
    // 동적으로 생성되는 클래스들을 safelist에 추가
    'bg-green-500', 'bg-yellow-500', 'bg-red-500',
    'bg-blue-600', 'bg-blue-700'
  ]
}
```

```erb
<!-- application.html.erb -->
<%= stylesheet_link_tag "tailwind", "data-turbo-track": "reload" %>
```

## 2. Stimulus 컨트롤러 로딩 실패 대응

### ❌ 문제점
- Rails 8의 importmap 설정 누락으로 Stimulus 컨트롤러 미작동
- 404 에러로 JavaScript 파일이 로드되지 않음

### ✅ 해결책

#### 1) Importmap 설정
```ruby
# config/importmap.rb
pin "application", preload: true
pin "@hotwired/turbo-rails", to: "turbo.min.js", preload: true
pin "@hotwired/stimulus", to: "stimulus.min.js", preload: true
pin_all_from "app/javascript/controllers", under: "controllers"
```

#### 2) Fallback 스크립트 패턴 (중요!)
```javascript
// Stimulus가 작동하지 않을 경우를 위한 백업 초기화
document.addEventListener('DOMContentLoaded', function() {
  setTimeout(function() {
    if (typeof YourLibrary !== 'undefined') {
      const container = document.querySelector('[data-target="container"]');
      if (container && container.children.length === 0) {
        // 직접 초기화 코드
        console.log('Fallback 초기화 실행');
        // 초기화 로직...
      }
    }
  }, 1000);
});
```

## 3. 파일 구조 체크리스트

### 필수 파일 위치 (자주 실수하는 부분!)
```
✅ app/assets/stylesheets/application.tailwind.css - Tailwind 진입점
✅ config/tailwind.config.js - Tailwind 설정 (루트가 아닌 config 폴더!)
✅ app/assets/builds/tailwind.css - 컴파일된 CSS 출력
✅ app/javascript/application.js - JavaScript 진입점
✅ config/importmap.rb - Import map 설정
✅ app/javascript/controllers/ - Stimulus 컨트롤러 폴더
```

## 4. 개발 서버 실행 방법

### 올바른 실행 방법
```bash
# Foreman을 사용한 동시 실행 (추천)
gem install foreman
bin/dev

# 또는 개별 실행
rails tailwindcss:watch  # 터미널 1
rails server            # 터미널 2

# Ruby 버전 명시 실행 (rbenv 사용 시)
/Users/[username]/.rbenv/versions/3.3.0/bin/rails server
```

## 5. Asset Pipeline 설정

```ruby
# config/application.rb
config.assets.paths << Rails.root.join("app/assets/builds")
```

## 6. 외부 JavaScript 라이브러리 통합 시 주의사항

### Script 로딩 순서
```erb
<!-- application.html.erb -->
<!-- 외부 스크립트를 Stimulus보다 먼저 로드! -->
<script type="text/javascript" src="//external-api.js"></script>
<%= javascript_importmap_tags %>

<script>
  // API 로드 확인 스크립트
  window.apiReady = false;
  if (typeof ExternalAPI !== 'undefined') {
    window.apiReady = true;
  } else {
    const checkAPI = setInterval(() => {
      if (typeof ExternalAPI !== 'undefined') {
        window.apiReady = true;
        clearInterval(checkAPI);
      }
    }, 100);
  }
</script>
```

## 7. 디버깅 체크리스트

### CSS가 적용되지 않을 때
1. ✅ `tailwindcss-rails` 버전이 2.x인지 확인
2. ✅ `config/tailwind.config.js` 파일이 올바른 위치에 있는지 확인
3. ✅ `application.html.erb`에 `stylesheet_link_tag "tailwind"` 포함 여부
4. ✅ `rails tailwindcss:build` 실행 후 `app/assets/builds/tailwind.css` 파일 크기 확인
5. ✅ 브라우저 캐시 삭제 후 새로고침 (Cmd+Shift+R)

### JavaScript가 작동하지 않을 때
1. ✅ 브라우저 개발자 콘솔(F12)에서 JavaScript 에러 확인
2. ✅ `typeof Stimulus` 콘솔에서 확인
3. ✅ Network 탭에서 404 에러 확인
4. ✅ `rails importmap:install` 실행
5. ✅ Fallback 스크립트가 실행되는지 콘솔 로그 확인

## 8. Rails 8 + SQLite3 Production 설정

```ruby
# SQLite3를 Production에서도 사용할 때
gem "solid_queue"  # 비동기 작업 큐
gem "solid_cache"  # 캐싱
```

## 9. 자주 하는 실수와 해결

### 실수 1: Tailwind 클래스가 동적으로 생성될 때
```erb
<!-- ❌ 잘못된 예 - PurgeCSS가 제거함 -->
<div class="<%= "bg-#{color}-500" %>">

<!-- ✅ 올바른 예 - safelist에 추가하거나 전체 클래스명 사용 -->
<div class="<%= status == 'danger' ? 'bg-red-500' : 'bg-green-500' %>">
```

### 실수 2: Stimulus 컨트롤러 명명
```javascript
// ❌ 잘못된 예
// app/javascript/controllers/MapController.js

// ✅ 올바른 예 - snake_case 사용
// app/javascript/controllers/map_controller.js
```

### 실수 3: Turbo Frame 새로고침
```erb
<!-- ❌ 페이지 전체 새로고침 -->
<%= link_to "보기", place_path(place) %>

<!-- ✅ Turbo Frame만 업데이트 -->
<%= link_to "보기", place_path(place),
    data: { turbo_frame: "place_detail" } %>
```

## 10. 프로젝트 초기 설정 명령어 모음

```bash
# 새 Rails 8 프로젝트 생성
rails new project_name --css tailwind --database sqlite3

# Tailwind CSS v2.0으로 다운그레이드
bundle add tailwindcss-rails -v "~> 2.0"
bundle install

# Stimulus 설치
rails stimulus:install

# Importmap 설치
rails importmap:install

# 개발 서버 실행
bin/dev

# 문제 발생 시 재설정
rails assets:clean
rails assets:precompile
rails tailwindcss:build
```

## 11. 핵심 요약

### 🔴 반드시 기억할 3가지
1. **Tailwind CSS는 v2.0 gem 사용** (v4는 호환성 문제)
2. **config/tailwind.config.js 위치** (루트 아님)
3. **Stimulus 실패 시 Fallback 스크립트 준비**

### 🟡 자주 놓치는 설정
- Asset Pipeline에 builds 폴더 추가
- 동적 Tailwind 클래스는 safelist에 추가
- 외부 JavaScript는 importmap보다 먼저 로드

### 🟢 개발 워크플로우
1. `bin/dev`로 개발 서버 실행
2. 브라우저 콘솔에서 에러 확인
3. 문제 시 개별 프로세스로 분리 실행

---

**Note:** 이 문서는 실제 Smart Town Control Center MVP 개발 중 발생한 문제들과 해결 방법을 정리한 것입니다.
다른 Rails 8 프로젝트에서도 동일한 문제가 발생할 수 있으므로 참고하세요.