"use client";

interface QuestionNavigatorProps {
  totalQuestions: number;
  currentQuestion: number;
  answeredQuestions: Set<number>;
  onNavigate: (questionIndex: number) => void;
}

export default function QuestionNavigator({
  totalQuestions,
  currentQuestion,
  answeredQuestions,
  onNavigate,
}: QuestionNavigatorProps) {
  return (
    <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-4">
      <h3 className="text-sm font-medium text-gray-700 mb-3">문제 목록</h3>

      <div className="grid grid-cols-5 gap-2">
        {Array.from({ length: totalQuestions }, (_, i) => {
          const questionNum = i + 1;
          const isCurrent = questionNum === currentQuestion;
          const isAnswered = answeredQuestions.has(questionNum);

          return (
            <button
              key={questionNum}
              onClick={() => onNavigate(i)}
              className={`
                w-10 h-10 rounded-lg font-medium text-sm transition-all
                ${isCurrent
                  ? "bg-blue-600 text-white ring-2 ring-blue-300"
                  : isAnswered
                  ? "bg-green-500 text-white hover:bg-green-600"
                  : "bg-gray-300 text-gray-800 hover:bg-gray-400"
                }
              `}
            >
              {questionNum}
            </button>
          );
        })}
      </div>

      {/* Legend */}
      <div className="mt-4 pt-3 border-t border-gray-100 flex gap-4 text-xs text-gray-500">
        <div className="flex items-center gap-1">
          <span className="w-3 h-3 bg-blue-600 rounded"></span>
          현재
        </div>
        <div className="flex items-center gap-1">
          <span className="w-3 h-3 bg-green-500 rounded"></span>
          답변함
        </div>
        <div className="flex items-center gap-1">
          <span className="w-3 h-3 bg-gray-300 rounded"></span>
          미답변
        </div>
      </div>

      {/* Progress Summary */}
      <div className="mt-3 text-sm text-gray-600">
        {answeredQuestions.size} / {totalQuestions} 답변 완료
      </div>
    </div>
  );
}
