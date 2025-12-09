'use client';

import { NotionCard, NotionPageHeader, NotionStatCard } from '@/components/ui/NotionCard';
import { Shield, Server, GitBranch, Users, Monitor, BarChart, CheckCircle, XCircle } from 'lucide-react';
import { useState } from 'react';

export default function InfoSystemStudyPage() {
  const [selectedModule, setSelectedModule] = useState('');

  const modules = [
    { id: 'project-mgmt', name: '프로젝트 관리', progress: 72, topics: 12 },
    { id: 'system-analysis', name: '시스템 분석', progress: 68, topics: 15 },
    { id: 'security-mgmt', name: '보안 관리', progress: 85, topics: 10 },
    { id: 'quality-mgmt', name: '품질 관리', progress: 60, topics: 8 },
    { id: 'risk-mgmt', name: '위험 관리', progress: 55, topics: 9 },
    { id: 'it-governance', name: 'IT 거버넌스', progress: 45, topics: 11 }
  ];

  const methodologies = [
    { name: 'Waterfall', understanding: 90, practical: 85, lastStudied: '2일 전' },
    { name: 'Agile/Scrum', understanding: 75, practical: 70, lastStudied: '오늘' },
    { name: 'DevOps', understanding: 60, practical: 50, lastStudied: '5일 전' },
    { name: 'ITIL', understanding: 55, practical: 45, lastStudied: '1주 전' }
  ];

  const securityTopics = [
    { name: '접근 통제', mastery: 85, questions: 45 },
    { name: '암호화', mastery: 70, questions: 60 },
    { name: '네트워크 보안', mastery: 65, questions: 55 },
    { name: '애플리케이션 보안', mastery: 75, questions: 40 },
    { name: '물리적 보안', mastery: 90, questions: 25 }
  ];

  return (
    <div className="space-y-6">
      <NotionPageHeader
        title="정보시스템 구축관리"
        icon="🏢"
        breadcrumbs={[
          { label: '대시보드' },
          { label: '학습' },
          { label: '정보시스템 구축관리' }
        ]}
      />

      {/* 학습 통계 */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
        <NotionStatCard
          title="전체 진도"
          value="71%"
          icon={<Monitor className="w-5 h-5 text-orange-500" />}
          trend={{ value: 6, isUp: true }}
        />
        <NotionStatCard
          title="완료 문제"
          value="199"
          description="총 280문제"
          icon={<Server className="w-5 h-5 text-blue-500" />}
        />
        <NotionStatCard
          title="보안 마스터리"
          value="85%"
          icon={<Shield className="w-5 h-5 text-green-500" />}
        />
        <NotionStatCard
          title="방법론 이해"
          value="70%"
          icon={<GitBranch className="w-5 h-5 text-purple-500" />}
        />
      </div>

      {/* 학습 모듈 */}
      <NotionCard title="학습 모듈" icon={<Server className="w-5 h-5" />}>
        <div className="p-6">
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
            {modules.map((module) => (
              <div
                key={module.id}
                onClick={() => setSelectedModule(module.id)}
                className={`p-4 border-2 rounded-lg cursor-pointer transition-all ${
                  selectedModule === module.id
                    ? 'border-orange-500 bg-orange-50 dark:bg-orange-900/20'
                    : 'border-gray-200 dark:border-gray-700 hover:bg-gray-50 dark:hover:bg-gray-800'
                }`}
              >
                <div className="flex justify-between items-start mb-3">
                  <h3 className="font-semibold">{module.name}</h3>
                  <span className="text-sm text-gray-500">{module.topics}개 주제</span>
                </div>
                <div className="space-y-2">
                  <div className="flex justify-between text-sm">
                    <span>완료율</span>
                    <span className={`font-medium ${
                      module.progress >= 80 ? 'text-green-600 dark:text-green-400' :
                      module.progress >= 60 ? 'text-yellow-600 dark:text-yellow-400' :
                      'text-red-600 dark:text-red-400'
                    }`}>
                      {module.progress}%
                    </span>
                  </div>
                  <div className="w-full bg-gray-200 dark:bg-gray-700 rounded-full h-2">
                    <div
                      className={`h-2 rounded-full ${
                        module.progress >= 80 ? 'bg-green-500' :
                        module.progress >= 60 ? 'bg-yellow-500' :
                        'bg-red-500'
                      }`}
                      style={{ width: `${module.progress}%` }}
                    />
                  </div>
                </div>
              </div>
            ))}
          </div>
        </div>
      </NotionCard>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* 방법론 이해도 */}
        <NotionCard title="개발 방법론" icon={<GitBranch className="w-5 h-5" />}>
          <div className="p-6 space-y-4">
            {methodologies.map((method, index) => (
              <div key={index} className="space-y-2">
                <div className="flex items-center justify-between">
                  <div>
                    <span className="font-medium">{method.name}</span>
                    <span className="text-xs text-gray-500 ml-2">({method.lastStudied})</span>
                  </div>
                </div>
                <div className="grid grid-cols-2 gap-2">
                  <div>
                    <div className="flex justify-between text-xs mb-1">
                      <span>이론 이해</span>
                      <span>{method.understanding}%</span>
                    </div>
                    <div className="w-full bg-gray-200 dark:bg-gray-700 rounded-full h-1.5">
                      <div
                        className="bg-blue-500 h-1.5 rounded-full"
                        style={{ width: `${method.understanding}%` }}
                      />
                    </div>
                  </div>
                  <div>
                    <div className="flex justify-between text-xs mb-1">
                      <span>실무 적용</span>
                      <span>{method.practical}%</span>
                    </div>
                    <div className="w-full bg-gray-200 dark:bg-gray-700 rounded-full h-1.5">
                      <div
                        className="bg-green-500 h-1.5 rounded-full"
                        style={{ width: `${method.practical}%` }}
                      />
                    </div>
                  </div>
                </div>
              </div>
            ))}
            <button className="mt-4 w-full px-4 py-2 bg-orange-500 text-white rounded-lg hover:bg-orange-600">
              방법론 심화 학습
            </button>
          </div>
        </NotionCard>

        {/* 보안 관리 */}
        <NotionCard title="정보 보안" icon={<Shield className="w-5 h-5" />}>
          <div className="p-6 space-y-3">
            {securityTopics.map((topic, index) => (
              <div
                key={index}
                className="flex items-center justify-between p-3 bg-gray-50 dark:bg-gray-800 rounded-lg"
              >
                <div className="flex-1">
                  <div className="flex items-center justify-between mb-1">
                    <span className="font-medium text-sm">{topic.name}</span>
                    <span className="text-xs text-gray-500">{topic.questions}문제</span>
                  </div>
                  <div className="flex items-center gap-2">
                    <div className="flex-1 bg-gray-200 dark:bg-gray-700 rounded-full h-1.5">
                      <div
                        className="bg-green-500 h-1.5 rounded-full"
                        style={{ width: `${topic.mastery}%` }}
                      />
                    </div>
                    <span className="text-xs font-medium">{topic.mastery}%</span>
                  </div>
                </div>
              </div>
            ))}
            <div className="pt-3 border-t dark:border-gray-700">
              <div className="flex items-center justify-between mb-2">
                <span className="font-medium">보안 종합 점수</span>
                <span className="text-lg font-bold text-green-600 dark:text-green-400">85%</span>
              </div>
              <p className="text-xs text-gray-600 dark:text-gray-400">
                CISSP 기준 상위 15% 수준
              </p>
            </div>
          </div>
        </NotionCard>
      </div>

      {/* 프로젝트 관리 */}
      <NotionCard title="프로젝트 관리 역량" icon={<Users className="w-5 h-5" />}>
        <div className="p-6">
          <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
            <div className="text-center p-4 bg-blue-50 dark:bg-blue-900/20 rounded-lg">
              <BarChart className="w-8 h-8 text-blue-500 mx-auto mb-2" />
              <h3 className="font-semibold mb-1">WBS 작성</h3>
              <div className="text-2xl font-bold text-blue-600 dark:text-blue-400">92%</div>
              <p className="text-xs text-gray-600 dark:text-gray-400 mt-1">15문제 완료</p>
            </div>
            <div className="text-center p-4 bg-green-50 dark:bg-green-900/20 rounded-lg">
              <CheckCircle className="w-8 h-8 text-green-500 mx-auto mb-2" />
              <h3 className="font-semibold mb-1">일정 관리</h3>
              <div className="text-2xl font-bold text-green-600 dark:text-green-400">78%</div>
              <p className="text-xs text-gray-600 dark:text-gray-400 mt-1">12문제 완료</p>
            </div>
            <div className="text-center p-4 bg-yellow-50 dark:bg-yellow-900/20 rounded-lg">
              <XCircle className="w-8 h-8 text-yellow-500 mx-auto mb-2" />
              <h3 className="font-semibold mb-1">위험 분석</h3>
              <div className="text-2xl font-bold text-yellow-600 dark:text-yellow-400">65%</div>
              <p className="text-xs text-gray-600 dark:text-gray-400 mt-1">8문제 완료</p>
            </div>
          </div>
          <div className="mt-6 p-4 bg-gradient-to-r from-orange-500 to-red-500 rounded-lg text-white">
            <h3 className="text-lg font-semibold mb-2">PMP 모의고사</h3>
            <p className="text-sm mb-3">
              프로젝트 관리 전문가 자격증 대비 실전 문제
            </p>
            <button className="px-4 py-2 bg-white text-orange-600 rounded-lg hover:bg-gray-100">
              모의고사 시작
            </button>
          </div>
        </div>
      </NotionCard>

      {/* 최근 학습 이력 */}
      <NotionCard title="최근 학습 이력" icon={<Monitor className="w-5 h-5" />}>
        <div className="p-6">
          <div className="space-y-3">
            <div className="flex items-center justify-between p-3 border-l-4 border-green-500 bg-gray-50 dark:bg-gray-800">
              <div>
                <p className="font-medium">IT 거버넌스 - COBIT 프레임워크</p>
                <p className="text-xs text-gray-600 dark:text-gray-400">30분 전 • 10문제 중 8문제 정답</p>
              </div>
              <CheckCircle className="w-5 h-5 text-green-500" />
            </div>
            <div className="flex items-center justify-between p-3 border-l-4 border-yellow-500 bg-gray-50 dark:bg-gray-800">
              <div>
                <p className="font-medium">시스템 분석 - DFD 작성법</p>
                <p className="text-xs text-gray-600 dark:text-gray-400">2시간 전 • 15문제 중 10문제 정답</p>
              </div>
              <XCircle className="w-5 h-5 text-yellow-500" />
            </div>
            <div className="flex items-center justify-between p-3 border-l-4 border-blue-500 bg-gray-50 dark:bg-gray-800">
              <div>
                <p className="font-medium">품질 관리 - ISO 9001</p>
                <p className="text-xs text-gray-600 dark:text-gray-400">어제 • 20문제 중 18문제 정답</p>
              </div>
              <CheckCircle className="w-5 h-5 text-blue-500" />
            </div>
          </div>
        </div>
      </NotionCard>
    </div>
  );
}