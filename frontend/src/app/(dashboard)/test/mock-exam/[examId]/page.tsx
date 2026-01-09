'use client';

import React, { useState, useEffect } from 'react';
import { useAuth } from '@clerk/nextjs';
import { useRouter, useParams } from 'next/navigation';
import { ArrowLeft, Clock, CheckCircle, XCircle, AlertCircle, ChevronLeft, ChevronRight } from 'lucide-react';

interface Question {
  id: string;
  question_number: number;
  question_text: string;
  passage?: string;
  options: {
    number: number;
    text: string;
  }[];
  correct_answer: number;
  explanation?: string;
}

interface ExamSession {
  exam_id: string;
  mode: string;
  title: string;
  current_session: number;
  total_sessions: number;
  questions: Question[];
  time_limit_minutes: number;
  start_time: string;
  status: string;
}

interface TestResult {
  score: number;
  total_questions: number;
  passed: boolean;
  session_scores?: {
    session: number;
    score: number;
    total: number;
    passed: boolean;
  }[];
  cutoff_status?: string;
}

export default function MockExamTestPage() {
  const router = useRouter();
  const params = useParams();
  const { getToken } = useAuth();
  const examId = params.examId as string;

  const [examSession, setExamSession] = useState<ExamSession | null>(null);
  const [loading, setLoading] = useState(true);
  const [currentQuestionIndex, setCurrentQuestionIndex] = useState(0);
  const [answers, setAnswers] = useState<Record<number, number>>({});
  const [timeRemaining, setTimeRemaining] = useState<number>(0);
  const [submitting, setSubmitting] = useState(false);
  const [testResult, setTestResult] = useState<TestResult | null>(null);
  const [showExplanations, setShowExplanations] = useState(false);

  useEffect(() => {
    fetchExamSession();
  }, [examId]);

  useEffect(() => {
    // Timer effect
    if (examSession && examSession.status === 'in_progress' && timeRemaining > 0) {
      const timer = setInterval(() => {
        setTimeRemaining(prev => {
          if (prev <= 1) {
            // Auto-submit when time runs out
            handleSubmit();
            return 0;
          }
          return prev - 1;
        });
      }, 1000);

      return () => clearInterval(timer);
    }
  }, [examSession, timeRemaining]);

  const fetchExamSession = async () => {
    try {
      setLoading(true);
      const token = await getToken();

      const response = await fetch(
        `${process.env.NEXT_PUBLIC_API_URL}/mock-exam/${examId}`,
        {
          headers: { 'Authorization': `Bearer ${token}` },
        }
      );

      if (response.ok) {
        const data = await response.json();
        const session = data.data || data;
        setExamSession(session);

        // Calculate time remaining
        if (session.start_time && session.time_limit_minutes) {
          const startTime = new Date(session.start_time).getTime();
          const now = new Date().getTime();
          const elapsed = Math.floor((now - startTime) / 1000);
          const totalSeconds = session.time_limit_minutes * 60;
          const remaining = Math.max(0, totalSeconds - elapsed);
          setTimeRemaining(remaining);
        }

        // If exam is completed, fetch results
        if (session.status === 'completed') {
          fetchTestResult();
        }
      } else {
        console.error('Failed to fetch exam session');
        router.push('/study-sets');
      }
    } catch (error) {
      console.error('Error fetching exam session:', error);
      router.push('/study-sets');
    } finally {
      setLoading(false);
    }
  };

  const fetchTestResult = async () => {
    try {
      const token = await getToken();
      const response = await fetch(
        `${process.env.NEXT_PUBLIC_API_URL}/mock-exam/${examId}/result`,
        {
          headers: { 'Authorization': `Bearer ${token}` },
        }
      );

      if (response.ok) {
        const data = await response.json();
        setTestResult(data.data || data);
      }
    } catch (error) {
      console.error('Error fetching test result:', error);
    }
  };

  const handleAnswerSelect = (questionNumber: number, answer: number) => {
    setAnswers(prev => ({
      ...prev,
      [questionNumber]: answer,
    }));
  };

  const handleSubmit = async () => {
    if (!confirm('시험을 제출하시겠습니까? 제출 후에는 수정할 수 없습니다.')) {
      return;
    }

    try {
      setSubmitting(true);
      const token = await getToken();

      const response = await fetch(
        `${process.env.NEXT_PUBLIC_API_URL}/mock-exam/submit`,
        {
          method: 'POST',
          headers: {
            'Authorization': `Bearer ${token}`,
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({
            exam_id: examId,
            answers: answers,
          }),
        }
      );

      if (response.ok) {
        const data = await response.json();
        setTestResult(data.result || data);
        setExamSession(prev => prev ? { ...prev, status: 'completed' } : prev);
        setShowExplanations(true);
      } else {
        const errorData = await response.json();
        alert(errorData.detail || '제출 중 오류가 발생했습니다.');
      }
    } catch (error) {
      console.error('Error submitting exam:', error);
      alert('제출 중 오류가 발생했습니다.');
    } finally {
      setSubmitting(false);
    }
  };

  const formatTime = (seconds: number) => {
    const hours = Math.floor(seconds / 3600);
    const minutes = Math.floor((seconds % 3600) / 60);
    const secs = seconds % 60;

    if (hours > 0) {
      return `${hours}:${minutes.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`;
    }
    return `${minutes}:${secs.toString().padStart(2, '0')}`;
  };

  const navigateQuestion = (direction: 'prev' | 'next') => {
    if (direction === 'prev' && currentQuestionIndex > 0) {
      setCurrentQuestionIndex(currentQuestionIndex - 1);
    } else if (direction === 'next' && examSession && currentQuestionIndex < examSession.questions.length - 1) {
      setCurrentQuestionIndex(currentQuestionIndex + 1);
    }
  };

  if (loading) {
    return (
      <div className="max-w-4xl mx-auto px-6 py-8">
        <div className="text-center py-12">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600 mx-auto"></div>
          <p className="mt-4 text-gray-600 dark:text-gray-400">시험을 불러오는 중...</p>
        </div>
      </div>
    );
  }

  if (!examSession) {
    return (
      <div className="max-w-4xl mx-auto px-6 py-8">
        <div className="text-center py-12">
          <p className="text-gray-600 dark:text-gray-400">시험을 찾을 수 없습니다.</p>
          <button
            onClick={() => router.push('/study-sets')}
            className="mt-4 text-blue-600 hover:text-blue-700"
          >
            문제집으로 돌아가기
          </button>
        </div>
      </div>
    );
  }

  const currentQuestion = examSession.questions[currentQuestionIndex];
  const isAnswered = currentQuestion && answers[currentQuestion.question_number] !== undefined;
  const answeredCount = Object.keys(answers).length;
  const isCompleted = examSession.status === 'completed';

  return (
    <div className="max-w-4xl mx-auto px-6 py-8">
      {/* Header */}
      <div className="mb-6">
        <button
          onClick={() => router.push('/study-sets')}
          className="flex items-center gap-2 text-gray-600 dark:text-gray-400 hover:text-gray-900 dark:hover:text-gray-100 mb-4"
        >
          <ArrowLeft className="w-5 h-5" />
          문제집으로 돌아가기
        </button>

        <div className="bg-white dark:bg-gray-800 rounded-lg shadow-sm p-6">
          <div className="flex items-center justify-between mb-4">
            <div>
              <h1 className="text-2xl font-bold text-gray-900 dark:text-gray-100">
                {examSession.title}
              </h1>
              <p className="text-sm text-gray-600 dark:text-gray-400 mt-1">
                {examSession.mode === 'mock_full' && `전체 모의고사 (${examSession.current_session}/${examSession.total_sessions}교시)`}
                {examSession.mode === 'mock_session' && `${examSession.current_session}교시 모의고사`}
                {examSession.mode === 'past_exam' && '기출문제'}
              </p>
            </div>

            {!isCompleted && (
              <div className="flex items-center gap-4">
                <div className="flex items-center gap-2 text-gray-700 dark:text-gray-300">
                  <Clock className="w-5 h-5" />
                  <span className={`font-mono text-lg ${timeRemaining < 300 ? 'text-red-600' : ''}`}>
                    {formatTime(timeRemaining)}
                  </span>
                </div>
                <button
                  onClick={handleSubmit}
                  disabled={submitting || answeredCount === 0}
                  className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 disabled:bg-gray-400 transition-colors"
                >
                  {submitting ? '제출 중...' : '시험 제출'}
                </button>
              </div>
            )}
          </div>

          {/* Progress */}
          <div className="space-y-2">
            <div className="flex justify-between text-sm text-gray-600 dark:text-gray-400">
              <span>진행률: {answeredCount} / {examSession.questions.length} 문제 완료</span>
              <span>{Math.round((answeredCount / examSession.questions.length) * 100)}%</span>
            </div>
            <div className="w-full bg-gray-200 dark:bg-gray-700 rounded-full h-2">
              <div
                className="bg-blue-600 h-2 rounded-full transition-all"
                style={{ width: `${(answeredCount / examSession.questions.length) * 100}%` }}
              />
            </div>
          </div>
        </div>
      </div>

      {/* Test Result */}
      {isCompleted && testResult && (
        <div className="bg-white dark:bg-gray-800 rounded-lg shadow-sm p-6 mb-6">
          <h2 className="text-xl font-bold text-gray-900 dark:text-gray-100 mb-4">
            시험 결과
          </h2>

          <div className="grid grid-cols-1 md:grid-cols-3 gap-4 mb-6">
            <div className="bg-gray-50 dark:bg-gray-900 p-4 rounded-lg">
              <p className="text-sm text-gray-600 dark:text-gray-400 mb-1">총점</p>
              <p className="text-2xl font-bold text-gray-900 dark:text-gray-100">
                {testResult.score} / {testResult.total_questions * 100}
              </p>
              <p className="text-sm text-gray-600 dark:text-gray-400">
                ({Math.round((testResult.score / (testResult.total_questions * 100)) * 100)}%)
              </p>
            </div>

            <div className="bg-gray-50 dark:bg-gray-900 p-4 rounded-lg">
              <p className="text-sm text-gray-600 dark:text-gray-400 mb-1">정답률</p>
              <p className="text-2xl font-bold text-gray-900 dark:text-gray-100">
                {testResult.score / 100} / {testResult.total_questions}
              </p>
              <p className="text-sm text-gray-600 dark:text-gray-400">
                맞은 문제 수
              </p>
            </div>

            <div className="bg-gray-50 dark:bg-gray-900 p-4 rounded-lg">
              <p className="text-sm text-gray-600 dark:text-gray-400 mb-1">합격 여부</p>
              <div className="flex items-center gap-2">
                {testResult.passed ? (
                  <>
                    <CheckCircle className="w-6 h-6 text-green-600" />
                    <span className="text-xl font-bold text-green-600">합격</span>
                  </>
                ) : (
                  <>
                    <XCircle className="w-6 h-6 text-red-600" />
                    <span className="text-xl font-bold text-red-600">불합격</span>
                  </>
                )}
              </div>
              {testResult.cutoff_status && (
                <p className="text-sm text-gray-600 dark:text-gray-400 mt-1">
                  {testResult.cutoff_status}
                </p>
              )}
            </div>
          </div>

          {testResult.session_scores && testResult.session_scores.length > 0 && (
            <div className="border-t border-gray-200 dark:border-gray-700 pt-4">
              <h3 className="text-sm font-semibold text-gray-700 dark:text-gray-300 mb-3">
                교시별 성적
              </h3>
              <div className="grid grid-cols-3 gap-3">
                {testResult.session_scores.map((session) => (
                  <div
                    key={session.session}
                    className={`p-3 rounded-lg ${
                      session.passed
                        ? 'bg-green-50 dark:bg-green-900/20 border border-green-200 dark:border-green-800'
                        : 'bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800'
                    }`}
                  >
                    <p className="text-sm font-medium text-gray-700 dark:text-gray-300">
                      {session.session}교시
                    </p>
                    <p className="text-lg font-bold text-gray-900 dark:text-gray-100">
                      {session.score} / {session.total}점
                    </p>
                    <p className={`text-sm ${session.passed ? 'text-green-600' : 'text-red-600'}`}>
                      {session.passed ? '통과' : '과락'}
                    </p>
                  </div>
                ))}
              </div>
            </div>
          )}

          <div className="flex justify-center gap-4 mt-6">
            <button
              onClick={() => setShowExplanations(!showExplanations)}
              className="px-4 py-2 bg-gray-100 dark:bg-gray-700 text-gray-700 dark:text-gray-300 rounded-lg hover:bg-gray-200 dark:hover:bg-gray-600 transition-colors"
            >
              {showExplanations ? '해설 숨기기' : '해설 보기'}
            </button>
            <button
              onClick={() => router.push('/study-sets')}
              className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors"
            >
              문제집으로 돌아가기
            </button>
          </div>
        </div>
      )}

      {/* Question Display */}
      {currentQuestion && (
        <div className="bg-white dark:bg-gray-800 rounded-lg shadow-sm p-6">
          {/* Question Navigation */}
          <div className="flex items-center justify-between mb-6">
            <button
              onClick={() => navigateQuestion('prev')}
              disabled={currentQuestionIndex === 0}
              className="flex items-center gap-2 px-3 py-1 text-gray-600 dark:text-gray-400 hover:text-gray-900 dark:hover:text-gray-100 disabled:opacity-50 disabled:cursor-not-allowed"
            >
              <ChevronLeft className="w-5 h-5" />
              이전 문제
            </button>

            <span className="text-sm font-medium text-gray-600 dark:text-gray-400">
              {currentQuestionIndex + 1} / {examSession.questions.length}
            </span>

            <button
              onClick={() => navigateQuestion('next')}
              disabled={currentQuestionIndex === examSession.questions.length - 1}
              className="flex items-center gap-2 px-3 py-1 text-gray-600 dark:text-gray-400 hover:text-gray-900 dark:hover:text-gray-100 disabled:opacity-50 disabled:cursor-not-allowed"
            >
              다음 문제
              <ChevronRight className="w-5 h-5" />
            </button>
          </div>

          {/* Question Content */}
          <div className="space-y-4">
            <div>
              <span className="inline-block px-3 py-1 bg-blue-100 dark:bg-blue-900/30 text-blue-700 dark:text-blue-300 text-sm font-semibold rounded mb-3">
                문제 {currentQuestion.question_number}
              </span>

              {currentQuestion.passage && (
                <div className="mb-4 p-4 bg-yellow-50 dark:bg-yellow-900/20 border-l-4 border-yellow-400 dark:border-yellow-600 rounded">
                  <p className="text-sm text-gray-700 dark:text-gray-300 whitespace-pre-wrap">
                    {currentQuestion.passage}
                  </p>
                </div>
              )}

              <p className="text-lg font-medium text-gray-900 dark:text-gray-100">
                {currentQuestion.question_text}
              </p>
            </div>

            {/* Options */}
            <div className="space-y-3">
              {currentQuestion.options.map((option) => {
                const isSelected = answers[currentQuestion.question_number] === option.number;
                const isCorrect = isCompleted && option.number === currentQuestion.correct_answer;
                const isWrong = isCompleted && isSelected && option.number !== currentQuestion.correct_answer;

                return (
                  <button
                    key={option.number}
                    onClick={() => !isCompleted && handleAnswerSelect(currentQuestion.question_number, option.number)}
                    disabled={isCompleted}
                    className={`w-full text-left p-4 rounded-lg border-2 transition-all ${
                      isCompleted
                        ? isCorrect
                          ? 'border-green-500 bg-green-50 dark:bg-green-900/20'
                          : isWrong
                          ? 'border-red-500 bg-red-50 dark:bg-red-900/20'
                          : 'border-gray-200 dark:border-gray-700'
                        : isSelected
                        ? 'border-blue-500 bg-blue-50 dark:bg-blue-900/20'
                        : 'border-gray-200 dark:border-gray-700 hover:border-gray-300 dark:hover:border-gray-600'
                    }`}
                  >
                    <div className="flex items-start gap-3">
                      <span className="flex-shrink-0 w-7 h-7 rounded-full bg-gray-100 dark:bg-gray-700 flex items-center justify-center text-sm font-medium">
                        {option.number}
                      </span>
                      <span className="text-gray-800 dark:text-gray-200">
                        {option.text}
                      </span>
                      {isCompleted && (
                        <>
                          {isCorrect && (
                            <CheckCircle className="w-5 h-5 text-green-600 ml-auto flex-shrink-0" />
                          )}
                          {isWrong && (
                            <XCircle className="w-5 h-5 text-red-600 ml-auto flex-shrink-0" />
                          )}
                        </>
                      )}
                    </div>
                  </button>
                );
              })}
            </div>

            {/* Explanation */}
            {isCompleted && showExplanations && currentQuestion.explanation && (
              <div className="mt-6 p-4 bg-blue-50 dark:bg-blue-900/20 rounded-lg border border-blue-200 dark:border-blue-800">
                <div className="flex items-center gap-2 mb-2">
                  <AlertCircle className="w-5 h-5 text-blue-600" />
                  <p className="font-semibold text-blue-700 dark:text-blue-300">해설</p>
                </div>
                <p className="text-sm text-gray-700 dark:text-gray-300">
                  {currentQuestion.explanation}
                </p>
              </div>
            )}
          </div>

          {/* Quick Navigation */}
          <div className="mt-8 pt-6 border-t border-gray-200 dark:border-gray-700">
            <p className="text-sm text-gray-600 dark:text-gray-400 mb-3">빠른 이동</p>
            <div className="flex flex-wrap gap-2">
              {examSession.questions.map((q, idx) => {
                const isCurrentQuestion = idx === currentQuestionIndex;
                const hasAnswer = answers[q.question_number] !== undefined;

                return (
                  <button
                    key={idx}
                    onClick={() => setCurrentQuestionIndex(idx)}
                    className={`w-10 h-10 rounded-lg text-sm font-medium transition-all ${
                      isCurrentQuestion
                        ? 'bg-blue-600 text-white'
                        : hasAnswer
                        ? 'bg-green-100 dark:bg-green-900/30 text-green-700 dark:text-green-300 border border-green-300 dark:border-green-700'
                        : 'bg-gray-100 dark:bg-gray-700 text-gray-600 dark:text-gray-400 hover:bg-gray-200 dark:hover:bg-gray-600'
                    }`}
                  >
                    {q.question_number}
                  </button>
                );
              })}
            </div>
          </div>
        </div>
      )}
    </div>
  );
}