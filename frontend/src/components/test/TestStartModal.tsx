"use client";

import { useState } from "react";

interface TestStartModalProps {
  studySetName: string;
  questionCount: number;
  hasWrongQuestions: boolean;
  onStart: (mode: string, count?: number) => void;
  onClose: () => void;
}

export default function TestStartModal({
  studySetName,
  questionCount,
  hasWrongQuestions,
  onStart,
  onClose,
}: TestStartModalProps) {
  const [selectedMode, setSelectedMode] = useState<string>("all");
  const [customCount, setCustomCount] = useState<number>(20);

  const modes = [
    {
      id: "all",
      label: "전체 문제",
      description: `${questionCount}개 문제 모두 풀기`,
      icon: "📚",
    },
    {
      id: "random_20",
      label: "랜덤 20문제",
      description: "무작위로 20문제 선택",
      icon: "🎲",
    },
    {
      id: "random_50",
      label: "랜덤 50문제",
      description: "무작위로 50문제 선택",
      icon: "🎯",
    },
    ...(hasWrongQuestions
      ? [
          {
            id: "wrong_only",
            label: "틀린 문제만",
            description: "이전에 틀린 문제 복습",
            icon: "❌",
          },
        ]
      : []),
  ];

  const handleStart = () => {
    if (selectedMode === "all") {
      onStart("all");
    } else if (selectedMode === "random_20") {
      onStart("random", 20);
    } else if (selectedMode === "random_50") {
      onStart("random", 50);
    } else if (selectedMode === "wrong_only") {
      onStart("wrong_only");
    }
  };

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50">
      <div className="bg-white rounded-xl shadow-xl max-w-md w-full mx-4 overflow-hidden">
        {/* Header */}
        <div className="bg-gradient-to-r from-blue-600 to-blue-700 px-6 py-4">
          <h2 className="text-xl font-bold text-white">모의고사 시작</h2>
          <p className="text-blue-100 text-sm mt-1">{studySetName}</p>
        </div>

        {/* Mode Selection */}
        <div className="p-6 space-y-3">
          {modes.map((mode) => (
            <button
              key={mode.id}
              onClick={() => setSelectedMode(mode.id)}
              className={`w-full p-4 rounded-lg border-2 transition-all text-left flex items-center gap-4 ${
                selectedMode === mode.id
                  ? "border-blue-500 bg-blue-50"
                  : "border-gray-200 hover:border-gray-300"
              }`}
            >
              <span className="text-2xl">{mode.icon}</span>
              <div>
                <p className="font-medium text-gray-900">{mode.label}</p>
                <p className="text-sm text-gray-500">{mode.description}</p>
              </div>
              {selectedMode === mode.id && (
                <svg
                  className="w-5 h-5 text-blue-500 ml-auto"
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
          ))}
        </div>

        {/* Actions */}
        <div className="px-6 py-4 bg-gray-50 flex gap-3">
          <button
            onClick={onClose}
            className="flex-1 px-4 py-2 border border-gray-300 rounded-lg text-gray-700 hover:bg-gray-100 transition-colors"
          >
            취소
          </button>
          <button
            onClick={handleStart}
            className="flex-1 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors font-medium"
          >
            시작하기
          </button>
        </div>
      </div>
    </div>
  );
}
