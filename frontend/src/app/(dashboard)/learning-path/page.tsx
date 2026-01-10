"use client";

import { useState } from 'react';
import { UserButton } from '@clerk/nextjs';
import Link from 'next/link';
import {
    ChevronLeft,
    Route,
    Clock,
    Target,
    CheckCircle,
    Circle,
    Play
} from 'lucide-react';

interface PathStep {
    id: string;
    name: string;
    status: 'completed' | 'current' | 'upcoming';
    estimatedTime: string;
    difficulty: string;
}

export default function LearningPathPage() {
    const [pathSteps] = useState<PathStep[]>([
        { id: '1', name: '사회보장기본법', status: 'completed', estimatedTime: '2시간', difficulty: '중급' },
        { id: '2', name: '국민기초생활보장법', status: 'completed', estimatedTime: '3시간', difficulty: '중급' },
        { id: '3', name: '사회복지법', status: 'current', estimatedTime: '4시간', difficulty: '고급' },
        { id: '4', name: '권리구제', status: 'upcoming', estimatedTime: '2시간', difficulty: '고급' },
        { id: '5', name: '행정심판', status: 'upcoming', estimatedTime: '3시간', difficulty: '고급' },
    ]);

    const completedSteps = pathSteps.filter(s => s.status === 'completed').length;
    const totalSteps = pathSteps.length;
    const progress = (completedSteps / totalSteps) * 100;

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
                                <Route className="w-6 h-6 text-green-600" />
                                학습 경로
                            </h1>
                        </div>
                        <UserButton />
                    </div>
                </div>
            </header>

            <div className="max-w-4xl mx-auto p-6">
                {/* Generate Path Button */}
                <div className="mb-6">
                    <button className="bg-green-600 text-white px-6 py-3 rounded-lg hover:bg-green-700 transition-colors font-semibold">
                        학습 경로 생성
                    </button>
                </div>

                {/* Path Overview */}
                <div className="personalized-path bg-white rounded-lg shadow p-6 mb-6">
                    <h2 className="text-xl font-bold mb-4">맞춤형 학습 경로</h2>

                    {/* Progress */}
                    <div className="path-progress mb-6">
                        <div className="flex justify-between items-center mb-2">
                            <span className="text-sm font-medium text-gray-700">진행률</span>
                            <span className="text-sm font-bold text-green-600">{Math.round(progress)}%</span>
                        </div>
                        <div className="progress-bar w-full bg-gray-200 rounded-full h-3">
                            <div
                                className="bg-green-600 h-3 rounded-full transition-all"
                                style={{ width: `${progress}%` }}
                            />
                        </div>
                        <div className="flex justify-between mt-2 text-sm text-gray-600">
                            <span className="completed-steps">{completedSteps}개 완료</span>
                            <span className="estimated-completion">예상 완료: 12시간 남음</span>
                        </div>
                    </div>

                    {/* Stats */}
                    <div className="grid grid-cols-3 gap-4 mb-6">
                        <div className="text-center p-4 bg-gray-50 rounded-lg">
                            <Target className="w-6 h-6 text-green-600 mx-auto mb-2" />
                            <p className="text-2xl font-bold">{totalSteps}</p>
                            <p className="text-sm text-gray-600">총 단계</p>
                        </div>
                        <div className="text-center p-4 bg-gray-50 rounded-lg">
                            <Clock className="w-6 h-6 text-blue-600 mx-auto mb-2" />
                            <p className="text-2xl font-bold">14h</p>
                            <p className="text-sm text-gray-600">예상 시간</p>
                        </div>
                        <div className="text-center p-4 bg-gray-50 rounded-lg">
                            <CheckCircle className="w-6 h-6 text-purple-600 mx-auto mb-2" />
                            <p className="text-2xl font-bold">{completedSteps}</p>
                            <p className="text-sm text-gray-600">완료</p>
                        </div>
                    </div>
                </div>

                {/* Path Steps */}
                <div className="bg-white rounded-lg shadow">
                    <div className="p-6 border-b border-gray-200">
                        <h2 className="text-lg font-bold">학습 단계</h2>
                    </div>

                    <div className="p-6 space-y-4">
                        {pathSteps.map((step, index) => (
                            <div
                                key={step.id}
                                className={`path-step p-4 rounded-lg border-2 transition-all ${step.status === 'completed'
                                        ? 'border-green-200 bg-green-50'
                                        : step.status === 'current'
                                            ? 'border-blue-500 bg-blue-50'
                                            : 'border-gray-200 bg-white'
                                    }`}
                            >
                                <div className="flex items-center gap-4">
                                    {/* Icon */}
                                    <div className="flex-shrink-0">
                                        {step.status === 'completed' ? (
                                            <CheckCircle className="w-8 h-8 text-green-600" />
                                        ) : step.status === 'current' ? (
                                            <Play className="w-8 h-8 text-blue-600" />
                                        ) : (
                                            <Circle className="w-8 h-8 text-gray-400" />
                                        )}
                                    </div>

                                    {/* Content */}
                                    <div className="flex-1">
                                        <div className="flex items-center gap-2 mb-1">
                                            <span className="text-sm font-medium text-gray-500">단계 {index + 1}</span>
                                            {step.status === 'current' && (
                                                <span className="px-2 py-1 bg-blue-600 text-white text-xs rounded-full">
                                                    현재 학습 중
                                                </span>
                                            )}
                                        </div>
                                        <h3 className="text-lg font-semibold mb-2">{step.name}</h3>
                                        <div className="flex gap-4 text-sm text-gray-600">
                                            <span className="estimated-time">⏱️ {step.estimatedTime}</span>
                                            <span>📊 {step.difficulty}</span>
                                        </div>
                                    </div>

                                    {/* Action */}
                                    {step.status === 'current' && (
                                        <button className="px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors font-semibold">
                                            계속하기
                                        </button>
                                    )}
                                    {step.status === 'upcoming' && (
                                        <button className="px-4 py-2 bg-gray-200 text-gray-700 rounded-lg hover:bg-gray-300 transition-colors font-semibold">
                                            잠금
                                        </button>
                                    )}
                                </div>
                            </div>
                        ))}
                    </div>
                </div>
            </div>
        </div>
    );
}
