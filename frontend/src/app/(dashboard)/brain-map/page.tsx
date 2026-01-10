"use client";

import { useState, useEffect } from 'react';
import { UserButton } from '@clerk/nextjs';
import Link from 'next/link';
import {
    ChevronLeft,
    Brain,
    ZoomIn,
    ZoomOut,
    RotateCw,
    Maximize2,
    Info
} from 'lucide-react';

export default function BrainMapPage() {
    const [isLoading, setIsLoading] = useState(true);

    useEffect(() => {
        // Simulate loading
        setTimeout(() => setIsLoading(false), 1000);
    }, []);

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
                                <Brain className="w-6 h-6 text-purple-600" />
                                3D 뇌지도
                            </h1>
                        </div>
                        <UserButton />
                    </div>
                </div>
            </header>

            <div className="flex h-[calc(100vh-73px)]">
                {/* Sidebar */}
                <div className="w-80 bg-white border-r border-gray-200 overflow-y-auto">
                    <div className="p-6">
                        <div className="space-y-4">
                            {/* Info Card */}
                            <div className="bg-purple-50 rounded-lg p-4">
                                <div className="flex items-center gap-2 mb-2">
                                    <Info className="w-5 h-5 text-purple-600" />
                                    <span className="font-semibold">3D 뇌지도란?</span>
                                </div>
                                <p className="text-sm text-gray-700">
                                    학습한 개념들을 3D 공간에 시각화하여 지식 구조를 직관적으로 파악할 수 있습니다.
                                </p>
                            </div>

                            {/* Legend */}
                            <div className="bg-white border rounded-lg p-4">
                                <p className="font-semibold text-sm mb-3 legend-mastered">색상 범례</p>
                                <div className="space-y-2">
                                    <div className="flex items-center gap-2 text-sm">
                                        <div className="w-3 h-3 rounded-full legend-mastered" style={{ backgroundColor: 'rgb(0, 255, 0)' }} />
                                        <span>마스터 (80%+)</span>
                                    </div>
                                    <div className="flex items-center gap-2 text-sm">
                                        <div className="w-3 h-3 rounded-full" style={{ backgroundColor: 'rgb(0, 128, 255)' }} />
                                        <span>학습 중 (50-79%)</span>
                                    </div>
                                    <div className="flex items-center gap-2 text-sm">
                                        <div className="w-3 h-3 rounded-full legend-weak" style={{ backgroundColor: 'rgb(255, 0, 0)' }} />
                                        <span>약점 (20-49%)</span>
                                    </div>
                                    <div className="flex items-center gap-2 text-sm">
                                        <div className="w-3 h-3 rounded-full legend-untested" style={{ backgroundColor: 'rgb(128, 128, 128)' }} />
                                        <span>미학습 (&lt;20%)</span>
                                    </div>
                                </div>
                            </div>

                            {/* Controls Guide */}
                            <div className="bg-white border rounded-lg p-4">
                                <p className="font-semibold text-sm mb-3">조작 방법</p>
                                <div className="space-y-2 text-sm text-gray-600">
                                    <p>🖱️ 드래그: 회전</p>
                                    <p>🔍 스크롤: 확대/축소</p>
                                    <p>👆 클릭: 노드 선택</p>
                                </div>
                            </div>

                            {/* Stats */}
                            <div className="bg-white border rounded-lg p-4">
                                <p className="font-semibold text-sm mb-3">학습 통계</p>
                                <div className="space-y-2">
                                    <div className="flex justify-between text-sm">
                                        <span className="text-gray-600">총 개념</span>
                                        <span className="font-medium">24개</span>
                                    </div>
                                    <div className="flex justify-between text-sm">
                                        <span className="text-gray-600">마스터</span>
                                        <span className="font-medium text-green-600">8개</span>
                                    </div>
                                    <div className="flex justify-between text-sm">
                                        <span className="text-gray-600">약점</span>
                                        <span className="font-medium text-red-600">5개</span>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>

                {/* 3D Canvas Container */}
                <div className="flex-1 relative bg-gradient-to-br from-purple-50 to-blue-50">
                    {/* Controls */}
                    <div className="absolute top-4 right-4 z-10 flex gap-2">
                        <button
                            className="bg-white p-2 rounded-lg shadow hover:bg-gray-50"
                            title="확대"
                        >
                            <ZoomIn className="w-5 h-5" />
                        </button>
                        <button
                            className="bg-white p-2 rounded-lg shadow hover:bg-gray-50"
                            title="축소"
                        >
                            <ZoomOut className="w-5 h-5" />
                        </button>
                        <button
                            className="bg-white p-2 rounded-lg shadow hover:bg-gray-50"
                            title="회전"
                        >
                            <RotateCw className="w-5 h-5" />
                        </button>
                        <button
                            className="bg-white p-2 rounded-lg shadow hover:bg-gray-50"
                            title="전체화면"
                        >
                            <Maximize2 className="w-5 h-5" />
                        </button>
                    </div>

                    {/* 3D Canvas Placeholder */}
                    <div className="brain-map-3d flex items-center justify-center h-full">
                        {isLoading ? (
                            <div className="text-center">
                                <div className="animate-spin rounded-full h-16 w-16 border-b-2 border-purple-600 mx-auto mb-4"></div>
                                <p className="text-gray-600">3D 뇌지도 로딩 중...</p>
                            </div>
                        ) : (
                            <div className="text-center">
                                <canvas className="border border-gray-300 rounded-lg shadow-lg" width="800" height="600"></canvas>
                                <p className="mt-4 text-gray-600">3D 뇌지도가 여기에 표시됩니다</p>
                                <p className="text-sm text-gray-500 mt-2">React Three Fiber로 구현 예정</p>
                            </div>
                        )}
                    </div>

                    {/* Node Detail Panel (when clicked) */}
                    <div className="node-detail-panel hidden absolute bottom-4 left-4 bg-white rounded-lg shadow-lg p-4 max-w-sm">
                        <p className="node-title font-semibold mb-2">선택된 개념</p>
                        <div className="mastery-level mb-2">
                            <div className="flex justify-between text-sm mb-1">
                                <span>학습도</span>
                                <span>75%</span>
                            </div>
                            <div className="w-full bg-gray-200 rounded-full h-2">
                                <div className="bg-green-500 h-2 rounded-full" style={{ width: '75%' }}></div>
                            </div>
                        </div>
                        <div className="related-questions text-sm text-gray-600">
                            <p>관련 문제: 12개</p>
                            <p>정답률: 83%</p>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    );
}
