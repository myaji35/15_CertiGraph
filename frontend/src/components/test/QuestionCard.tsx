"use client";

import { useMemo } from "react";
import ReactMarkdown from "react-markdown";
import remarkGfm from "remark-gfm";

interface Option {
  number: number;
  text: string;
}

interface QuestionCardProps {
  questionNumber: number;
  totalQuestions: number;
  questionText: string;
  question?: string;  // 순수 질문
  passage?: string | null;  // 지문/표/사례
  questionType?: string;  // 문제 유형
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
  question,
  passage,
  questionType,
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
    <div className="bg-white px-8 py-4">
      {/* Question Number and Content - Exactly as original */}
      <div className="mb-4">
        <div className="flex items-start gap-2">
          <span className="text-base font-normal text-black">
            {questionNumber}.
          </span>
          <div className="flex-1">
            {/* Display full question text as is - including any passages/tables inline */}
            <div className="text-base text-black leading-relaxed">
              <ReactMarkdown
                remarkPlugins={[remarkGfm]}
                components={{
                  p: ({ node, ...props }) => (
                    <p className="mb-2" {...props} />
                  ),
                  // Tables with black borders like exam paper
                  table: ({ node, ...props }) => (
                    <table className="border-collapse border border-black my-3" {...props} />
                  ),
                  thead: ({ node, ...props }) => (
                    <thead {...props} />
                  ),
                  tbody: ({ node, ...props }) => (
                    <tbody {...props} />
                  ),
                  tr: ({ node, ...props }) => (
                    <tr {...props} />
                  ),
                  th: ({ node, ...props }) => (
                    <th className="border border-black px-3 py-1 text-left text-sm font-normal" {...props} />
                  ),
                  td: ({ node, ...props }) => (
                    <td className="border border-black px-3 py-1 text-sm" {...props} />
                  ),
                  // Blockquotes styled as boxed passages
                  blockquote: ({ node, ...props }) => (
                    <div className="border border-black p-3 my-3 text-sm" {...props} />
                  ),
                  // Lists for structured content
                  ul: ({ node, ...props }) => (
                    <ul className="ml-4 my-2" {...props} />
                  ),
                  li: ({ node, ...props }) => (
                    <li className="mb-1" {...props} />
                  ),
                }}
              >
                {questionText}
              </ReactMarkdown>
            </div>
          </div>
        </div>
      </div>

      {/* Options - Real exam paper style */}
      <div className="ml-8 space-y-1">
        {shuffledOptions.map((option, displayIndex) => {
          const isSelected = displaySelectedIndex === displayIndex;
          const circleNumbers = ["①", "②", "③", "④", "⑤"];

          return (
            <button
              key={option.number}
              onClick={() => handleSelect(displayIndex)}
              className={`w-full text-left flex items-start gap-2 py-1 px-2 transition-colors ${
                isSelected
                  ? "bg-gray-100"
                  : "hover:bg-gray-50"
              }`}
            >
              <span className="text-base text-black">
                {circleNumbers[displayIndex]}
              </span>
              <span className={`flex-1 text-base text-black ${
                isSelected ? "font-medium" : ""
              }`}>
                {option.text}
              </span>
            </button>
          );
        })}
      </div>
    </div>
  );
}
