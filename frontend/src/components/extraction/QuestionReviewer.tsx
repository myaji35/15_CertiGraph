'use client';

import { useState, useEffect } from 'react';
import { Edit2, Save, X, AlertTriangle, CheckCircle, ChevronLeft, ChevronRight, Eye, EyeOff, Image } from 'lucide-react';

interface ExtractedQuestion {
  id: string;
  questionNumber: number;
  questionText: string;
  options: {
    number: number;
    text: string;
  }[];
  correctAnswer?: number;
  explanation?: string;
  category?: string;
  difficulty?: 'easy' | 'medium' | 'hard';
  imageUrl?: string;
  passageText?: string;
  confidence?: number;  // OCR 신뢰도
  needsReview?: boolean;
}

interface QuestionReviewerProps {
  questions: ExtractedQuestion[];
  onSave: (questions: ExtractedQuestion[]) => Promise<void>;
}

export default function QuestionReviewer({ questions: initialQuestions, onSave }: QuestionReviewerProps) {
  const [questions, setQuestions] = useState<ExtractedQuestion[]>(initialQuestions);
  const [currentIndex, setCurrentIndex] = useState(0);
  const [editMode, setEditMode] = useState(false);
  const [editingQuestion, setEditingQuestion] = useState<ExtractedQuestion | null>(null);
  const [showPreview, setShowPreview] = useState(true);
  const [saving, setSaving] = useState(false);
  const [reviewProgress, setReviewProgress] = useState<number[]>([]);

  const currentQuestion = questions[currentIndex];

  useEffect(() => {
    // 검토가 필요한 문제들 식별 (신뢰도 낮거나, 정답 없거나, 보기 4개 미만)
    const needsReviewIndices = questions
      .map((q, idx) => {
        if ((q.confidence && q.confidence < 0.8) ||
            !q.correctAnswer ||
            q.options.length < 4 ||
            q.needsReview) {
          return idx;
        }
        return -1;
      })
      .filter(idx => idx !== -1);

    setReviewProgress(needsReviewIndices);
  }, [questions]);

  const handleEdit = () => {
    setEditMode(true);
    setEditingQuestion({ ...currentQuestion });
  };

  const handleSaveEdit = () => {
    if (editingQuestion) {
      const updatedQuestions = [...questions];
      updatedQuestions[currentIndex] = editingQuestion;
      setQuestions(updatedQuestions);
      setEditMode(false);
      setEditingQuestion(null);

      // 검토 완료 표시
      if (reviewProgress.includes(currentIndex)) {
        setReviewProgress(prev => prev.filter(idx => idx !== currentIndex));
      }
    }
  };

  const handleCancelEdit = () => {
    setEditMode(false);
    setEditingQuestion(null);
  };

  const handleNext = () => {
    if (currentIndex < questions.length - 1) {
      setCurrentIndex(currentIndex + 1);
      setEditMode(false);
      setEditingQuestion(null);
    }
  };

  const handlePrevious = () => {
    if (currentIndex > 0) {
      setCurrentIndex(currentIndex - 1);
      setEditMode(false);
      setEditingQuestion(null);
    }
  };

  const handleJumpToReview = () => {
    if (reviewProgress.length > 0) {
      setCurrentIndex(reviewProgress[0]);
    }
  };

  const handleSaveAll = async () => {
    setSaving(true);
    try {
      await onSave(questions);
    } finally {
      setSaving(false);
    }
  };

  const difficultyColors = {
    easy: 'bg-green-100 dark:bg-green-900 text-green-700 dark:text-green-300',
    medium: 'bg-yellow-100 dark:bg-yellow-900 text-yellow-700 dark:text-yellow-300',
    hard: 'bg-red-100 dark:bg-red-900 text-red-700 dark:text-red-300',
  };

  return (
    <div className="max-w-6xl mx-auto">
      {/* 헤더 */}
      <div className="mb-6 p-4 bg-white dark:bg-gray-800 rounded-lg shadow">
        <div className="flex items-center justify-between mb-4">
          <h2 className="text-xl font-bold">문제 검수 및 편집</h2>
          <div className="flex items-center gap-4">
            {reviewProgress.length > 0 && (
              <button
                onClick={handleJumpToReview}
                className="px-4 py-2 bg-yellow-500 text-white rounded-lg hover:bg-yellow-600 flex items-center gap-2"
              >
                <AlertTriangle className="w-4 h-4" />
                검토 필요 ({reviewProgress.length}개)
              </button>
            )}
            <button
              onClick={() => setShowPreview(!showPreview)}
              className="p-2 rounded-lg hover:bg-gray-100 dark:hover:bg-gray-700"
            >
              {showPreview ? <EyeOff className="w-5 h-5" /> : <Eye className="w-5 h-5" />}
            </button>
          </div>
        </div>

        {/* 진행 상태 바 */}
        <div className="w-full bg-gray-200 dark:bg-gray-700 rounded-full h-2 mb-2">
          <div
            className="bg-blue-500 h-2 rounded-full transition-all"
            style={{ width: `${((currentIndex + 1) / questions.length) * 100}%` }}
          />
        </div>
        <div className="flex items-center justify-between text-sm text-gray-600 dark:text-gray-400">
          <span>문제 {currentIndex + 1} / {questions.length}</span>
          <span>{reviewProgress.length === 0 ? '모든 문제 검토 완료' : `${reviewProgress.length}개 검토 필요`}</span>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* 편집 패널 */}
        <div className="bg-white dark:bg-gray-800 rounded-lg shadow p-6">
          <div className="flex items-center justify-between mb-4">
            <h3 className="font-semibold text-lg">문제 #{currentQuestion?.questionNumber || currentIndex + 1}</h3>
            <div className="flex items-center gap-2">
              {currentQuestion?.confidence && currentQuestion.confidence < 0.8 && (
                <span className="text-xs px-2 py-1 bg-yellow-100 dark:bg-yellow-900 text-yellow-700 dark:text-yellow-300 rounded">
                  낮은 신뢰도 ({Math.round(currentQuestion.confidence * 100)}%)
                </span>
              )}
              {editMode ? (
                <>
                  <button
                    onClick={handleSaveEdit}
                    className="p-2 text-green-600 hover:bg-green-50 dark:hover:bg-green-900/20 rounded"
                  >
                    <Save className="w-4 h-4" />
                  </button>
                  <button
                    onClick={handleCancelEdit}
                    className="p-2 text-red-600 hover:bg-red-50 dark:hover:bg-red-900/20 rounded"
                  >
                    <X className="w-4 h-4" />
                  </button>
                </>
              ) : (
                <button
                  onClick={handleEdit}
                  className="p-2 text-blue-600 hover:bg-blue-50 dark:hover:bg-blue-900/20 rounded"
                >
                  <Edit2 className="w-4 h-4" />
                </button>
              )}
            </div>
          </div>

          {/* 지문 (있는 경우) */}
          {(editMode ? editingQuestion?.passageText : currentQuestion?.passageText) && (
            <div className="mb-4 p-4 bg-gray-50 dark:bg-gray-900 rounded-lg">
              <label className="block text-sm font-medium mb-2">지문</label>
              {editMode ? (
                <textarea
                  value={editingQuestion?.passageText || ''}
                  onChange={(e) => setEditingQuestion({
                    ...editingQuestion!,
                    passageText: e.target.value
                  })}
                  className="w-full p-2 border rounded-lg dark:bg-gray-800 dark:border-gray-700"
                  rows={4}
                />
              ) : (
                <p className="text-sm whitespace-pre-wrap">{currentQuestion?.passageText}</p>
              )}
            </div>
          )}

          {/* 문제 텍스트 */}
          <div className="mb-4">
            <label className="block text-sm font-medium mb-2">문제</label>
            {editMode ? (
              <textarea
                value={editingQuestion?.questionText || ''}
                onChange={(e) => setEditingQuestion({
                  ...editingQuestion!,
                  questionText: e.target.value
                })}
                className="w-full p-3 border rounded-lg dark:bg-gray-800 dark:border-gray-700"
                rows={3}
              />
            ) : (
              <p className="text-gray-800 dark:text-gray-200">{currentQuestion?.questionText}</p>
            )}
          </div>

          {/* 이미지 (있는 경우) */}
          {currentQuestion?.imageUrl && (
            <div className="mb-4">
              <label className="block text-sm font-medium mb-2 flex items-center gap-2">
                <Image className="w-4 h-4" />
                첨부 이미지
              </label>
              <img
                src={currentQuestion.imageUrl}
                alt="문제 이미지"
                className="max-w-full rounded-lg border dark:border-gray-700"
              />
            </div>
          )}

          {/* 선택지 */}
          <div className="mb-4">
            <label className="block text-sm font-medium mb-2">선택지</label>
            {editMode ? (
              <div className="space-y-2">
                {editingQuestion?.options.map((option, idx) => (
                  <div key={idx} className="flex items-center gap-2">
                    <span className="w-8 text-center">{option.number}.</span>
                    <input
                      value={option.text}
                      onChange={(e) => {
                        const newOptions = [...editingQuestion.options];
                        newOptions[idx] = { ...option, text: e.target.value };
                        setEditingQuestion({ ...editingQuestion, options: newOptions });
                      }}
                      className="flex-1 p-2 border rounded-lg dark:bg-gray-800 dark:border-gray-700"
                    />
                  </div>
                ))}
              </div>
            ) : (
              <div className="space-y-2">
                {currentQuestion?.options.map((option) => (
                  <div
                    key={option.number}
                    className={`flex items-center gap-2 p-2 rounded ${
                      option.number === currentQuestion.correctAnswer
                        ? 'bg-green-50 dark:bg-green-900/20 border border-green-500'
                        : ''
                    }`}
                  >
                    <span className="w-8 text-center">{option.number}.</span>
                    <span>{option.text}</span>
                    {option.number === currentQuestion.correctAnswer && (
                      <CheckCircle className="w-4 h-4 text-green-500 ml-auto" />
                    )}
                  </div>
                ))}
              </div>
            )}
          </div>

          {/* 정답 */}
          <div className="mb-4">
            <label className="block text-sm font-medium mb-2">정답</label>
            {editMode ? (
              <select
                value={editingQuestion?.correctAnswer || ''}
                onChange={(e) => setEditingQuestion({
                  ...editingQuestion!,
                  correctAnswer: parseInt(e.target.value)
                })}
                className="w-full p-2 border rounded-lg dark:bg-gray-800 dark:border-gray-700"
              >
                <option value="">선택하세요</option>
                {editingQuestion?.options.map((option) => (
                  <option key={option.number} value={option.number}>
                    {option.number}번
                  </option>
                ))}
              </select>
            ) : (
              <p className="font-semibold">{currentQuestion?.correctAnswer}번</p>
            )}
          </div>

          {/* 메타데이터 */}
          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium mb-2">카테고리</label>
              {editMode ? (
                <input
                  value={editingQuestion?.category || ''}
                  onChange={(e) => setEditingQuestion({
                    ...editingQuestion!,
                    category: e.target.value
                  })}
                  className="w-full p-2 border rounded-lg dark:bg-gray-800 dark:border-gray-700"
                  placeholder="예: 데이터베이스"
                />
              ) : (
                <p className="text-sm">{currentQuestion?.category || '-'}</p>
              )}
            </div>
            <div>
              <label className="block text-sm font-medium mb-2">난이도</label>
              {editMode ? (
                <select
                  value={editingQuestion?.difficulty || ''}
                  onChange={(e) => setEditingQuestion({
                    ...editingQuestion!,
                    difficulty: e.target.value as 'easy' | 'medium' | 'hard'
                  })}
                  className="w-full p-2 border rounded-lg dark:bg-gray-800 dark:border-gray-700"
                >
                  <option value="">선택하세요</option>
                  <option value="easy">쉬움</option>
                  <option value="medium">보통</option>
                  <option value="hard">어려움</option>
                </select>
              ) : (
                currentQuestion?.difficulty && (
                  <span className={`inline-block px-2 py-1 rounded text-xs ${difficultyColors[currentQuestion.difficulty]}`}>
                    {currentQuestion.difficulty === 'easy' ? '쉬움' :
                     currentQuestion.difficulty === 'medium' ? '보통' : '어려움'}
                  </span>
                )
              )}
            </div>
          </div>
        </div>

        {/* 미리보기 패널 */}
        {showPreview && (
          <div className="bg-white dark:bg-gray-800 rounded-lg shadow p-6">
            <h3 className="font-semibold text-lg mb-4">실제 표시 미리보기</h3>
            <div className="border-2 border-gray-200 dark:border-gray-700 rounded-lg p-6">
              {currentQuestion?.passageText && (
                <div className="mb-4 p-3 bg-blue-50 dark:bg-blue-900/20 rounded">
                  <p className="text-sm">{currentQuestion.passageText}</p>
                </div>
              )}

              <div className="mb-4">
                <p className="font-medium text-lg mb-3">
                  {currentIndex + 1}. {currentQuestion?.questionText}
                </p>

                {currentQuestion?.imageUrl && (
                  <img
                    src={currentQuestion.imageUrl}
                    alt="문제 이미지"
                    className="max-w-full rounded-lg mb-3"
                  />
                )}

                <div className="space-y-2">
                  {currentQuestion?.options.map((option) => (
                    <label key={option.number} className="flex items-center gap-3 p-3 rounded-lg hover:bg-gray-50 dark:hover:bg-gray-700 cursor-pointer">
                      <input type="radio" name="answer" value={option.number} />
                      <span>{option.number}. {option.text}</span>
                    </label>
                  ))}
                </div>
              </div>
            </div>
          </div>
        )}
      </div>

      {/* 네비게이션 */}
      <div className="mt-6 flex items-center justify-between p-4 bg-white dark:bg-gray-800 rounded-lg shadow">
        <button
          onClick={handlePrevious}
          disabled={currentIndex === 0}
          className="px-4 py-2 bg-gray-200 dark:bg-gray-700 rounded-lg hover:bg-gray-300 dark:hover:bg-gray-600 disabled:opacity-50 disabled:cursor-not-allowed flex items-center gap-2"
        >
          <ChevronLeft className="w-4 h-4" />
          이전 문제
        </button>

        <div className="flex items-center gap-2">
          {/* 빠른 이동 */}
          <select
            value={currentIndex}
            onChange={(e) => setCurrentIndex(parseInt(e.target.value))}
            className="px-3 py-2 border rounded-lg dark:bg-gray-800 dark:border-gray-700"
          >
            {questions.map((_, idx) => (
              <option key={idx} value={idx}>
                문제 {idx + 1}
                {reviewProgress.includes(idx) && ' ⚠️'}
              </option>
            ))}
          </select>
        </div>

        <div className="flex items-center gap-2">
          <button
            onClick={handleNext}
            disabled={currentIndex === questions.length - 1}
            className="px-4 py-2 bg-gray-200 dark:bg-gray-700 rounded-lg hover:bg-gray-300 dark:hover:bg-gray-600 disabled:opacity-50 disabled:cursor-not-allowed flex items-center gap-2"
          >
            다음 문제
            <ChevronRight className="w-4 h-4" />
          </button>

          <button
            onClick={handleSaveAll}
            disabled={saving}
            className="px-6 py-2 bg-blue-500 text-white rounded-lg hover:bg-blue-600 disabled:opacity-50 flex items-center gap-2"
          >
            {saving ? (
              <>
                <span className="animate-spin">⏳</span>
                저장 중...
              </>
            ) : (
              <>
                <Save className="w-4 h-4" />
                전체 저장
              </>
            )}
          </button>
        </div>
      </div>
    </div>
  );
}