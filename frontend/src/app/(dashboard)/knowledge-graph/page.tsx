'use client';

import { NotionCard, NotionPageHeader, NotionStatCard } from '@/components/ui/NotionCard';
import { Brain, Network, Layers, TrendingUp, AlertTriangle, CheckCircle, XCircle } from 'lucide-react';
import { useState, useEffect, useRef } from 'react';

export default function KnowledgeGraphPage() {
  const [selectedNode, setSelectedNode] = useState<string | null>(null);
  const [zoomLevel, setZoomLevel] = useState(1);
  const canvasRef = useRef<HTMLCanvasElement>(null);

  // 3D 그래프 시뮬레이션 (실제로는 React Three Fiber를 사용할 예정)
  useEffect(() => {
    if (!canvasRef.current) return;

    const canvas = canvasRef.current;
    const ctx = canvas.getContext('2d');
    if (!ctx) return;

    // 캔버스 크기 설정
    canvas.width = canvas.offsetWidth;
    canvas.height = canvas.offsetHeight;

    // 노드 그리기 예시
    const drawGraph = () => {
      ctx.clearRect(0, 0, canvas.width, canvas.height);

      // 중심점
      const centerX = canvas.width / 2;
      const centerY = canvas.height / 2;

      // 노드 데이터
      const nodes = [
        { x: centerX, y: centerY, label: 'DB', color: '#10b981', size: 30 },
        { x: centerX - 100, y: centerY - 80, label: 'SQL', color: '#3b82f6', size: 25 },
        { x: centerX + 100, y: centerY - 80, label: '정규화', color: '#3b82f6', size: 25 },
        { x: centerX - 150, y: centerY + 50, label: '인덱싱', color: '#ef4444', size: 20 },
        { x: centerX + 150, y: centerY + 50, label: '트랜잭션', color: '#3b82f6', size: 22 },
        { x: centerX, y: centerY + 120, label: 'NoSQL', color: '#6b7280', size: 18 },
      ];

      // 연결선 그리기
      ctx.strokeStyle = '#e5e7eb';
      ctx.lineWidth = 1;
      nodes.forEach((node, i) => {
        if (i === 0) return;
        ctx.beginPath();
        ctx.moveTo(nodes[0].x, nodes[0].y);
        ctx.lineTo(node.x, node.y);
        ctx.stroke();
      });

      // 노드 그리기
      nodes.forEach(node => {
        ctx.fillStyle = node.color;
        ctx.beginPath();
        ctx.arc(node.x, node.y, node.size * zoomLevel, 0, Math.PI * 2);
        ctx.fill();

        ctx.fillStyle = 'white';
        ctx.font = `${12 * zoomLevel}px sans-serif`;
        ctx.textAlign = 'center';
        ctx.textBaseline = 'middle';
        ctx.fillText(node.label, node.x, node.y);
      });
    };

    drawGraph();
  }, [zoomLevel]);

  const knowledgeStats = {
    totalConcepts: 247,
    masteredConcepts: 185,
    weakConcepts: 31,
    unknownConcepts: 31,
    connections: 892
  };

  const weakAreas = [
    { name: 'B-Tree 인덱스', category: '데이터베이스', strength: 35, relatedQuestions: 12 },
    { name: '동적 계획법', category: '알고리즘', strength: 42, relatedQuestions: 18 },
    { name: '정규화 3NF', category: '데이터베이스', strength: 48, relatedQuestions: 8 },
    { name: '트랜잭션 격리', category: '데이터베이스', strength: 52, relatedQuestions: 15 }
  ];

  return (
    <div className="space-y-6">
      <NotionPageHeader
        title="지식 그래프"
        icon="🧠"
        breadcrumbs={[
          { label: '대시보드' },
          { label: '학습' },
          { label: '지식 그래프' }
        ]}
      />

      {/* 통계 카드 */}
      <div className="grid grid-cols-1 md:grid-cols-5 gap-4">
        <NotionStatCard
          title="전체 개념"
          value={knowledgeStats.totalConcepts.toString()}
          icon={<Brain className="w-5 h-5 text-blue-500" />}
        />
        <NotionStatCard
          title="마스터"
          value={knowledgeStats.masteredConcepts.toString()}
          icon={<CheckCircle className="w-5 h-5 text-green-500" />}
        />
        <NotionStatCard
          title="취약"
          value={knowledgeStats.weakConcepts.toString()}
          icon={<AlertTriangle className="w-5 h-5 text-yellow-500" />}
        />
        <NotionStatCard
          title="미학습"
          value={knowledgeStats.unknownConcepts.toString()}
          icon={<XCircle className="w-5 h-5 text-gray-500" />}
        />
        <NotionStatCard
          title="연결"
          value={knowledgeStats.connections.toString()}
          icon={<Network className="w-5 h-5 text-purple-500" />}
        />
      </div>

      {/* 3D 그래프 영역 */}
      <NotionCard title="지식 네트워크 시각화" icon={<Network className="w-5 h-5" />}>
        <div className="p-6">
          <div className="mb-4 flex items-center justify-between">
            <div className="flex items-center gap-4">
              <button
                onClick={() => setZoomLevel(Math.max(0.5, zoomLevel - 0.1))}
                className="px-3 py-1 bg-gray-100 dark:bg-gray-700 rounded hover:bg-gray-200 dark:hover:bg-gray-600"
              >
                축소
              </button>
              <span className="text-sm">줌: {Math.round(zoomLevel * 100)}%</span>
              <button
                onClick={() => setZoomLevel(Math.min(2, zoomLevel + 0.1))}
                className="px-3 py-1 bg-gray-100 dark:bg-gray-700 rounded hover:bg-gray-200 dark:hover:bg-gray-600"
              >
                확대
              </button>
            </div>
            <div className="flex items-center gap-2">
              <span className="text-xs px-2 py-1 bg-green-100 dark:bg-green-900 text-green-700 dark:text-green-300 rounded">
                마스터
              </span>
              <span className="text-xs px-2 py-1 bg-yellow-100 dark:bg-yellow-900 text-yellow-700 dark:text-yellow-300 rounded">
                학습중
              </span>
              <span className="text-xs px-2 py-1 bg-red-100 dark:bg-red-900 text-red-700 dark:text-red-300 rounded">
                취약
              </span>
              <span className="text-xs px-2 py-1 bg-gray-100 dark:bg-gray-700 text-gray-700 dark:text-gray-300 rounded">
                미학습
              </span>
            </div>
          </div>
          <div className="bg-gray-50 dark:bg-gray-900 rounded-lg p-4" style={{ height: '400px' }}>
            <canvas
              ref={canvasRef}
              className="w-full h-full"
              style={{ cursor: 'grab' }}
            />
          </div>
          <div className="mt-4 text-center text-sm text-gray-600 dark:text-gray-400">
            * 실제 서비스에서는 React Three Fiber를 사용한 3D 인터랙티브 그래프로 구현됩니다
          </div>
        </div>
      </NotionCard>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* 취약 영역 분석 */}
        <NotionCard title="취약 영역 TOP" icon={<AlertTriangle className="w-5 h-5" />}>
          <div className="p-6 space-y-3">
            {weakAreas.map((area, index) => (
              <div
                key={index}
                className="p-4 border border-gray-200 dark:border-gray-700 rounded-lg hover:bg-gray-50 dark:hover:bg-gray-800 cursor-pointer"
              >
                <div className="flex items-center justify-between mb-2">
                  <div>
                    <h3 className="font-medium">{area.name}</h3>
                    <span className="text-xs text-gray-500">{area.category}</span>
                  </div>
                  <span className="text-sm font-medium text-red-600 dark:text-red-400">
                    {area.strength}%
                  </span>
                </div>
                <div className="w-full bg-gray-200 dark:bg-gray-700 rounded-full h-2 mb-2">
                  <div
                    className="bg-red-500 h-2 rounded-full"
                    style={{ width: `${area.strength}%` }}
                  />
                </div>
                <div className="flex items-center justify-between text-xs text-gray-600 dark:text-gray-400">
                  <span>관련 문제: {area.relatedQuestions}개</span>
                  <button className="text-blue-500 hover:underline">집중 학습</button>
                </div>
              </div>
            ))}
          </div>
        </NotionCard>

        {/* 학습 경로 추천 */}
        <NotionCard title="추천 학습 경로" icon={<TrendingUp className="w-5 h-5" />}>
          <div className="p-6">
            <div className="space-y-4">
              <div className="flex items-start gap-3">
                <div className="w-8 h-8 bg-blue-500 text-white rounded-full flex items-center justify-center text-sm font-bold">
                  1
                </div>
                <div className="flex-1">
                  <h3 className="font-medium">인덱싱 기초</h3>
                  <p className="text-sm text-gray-600 dark:text-gray-400 mt-1">
                    B-Tree 구조와 인덱스 스캔 방식 이해
                  </p>
                  <div className="mt-2 flex items-center gap-2">
                    <span className="text-xs px-2 py-1 bg-blue-100 dark:bg-blue-900 text-blue-700 dark:text-blue-300 rounded">
                      15문제
                    </span>
                    <span className="text-xs text-gray-500">예상 시간: 30분</span>
                  </div>
                </div>
              </div>

              <div className="flex items-start gap-3">
                <div className="w-8 h-8 bg-purple-500 text-white rounded-full flex items-center justify-center text-sm font-bold">
                  2
                </div>
                <div className="flex-1">
                  <h3 className="font-medium">정규화 심화</h3>
                  <p className="text-sm text-gray-600 dark:text-gray-400 mt-1">
                    3NF, BCNF 개념과 정규화 실습
                  </p>
                  <div className="mt-2 flex items-center gap-2">
                    <span className="text-xs px-2 py-1 bg-purple-100 dark:bg-purple-900 text-purple-700 dark:text-purple-300 rounded">
                      20문제
                    </span>
                    <span className="text-xs text-gray-500">예상 시간: 45분</span>
                  </div>
                </div>
              </div>

              <div className="flex items-start gap-3">
                <div className="w-8 h-8 bg-green-500 text-white rounded-full flex items-center justify-center text-sm font-bold">
                  3
                </div>
                <div className="flex-1">
                  <h3 className="font-medium">트랜잭션 관리</h3>
                  <p className="text-sm text-gray-600 dark:text-gray-400 mt-1">
                    격리 수준과 동시성 제어 메커니즘
                  </p>
                  <div className="mt-2 flex items-center gap-2">
                    <span className="text-xs px-2 py-1 bg-green-100 dark:bg-green-900 text-green-700 dark:text-green-300 rounded">
                      25문제
                    </span>
                    <span className="text-xs text-gray-500">예상 시간: 60분</span>
                  </div>
                </div>
              </div>
            </div>

            <button className="mt-6 w-full px-4 py-2 bg-blue-500 text-white rounded-lg hover:bg-blue-600">
              학습 경로 시작하기
            </button>
          </div>
        </NotionCard>
      </div>

      {/* 개념 관계도 */}
      <NotionCard title="개념 관계 분석" icon={<Layers className="w-5 h-5" />}>
        <div className="p-6">
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            <div className="p-4 bg-blue-50 dark:bg-blue-900/20 rounded-lg">
              <h3 className="font-medium mb-2">선수 지식</h3>
              <div className="space-y-2">
                <div className="text-sm">
                  <span className="font-medium">SQL 기본</span>
                  <span className="text-gray-600 dark:text-gray-400 ml-2">→ JOIN</span>
                </div>
                <div className="text-sm">
                  <span className="font-medium">집합론</span>
                  <span className="text-gray-600 dark:text-gray-400 ml-2">→ 정규화</span>
                </div>
                <div className="text-sm">
                  <span className="font-medium">자료구조</span>
                  <span className="text-gray-600 dark:text-gray-400 ml-2">→ 인덱싱</span>
                </div>
              </div>
            </div>

            <div className="p-4 bg-green-50 dark:bg-green-900/20 rounded-lg">
              <h3 className="font-medium mb-2">강한 연결</h3>
              <div className="space-y-2">
                <div className="text-sm">
                  <span>인덱싱 ↔ 쿼리 최적화</span>
                </div>
                <div className="text-sm">
                  <span>정규화 ↔ 무결성 제약</span>
                </div>
                <div className="text-sm">
                  <span>트랜잭션 ↔ 동시성 제어</span>
                </div>
              </div>
            </div>

            <div className="p-4 bg-purple-50 dark:bg-purple-900/20 rounded-lg">
              <h3 className="font-medium mb-2">응용 분야</h3>
              <div className="space-y-2">
                <div className="text-sm">
                  <span>NoSQL 데이터베이스</span>
                </div>
                <div className="text-sm">
                  <span>분산 데이터베이스</span>
                </div>
                <div className="text-sm">
                  <span>데이터 웨어하우스</span>
                </div>
              </div>
            </div>
          </div>
        </div>
      </NotionCard>
    </div>
  );
}