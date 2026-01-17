# React Best Practices (react-boilerplate 기반)

react-boilerplate의 검증된 패턴을 정리한 FE 개발 가이드.

## 1. Container/Component 분리 패턴

### 핵심 개념
**Smart(Container) vs Dumb(Component)** 분리로 관심사 분리 달성

```
┌─────────────────────────────────────────────────┐
│                   Container                      │
│  ┌─────────────────────────────────────────┐    │
│  │ • Redux Store 연결                       │    │
│  │ • 비즈니스 로직 처리                     │    │
│  │ • 데이터 페칭 트리거                     │    │
│  │ • 상태 관리                              │    │
│  └─────────────────────────────────────────┘    │
│                      ↓                           │
│  ┌─────────────────────────────────────────┐    │
│  │              Component                   │    │
│  │ • 순수 UI 렌더링                         │    │
│  │ • Props만 사용                           │    │
│  │ • 재사용 가능                            │    │
│  │ • 테스트 용이                            │    │
│  └─────────────────────────────────────────┘    │
└─────────────────────────────────────────────────┘
```

### 폴더 구조

```
app/
├── containers/           # Smart Components (Redux 연결)
│   └── HomePage/
│       ├── index.js      # Container 로직
│       ├── actions.js    # Action Creators
│       ├── constants.js  # Action Types
│       ├── reducer.js    # Reducer
│       ├── selectors.js  # Reselect Selectors
│       ├── saga.js       # Redux-Saga
│       ├── messages.js   # i18n 메시지
│       ├── Loadable.js   # 코드 스플리팅
│       └── tests/        # 테스트 파일
│
├── components/           # Dumb Components (순수 UI)
│   └── Button/
│       ├── index.js      # Component
│       ├── StyledButton.js # Styled-components
│       └── tests/
│
└── utils/                # 공유 유틸리티
```

### 적용 기준

| 구분 | Container | Component |
|------|-----------|-----------|
| Redux 연결 | ✅ Yes | ❌ No |
| 비즈니스 로직 | ✅ Yes | ❌ No |
| 재사용성 | 낮음 (페이지별) | 높음 (공용) |
| 테스트 방식 | Integration | Unit |
| 파일 위치 | containers/ | components/ |

---

## 2. Redux-Saga 패턴

### 핵심 개념
**Generator 기반 사이드 이펙트 관리** - 비동기 흐름을 동기적으로 작성

```javascript
// saga.js - API 호출 패턴
import { call, put, takeLatest } from 'redux-saga/effects';

export function* fetchUserSaga(action) {
  try {
    // 로딩 시작
    yield put({ type: 'FETCH_USER_REQUEST' });
    
    // API 호출 (call = 동기적 표현)
    const user = yield call(api.fetchUser, action.payload.userId);
    
    // 성공 처리
    yield put({ type: 'FETCH_USER_SUCCESS', payload: user });
  } catch (error) {
    // 에러 처리
    yield put({ type: 'FETCH_USER_FAILURE', error: error.message });
  }
}

// Watcher Saga
export default function* userSaga() {
  yield takeLatest('FETCH_USER', fetchUserSaga);
}
```

### Saga 패턴 유형

| 패턴 | Effect | 용도 |
|------|--------|------|
| 최신만 실행 | `takeLatest` | 검색, 자동완성 |
| 모두 실행 | `takeEvery` | 로깅, 알림 |
| 첫 번째만 | `take` | 로그인, 초기화 |
| 병렬 실행 | `all` | 여러 API 동시 호출 |
| 경쟁 | `race` | 타임아웃 처리 |

### 3단계 액션 패턴

```javascript
// constants.js
export const FETCH_USER = 'app/User/FETCH_USER';           // 요청
export const FETCH_USER_SUCCESS = 'app/User/FETCH_USER_SUCCESS';  // 성공
export const FETCH_USER_FAILURE = 'app/User/FETCH_USER_FAILURE';  // 실패

// reducer.js
const initialState = {
  user: null,
  loading: false,
  error: null,
};

function userReducer(state = initialState, action) {
  switch (action.type) {
    case FETCH_USER:
      return { ...state, loading: true, error: null };
    case FETCH_USER_SUCCESS:
      return { ...state, loading: false, user: action.payload };
    case FETCH_USER_FAILURE:
      return { ...state, loading: false, error: action.error };
    default:
      return state;
  }
}
```

---

## 3. Reselect 패턴

### 핵심 개념
**메모이제이션된 Selector**로 불필요한 리렌더링 방지

```javascript
// selectors.js
import { createSelector } from 'reselect';

// 기본 Selector (Input Selector)
const selectUserDomain = (state) => state.user;
const selectFilterDomain = (state) => state.filter;

// 메모이제이션 Selector (Output Selector)
export const makeSelectUser = () =>
  createSelector(selectUserDomain, (userState) => userState.user);

// 조합 Selector
export const makeSelectFilteredUsers = () =>
  createSelector(
    [selectUserDomain, selectFilterDomain],
    (userState, filter) => {
      const users = userState.users;
      if (!filter.keyword) return users;
      return users.filter((user) =>
        user.name.toLowerCase().includes(filter.keyword.toLowerCase())
      );
    }
  );
```

### Selector 3대 장점

| 특성 | 설명 | 효과 |
|------|------|------|
| **Computation** | 파생 데이터 계산 | Store 단순화 |
| **Memoization** | 입력 변경 시만 재계산 | 성능 최적화 |
| **Composability** | Selector 조합 가능 | 코드 재사용 |

### 사용 패턴

```javascript
// Container에서 사용
import { createStructuredSelector } from 'reselect';
import { makeSelectUser, makeSelectLoading } from './selectors';

const mapStateToProps = createStructuredSelector({
  user: makeSelectUser(),
  loading: makeSelectLoading(),
});
```

---

## 4. CLI 스캐폴딩 패턴

### 핵심 개념
**일관된 코드 생성**으로 보일러플레이트 제거

```bash
# Container 생성
npm run generate container HomePage

# 생성 파일:
# - containers/HomePage/index.js
# - containers/HomePage/actions.js
# - containers/HomePage/constants.js
# - containers/HomePage/reducer.js
# - containers/HomePage/selectors.js
# - containers/HomePage/saga.js
# - containers/HomePage/tests/index.test.js
# - containers/HomePage/tests/actions.test.js
# - containers/HomePage/tests/reducer.test.js
# - containers/HomePage/tests/selectors.test.js
# - containers/HomePage/tests/saga.test.js
```

### Plop Generator 설정

```javascript
// internals/generators/container/index.js
module.exports = {
  description: 'Add a container',
  prompts: [
    {
      type: 'input',
      name: 'name',
      message: 'What should it be called?',
    },
    {
      type: 'confirm',
      name: 'wantSaga',
      default: true,
      message: 'Do you want sagas for asynchronous flows?',
    },
  ],
  actions: (data) => {
    const actions = [
      {
        type: 'add',
        path: '../../app/containers/{{properCase name}}/index.js',
        templateFile: './container/index.js.hbs',
      },
      // ... 추가 파일들
    ];
    return actions;
  },
};
```

---

## 5. Styled-Components 패턴

### 핵심 개념
**CSS-in-JS**로 컴포넌트와 스타일 Co-location

```javascript
// StyledButton.js
import styled from 'styled-components';

const Button = styled.button`
  background: ${(props) => (props.primary ? '#007bff' : '#6c757d')};
  color: white;
  padding: 0.5rem 1rem;
  border: none;
  border-radius: 4px;
  cursor: pointer;

  &:hover {
    opacity: 0.9;
  }

  &:disabled {
    opacity: 0.5;
    cursor: not-allowed;
  }
`;

// 확장
const LargeButton = styled(Button)`
  padding: 1rem 2rem;
  font-size: 1.2rem;
`;

export { Button, LargeButton };
```

### 장점

| 특성 | 설명 |
|------|------|
| 스코프 격리 | 고유 클래스명 자동 생성 |
| 동적 스타일 | Props 기반 스타일 변경 |
| 최적화 | 사용된 스타일만 번들링 |
| 타입 안전성 | TypeScript 지원 |

---

## 6. Offline-First 패턴

### 핵심 개념
**Service Worker**로 오프라인 지원

```javascript
// sw.js (Service Worker)
const CACHE_NAME = 'app-v1';
const urlsToCache = ['/', '/static/js/bundle.js', '/static/css/main.css'];

self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(CACHE_NAME).then((cache) => cache.addAll(urlsToCache))
  );
});

self.addEventListener('fetch', (event) => {
  event.respondWith(
    caches.match(event.request).then((response) => {
      // 캐시에 있으면 캐시 반환, 없으면 네트워크 요청
      return response || fetch(event.request);
    })
  );
});
```

### 캐싱 전략

| 전략 | 설명 | 용도 |
|------|------|------|
| Cache First | 캐시 우선, 없으면 네트워크 | 정적 자산 |
| Network First | 네트워크 우선, 실패 시 캐시 | API 데이터 |
| Stale While Revalidate | 캐시 반환 + 백그라운드 갱신 | 뉴스, 피드 |

---

## 7. 테스트 전략

### 테스트 피라미드

```
         ┌───────┐
         │  E2E  │  10% - Cypress/Playwright
         ├───────┤
         │ Integ │  20% - Container 테스트
         ├───────┤
         │ Unit  │  70% - Component, Reducer, Saga
         └───────┘
```

### 테스트 유형별 패턴

```javascript
// Reducer 테스트
describe('userReducer', () => {
  it('should return initial state', () => {
    expect(userReducer(undefined, {})).toEqual(initialState);
  });

  it('should handle FETCH_USER_SUCCESS', () => {
    const user = { id: 1, name: 'Test' };
    const action = { type: FETCH_USER_SUCCESS, payload: user };
    expect(userReducer(initialState, action)).toEqual({
      ...initialState,
      user,
    });
  });
});

// Saga 테스트
describe('fetchUserSaga', () => {
  it('should fetch user successfully', () => {
    const gen = fetchUserSaga({ payload: { userId: 1 } });
    
    expect(gen.next().value).toEqual(put({ type: 'FETCH_USER_REQUEST' }));
    expect(gen.next().value).toEqual(call(api.fetchUser, 1));
    expect(gen.next({ id: 1 }).value).toEqual(
      put({ type: 'FETCH_USER_SUCCESS', payload: { id: 1 } })
    );
  });
});

// Component 테스트 (React Testing Library)
describe('Button', () => {
  it('should render correctly', () => {
    render(<Button>Click me</Button>);
    expect(screen.getByText('Click me')).toBeInTheDocument();
  });

  it('should call onClick when clicked', () => {
    const onClick = jest.fn();
    render(<Button onClick={onClick}>Click</Button>);
    fireEvent.click(screen.getByText('Click'));
    expect(onClick).toHaveBeenCalledTimes(1);
  });
});
```

---

## 8. i18n 국제화 패턴

### react-intl 사용

```javascript
// messages.js
import { defineMessages } from 'react-intl';

export default defineMessages({
  header: {
    id: 'app.components.Header.header',
    defaultMessage: 'Welcome to the app',
  },
  greeting: {
    id: 'app.components.Header.greeting',
    defaultMessage: 'Hello, {name}!',
  },
});

// Component에서 사용
import { FormattedMessage } from 'react-intl';
import messages from './messages';

const Header = ({ name }) => (
  <h1>
    <FormattedMessage {...messages.greeting} values={{ name }} />
  </h1>
);
```

---

## 9. 코드 스플리팅 패턴

### React Loadable 사용

```javascript
// Loadable.js
import loadable from '@loadable/component';
import LoadingIndicator from 'components/LoadingIndicator';

export default loadable(() => import('./index'), {
  fallback: <LoadingIndicator />,
});

// App.js에서 사용
import HomePage from 'containers/HomePage/Loadable';

const App = () => (
  <Routes>
    <Route path="/" element={<HomePage />} />
  </Routes>
);
```

---

## 10. 성능 최적화 체크리스트

### 빌드 최적화
- [ ] Code Splitting 적용
- [ ] Tree Shaking 활성화
- [ ] 번들 분석 (webpack-bundle-analyzer)
- [ ] 이미지 최적화
- [ ] Gzip/Brotli 압축

### 런타임 최적화
- [ ] React.memo 적용 (순수 컴포넌트)
- [ ] useMemo/useCallback 활용
- [ ] Reselect로 Selector 메모이제이션
- [ ] 가상화 (react-window) - 대량 리스트
- [ ] Lazy Loading

### 모니터링
- [ ] Lighthouse 점수 확인
- [ ] Web Vitals (LCP, FID, CLS)
- [ ] 에러 트래킹 (Sentry)

---

## FE 에이전트 체크리스트

프론트엔드 구현 시 확인 사항:

### 아키텍처
- [ ] Container/Component 분리 적용
- [ ] 폴더 구조 일관성
- [ ] 공용 컴포넌트 추출

### 상태 관리
- [ ] Redux 액션 3단계 패턴 (Request/Success/Failure)
- [ ] Saga로 사이드 이펙트 처리
- [ ] Selector 메모이제이션

### 스타일
- [ ] Styled-components Co-location
- [ ] 테마/디자인 토큰 활용
- [ ] 반응형 브레이크포인트

### 테스트
- [ ] 단위 테스트 (Component, Reducer)
- [ ] 통합 테스트 (Container)
- [ ] 커버리지 80% 이상

### 성능
- [ ] 코드 스플리팅 적용
- [ ] 메모이제이션 적용
- [ ] 번들 사이즈 확인
