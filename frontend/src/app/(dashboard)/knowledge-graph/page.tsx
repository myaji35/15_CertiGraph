"use client";

import { useState, useEffect, useCallback, useRef } from 'react';
import dynamic from 'next/dynamic';
import { UserButton } from '@clerk/nextjs';
import Link from 'next/link';
import {
  Home,
  BookOpen,
  Brain,
  ChevronLeft,
  ZoomIn,
  ZoomOut,
  Maximize2,
  RefreshCw,
  Info,
  Layers,
  Target
} from 'lucide-react';

// Dynamic import for force graph (client-side only)
const ForceGraph2D = dynamic(
  () => import('react-force-graph-2d').then(mod => mod.default),
  { ssr: false }
);

interface GraphNode {
  id: string;
  name: string;
  val: number;
  color: string;
  category: 'chapter' | 'topic' | 'concept';
  mastery: number; // 0-100
  questions: number;
  correct: number;
}

interface GraphLink {
  source: string;
  target: string;
  value: number;
}

interface GraphData {
  nodes: GraphNode[];
  links: GraphLink[];
}

export default function KnowledgeGraphPage() {
  const [graphData, setGraphData] = useState<GraphData>({ nodes: [], links: [] });
  const [selectedNode, setSelectedNode] = useState<GraphNode | null>(null);
  const [highlightNodes, setHighlightNodes] = useState(new Set());
  const [highlightLinks, setHighlightLinks] = useState(new Set());
  const [hoverNode, setHoverNode] = useState<GraphNode | null>(null);
  const [dimensions, setDimensions] = useState({ width: 800, height: 600 });
  const graphRef = useRef<any>(null);

  // Generate sample data
  useEffect(() => {
    const generateSampleData = (): GraphData => {
      const chapters = [
        { id: 'ch1', name: '사회복지정책론', mastery: 75 },
        { id: 'ch2', name: '사회복지행정론', mastery: 60 },
        { id: 'ch3', name: '사회복지법제론', mastery: 45 },
      ];

      const topics = [
        { id: 't1', name: '복지국가', chapter: 'ch1', mastery: 80 },
        { id: 't2', name: '사회보장', chapter: 'ch1', mastery: 70 },
        { id: 't3', name: '조직이론', chapter: 'ch2', mastery: 65 },
        { id: 't4', name: '인적자원관리', chapter: 'ch2', mastery: 55 },
        { id: 't5', name: '사회복지법', chapter: 'ch3', mastery: 50 },
        { id: 't6', name: '권리구제', chapter: 'ch3', mastery: 40 },
      ];

      const concepts = [
        { id: 'c1', name: '베버리지 보고서', topic: 't1', mastery: 85 },
        { id: 'c2', name: '복지다원주의', topic: 't1', mastery: 75 },
        { id: 'c3', name: '사회보험', topic: 't2', mastery: 70 },
        { id: 'c4', name: '공공부조', topic: 't2', mastery: 65 },
        { id: 'c5', name: '관료제', topic: 't3', mastery: 60 },
        { id: 'c6', name: '매트릭스 조직', topic: 't3', mastery: 70 },
        { id: 'c7', name: '동기부여이론', topic: 't4', mastery: 55 },
        { id: 'c8', name: '리더십', topic: 't4', mastery: 50 },
        { id: 'c9', name: '사회보장기본법', topic: 't5', mastery: 45 },
        { id: 'c10', name: '국민기초생활보장법', topic: 't5', mastery: 55 },
        { id: 'c11', name: '행정심판', topic: 't6', mastery: 35 },
        { id: 'c12', name: '행정소송', topic: 't6', mastery: 40 },
      ];

      const nodes: GraphNode[] = [];
      const links: GraphLink[] = [];

      // Add chapter nodes
      chapters.forEach(ch => {
        nodes.push({
          id: ch.id,
          name: ch.name,
          val: 30,
          color: getMasteryColor(ch.mastery),
          category: 'chapter',
          mastery: ch.mastery,
          questions: Math.floor(Math.random() * 50) + 20,
          correct: Math.floor(ch.mastery * 0.5)
        });
      });

      // Add topic nodes and links
      topics.forEach(topic => {
        nodes.push({
          id: topic.id,
          name: topic.name,
          val: 20,
          color: getMasteryColor(topic.mastery),
          category: 'topic',
          mastery: topic.mastery,
          questions: Math.floor(Math.random() * 30) + 10,
          correct: Math.floor(topic.mastery * 0.3)
        });
        links.push({
          source: topic.chapter,
          target: topic.id,
          value: 3
        });
      });

      // Add concept nodes and links
      concepts.forEach(concept => {
        nodes.push({
          id: concept.id,
          name: concept.name,
          val: 10,
          color: getMasteryColor(concept.mastery),
          category: 'concept',
          mastery: concept.mastery,
          questions: Math.floor(Math.random() * 15) + 5,
          correct: Math.floor(concept.mastery * 0.15)
        });
        links.push({
          source: concept.topic,
          target: concept.id,
          value: 1
        });
      });

      // Add some cross-links between related concepts
      links.push(
        { source: 'c3', target: 'c4', value: 0.5 }, // 사회보험 - 공공부조
        { source: 'c1', target: 'c3', value: 0.5 }, // 베버리지 - 사회보험
        { source: 'c11', target: 'c12', value: 0.5 }, // 행정심판 - 행정소송
      );

      return { nodes, links };
    };

    const data = generateSampleData();
    setGraphData(data);

    // Set dimensions
    if (typeof window !== 'undefined') {
      const updateDimensions = () => {
        setDimensions({
          width: window.innerWidth - 300, // Account for sidebar
          height: window.innerHeight - 200
        });
      };
      updateDimensions();
      window.addEventListener('resize', updateDimensions);
      return () => window.removeEventListener('resize', updateDimensions);
    }
  }, []);

  const getMasteryColor = (mastery: number): string => {
    if (mastery >= 80) return '#10b981'; // green
    if (mastery >= 60) return '#3b82f6'; // blue
    if (mastery >= 40) return '#f59e0b'; // amber
    if (mastery >= 20) return '#ef4444'; // red
    return '#6b7280'; // gray
  };

  const handleNodeClick = useCallback((node: GraphNode) => {
    setSelectedNode(node);

    // Highlight neighbors
    const neighbors = new Set<string>();
    const links = new Set();

    graphData.links.forEach(link => {
      if (link.source === node.id || (link.source as any).id === node.id) {
        neighbors.add(typeof link.target === 'string' ? link.target : (link.target as any).id);
        links.add(link);
      }
      if (link.target === node.id || (link.target as any).id === node.id) {
        neighbors.add(typeof link.source === 'string' ? link.source : (link.source as any).id);
        links.add(link);
      }
    });

    setHighlightNodes(neighbors);
    setHighlightLinks(links);
  }, [graphData]);

  const handleNodeHover = (node: GraphNode | null) => {
    setHoverNode(node);
  };

  const handleZoomIn = () => {
    if (graphRef.current) {
      graphRef.current.zoom(1.2);
    }
  };

  const handleZoomOut = () => {
    if (graphRef.current) {
      graphRef.current.zoom(0.8);
    }
  };

  const handleZoomFit = () => {
    if (graphRef.current) {
      graphRef.current.zoomToFit(400);
    }
  };

  const handleReset = () => {
    setSelectedNode(null);
    setHighlightNodes(new Set());
    setHighlightLinks(new Set());
    handleZoomFit();
  };

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
                <Brain className="w-6 h-6 text-blue-600" />
                지식 그래프
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
            {/* Stats */}
            <div className="space-y-4 mb-6">
              <div className="bg-blue-50 rounded-lg p-4">
                <div className="flex items-center gap-3 mb-2">
                  <Layers className="w-5 h-5 text-blue-600" />
                  <span className="font-semibold">전체 개요</span>
                </div>
                <div className="grid grid-cols-2 gap-2 text-sm">
                  <div>
                    <p className="text-gray-600">총 개념</p>
                    <p className="font-bold">{graphData.nodes.length}개</p>
                  </div>
                  <div>
                    <p className="text-gray-600">연결 관계</p>
                    <p className="font-bold">{graphData.links.length}개</p>
                  </div>
                </div>
              </div>

              {/* Selected Node Info */}
              {selectedNode ? (
                <div className="bg-white border rounded-lg p-4">
                  <div className="flex items-center gap-2 mb-3">
                    <div
                      className="w-3 h-3 rounded-full"
                      style={{ backgroundColor: selectedNode.color }}
                    />
                    <span className="font-semibold text-sm">{selectedNode.name}</span>
                  </div>
                  <div className="space-y-2">
                    <div>
                      <div className="flex justify-between text-sm">
                        <span className="text-gray-600">학습도</span>
                        <span className="font-medium">{selectedNode.mastery}%</span>
                      </div>
                      <div className="w-full bg-gray-200 rounded-full h-2 mt-1">
                        <div
                          className="h-2 rounded-full transition-all"
                          style={{
                            width: `${selectedNode.mastery}%`,
                            backgroundColor: selectedNode.color
                          }}
                        />
                      </div>
                    </div>
                    <div className="flex justify-between text-sm">
                      <span className="text-gray-600">문제 수</span>
                      <span>{selectedNode.questions}개</span>
                    </div>
                    <div className="flex justify-between text-sm">
                      <span className="text-gray-600">정답률</span>
                      <span>{Math.round((selectedNode.correct / selectedNode.questions) * 100)}%</span>
                    </div>
                  </div>
                </div>
              ) : (
                <div className="bg-gray-50 rounded-lg p-4 text-center text-sm text-gray-500">
                  노드를 클릭하여 상세 정보를 확인하세요
                </div>
              )}

              {/* Legend */}
              <div className="bg-white border rounded-lg p-4">
                <p className="font-semibold text-sm mb-3">범례</p>
                <div className="space-y-2">
                  <div className="flex items-center gap-2 text-sm">
                    <div className="w-3 h-3 rounded-full bg-green-500" />
                    <span>높은 학습도 (80%+)</span>
                  </div>
                  <div className="flex items-center gap-2 text-sm">
                    <div className="w-3 h-3 rounded-full bg-blue-500" />
                    <span>중간 학습도 (60-79%)</span>
                  </div>
                  <div className="flex items-center gap-2 text-sm">
                    <div className="w-3 h-3 rounded-full bg-amber-500" />
                    <span>낮은 학습도 (40-59%)</span>
                  </div>
                  <div className="flex items-center gap-2 text-sm">
                    <div className="w-3 h-3 rounded-full bg-red-500" />
                    <span>매우 낮음 (20-39%)</span>
                  </div>
                  <div className="flex items-center gap-2 text-sm">
                    <div className="w-3 h-3 rounded-full bg-gray-500" />
                    <span>미학습 (&lt;20%)</span>
                  </div>
                </div>
              </div>

              {/* Node Categories */}
              <div className="bg-white border rounded-lg p-4">
                <p className="font-semibold text-sm mb-3">카테고리</p>
                <div className="space-y-2">
                  <div className="flex items-center justify-between text-sm">
                    <span>📚 챕터</span>
                    <span className="text-gray-500">
                      {graphData.nodes.filter(n => n.category === 'chapter').length}개
                    </span>
                  </div>
                  <div className="flex items-center justify-between text-sm">
                    <span>📖 주제</span>
                    <span className="text-gray-500">
                      {graphData.nodes.filter(n => n.category === 'topic').length}개
                    </span>
                  </div>
                  <div className="flex items-center justify-between text-sm">
                    <span>💡 개념</span>
                    <span className="text-gray-500">
                      {graphData.nodes.filter(n => n.category === 'concept').length}개
                    </span>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>

        {/* Graph Container */}
        <div className="flex-1 relative bg-gray-100">
          {/* Controls */}
          <div className="absolute top-4 right-4 z-10 flex gap-2">
            <button
              onClick={handleZoomIn}
              className="bg-white p-2 rounded-lg shadow hover:bg-gray-50"
              title="확대"
            >
              <ZoomIn className="w-5 h-5" />
            </button>
            <button
              onClick={handleZoomOut}
              className="bg-white p-2 rounded-lg shadow hover:bg-gray-50"
              title="축소"
            >
              <ZoomOut className="w-5 h-5" />
            </button>
            <button
              onClick={handleZoomFit}
              className="bg-white p-2 rounded-lg shadow hover:bg-gray-50"
              title="화면에 맞추기"
            >
              <Maximize2 className="w-5 h-5" />
            </button>
            <button
              onClick={handleReset}
              className="bg-white p-2 rounded-lg shadow hover:bg-gray-50"
              title="초기화"
            >
              <RefreshCw className="w-5 h-5" />
            </button>
          </div>

          {/* Hover Info */}
          {hoverNode && (
            <div className="absolute top-4 left-4 z-10 bg-white rounded-lg shadow-lg p-3 max-w-xs">
              <p className="font-semibold text-sm">{hoverNode.name}</p>
              <p className="text-xs text-gray-600 mt-1">
                학습도: {hoverNode.mastery}% | 문제: {hoverNode.questions}개
              </p>
            </div>
          )}

          {/* Force Graph */}
          {typeof window !== 'undefined' && graphData.nodes.length > 0 && (
            <ForceGraph2D
              ref={graphRef}
              graphData={graphData}
              width={dimensions.width}
              height={dimensions.height}
              nodeLabel=""
              nodeRelSize={1}
              nodeVal={(node: any) => node.val}
              nodeColor={(node: any) => node.color}
              linkColor={() => '#d1d5db'}
              linkWidth={(link: any) => link.value}
              linkDirectionalParticles={2}
              linkDirectionalParticleSpeed={0.01}
              onNodeClick={handleNodeClick as any}
              onNodeHover={handleNodeHover as any}
              nodeCanvasObject={(node: any, ctx: CanvasRenderingContext2D, globalScale: number) => {
                const label = node.name;
                const fontSize = 12 / globalScale;
                ctx.font = `${fontSize}px Sans-Serif`;

                // Draw node circle
                ctx.fillStyle = node.color;
                ctx.beginPath();
                ctx.arc(node.x, node.y, node.val, 0, 2 * Math.PI, false);
                ctx.fill();

                // Draw label
                ctx.textAlign = 'center';
                ctx.textBaseline = 'middle';
                ctx.fillStyle = node.category === 'chapter' ? '#ffffff' : '#374151';
                const lines = label.length > 8 ? [label.slice(0, 8), label.slice(8)] : [label];
                lines.forEach((line, i) => {
                  ctx.fillText(line, node.x, node.y + (i * fontSize) - ((lines.length - 1) * fontSize / 2));
                });

                // Highlight on hover or selection
                if (highlightNodes.has(node.id) || node === hoverNode) {
                  ctx.strokeStyle = '#3b82f6';
                  ctx.lineWidth = 3 / globalScale;
                  ctx.beginPath();
                  ctx.arc(node.x, node.y, node.val + 2, 0, 2 * Math.PI, false);
                  ctx.stroke();
                }
              }}
              onBackgroundClick={() => {
                setSelectedNode(null);
                setHighlightNodes(new Set());
                setHighlightLinks(new Set());
              }}
              cooldownTicks={100}
              onEngineStop={() => graphRef.current && graphRef.current.zoomToFit(400)}
            />
          )}
        </div>
      </div>
    </div>
  );
}