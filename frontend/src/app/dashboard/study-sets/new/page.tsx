'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { useAuth } from '@clerk/nextjs';
import { ArrowLeft } from 'lucide-react';
import Link from 'next/link';
import PdfUploader from '@/components/study-sets/PdfUploader';

interface ExamMetadata {
  examName?: string;
  examYear?: number;
  examRound?: number;
  examSession?: number;
  examSessionName?: string;
  tags?: string[];
}

export default function NewStudySetPage() {
  const router = useRouter();
  const { getToken } = useAuth();
  const [isUploading, setIsUploading] = useState(false);
  const [uploadProgress, setUploadProgress] = useState(0);
  const [error, setError] = useState<string | null>(null);

  const handleUpload = async (file: File, name: string, metadata?: ExamMetadata) => {
    try {
      setIsUploading(true);
      setError(null);
      setUploadProgress(10);

      const token = await getToken();
      if (!token) {
        throw new Error('인증이 필요합니다.');
      }

      // Create FormData
      const formData = new FormData();
      formData.append('file', file);
      formData.append('name', name);

      // Add optional metadata
      if (metadata?.examName) formData.append('exam_name', metadata.examName);
      if (metadata?.examYear) formData.append('exam_year', String(metadata.examYear));
      if (metadata?.examRound) formData.append('exam_round', String(metadata.examRound));
      if (metadata?.examSession) formData.append('exam_session', String(metadata.examSession));
      if (metadata?.examSessionName) formData.append('exam_session_name', metadata.examSessionName);

      setUploadProgress(30);

      // Upload to backend
      const response = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/v1/study-sets/upload`, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${token}`,
        },
        body: formData,
      });

      setUploadProgress(70);

      if (!response.ok) {
        const errorData = await response.json();
        const errorMessage = errorData.error?.message || errorData.detail || '업로드에 실패했습니다.';
        throw new Error(errorMessage);
      }

      const data = await response.json();
      setUploadProgress(100);

      // Redirect to the study set detail page
      router.push(`/dashboard/study-sets/${data.data.id}`);

    } catch (err) {
      console.error('Upload error:', err);
      setError(err instanceof Error ? err.message : '업로드 중 오류가 발생했습니다.');
      setIsUploading(false);
      setUploadProgress(0);
    }
  };

  return (
    <div className="max-w-2xl mx-auto">
      {/* Header */}
      <div className="mb-8">
        <Link
          href="/dashboard/study-sets"
          className="inline-flex items-center gap-2 text-gray-500 hover:text-gray-700 mb-4 transition-colors"
        >
          <ArrowLeft className="w-4 h-4" />
          돌아가기
        </Link>
        <h1 className="text-2xl font-bold text-gray-900 dark:text-gray-100">
          새 문제집 만들기
        </h1>
        <p className="mt-2 text-gray-600 dark:text-gray-400">
          PDF 파일을 업로드하면 AI가 자동으로 문제를 추출합니다.
        </p>
      </div>

      {/* Upload Form */}
      <div className="bg-white dark:bg-gray-800 rounded-xl shadow-sm border border-gray-200 dark:border-gray-700 p-6">
        <PdfUploader
          onUpload={handleUpload}
          isUploading={isUploading}
          uploadProgress={uploadProgress}
        />

        {/* Error Display */}
        {error && (
          <div className="mt-4 p-4 bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-lg">
            <p className="text-sm text-red-800 dark:text-red-200">{error}</p>
          </div>
        )}
      </div>

      {/* Help Text */}
      <div className="mt-6 p-4 bg-blue-50 dark:bg-blue-900/20 rounded-lg border border-blue-200 dark:border-blue-800">
        <h3 className="font-medium text-blue-900 dark:text-blue-100 mb-2">
          지원하는 PDF 형식
        </h3>
        <ul className="text-sm text-blue-800 dark:text-blue-200 space-y-1">
          <li>• 사회복지사 1급 기출문제 PDF</li>
          <li>• 문제, 보기, 정답, 해설이 포함된 시험지</li>
          <li>• 스캔본 및 텍스트 기반 PDF 모두 지원</li>
        </ul>
      </div>
    </div>
  );
}
