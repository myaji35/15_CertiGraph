'use client';

import { useState } from 'react';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs';
import { CalendarView } from '@/components/certifications/calendar-view';
import { CertificationList } from '@/components/certifications/certification-list';
import { UpcomingExams } from '@/components/certifications/upcoming-exams';
import { Award, Calendar, Clock } from 'lucide-react';
import type { Certification } from '@/types/certification';

export default function CertificationsPage() {
  const [selectedCertification, setSelectedCertification] = useState<Certification | null>(null);
  const [activeTab, setActiveTab] = useState('list');

  const handleSelectCertification = (certification: Certification) => {
    setSelectedCertification(certification);
    // 자격증 선택 후 달력 탭으로 자동 이동
    if (activeTab === 'list') {
      setActiveTab('calendar');
    }
  };

  return (
    <div className="container mx-auto px-4 py-8">
      {/* Page Header */}
      <div className="mb-8">
        <h1 className="text-3xl font-bold text-gray-900 mb-2">자격증 시험 캘린더</h1>
        <p className="text-gray-600">
          전국 자격증 시험 일정을 확인하고 목표 자격증을 선택하세요.
        </p>

        {selectedCertification && (
          <div className="mt-4 p-4 bg-indigo-50 rounded-lg">
            <div className="flex items-center gap-2 text-sm">
              <Award className="h-4 w-4 text-indigo-600" />
              <span className="font-medium">선택된 자격증:</span>
              <span className="font-bold text-indigo-700">
                {selectedCertification.name}
              </span>
              <button
                onClick={() => setSelectedCertification(null)}
                className="ml-auto text-xs text-gray-500 hover:text-gray-700"
              >
                변경
              </button>
            </div>
          </div>
        )}
      </div>

      {/* Tabs */}
      <Tabs value={activeTab} onValueChange={setActiveTab}>
        <TabsList className="grid w-full grid-cols-3 mb-8">
          <TabsTrigger value="list" className="flex items-center gap-2">
            <Award className="h-4 w-4" />
            자격증 목록
          </TabsTrigger>
          <TabsTrigger value="calendar" className="flex items-center gap-2">
            <Calendar className="h-4 w-4" />
            시험 달력
          </TabsTrigger>
          <TabsTrigger value="upcoming" className="flex items-center gap-2">
            <Clock className="h-4 w-4" />
            다가오는 시험
          </TabsTrigger>
        </TabsList>

        <TabsContent value="list" className="space-y-6">
          <CertificationList onSelect={handleSelectCertification} />
        </TabsContent>

        <TabsContent value="calendar" className="space-y-6">
          <CalendarView />
        </TabsContent>

        <TabsContent value="upcoming" className="space-y-6">
          <UpcomingExams />
        </TabsContent>
      </Tabs>

      {/* Bottom CTA */}
      {selectedCertification && (
        <div className="mt-12 p-6 bg-gradient-to-r from-indigo-500 to-purple-600 rounded-lg text-white">
          <h3 className="text-xl font-bold mb-2">
            {selectedCertification.name} 준비를 시작하세요!
          </h3>
          <p className="mb-4">
            문제집 PDF를 업로드하면 AI가 학습을 도와드립니다.
          </p>
          <a
            href="/study-sets"
            className="inline-block px-6 py-3 bg-white text-indigo-600 font-medium rounded-lg hover:bg-gray-100 transition-colors"
          >
            문제집 업로드하기
          </a>
        </div>
      )}
    </div>
  );
}