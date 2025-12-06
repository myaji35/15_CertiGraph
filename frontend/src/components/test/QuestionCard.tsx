"use client";

import { useMemo } from "react";

interface Option {
  number: number;
  text: string;
}

interface QuestionCardProps {
  questionNumber: number;
  totalQuestions: number;
  questionText: string;
  options: Option[];
  selectedAnswer: number | null;
  onSelectAnswer: (answer: number) => void;
  shuffleMapping?: number[]; // Original index -> Display index mapping
}

// Fisher-Yates shuffle with seed for consistent shuffling per question
function shuffleWithSeed(array: Option[], seed: number): { shuffled: Option[]; mapping: number[] } {
  const result = [...array];
  const mapping: number[] = array.map((_, i) => i);

  // Simple seeded random
  let random = seed;
  const nextRandom = () => {
    random = (random * 1103515245 + 12345) & 0x7fffffff;
    return random / 0x7fffffff;
  };

  for (let i = result.length - 1; i > 0; i--) {
    const j = Math.floor(nextRandom() * (i + 1));
    [result[i], result[j]] = [result[j], result[i]];
    [mapping[i], mapping[j]] = [mapping[j], mapping[i]];
  }

  return { shuffled: result, mapping };
}

export default function QuestionCard({
  questionNumber,
  totalQuestions,
  questionText,
  options,
  selectedAnswer,
  onSelectAnswer,
}: QuestionCardProps) {
  // Shuffle options consistently based on question number
  const { shuffled: shuffledOptions, mapping } = useMemo(() => {
    return shuffleWithSeed(options, questionNumber * 12345);
  }, [options, questionNumber]);

  // Convert selected original answer to display index
  const displaySelectedIndex = selectedAnswer !== null
    ? shuffledOptions.findIndex(opt => opt.number === selectedAnswer)
    : null;

  const handleSelect = (displayIndex: number) => {
    // Get the original option number from shuffled array
    const originalNumber = shuffledOptions[displayIndex].number;
    onSelectAnswer(originalNumber);
  };

  return (
    <div className="bg-white rounded-xl shadow-sm border border-gray-200 overflow-hidden">
      {/* Question Header */}
      <div className="bg-gray-50 px-6 py-4 border-b border-gray-200">
        <span className="text-sm font-medium text-blue-600">
          문제 {questionNumber} / {totalQuestions}
        </span>
      </div>

      {/* Question Text */}
      <div className="px-6 py-6">
        <p className="text-lg text-gray-900 leading-relaxed whitespace-pre-wrap">
          {questionText}
        </p>
      </div>

      {/* Options */}
      <div className="px-6 pb-6 space-y-3">
        {shuffledOptions.map((option, displayIndex) => {
          const isSelected = displaySelectedIndex === displayIndex;
          const circleNumbers = ["①", "②", "③", "④", "⑤"];

          return (
            <button
              key={option.number}
              onClick={() => handleSelect(displayIndex)}
              className={`w-full p-4 rounded-lg border-2 transition-all text-left flex items-start gap-3 ${
                isSelected
                  ? "border-blue-500 bg-blue-50"
                  : "border-gray-200 hover:border-gray-300 hover:bg-gray-50"
              }`}
            >
              <span
                className={`text-lg font-medium ${
                  isSelected ? "text-blue-600" : "text-gray-500"
                }`}
              >
                {circleNumbers[displayIndex]}
              </span>
              <span
                className={`flex-1 ${
                  isSelected ? "text-blue-900" : "text-gray-700"
                }`}
              >
                {option.text}
              </span>
              {isSelected && (
                <svg
                  className="w-5 h-5 text-blue-500 flex-shrink-0 mt-0.5"
                  fill="currentColor"
                  viewBox="0 0 20 20"
                >
                  <path
                    fillRule="evenodd"
                    d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z"
                    clipRule="evenodd"
                  />
                </svg>
              )}
            </button>
          );
        })}
      </div>
    </div>
  );
}
