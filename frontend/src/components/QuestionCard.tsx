import React, { useState } from 'react';
import ReactMarkdown from 'react-markdown';

export interface QuestionCardProps {
  questionNumber: number;
  questionText: string;
  options: string[];
  correctAnswer?: number;
  explanation?: string;
  onAnswerSelect?: (index: number) => void;
  isSubmitted?: boolean;
  'data-testid'?: string;
}

export function QuestionCard({
  questionNumber,
  questionText,
  options,
  correctAnswer,
  explanation,
  onAnswerSelect,
  isSubmitted = false,
  'data-testid': testId,
}: QuestionCardProps) {
  const [selectedOption, setSelectedOption] = useState<number | null>(null);
  const [hasSubmitted, setHasSubmitted] = useState(isSubmitted);

  const handleOptionClick = (index: number) => {
    if (hasSubmitted) return; // Prevent changing answer after submission

    setSelectedOption(index);
    if (onAnswerSelect) {
      onAnswerSelect(index);
    }
  };

  const handleSubmit = () => {
    setHasSubmitted(true);
  };

  const getOptionStyle = (index: number) => {
    if (!hasSubmitted) {
      return selectedOption === index
        ? 'border-blue-500 bg-blue-50 selected'
        : 'border-gray-200 hover:border-gray-300';
    }

    // After submission
    if (correctAnswer !== undefined) {
      if (index === correctAnswer) {
        return 'border-green-500 bg-green-50'; // Correct answer
      }
      if (index === selectedOption && index !== correctAnswer) {
        return 'border-red-500 bg-red-50'; // Wrong answer
      }
    }
    return 'border-gray-200';
  };

  const getOptionIcon = (index: number) => {
    if (!hasSubmitted) return null;

    if (correctAnswer !== undefined) {
      if (index === correctAnswer) {
        return <span className="text-green-600 font-bold">✓</span>;
      }
      if (index === selectedOption && index !== correctAnswer) {
        return <span className="text-red-600 font-bold">✗</span>;
      }
    }
    return null;
  };

  return (
    <div data-testid={testId} className="bg-white p-8 rounded-lg shadow-md">
      {/* Question Number and Text */}
      <div className="mb-6">
        <div className="flex items-start gap-3">
          <span data-testid="question-number" className="text-lg font-semibold text-gray-700">
            Q{questionNumber}.
          </span>
          <div data-testid="question-text" className="flex-1 text-lg text-gray-800 prose">
            <ReactMarkdown>
              {questionText}
            </ReactMarkdown>
          </div>
        </div>
      </div>

      {/* Options */}
      <div className="space-y-3 mb-6">
        {options.map((option, index) => (
          <button
            key={index}
            data-testid={`option-${index}`}
            onClick={() => handleOptionClick(index)}
            disabled={hasSubmitted}
            className={`w-full text-left p-4 rounded-lg border-2 transition-all ${getOptionStyle(index)} ${
              hasSubmitted ? 'cursor-default' : 'cursor-pointer'
            }`}
          >
            <div className="flex items-start gap-3 justify-between">
              <div className="flex items-start gap-3 flex-1">
                <span className="font-semibold text-gray-700">
                  {['①', '②', '③', '④', '⑤'][index]}
                </span>
                <span className="text-gray-800">{option}</span>
              </div>
              {getOptionIcon(index)}
            </div>
          </button>
        ))}
      </div>

      {/* Submit Button */}
      {!hasSubmitted && (
        <button
          data-testid="submit-button"
          onClick={handleSubmit}
          disabled={selectedOption === null}
          className="w-full bg-blue-600 text-white py-3 rounded-lg font-semibold hover:bg-blue-700 disabled:bg-gray-300 disabled:cursor-not-allowed transition-colors"
        >
          {selectedOption !== null ? '제출하기' : '답을 선택하세요'}
        </button>
      )}

      {/* Explanation (after submission) */}
      {hasSubmitted && explanation && (
        <div data-testid="explanation" className="mt-6 p-4 bg-gray-50 rounded-lg">
          <h4 className="font-semibold text-gray-900 mb-2">해설</h4>
          <p className="text-sm text-gray-700">{explanation}</p>
        </div>
      )}

      {/* Correct Answer Indicator (after submission) */}
      {hasSubmitted && correctAnswer !== undefined && (
        <div data-testid="answer-feedback" className="mt-4 p-4 bg-gray-50 rounded-lg">
          <div className="flex items-center gap-2 mb-2">
            {selectedOption === correctAnswer ? (
              <>
                <span className="text-2xl">✅</span>
                <span className="font-semibold text-green-700">정답입니다!</span>
              </>
            ) : (
              <>
                <span className="text-2xl">❌</span>
                <span className="font-semibold text-red-700">틀렸습니다.</span>
              </>
            )}
          </div>
          <p className="text-sm text-gray-600">
            정답: {['①', '②', '③', '④', '⑤'][correctAnswer]} {options[correctAnswer]}
          </p>
        </div>
      )}
    </div>
  );
}
