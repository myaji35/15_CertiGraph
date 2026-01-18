# 시험 직전 컨닝페이퍼 사용 가이드

## 개요

GraphRAG 분석 시스템을 활용하여 시험 직전에 출력할 수 있는 1-2페이지 압축 요약 레포트를 자동 생성합니다.

## 주요 기능

### 1. 긴급 취약점 TOP 5
- 취약도 70% 이상의 심각한 개념만 선별
- 각 취약점별 예상 학습 시간 제공
- 빠른 복습을 위한 핵심 팁 포함

### 2. 우선순위 체크리스트
- 시험 전 반드시 복습해야 할 개념 TOP 10
- 체크박스 형식으로 진도 관리 가능
- 취약도 순으로 자동 정렬

### 3. 핵심 개념 플래시카드
- 암기해야 할 핵심 개념 10-15개
- 개념명 + 1문장 정의
- 우선순위 표시 (🔴 긴급, 🟡 중요, 🟢 일반)

### 4. 예상 성적 향상
- 현재 예상 점수 vs 복습 후 예상 점수
- 합격 확률 예측
- 데이터 기반 동기부여

## API 사용법

### 엔드포인트

```bash
# 1. 컨닝페이퍼 생성 (JSON)
GET /api/v1/study_sets/:id/cheat_sheet

# 2. 컨닝페이퍼 다운로드 (Markdown)
GET /api/v1/study_sets/:id/cheat_sheet/pdf
```

### 요청 예시

```bash
# cURL
curl -X GET "http://localhost:8000/api/v1/study_sets/1/cheat_sheet" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json"

# HTTPie
http GET http://localhost:8000/api/v1/study_sets/1/cheat_sheet \
  Authorization:"Bearer YOUR_TOKEN"
```

### 응답 예시

```json
{
  "success": true,
  "data": {
    "student_name": "홍길동",
    "exam_name": "사회복지사 1급",
    "generated_date": "2026년 01월 18일",
    "confidence_score": 78,
    "current_score": 64,
    "predicted_score": 79,
    "improvement": 15,
    "pass_probability": 85,
    "total_questions": 45
  },
  "markdown": "# 🎯 시험 직전 컨닝페이퍼\n\n...",
  "html": "<h1>🎯 시험 직전 컨닝페이퍼</h1>...",
  "generated_at": "2026-01-18T16:05:00+09:00"
}
```

## Rails Console 사용법

```ruby
# 1. 서비스 직접 호출
service = CheatSheetGeneratorService.new
user = User.find(1)
study_set = StudySet.find(1)

report = service.generate_for_user(user, study_set)

# 2. Markdown 출력
puts report[:markdown]

# 3. 파일로 저장
File.write("cheat_sheet_#{Date.today}.md", report[:markdown])

# 4. 데이터만 확인
pp report[:data]
```

## 실제 출력 예시

```markdown
# 🎯 시험 직전 컨닝페이퍼

**수험생**: 홍길동  
**시험**: 사회복지사 1급  
**생성일**: 2026년 01월 18일  
**분석 신뢰도**: 78%

---

## 🚨 긴급! 반드시 복습해야 할 취약점 TOP 5

### 🔴 1. 소득 재분배 이론

- **취약도**: 85% (critical)
- **영향받는 문제**: 12개
- **예상 학습 시간**: 30분
- **핵심 팁**: 소득 재분배 이론의 정의와 예시를 암기하세요

### 🔴 2. 사회복지 행정 조직론

- **취약도**: 78% (critical)
- **영향받는 문제**: 8개
- **예상 학습 시간**: 30분
- **핵심 팁**: 사회복지 행정 조직론의 정의와 예시를 암기하세요

### 🟡 3. 사회복지 실천 기술

- **취약도**: 65% (high)
- **영향받는 문제**: 6개
- **예상 학습 시간**: 20분
- **핵심 팁**: 사회복지 실천 기술의 정의와 예시를 암기하세요

---

## ✅ 시험 전 우선순위 체크리스트

- [ ] **1순위**: 소득 재분배 이론 (30분) - 취약도 85%
- [ ] **2순위**: 사회복지 행정 조직론 (30분) - 취약도 78%
- [ ] **3순위**: 사회복지 실천 기술 (20분) - 취약도 65%
- [ ] **4순위**: 지역사회 복지론 (20분) - 취약도 58%
- [ ] **5순위**: 사회복지 법제 (20분) - 취약도 52%

---

## 💡 핵심 개념 플래시카드

#### 🔴 소득 재분배 이론

소득 재분배 이론에 대한 핵심 개념 정리 (교재 참조)

#### 🔴 복지 국가 유형

복지 국가 유형에 대한 핵심 개념 정리 (교재 참조)

#### 🟡 사회복지 행정

사회복지 행정에 대한 핵심 개념 정리 (교재 참조)

---

## ⚠️ 실수 방지 팁

⚠️ **시간 배분 실수**: 어려운 문제에 너무 많은 시간 소비하지 마세요
⚠️ **문제 오독**: 문제를 끝까지 꼼꼼히 읽으세요
⚠️ **개념 혼동**: 소득 재분배 이론와 유사 개념을 구분하세요

---

## 📊 예상 성적 향상

현재 예상 점수: **64점**  
복습 후 예상 점수: **79점** (▲ 15점)  
합격 확률: **85%**

---

*이 레포트는 GraphRAG 분석 시스템이 45개 문제 분석을 바탕으로 자동 생성했습니다.*  
*마지막 업데이트: 2026-01-18 16:05:00*
```

## 프론트엔드 통합

### React 컴포넌트 예시

```typescript
import { useState } from 'react';

function CheatSheetGenerator({ studySetId }: { studySetId: number }) {
  const [loading, setLoading] = useState(false);
  const [cheatSheet, setCheatSheet] = useState(null);

  const generateCheatSheet = async () => {
    setLoading(true);
    try {
      const response = await fetch(
        `/api/v1/study_sets/${studySetId}/cheat_sheet`,
        {
          headers: {
            'Authorization': `Bearer ${getToken()}`,
          },
        }
      );
      const data = await response.json();
      setCheatSheet(data);
    } catch (error) {
      console.error('Failed to generate cheat sheet:', error);
    } finally {
      setLoading(false);
    }
  };

  const downloadMarkdown = () => {
    const blob = new Blob([cheatSheet.markdown], { type: 'text/markdown' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `cheat_sheet_${new Date().toISOString()}.md`;
    a.click();
  };

  return (
    <div>
      <button onClick={generateCheatSheet} disabled={loading}>
        {loading ? '생성 중...' : '컨닝페이퍼 생성'}
      </button>
      
      {cheatSheet && (
        <div>
          <button onClick={downloadMarkdown}>
            Markdown 다운로드
          </button>
          <div dangerouslySetInnerHTML={{ __html: cheatSheet.html }} />
        </div>
      )}
    </div>
  );
}
```

## 출력 및 사용 시나리오

### 시나리오 1: 시험 전날 밤

1. 사용자가 "컨닝페이퍼 생성" 버튼 클릭
2. GraphRAG 분석 기반 1-2페이지 레포트 생성
3. Markdown 다운로드 또는 바로 출력
4. 취약점 TOP 5를 집중 복습 (총 1.5시간)
5. 체크리스트 완료하며 진도 확인

### 시나리오 2: 시험 당일 아침

1. 저장해둔 컨닝페이퍼 출력물 확인
2. 핵심 개념 플래시카드 10분 암기
3. 실수 방지 팁 숙지
4. 자신감 있게 시험장 입장

### 시나리오 3: 시험 직전 대기실

1. 모바일로 컨닝페이퍼 확인
2. 우선순위 체크리스트 최종 점검
3. 긴급 취약점 개념 마지막 복습
4. 예상 점수 확인하며 동기부여

## 향후 개선 사항

### Phase 2
- [ ] PDF 생성 기능 (Prawn gem)
- [ ] 이미지/다이어그램 포함
- [ ] 맞춤형 레이아웃 (1페이지/2페이지 선택)

### Phase 3
- [ ] 모바일 최적화 뷰
- [ ] 인쇄 최적화 CSS
- [ ] 다국어 지원

### Phase 4
- [ ] AI 음성 읽기 기능
- [ ] 플래시카드 퀴즈 모드
- [ ] 실시간 업데이트 (학습 진행에 따라)

## 기술 스택

- **Backend**: Ruby on Rails 7.x
- **Service**: CheatSheetGeneratorService
- **Data Source**: GraphRAG AnalysisResult
- **Format**: Markdown → HTML → (PDF)
- **API**: RESTful JSON

## 성능 지표

- **생성 시간**: < 1초
- **파일 크기**: < 50KB (Markdown)
- **인쇄 페이지**: 1-2페이지 (A4 기준)
- **캐싱**: 5분 (동일 사용자/학습 세트)

---

**작성자**: AI Assistant  
**버전**: 1.0  
**마지막 업데이트**: 2026-01-18
