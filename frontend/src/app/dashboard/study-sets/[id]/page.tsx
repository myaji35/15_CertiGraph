'use client';

import React, { useState, useEffect } from 'react';
import { useAuth } from '@clerk/nextjs';
import { useRouter, useParams } from 'next/navigation';
import { ArrowLeft, Upload, FileText, Trash2, Calendar, BookOpen, ChevronUpIcon, ChevronDownIcon, X } from 'lucide-react';

interface ProcessingLog {
  timestamp: string;
  progress: number;
  message: string;
  status: string;
}

interface StudyMaterial {
  id: string;
  title: string;
  pdf_url: string;
  file_size_bytes: number;
  status: string;
  total_questions: number;
  processing_progress: number;
  processing_logs?: ProcessingLog[];
  created_at: string;
}

interface StudySet {
  id: string;
  name: string;
  certification_id: string;
  total_materials: number;
  total_questions: number;
  created_at: string;
}

export default function StudySetDetailPage() {
  const router = useRouter();
  const params = useParams();
  const { getToken } = useAuth();
  const studySetId = params.id as string;

  const [studySet, setStudySet] = useState<StudySet | null>(null);
  const [materials, setMaterials] = useState<StudyMaterial[]>([]);
  const [loading, setLoading] = useState(true);
  const [uploading, setUploading] = useState(false);
  const [uploadError, setUploadError] = useState('');
  const [selectedMaterials, setSelectedMaterials] = useState<Set<string>>(new Set());
  const [viewMode, setViewMode] = useState<'card' | 'table'>('table');
  const [questionModalOpen, setQuestionModalOpen] = useState(false);
  const [currentMaterial, setCurrentMaterial] = useState<StudyMaterial | null>(null);
  const [currentQuestions, setCurrentQuestions] = useState<any[]>([]);
  const [expandedLogs, setExpandedLogs] = useState<Set<string>>(new Set());

  useEffect(() => {
    fetchStudySetAndMaterials();
  }, [studySetId]);

  const fetchStudySetAndMaterials = async () => {
    try {
      setLoading(true);
      const token = await getToken();

      // Fetch study set info
      const studySetResponse = await fetch(
        `${process.env.NEXT_PUBLIC_API_URL}/study-sets/${studySetId}`,
        {
          headers: { 'Authorization': `Bearer ${token}` },
        }
      );

      if (studySetResponse.ok) {
        const studySetData = await studySetResponse.json();
        setStudySet(studySetData.data || studySetData.study_set);
      }

      // Fetch materials
      const materialsResponse = await fetch(
        `${process.env.NEXT_PUBLIC_API_URL}/study-materials/${studySetId}`,
        {
          headers: { 'Authorization': `Bearer ${token}` },
        }
      );

      if (materialsResponse.ok) {
        const materialsData = await materialsResponse.json();
        setMaterials(materialsData.materials || []);
      }
    } catch (error) {
      console.error('Failed to fetch data:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleFileUpload = async (event: React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0];
    if (!file) return;

    if (file.type !== 'application/pdf') {
      setUploadError('PDF 파일만 업로드 가능합니다.');
      return;
    }

    if (file.size > 50 * 1024 * 1024) {
      setUploadError('파일 크기는 50MB 이하여야 합니다.');
      return;
    }

    try {
      setUploading(true);
      setUploadError('');

      const token = await getToken();
      const formData = new FormData();
      formData.append('file', file);
      formData.append('title', file.name.replace('.pdf', ''));

      const response = await fetch(
        `${process.env.NEXT_PUBLIC_API_URL}/study-materials/${studySetId}/upload`,
        {
          method: 'POST',
          headers: {
            'Authorization': `Bearer ${token}`,
          },
          body: formData,
        }
      );

      if (!response.ok) {
        const errorData = await response.json();
        throw new Error(errorData.detail || '업로드에 실패했습니다.');
      }

      // Refresh data
      await fetchStudySetAndMaterials();

      // Reset file input
      event.target.value = '';
    } catch (error: any) {
      console.error('Upload error:', error);
      setUploadError(error.message || '업로드 중 오류가 발생했습니다.');
    } finally {
      setUploading(false);
    }
  };

  const handleDeleteMaterial = async (materialId: string) => {
    if (!confirm('이 학습자료를 삭제하시겠습니까?')) {
      return;
    }

    try {
      const token = await getToken();
      const response = await fetch(
        `${process.env.NEXT_PUBLIC_API_URL}/study-materials/${materialId}`,
        {
          method: 'DELETE',
          headers: {
            'Authorization': `Bearer ${token}`,
          },
        }
      );

      if (!response.ok) {
        throw new Error('삭제에 실패했습니다.');
      }

      // Refresh data
      await fetchStudySetAndMaterials();
    } catch (error: any) {
      console.error('Delete error:', error);
      alert(error.message || '삭제 중 오류가 발생했습니다.');
    }
  };

  const formatFileSize = (bytes: number) => {
    if (bytes < 1024) return bytes + ' B';
    if (bytes < 1024 * 1024) return (bytes / 1024).toFixed(1) + ' KB';
    return (bytes / (1024 * 1024)).toFixed(1) + ' MB';
  };

  const handleViewQuestions = async (material: StudyMaterial) => {
    setCurrentMaterial(material);
    setQuestionModalOpen(true);
    setCurrentQuestions([]);

    try {
      const token = await getToken();
      const response = await fetch(
        `${process.env.NEXT_PUBLIC_API_URL}/questions/material/${material.id}`,
        {
          headers: { 'Authorization': `Bearer ${token}` },
        }
      );

      if (response.ok) {
        const data = await response.json();
        setCurrentQuestions(data.questions || []);
      }
    } catch (error) {
      console.error('Failed to fetch questions:', error);
    }
  };

  const toggleSelectMaterial = (materialId: string) => {
    const newSelected = new Set(selectedMaterials);
    if (newSelected.has(materialId)) {
      newSelected.delete(materialId);
    } else {
      newSelected.add(materialId);
    }
    setSelectedMaterials(newSelected);
  };

  const toggleSelectAll = () => {
    if (selectedMaterials.size === materials.length) {
      setSelectedMaterials(new Set());
    } else {
      setSelectedMaterials(new Set(materials.map(m => m.id)));
    }
  };

  const handleDeleteSelected = async () => {
    if (selectedMaterials.size === 0) return;

    if (!confirm(`선택한 ${selectedMaterials.size}개의 학습자료를 삭제하시겠습니까?`)) {
      return;
    }

    try {
      const token = await getToken();
      const deletePromises = Array.from(selectedMaterials).map(materialId =>
        fetch(`${process.env.NEXT_PUBLIC_API_URL}/study-materials/${materialId}`, {
          method: 'DELETE',
          headers: { 'Authorization': `Bearer ${token}` },
        })
      );

      await Promise.all(deletePromises);
      setSelectedMaterials(new Set());
      await fetchStudySetAndMaterials();
    } catch (error) {
      console.error('Delete error:', error);
      alert('삭제 중 오류가 발생했습니다.');
    }
  };

  const moveMaterial = (index: number, direction: 'up' | 'down') => {
    const newMaterials = [...materials];
    const targetIndex = direction === 'up' ? index - 1 : index + 1;

    if (targetIndex < 0 || targetIndex >= materials.length) return;

    [newMaterials[index], newMaterials[targetIndex]] = [newMaterials[targetIndex], newMaterials[index]];
    setMaterials(newMaterials);

    // Note: In a real app, you'd save this order to the backend
  };

  const toggleLogs = (materialId: string) => {
    const newExpanded = new Set(expandedLogs);
    if (newExpanded.has(materialId)) {
      newExpanded.delete(materialId);
    } else {
      newExpanded.add(materialId);
    }
    setExpandedLogs(newExpanded);
  };

  if (loading) {
    return (
      <div className="max-w-5xl mx-auto px-6 py-8">
        <div className="text-center py-12">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600 mx-auto"></div>
          <p className="mt-4 text-gray-600 dark:text-gray-400">로딩 중...</p>
        </div>
      </div>
    );
  }

  if (!studySet) {
    return (
      <div className="max-w-5xl mx-auto px-6 py-8">
        <div className="text-center py-12">
          <p className="text-gray-600 dark:text-gray-400">문제집을 찾을 수 없습니다.</p>
          <button
            onClick={() => router.push('/study-sets')}
            className="mt-4 text-blue-600 hover:text-blue-700"
          >
            목록으로 돌아가기
          </button>
        </div>
      </div>
    );
  }

  return (
    <div className="max-w-5xl mx-auto px-6 py-8">
      {/* Header */}
      <div className="mb-8">
        <button
          onClick={() => router.push('/study-sets')}
          className="flex items-center gap-2 text-gray-600 dark:text-gray-400 hover:text-gray-900 dark:hover:text-gray-100 mb-4"
        >
          <ArrowLeft className="w-5 h-5" />
          문제집 목록
        </button>
        <div className="flex items-start justify-between">
          <div>
            <h1 className="text-3xl font-bold text-gray-900 dark:text-gray-100 mb-2">
              {studySet.name}
            </h1>
            <div className="flex items-center gap-4 text-sm text-gray-600 dark:text-gray-400">
              <div className="flex items-center gap-1">
                <FileText className="w-4 h-4" />
                <span>학습자료 {studySet.total_materials}개</span>
              </div>
              <div className="flex items-center gap-1">
                <BookOpen className="w-4 h-4" />
                <span>총 문제 {studySet.total_questions}개</span>
              </div>
              <div className="flex items-center gap-1">
                <Calendar className="w-4 h-4" />
                <span>{new Date(studySet.created_at).toLocaleDateString('ko-KR')}</span>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Upload Section */}
      <div className="bg-white dark:bg-gray-800 rounded-lg shadow-sm p-6 mb-6">
        <h2 className="text-lg font-semibold text-gray-900 dark:text-gray-100 mb-4">
          학습자료 업로드
        </h2>
        <div className="border-2 border-dashed border-gray-300 dark:border-gray-700 rounded-lg p-8 text-center">
          <Upload className="w-12 h-12 text-gray-400 mx-auto mb-4" />
          <p className="text-gray-600 dark:text-gray-400 mb-4">
            PDF 파일을 선택하거나 드래그하여 업로드하세요
          </p>
          <label className="inline-flex items-center gap-2 px-6 py-3 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors cursor-pointer">
            <Upload className="w-5 h-5" />
            {uploading ? '업로드 중...' : 'PDF 선택'}
            <input
              type="file"
              accept="application/pdf"
              onChange={handleFileUpload}
              disabled={uploading}
              className="hidden"
            />
          </label>
          <p className="text-sm text-gray-500 dark:text-gray-500 mt-2">
            최대 50MB, PDF 형식만 가능
          </p>
        </div>
        {uploadError && (
          <div className="mt-4 bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-lg p-4">
            <p className="text-sm text-red-800 dark:text-red-200">{uploadError}</p>
          </div>
        )}
      </div>

      {/* Materials List */}
      <div className="bg-white dark:bg-gray-800 rounded-lg shadow-sm p-6">
        <div className="flex items-center justify-between mb-4">
          <h2 className="text-lg font-semibold text-gray-900 dark:text-gray-100">
            학습자료 목록 ({materials.length}개)
          </h2>
          {materials.length > 0 && (
            <div className="flex items-center gap-2">
              {selectedMaterials.size > 0 && (
                <button
                  onClick={handleDeleteSelected}
                  className="px-3 py-1.5 text-sm bg-red-600 text-white rounded-lg hover:bg-red-700 transition-colors"
                >
                  선택 삭제 ({selectedMaterials.size}개)
                </button>
              )}
            </div>
          )}
        </div>

        {materials.length === 0 ? (
          <div className="text-center py-8 text-gray-600 dark:text-gray-400">
            아직 업로드된 학습자료가 없습니다.
          </div>
        ) : (
          /* Table View */
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead className="bg-gray-50 dark:bg-gray-900 border-b border-gray-200 dark:border-gray-700">
                <tr>
                  <th className="w-12 px-4 py-3">
                    <input
                      type="checkbox"
                      checked={selectedMaterials.size === materials.length && materials.length > 0}
                      onChange={toggleSelectAll}
                      className="w-4 h-4 rounded border-gray-300 text-blue-600 focus:ring-blue-500"
                    />
                  </th>
                  <th className="px-4 py-3 text-left text-sm font-medium text-gray-700 dark:text-gray-300">순서</th>
                  <th className="px-4 py-3 text-left text-sm font-medium text-gray-700 dark:text-gray-300">제목</th>
                  <th className="px-4 py-3 text-left text-sm font-medium text-gray-700 dark:text-gray-300">문제 수</th>
                  <th className="px-4 py-3 text-left text-sm font-medium text-gray-700 dark:text-gray-300">파일 크기</th>
                  <th className="px-4 py-3 text-left text-sm font-medium text-gray-700 dark:text-gray-300">업로드 날짜</th>
                  <th className="px-4 py-3 text-left text-sm font-medium text-gray-700 dark:text-gray-300">상태</th>
                  <th className="px-4 py-3 text-center text-sm font-medium text-gray-700 dark:text-gray-300">작업</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-200 dark:divide-gray-700">
                {materials.map((material, index) => {
                  const isSelected = selectedMaterials.has(material.id);

                  return (
                    <React.Fragment key={material.id}>
                    <tr
                      className={`${isSelected ? 'bg-blue-50 dark:bg-blue-900/20' : 'hover:bg-gray-50 dark:hover:bg-gray-900/50'} transition-colors cursor-pointer`}
                      onClick={(e) => {
                        if ((e.target as HTMLElement).closest('input, button')) return;
                        if (material.status === 'completed' && material.total_questions > 0) {
                          handleViewQuestions(material);
                        }
                      }}
                    >
                        <td className="px-4 py-3">
                          <input
                            type="checkbox"
                            checked={isSelected}
                            onChange={() => toggleSelectMaterial(material.id)}
                            className="w-4 h-4 rounded border-gray-300 text-blue-600 focus:ring-blue-500"
                          />
                        </td>
                        <td className="px-4 py-3">
                          <div className="flex items-center gap-1">
                            <span className="text-sm text-gray-600 dark:text-gray-400">{index + 1}</span>
                            <div className="flex flex-col">
                              <button
                                onClick={() => moveMaterial(index, 'up')}
                                disabled={index === 0}
                                className="p-0.5 text-gray-400 hover:text-gray-600 dark:hover:text-gray-300 disabled:opacity-30 disabled:cursor-not-allowed"
                                title="위로 이동"
                              >
                                <ChevronUpIcon className="w-3 h-3" />
                              </button>
                              <button
                                onClick={() => moveMaterial(index, 'down')}
                                disabled={index === materials.length - 1}
                                className="p-0.5 text-gray-400 hover:text-gray-600 dark:hover:text-gray-300 disabled:opacity-30 disabled:cursor-not-allowed"
                                title="아래로 이동"
                              >
                                <ChevronDownIcon className="w-3 h-3" />
                              </button>
                            </div>
                          </div>
                        </td>
                        <td className="px-4 py-3">
                          <div className="flex items-center gap-2">
                            <FileText className="w-4 h-4 text-blue-600 dark:text-blue-400" />
                            <span className="font-medium text-gray-900 dark:text-gray-100">
                              {material.title}
                            </span>
                          </div>
                        </td>
                        <td className="px-4 py-3">
                          <span className="text-sm text-gray-600 dark:text-gray-400">
                            {material.total_questions}개
                          </span>
                        </td>
                        <td className="px-4 py-3">
                          <span className="text-sm text-gray-600 dark:text-gray-400">
                            {formatFileSize(material.file_size_bytes)}
                          </span>
                        </td>
                        <td className="px-4 py-3">
                          <span className="text-sm text-gray-600 dark:text-gray-400">
                            {new Date(material.created_at).toLocaleDateString('ko-KR')}
                          </span>
                        </td>
                        <td className="px-4 py-3">
                          <div className="flex items-center gap-2">
                            {material.status === 'processing' ? (
                              <div className="flex items-center gap-2">
                                <div className="w-20 bg-gray-200 dark:bg-gray-700 rounded-full h-2">
                                  <div
                                    className="bg-blue-600 h-2 rounded-full transition-all"
                                    style={{ width: `${material.processing_progress}%` }}
                                  ></div>
                                </div>
                                <span className="text-xs text-gray-500">{material.processing_progress}%</span>
                              </div>
                            ) : material.status === 'completed' ? (
                              <span className="inline-flex items-center px-2 py-1 text-xs font-medium text-green-700 bg-green-100 rounded-full dark:bg-green-900/20 dark:text-green-400">
                                완료
                              </span>
                            ) : (
                              <span className="inline-flex items-center px-2 py-1 text-xs font-medium text-yellow-700 bg-yellow-100 rounded-full dark:bg-yellow-900/20 dark:text-yellow-400">
                                {material.status}
                              </span>
                            )}
                            {material.processing_logs && material.processing_logs.length > 0 && (
                              <button
                                onClick={(e) => {
                                  e.stopPropagation();
                                  toggleLogs(material.id);
                                }}
                                className="p-1 hover:bg-gray-200 dark:hover:bg-gray-700 rounded transition-colors"
                                title="처리 로그 보기"
                              >
                                {expandedLogs.has(material.id) ? (
                                  <ChevronUpIcon className="w-4 h-4 text-gray-500" />
                                ) : (
                                  <ChevronDownIcon className="w-4 h-4 text-gray-500" />
                                )}
                              </button>
                            )}
                          </div>
                        </td>
                        <td className="px-4 py-3">
                          <div className="flex items-center justify-center gap-1">
                            <button
                              onClick={() => handleDeleteMaterial(material.id)}
                              className="p-1.5 text-red-600 hover:bg-red-50 dark:hover:bg-red-900/20 rounded-lg transition-colors"
                              title="삭제"
                            >
                              <Trash2 className="w-4 h-4" />
                            </button>
                          </div>
                        </td>
                      </tr>
                      {expandedLogs.has(material.id) && material.processing_logs && material.processing_logs.length > 0 && (
                        <tr key={`${material.id}-logs`} className="bg-gray-50 dark:bg-gray-900/50">
                          <td colSpan={8} className="px-4 py-4">
                            <div className="ml-8">
                              <h4 className="text-sm font-semibold text-gray-700 dark:text-gray-300 mb-3 flex items-center gap-2">
                                <span className="inline-block w-2 h-2 bg-blue-500 rounded-full"></span>
                                처리 로그
                              </h4>
                              <div className="space-y-2 max-h-60 overflow-y-auto">
                                {material.processing_logs.map((log, logIdx) => (
                                  <div
                                    key={logIdx}
                                    className="flex items-start gap-3 text-xs bg-white dark:bg-gray-800 p-3 rounded border border-gray-200 dark:border-gray-700"
                                  >
                                    <span className="text-gray-500 dark:text-gray-400 font-mono whitespace-nowrap">
                                      {new Date(log.timestamp).toLocaleTimeString('ko-KR')}
                                    </span>
                                    <div className="flex items-center gap-2">
                                      <div className="w-16 bg-gray-200 dark:bg-gray-700 rounded-full h-1.5">
                                        <div
                                          className={`h-1.5 rounded-full ${
                                            log.status === 'completed' ? 'bg-green-500' :
                                            log.status === 'failed' ? 'bg-red-500' :
                                            'bg-blue-500'
                                          }`}
                                          style={{ width: `${log.progress}%` }}
                                        ></div>
                                      </div>
                                      <span className="text-gray-500 dark:text-gray-400 w-10">{log.progress}%</span>
                                    </div>
                                    <span className={`flex-1 ${
                                      log.status === 'completed' ? 'text-green-700 dark:text-green-400' :
                                      log.status === 'failed' ? 'text-red-700 dark:text-red-400' :
                                      'text-gray-700 dark:text-gray-300'
                                    }`}>
                                      {log.message}
                                    </span>
                                  </div>
                                ))}
                              </div>
                            </div>
                          </td>
                        </tr>
                      )}
                    </React.Fragment>
                  );
                })}
              </tbody>
            </table>
          </div>
        )}
      </div>

      {/* Actions */}
      {materials.length > 0 && studySet.total_questions > 0 && (
        <div className="mt-6 flex justify-end">
          <button
            onClick={() => router.push(`/test/${studySetId}`)}
            className="px-6 py-3 bg-green-600 text-white rounded-lg hover:bg-green-700 transition-colors"
          >
            학습 시작
          </button>
        </div>
      )}

      {/* Question Modal */}
      {questionModalOpen && (
        <div
          className="fixed inset-0 z-50 flex items-center justify-center bg-black bg-opacity-50 p-4"
          onClick={() => setQuestionModalOpen(false)}
        >
          <div
            className="bg-white dark:bg-gray-800 rounded-lg shadow-xl w-full max-w-7xl max-h-[90vh] overflow-hidden flex flex-col"
            onClick={(e) => e.stopPropagation()}
          >
            {/* Modal Header */}
            <div className="flex items-center justify-between p-6 border-b border-gray-200 dark:border-gray-700">
              <h2 className="text-xl font-semibold text-gray-900 dark:text-gray-100">
                {currentMaterial?.title}
              </h2>
              <button
                onClick={() => setQuestionModalOpen(false)}
                className="p-2 hover:bg-gray-100 dark:hover:bg-gray-700 rounded-lg transition-colors"
              >
                <X className="w-5 h-5 text-gray-500 dark:text-gray-400" />
              </button>
            </div>

            {/* Modal Body - Split View */}
            <div className="flex flex-1 overflow-hidden">
              {/* Left: Questions */}
              <div className="w-1/2 p-6 overflow-y-auto border-r border-gray-200 dark:border-gray-700">
                {currentQuestions.length === 0 ? (
                  <div className="text-center py-8 text-gray-500 dark:text-gray-400">
                    문제를 불러오는 중...
                  </div>
                ) : (
                  <div className="space-y-6">
                    {currentQuestions.map((q, idx) => (
                      <div key={q.id || idx} className="bg-gray-50 dark:bg-gray-900/50 p-5 rounded-lg border border-gray-200 dark:border-gray-700">
                        <div className="mb-4">
                          <span className="inline-block px-3 py-1 bg-blue-100 dark:bg-blue-900/30 text-blue-700 dark:text-blue-300 text-sm font-semibold rounded mb-3">
                            문제 {q.question_number}
                          </span>
                          {q.passage && (
                            <div className="mb-4 p-4 bg-yellow-50 dark:bg-yellow-900/20 border-l-4 border-yellow-400 dark:border-yellow-600 rounded">
                              <p className="text-sm text-gray-700 dark:text-gray-300 whitespace-pre-wrap leading-relaxed">
                                {q.passage}
                              </p>
                            </div>
                          )}
                          <p className="text-gray-900 dark:text-gray-100 font-medium text-lg">
                            {q.question_text}
                          </p>
                        </div>
                        <div className="space-y-2 mb-4">
                          {q.options && q.options.map((opt: any) => (
                            <div
                              key={opt.number}
                              className={`p-3 rounded-lg ${
                                opt.number === q.correct_answer
                                  ? 'bg-green-50 dark:bg-green-900/20 border-2 border-green-300 dark:border-green-700'
                                  : 'bg-white dark:bg-gray-800 border border-gray-200 dark:border-gray-700'
                              }`}
                            >
                              <p className="text-sm text-gray-800 dark:text-gray-200">
                                {opt.text}
                                {opt.number === q.correct_answer && (
                                  <span className="ml-2 text-green-600 dark:text-green-400 font-semibold">
                                    ✓ 정답
                                  </span>
                                )}
                              </p>
                            </div>
                          ))}
                        </div>
                        {q.explanation && (
                          <div className="mt-4 p-4 bg-blue-50 dark:bg-blue-900/20 rounded-lg">
                            <p className="text-xs font-semibold text-blue-700 dark:text-blue-300 mb-2">
                              💡 해설
                            </p>
                            <p className="text-sm text-gray-700 dark:text-gray-300 leading-relaxed">
                              {q.explanation}
                            </p>
                          </div>
                        )}
                      </div>
                    ))}
                  </div>
                )}
              </div>

              {/* Right: PDF Viewer */}
              <div className="w-1/2 bg-gray-100 dark:bg-gray-900 flex items-center justify-center">
                {currentMaterial?.pdf_url ? (
                  <iframe
                    src={`${process.env.NEXT_PUBLIC_API_URL?.replace('/api/v1', '')}${currentMaterial.pdf_url}`}
                    className="w-full h-full"
                    title="PDF Viewer"
                  />
                ) : (
                  <div className="text-center text-gray-500 dark:text-gray-400">
                    <FileText className="w-16 h-16 mx-auto mb-4 opacity-50" />
                    <p>PDF를 불러올 수 없습니다</p>
                  </div>
                )}
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
