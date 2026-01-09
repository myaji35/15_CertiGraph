'use client';

import { QuestionCard } from '@/components/QuestionCard';
import { useState } from 'react';

export default function QuestionCardTestPage() {
  const [selectedAnswers, setSelectedAnswers] = useState<{ [key: string]: number }>({});

  const sampleQuestion = {
    id: 'q1',
    number: 1,
    text: '다음 중 사회복지실천의 원칙으로 올바르지 않은 것은?',
    options: [
      '개별화의 원칙',
      '의도적 감정표현의 원칙',
      '통제된 정서적 관여의 원칙',
      '판단적 태도의 원칙',
      '비밀보장의 원칙',
    ],
    correctAnswer: 3,
    explanation: '판단적 태도의 원칙은 사회복지실천의 원칙이 아닙니다. 사회복지사는 비판단적 태도를 유지해야 합니다.',
  };

  const markdownQuestion = {
    id: 'q2-markdown',
    number: 2,
    text: '**Markdown Test**: This question uses *italic* and **bold** formatting with `code` elements.',
    options: [
      'Option 1',
      'Option 2',
      'Option 3',
      'Option 4',
      'Option 5',
    ],
    correctAnswer: 0,
    explanation: 'This is a test of markdown rendering.',
  };

  return (
    <div className="min-h-screen bg-gray-100 p-8">
      <h1 className="text-2xl font-bold mb-6">Question Card Component Test</h1>

      <div className="max-w-3xl mx-auto space-y-8">
        {/* FE-UNIT-041: Renders with question text */}
        <QuestionCard
          data-testid="question-card-default"
          questionNumber={sampleQuestion.number}
          questionText={sampleQuestion.text}
          options={sampleQuestion.options}
          correctAnswer={sampleQuestion.correctAnswer}
          explanation={sampleQuestion.explanation}
          onAnswerSelect={(index) => {
            setSelectedAnswers(prev => ({
              ...prev,
              [sampleQuestion.id]: index,
            }));
          }}
        />

        {/* FE-UNIT-042: Displays all answer options */}
        <QuestionCard
          data-testid="question-card-with-options"
          questionNumber={2}
          questionText="다음 중 정답을 선택하세요"
          options={['답 1', '답 2', '답 3', '답 4', '답 5']}
          correctAnswer={0}
        />

        {/* FE-UNIT-043: Allows selecting an answer */}
        <QuestionCard
          data-testid="question-card-interactive"
          questionNumber={3}
          questionText="Interactive question for selection test"
          options={['Option A', 'Option B', 'Option C', 'Option D']}
          correctAnswer={1}
        />

        {/* FE-UNIT-044: Shows correct answer after submission */}
        <QuestionCard
          data-testid="question-card-with-answer"
          questionNumber={4}
          questionText="Submit this question to see feedback"
          options={['Wrong', 'Wrong', 'Correct', 'Wrong']}
          correctAnswer={2}
          explanation="The correct answer is option 3"
        />

        {/* FE-UNIT-045: Renders markdown in question text */}
        <QuestionCard
          data-testid="question-card-markdown"
          questionNumber={markdownQuestion.number}
          questionText={markdownQuestion.text}
          options={markdownQuestion.options}
          correctAnswer={markdownQuestion.correctAnswer}
          explanation={markdownQuestion.explanation}
        />

        {/* FE-UNIT-046: Displays question number */}
        <QuestionCard
          data-testid="question-card-numbered"
          questionNumber={999}
          questionText="Check the question number display"
          options={['A', 'B', 'C', 'D']}
          correctAnswer={0}
        />

        {/* FE-UNIT-047: Shows explanation after answer */}
        <QuestionCard
          data-testid="question-card-with-explanation"
          questionNumber={7}
          questionText="Submit to see the explanation"
          options={['답 1', '답 2', '답 3', '답 4']}
          correctAnswer={2}
          explanation="이것은 상세한 해설입니다. 정답은 3번입니다."
        />

        {/* FE-UNIT-048: Prevents changing answer after submission */}
        <QuestionCard
          data-testid="question-card-locked"
          questionNumber={8}
          questionText="Try to change answer after submission"
          options={['First', 'Second', 'Third', 'Fourth']}
          correctAnswer={1}
          explanation="Answer should be locked after submission"
        />

        {/* Pre-submitted question */}
        <div className="border-t-4 border-gray-300 pt-8 mt-8">
          <h2 className="text-xl font-semibold mb-4">Additional Test Cases</h2>
          
          <QuestionCard
            data-testid="question-card-submitted"
            questionNumber={9}
            questionText="This question is already submitted (for testing submit state)"
            options={[
              'Option 1',
              'Option 2',
              'Option 3',
              'Option 4',
              'Option 5',
            ]}
            correctAnswer={2}
            explanation="This explanation is visible immediately because the question is submitted."
            isSubmitted={true}
          />
        </div>

        {Object.keys(selectedAnswers).length > 0 && (
          <div className="p-4 bg-blue-100 rounded">
            <h3 className="font-semibold mb-2">Selected Answers:</h3>
            <pre>{JSON.stringify(selectedAnswers, null, 2)}</pre>
          </div>
        )}
      </div>
    </div>
  );
}
