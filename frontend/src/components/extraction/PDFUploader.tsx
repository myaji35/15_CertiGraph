'use client';

import { useState, useCallback } from 'react';
import { Upload, FileText, AlertCircle, CheckCircle, Loader2 } from 'lucide-react';
import { useDropzone } from 'react-dropzone';

interface PDFUploaderProps {
  studySetId: string;
  onExtractComplete: (questions: ExtractedQuestion[]) => void;
}

interface ExtractedQuestion {
  id: string;
  questionNumber: number;
  questionText: string;
  options: {
    number: number;
    text: string;
  }[];
  correctAnswer?: number;
  explanation?: string;
  category?: string;
  difficulty?: 'easy' | 'medium' | 'hard';
  imageUrl?: string;
  passageText?: string;  // 지문 (여러 문제가 공유)
}

export default function PDFUploader({ studySetId, onExtractComplete }: PDFUploaderProps) {
  const [uploadStatus, setUploadStatus] = useState<'idle' | 'uploading' | 'processing' | 'complete' | 'error'>('idle');
  const [progress, setProgress] = useState(0);
  const [extractedQuestions, setExtractedQuestions] = useState<ExtractedQuestion[]>([]);
  const [errorMessage, setErrorMessage] = useState('');

  const onDrop = useCallback(async (acceptedFiles: File[]) => {
    if (acceptedFiles.length === 0) return;

    const file = acceptedFiles[0];

    // 파일 크기 체크 (50MB)
    if (file.size > 50 * 1024 * 1024) {
      setErrorMessage('파일 크기는 50MB를 초과할 수 없습니다.');
      setUploadStatus('error');
      return;
    }

    setUploadStatus('uploading');
    setProgress(0);

    try {
      // 1. 파일 업로드
      const formData = new FormData();
      formData.append('file', file);
      formData.append('studySetId', studySetId);

      const uploadResponse = await fetch('/api/extract/upload', {
        method: 'POST',
        body: formData,
      });

      if (!uploadResponse.ok) {
        throw new Error('파일 업로드 실패');
      }

      const { fileId } = await uploadResponse.json();
      setProgress(30);
      setUploadStatus('processing');

      // 2. OCR 처리 및 문제 추출 (SSE for progress)
      const eventSource = new EventSource(`/api/extract/process?fileId=${fileId}`);

      eventSource.addEventListener('progress', (event) => {
        const data = JSON.parse(event.data);
        setProgress(data.progress);
      });

      eventSource.addEventListener('complete', (event) => {
        const data = JSON.parse(event.data);
        setExtractedQuestions(data.questions);
        setUploadStatus('complete');
        eventSource.close();
        onExtractComplete(data.questions);
      });

      eventSource.addEventListener('error', (event) => {
        console.error('Processing error:', event);
        setErrorMessage('문제 추출 중 오류가 발생했습니다.');
        setUploadStatus('error');
        eventSource.close();
      });

    } catch (error) {
      console.error('Upload error:', error);
      setErrorMessage('파일 업로드 중 오류가 발생했습니다.');
      setUploadStatus('error');
    }
  }, [studySetId, onExtractComplete]);

  const { getRootProps, getInputProps, isDragActive } = useDropzone({
    onDrop,
    accept: {
      'application/pdf': ['.pdf'],
    },
    maxFiles: 1,
  });

  return (
    <div className="w-full">
      {uploadStatus === 'idle' && (
        <div
          {...getRootProps()}
          className={`
            border-2 border-dashed rounded-lg p-8 text-center cursor-pointer transition-all
            ${isDragActive
              ? 'border-blue-500 bg-blue-50 dark:bg-blue-900/20'
              : 'border-gray-300 dark:border-gray-700 hover:border-blue-400 dark:hover:border-blue-600'
            }
          `}
        >
          <input {...getInputProps()} />
          <Upload className="w-12 h-12 mx-auto mb-4 text-gray-400" />
          <p className="text-lg font-medium mb-2">
            PDF 파일을 드래그하거나 클릭하여 업로드
          </p>
          <p className="text-sm text-gray-500">
            기출문제 PDF를 업로드하면 자동으로 문제를 추출합니다
          </p>
          <p className="text-xs text-gray-400 mt-2">
            최대 50MB, PDF 형식만 지원
          </p>
        </div>
      )}

      {(uploadStatus === 'uploading' || uploadStatus === 'processing') && (
        <div className="border-2 border-blue-500 rounded-lg p-8">
          <div className="flex items-center justify-center mb-4">
            <Loader2 className="w-8 h-8 animate-spin text-blue-500" />
          </div>
          <p className="text-center font-medium mb-2">
            {uploadStatus === 'uploading' ? 'PDF 업로드 중...' : '문제 추출 중...'}
          </p>
          <div className="w-full bg-gray-200 dark:bg-gray-700 rounded-full h-2">
            <div
              className="bg-blue-500 h-2 rounded-full transition-all duration-300"
              style={{ width: `${progress}%` }}
            />
          </div>
          <p className="text-center text-sm text-gray-500 mt-2">
            {progress}% 완료
          </p>
          {uploadStatus === 'processing' && (
            <div className="mt-4 text-center text-xs text-gray-400">
              <p>• Upstage OCR로 텍스트 추출 중...</p>
              <p>• AI가 문제 구조를 분석 중...</p>
              <p>• 문제와 보기를 정리 중...</p>
            </div>
          )}
        </div>
      )}

      {uploadStatus === 'complete' && (
        <div className="border-2 border-green-500 rounded-lg p-8">
          <div className="flex items-center justify-center mb-4">
            <CheckCircle className="w-8 h-8 text-green-500" />
          </div>
          <p className="text-center font-medium mb-2">
            문제 추출 완료!
          </p>
          <p className="text-center text-sm text-gray-500">
            총 {extractedQuestions.length}개의 문제를 추출했습니다
          </p>
          <div className="mt-4 flex justify-center gap-2">
            <button
              onClick={() => {
                setUploadStatus('idle');
                setExtractedQuestions([]);
                setProgress(0);
              }}
              className="px-4 py-2 bg-gray-200 dark:bg-gray-700 rounded-lg hover:bg-gray-300 dark:hover:bg-gray-600"
            >
              다른 파일 업로드
            </button>
          </div>
        </div>
      )}

      {uploadStatus === 'error' && (
        <div className="border-2 border-red-500 rounded-lg p-8">
          <div className="flex items-center justify-center mb-4">
            <AlertCircle className="w-8 h-8 text-red-500" />
          </div>
          <p className="text-center font-medium mb-2 text-red-500">
            오류 발생
          </p>
          <p className="text-center text-sm text-gray-500">
            {errorMessage}
          </p>
          <div className="mt-4 flex justify-center">
            <button
              onClick={() => {
                setUploadStatus('idle');
                setErrorMessage('');
                setProgress(0);
              }}
              className="px-4 py-2 bg-red-500 text-white rounded-lg hover:bg-red-600"
            >
              다시 시도
            </button>
          </div>
        </div>
      )}
    </div>
  );
}