'use client';

import { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import { useAuth } from '@clerk/nextjs';
import { Upload, FileText, X, AlertCircle } from 'lucide-react';

interface Certification {
  id: string;
  name: string;
  category: string;
  organization: string;
}

export default function NewStudySetPage() {
  const router = useRouter();
  const { getToken } = useAuth();
  const [file, setFile] = useState<File | null>(null);
  const [name, setName] = useState('');
  const [uploading, setUploading] = useState(false);
  const [error, setError] = useState('');
  const [certificationId, setCertificationId] = useState('');
  const [certifications, setCertifications] = useState<Certification[]>([]);
  const [loadingCerts, setLoadingCerts] = useState(true);

  // Fetch certifications on component mount
  useEffect(() => {
    const fetchCertifications = async () => {
      try {
        const response = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/v1/certifications`);
        if (response.ok) {
          const data = await response.json();
          setCertifications(data.certifications || []);
        } else {
          console.error('Failed to fetch certifications');
        }
      } catch (err) {
        console.error('Error fetching certifications:', err);
      } finally {
        setLoadingCerts(false);
      }
    };

    fetchCertifications();
  }, []);

  const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const selectedFile = e.target.files?.[0];
    if (selectedFile) {
      if (selectedFile.type !== 'application/pdf') {
        setError('PDF 파일만 업로드 가능합니다.');
        return;
      }
      if (selectedFile.size > 50 * 1024 * 1024) {
        setError('파일 크기는 50MB를 초과할 수 없습니다.');
        return;
      }
      setFile(selectedFile);
      setError('');
      // Auto-generate name from filename
      if (!name) {
        setName(selectedFile.name.replace('.pdf', ''));
      }
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    if (!file) {
      setError('PDF 파일을 선택해주세요.');
      return;
    }

    if (!name.trim()) {
      setError('문제집 이름을 입력해주세요.');
      return;
    }

    if (!certificationId) {
      setError('자격증을 선택해주세요.');
      return;
    }

    try {
      setUploading(true);
      setError('');

      const token = await getToken();
      const formData = new FormData();
      formData.append('file', file);
      formData.append('name', name);
      formData.append('certification_id', certificationId);

      const response = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/v1/study-sets/upload`, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${token}`,
        },
        body: formData,
      });

      if (!response.ok) {
        const errorData = await response.json();
        throw new Error(errorData.detail || '업로드에 실패했습니다.');
      }

      const data = await response.json();
      console.log('Upload success:', data);

      // Redirect to study sets list
      router.push('/dashboard/study-sets');
    } catch (err: any) {
      console.error('Upload error:', err);
      setError(err.message || '업로드 중 오류가 발생했습니다.');
    } finally {
      setUploading(false);
    }
  };

  return (
    <div className="max-w-2xl mx-auto">
      <div className="mb-8">
        <h1 className="text-3xl font-bold text-gray-900 dark:text-gray-100 mb-2">
          새 문제집 추가
        </h1>
        <p className="text-gray-600 dark:text-gray-400">
          PDF 파일을 업로드하여 새로운 문제집을 만드세요
        </p>
      </div>

      <form onSubmit={handleSubmit} className="space-y-6">
        {/* File Upload */}
        <div className="bg-white dark:bg-gray-800 rounded-lg shadow-sm p-6">
          <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
            PDF 파일
          </label>

          {!file ? (
            <label className="flex flex-col items-center justify-center w-full h-64 border-2 border-dashed border-gray-300 dark:border-gray-700 rounded-lg cursor-pointer hover:bg-gray-50 dark:hover:bg-gray-700 transition-colors">
              <div className="flex flex-col items-center justify-center pt-5 pb-6">
                <Upload className="w-12 h-12 text-gray-400 mb-3" />
                <p className="mb-2 text-sm text-gray-500 dark:text-gray-400">
                  <span className="font-semibold">클릭하여 업로드</span> 또는 드래그 앤 드롭
                </p>
                <p className="text-xs text-gray-500 dark:text-gray-400">
                  PDF 파일 (최대 50MB)
                </p>
              </div>
              <input
                type="file"
                accept=".pdf"
                onChange={handleFileChange}
                className="hidden"
              />
            </label>
          ) : (
            <div className="flex items-center justify-between p-4 bg-blue-50 dark:bg-blue-900/20 rounded-lg">
              <div className="flex items-center gap-3">
                <FileText className="w-10 h-10 text-blue-600 dark:text-blue-400" />
                <div>
                  <p className="font-medium text-gray-900 dark:text-gray-100">
                    {file.name}
                  </p>
                  <p className="text-sm text-gray-500 dark:text-gray-400">
                    {(file.size / 1024 / 1024).toFixed(2)} MB
                  </p>
                </div>
              </div>
              <button
                type="button"
                onClick={() => setFile(null)}
                className="p-2 text-gray-500 hover:text-red-600 transition-colors"
              >
                <X className="w-5 h-5" />
              </button>
            </div>
          )}
        </div>

        {/* Study Set Name */}
        <div className="bg-white dark:bg-gray-800 rounded-lg shadow-sm p-6">
          <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
            문제집 이름
          </label>
          <input
            type="text"
            value={name}
            onChange={(e) => setName(e.target.value)}
            placeholder="예: 2024 사회복지사 1급 기출문제"
            className="w-full px-4 py-2 border border-gray-300 dark:border-gray-700 rounded-lg bg-white dark:bg-gray-900 text-gray-900 dark:text-gray-100 focus:outline-none focus:ring-2 focus:ring-blue-500"
            required
          />
        </div>

        {/* Certification Selection */}
        <div className="bg-white dark:bg-gray-800 rounded-lg shadow-sm p-6">
          <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
            자격증 선택
          </label>
          <select
            value={certificationId}
            onChange={(e) => setCertificationId(e.target.value)}
            className="w-full px-4 py-2 border border-gray-300 dark:border-gray-700 rounded-lg bg-white dark:bg-gray-900 text-gray-900 dark:text-gray-100 focus:outline-none focus:ring-2 focus:ring-blue-500"
            required
            disabled={loadingCerts}
          >
            <option value="">
              {loadingCerts ? '자격증 목록 로딩 중...' : '자격증을 선택하세요'}
            </option>
            {certifications.map((cert) => (
              <option key={cert.id} value={cert.id}>
                {cert.name} ({cert.organization})
              </option>
            ))}
          </select>
          <p className="mt-2 text-sm text-gray-500 dark:text-gray-400">
            💡 업로드하려면 해당 자격증에 대한 구독이 필요합니다
          </p>
          {certifications.length === 0 && !loadingCerts && (
            <p className="mt-2 text-sm text-amber-600 dark:text-amber-400">
              ⚠️ 자격증 목록을 불러오지 못했습니다
            </p>
          )}
        </div>

        {/* Error Message */}
        {error && (
          <div className="bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-lg p-4 flex items-start gap-3">
            <AlertCircle className="w-5 h-5 text-red-600 dark:text-red-400 flex-shrink-0 mt-0.5" />
            <p className="text-sm text-red-800 dark:text-red-200">{error}</p>
          </div>
        )}

        {/* Actions */}
        <div className="flex gap-4">
          <button
            type="button"
            onClick={() => router.back()}
            className="flex-1 px-6 py-3 border border-gray-300 dark:border-gray-700 text-gray-700 dark:text-gray-300 rounded-lg hover:bg-gray-50 dark:hover:bg-gray-700 transition-colors"
          >
            취소
          </button>
          <button
            type="submit"
            disabled={uploading || !file || !name}
            className="flex-1 px-6 py-3 bg-blue-600 text-white rounded-lg hover:bg-blue-700 disabled:bg-gray-300 disabled:cursor-not-allowed transition-colors"
          >
            {uploading ? (
              <span className="flex items-center justify-center gap-2">
                <div className="animate-spin rounded-full h-5 w-5 border-b-2 border-white"></div>
                업로드 중...
              </span>
            ) : (
              '문제집 생성'
            )}
          </button>
        </div>
      </form>
    </div>
  );
}
