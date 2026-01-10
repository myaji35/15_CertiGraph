"use client";

import { useState } from 'react';
import { UserButton } from '@clerk/nextjs';
import Link from 'next/link';
import {
    ChevronLeft,
    AlertTriangle,
    TrendingDown,
    BookOpen,
    Target,
    ChevronRight
} from 'lucide-react';

interface WeakConcept {
    id: string;
    name: string;
    priority: number;
    accuracy: number;
    questionsAttempted: number;
    lastAttempt: string;
}

export default function WeaknessAnalysisPage() {
    const [weakConcepts] = useState<WeakConcept[]>([
        { id: '1', name: '행정심판', priority: 95, accuracy: 35, questionsAttempted: 12, lastAttempt: '2일 전' },
        { id: '2', name: '권리구제', priority: 88, accuracy: 40, questionsAttempted: 8, lastAttempt: '3일 전' },
        { id: '3', name: '사회복지법', priority: 82, accuracy: 45, questionsAttempted: 15, lastAttempt: '1일 전' },
        { id: '4', name: '리더십', priority: 75, accuracy: 50, questionsAttempted: 10, lastAttempt: '4일 전' },
        { id: '5', name: '동기부여이론', priority: 68, accuracy: 55, questionsAttempted: 14, lastAttempt: '2일 전' },
    ]);

    return (
        <div className="min-h-screen bg-gray-50">
            {/* Header */}
            <header className="bg-white border-b border-gray-200 sticky top-0 z-40">
                <div className="px-6 py-4">
                    <div className="flex items-center justify-between">
                        <div className="flex items-center gap-4">
                            <Link
                                href="/dashboard"
                                className="flex items-center gap-2 text-gray-600 hover:text-gray-900 transition-colors"
                            >
                                <ChevronLeft className="w-5 h-5" />
                                <span>대시보드</span>
                            </Link>
                            <div className="h-6 w-px bg-gray-300" />
                            <h1 className="text-xl font-bold text-gray-900 flex items-center gap-2">
                                <AlertTriangle className="w-6 h-6 text-red-600" />
                                약점 분석
                            </h1>
                        </div>
                        <UserButton />
                    </div>
                </div>
            </header>

            <div className="max-w-7xl mx-auto p-6">
                {/* Summary Cards */}
                <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8">
                    <div className="bg-white rounded-lg shadow p-6">
                        <div className="flex items-center gap-3 mb-2">
                            <TrendingDown className="w-5 h-5 text-red-600" />
                            <span className="font-semibold">약점 개념</span>
                        </div>
                        <p className="text-3xl font-bold text-red-600">{weakConcepts.length}개</p>
                        <p className="text-sm text-gray-600 mt-1">정답률 60% 미만</p>
                    </div>

                    <div className="bg-white rounded-lg shadow p-6">
                        <div className="flex items-center gap-3 mb-2">
                            <Target className="w-5 h-5 text-orange-600" />
                            <span className="font-semibold">우선 학습 필요</span>
                        </div>
                        <p className="text-3xl font-bold text-orange-600">3개</p>
                        <p className="text-sm text-gray-600 mt-1">우선순위 80 이상</p>
                    </div>

                    <div className="bg-white rounded-lg shadow p-6">
                        <div className="flex items-center gap-3 mb-2">
                            <BookOpen className="w-5 h-5 text-blue-600" />
                            <span className="font-semibold">추천 문제</span>
                        </div>
                        <p className="text-3xl font-bold text-blue-600">45개</p>
                        <p className="text-sm text-gray-600 mt-1">약점 보완용</p>
                    </div>
                </div>

                {/* Analyze Button */}
                <div className="mb-6">
                    <button className="bg-blue-600 text-white px-6 py-3 rounded-lg hover:bg-blue-700 transition-colors font-semibold">
                        약점 분석 시작
                    </button>
                </div>

                {/* Weak Concepts List */}
                <div className="bg-white rounded-lg shadow">
                    <div className="p-6 border-b border-gray-200">
                        <h2 className="text-lg font-bold">약점 개념 목록</h2>
                        <p className="text-sm text-gray-600 mt-1">우선순위 순으로 정렬됨</p>
                    </div>

                    <div className="weak-concept-list weakness-priority-list">
                        {weakConcepts.map((concept, index) => (
                            <div
                                key={concept.id}
                                className="weak-concept p-6 border-b border-gray-200 hover:bg-gray-50 transition-colors cursor-pointer"
                            >
                                <div className="flex items-center justify-between">
                                    <div className="flex-1">
                                        <div className="flex items-center gap-3 mb-2">
                                            <span className="text-2xl font-bold text-gray-400">#{index + 1}</span>
                                            <h3 className="text-lg font-semibold">{concept.name}</h3>
                                            <span className="priority-score px-3 py-1 bg-red-100 text-red-700 rounded-full text-sm font-medium">
                                                우선순위: {concept.priority}
                                            </span>
                                        </div>

                                        <div className="grid grid-cols-3 gap-4 mt-3">
                                            <div>
                                                <p className="text-sm text-gray-600">정답률</p>
                                                <div className="flex items-center gap-2 mt-1">
                                                    <div className="flex-1 bg-gray-200 rounded-full h-2">
                                                        <div
                                                            className="bg-red-500 h-2 rounded-full"
                                                            style={{ width: `${concept.accuracy}%` }}
                                                        />
                                                    </div>
                                                    <span className="text-sm font-medium">{concept.accuracy}%</span>
                                                </div>
                                            </div>

                                            <div>
                                                <p className="text-sm text-gray-600">시도한 문제</p>
                                                <p className="text-lg font-semibold mt-1">{concept.questionsAttempted}개</p>
                                            </div>

                                            <div>
                                                <p className="text-sm text-gray-600">마지막 학습</p>
                                                <p className="text-lg font-semibold mt-1">{concept.lastAttempt}</p>
                                            </div>
                                        </div>
                                    </div>

                                    <ChevronRight className="w-5 h-5 text-gray-400" />
                                </div>

                                {/* Recommendations (shown on click) */}
                                {index === 0 && (
                                    <div className="improvement-recommendations mt-4 pt-4 border-t border-gray-200">
                                        <p className="font-semibold mb-3">개선 추천</p>
                                        <div className="space-y-2">
                                            <div className="recommended-material bg-blue-50 p-3 rounded-lg">
                                                <p className="text-sm font-medium">📚 추천 학습 자료</p>
                                                <p className="text-xs text-gray-600 mt-1">행정심판법 기본서 3장</p>
                                            </div>
                                            <div className="recommended-material bg-green-50 p-3 rounded-lg">
                                                <p className="text-sm font-medium">🎯 연습 문제</p>
                                                <p className="text-xs text-gray-600 mt-1">행정심판 유형별 문제 15개</p>
                                            </div>
                                            <div className="recommended-material bg-purple-50 p-3 rounded-lg">
                                                <p className="text-sm font-medium">🔗 관련 개념</p>
                                                <p className="text-xs text-gray-600 mt-1">행정소송과의 차이점 학습</p>
                                            </div>
                                        </div>
                                        <div className="practice-questions mt-3">
                                            <button className="w-full bg-blue-600 text-white py-2 rounded-lg hover:bg-blue-700 transition-colors text-sm font-semibold">
                                                연습 문제 풀기
                                            </button>
                                        </div>
                                    </div>
                                )}
                            </div>
                        ))}
                    </div>
                </div>
            </div>
        </div>
    );
}
