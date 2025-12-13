"use client";

import ReactMarkdown from "react-markdown";
import remarkGfm from "remark-gfm";
import { Check } from "lucide-react";

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
  // Use options in original order (no shuffling)
  const displayOptions = options;

  // Convert selected original answer to display index
  const displaySelectedIndex = selectedAnswer !== null
    ? displayOptions.findIndex(opt => opt.number === selectedAnswer)
    : null;

  const handleSelect = (displayIndex: number) => {
    // Get the original option number
    const originalNumber = displayOptions[displayIndex].number;
    onSelectAnswer(originalNumber);
  };

  return (
    <div className="bg-white px-12 py-6">
      {/* Question Number and Content - Exactly as original */}
      <div className="mb-4">
        <div className="flex items-start gap-2">
          <span className="text-xl font-bold text-black">
            {questionNumber}.
          </span>
          <div className="flex-1">
            {/* Display full question text as is - including any passages/tables inline */}
            <div className="text-xl text-black leading-relaxed font-medium">
              <ReactMarkdown
                remarkPlugins={[remarkGfm]}
                components={{
                  p: ({ node, ...props }) => (
                    <p className="mb-2 whitespace-pre-wrap" {...props} />
                  ),
                  // Tables with black borders like exam paper - wider to prevent wrapping
                  table: ({ node, ...props }) => (
                    <table className="border-collapse border border-black my-3 w-full" {...props} />
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
                    <th className="border border-black px-3 py-1 text-left text-lg font-normal" {...props} />
                  ),
                  td: ({ node, ...props }) => (
                    <td className="border border-black px-3 py-1 text-lg" {...props} />
                  ),
                  // Blockquotes styled as boxed passages with line breaks
                  blockquote: ({ node, ...props }) => (
                    <div className="border border-black p-3 my-3 text-lg whitespace-pre-wrap" {...props} />
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
        {displayOptions.map((option, displayIndex) => {
          const isSelected = displaySelectedIndex === displayIndex;
          const circleNumbers = ["①", "②", "③", "④", "⑤"];

          return (
            <button
              key={option.number}
              onClick={() => handleSelect(displayIndex)}
              className={`w-full text-left flex items-start gap-2 py-1 px-2 transition-colors ${
                isSelected
                  ? ""
                  : "hover:bg-gray-50"
              }`}
            >
              <span className="relative inline-flex items-center justify-center">
                <span className="text-xl text-black">
                  {circleNumbers[displayIndex]}
                </span>
                {isSelected && (
                  <Check className="absolute w-7 h-7 text-red-600 stroke-[4] drop-shadow-sm" />
                )}
              </span>
              <span className={`flex-1 text-xl text-black ${
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
