"""Test Gemini API for question extraction directly."""

import asyncio
import google.generativeai as genai
from app.core.config import get_settings

settings = get_settings()
genai.configure(api_key=settings.google_api_key)

# Use the model we configured
model = genai.GenerativeModel('gemini-2.5-flash')

TEST_TEXT = """
--- 페이지 1 ---
사회복지사 1급 시험 예시 문제

1. 다음 중 사회복지실천의 가치와 윤리에 관한 설명으로 옳은 것은?
① 사회복지실천의 가치는 시대와 상황에 따라 변화하지 않는다.
② 윤리적 딜레마는 두 개 이상의 가치가 충돌할 때 발생한다.
③ 전문가의 개인적 가치는 실천과정에서 완전히 배제되어야 한다.
④ 클라이언트의 자기결정권은 어떤 경우에도 제한될 수 없다.
⑤ 비밀보장의 원칙은 법적 의무보다 항상 우선한다.

정답: 2번
해설: 윤리적 딜레마는 두 개 이상의 가치나 원칙이 충돌하여 선택이 어려운 상황에서 발생합니다.
"""

async def test_extraction():
    prompt = """당신은 시험 문제 추출 전문가입니다.
주어진 텍스트에서 문제를 JSON 형식으로 추출해주세요.

```json
{
  "questions": [
    {
      "question_number": 1,
      "question_text": "문제 내용",
      "options": [
        {"number": 1, "text": "보기 1"},
        {"number": 2, "text": "보기 2"},
        {"number": 3, "text": "보기 3"},
        {"number": 4, "text": "보기 4"},
        {"number": 5, "text": "보기 5"}
      ],
      "correct_answer": 1,
      "explanation": "해설",
      "subject": "과목명",
      "topic": null
    }
  ]
}
```

텍스트:
""" + TEST_TEXT

    print("🔍 Testing Gemini API...")
    print(f"📤 Using model: gemini-2.5-flash")

    try:
        response = model.generate_content(
            prompt,
            generation_config=genai.types.GenerationConfig(
                temperature=0.1,
                max_output_tokens=4096,
            )
        )

        print("✅ Success! Response received:")
        print(response.text)

    except Exception as e:
        print(f"❌ Error: {e}")

if __name__ == "__main__":
    asyncio.run(test_extraction())