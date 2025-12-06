"use client";

import { useCallback, useState } from "react";
import { useDropzone } from "react-dropzone";

interface PdfUploaderProps {
  onUpload: (file: File, name: string) => Promise<void>;
  isUploading?: boolean;
  uploadProgress?: number;
}

const MAX_FILE_SIZE = 50 * 1024 * 1024; // 50MB

export default function PdfUploader({
  onUpload,
  isUploading = false,
  uploadProgress = 0,
}: PdfUploaderProps) {
  const [selectedFile, setSelectedFile] = useState<File | null>(null);
  const [studySetName, setStudySetName] = useState("");
  const [error, setError] = useState<string | null>(null);

  const onDrop = useCallback((acceptedFiles: File[], rejectedFiles: any[]) => {
    setError(null);

    if (rejectedFiles.length > 0) {
      const rejection = rejectedFiles[0];
      if (rejection.errors[0]?.code === "file-too-large") {
        setError("파일 크기는 50MB 이하여야 합니다");
      } else if (rejection.errors[0]?.code === "file-invalid-type") {
        setError("PDF 파일만 업로드 가능합니다");
      }
      return;
    }

    if (acceptedFiles.length > 0) {
      const file = acceptedFiles[0];
      setSelectedFile(file);
      // Auto-fill name from filename (without extension)
      if (!studySetName) {
        const nameWithoutExt = file.name.replace(/\.pdf$/i, "");
        setStudySetName(nameWithoutExt);
      }
    }
  }, [studySetName]);

  const { getRootProps, getInputProps, isDragActive } = useDropzone({
    onDrop,
    accept: {
      "application/pdf": [".pdf"],
    },
    maxSize: MAX_FILE_SIZE,
    multiple: false,
    disabled: isUploading,
  });

  const handleSubmit = async () => {
    if (!selectedFile || !studySetName.trim()) return;

    try {
      await onUpload(selectedFile, studySetName.trim());
    } catch (err) {
      setError(err instanceof Error ? err.message : "업로드 중 오류가 발생했습니다");
    }
  };

  const formatFileSize = (bytes: number) => {
    if (bytes < 1024) return bytes + " B";
    if (bytes < 1024 * 1024) return (bytes / 1024).toFixed(1) + " KB";
    return (bytes / (1024 * 1024)).toFixed(1) + " MB";
  };

  const clearFile = () => {
    setSelectedFile(null);
    setError(null);
  };

  return (
    <div className="space-y-6">
      {/* Study Set Name Input */}
      <div>
        <label htmlFor="studySetName" className="block text-sm font-medium text-gray-700 mb-2">
          학습 세트 이름
        </label>
        <input
          type="text"
          id="studySetName"
          value={studySetName}
          onChange={(e) => setStudySetName(e.target.value)}
          placeholder="예: 사회복지사 1급 기출문제 2024"
          className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 outline-none transition-colors"
          disabled={isUploading}
        />
      </div>

      {/* Dropzone */}
      <div
        {...getRootProps()}
        className={`
          relative border-2 border-dashed rounded-lg p-8 text-center cursor-pointer transition-colors
          ${isDragActive ? "border-blue-500 bg-blue-50" : "border-gray-300 hover:border-gray-400"}
          ${isUploading ? "pointer-events-none opacity-60" : ""}
          ${error ? "border-red-300 bg-red-50" : ""}
        `}
      >
        <input {...getInputProps()} />

        {selectedFile ? (
          <div className="space-y-3">
            <div className="flex items-center justify-center gap-3">
              <svg
                className="w-10 h-10 text-red-500"
                fill="none"
                stroke="currentColor"
                viewBox="0 0 24 24"
              >
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  strokeWidth={2}
                  d="M7 21h10a2 2 0 002-2V9.414a1 1 0 00-.293-.707l-5.414-5.414A1 1 0 0012.586 3H7a2 2 0 00-2 2v14a2 2 0 002 2z"
                />
              </svg>
              <div className="text-left">
                <p className="font-medium text-gray-900">{selectedFile.name}</p>
                <p className="text-sm text-gray-500">{formatFileSize(selectedFile.size)}</p>
              </div>
            </div>
            {!isUploading && (
              <button
                type="button"
                onClick={(e) => {
                  e.stopPropagation();
                  clearFile();
                }}
                className="text-sm text-gray-500 hover:text-gray-700 underline"
              >
                다른 파일 선택
              </button>
            )}
          </div>
        ) : (
          <div className="space-y-3">
            <svg
              className="mx-auto w-12 h-12 text-gray-400"
              fill="none"
              stroke="currentColor"
              viewBox="0 0 24 24"
            >
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                strokeWidth={2}
                d="M7 16a4 4 0 01-.88-7.903A5 5 0 1115.9 6L16 6a5 5 0 011 9.9M15 13l-3-3m0 0l-3 3m3-3v12"
              />
            </svg>
            <div>
              <p className="text-gray-700">
                {isDragActive
                  ? "파일을 여기에 놓으세요"
                  : "PDF 파일을 여기에 드래그하거나 클릭하여 선택하세요"}
              </p>
              <p className="text-sm text-gray-500 mt-1">
                PDF 파일만 가능 · 최대 50MB
              </p>
            </div>
          </div>
        )}
      </div>

      {/* Error Message */}
      {error && (
        <div className="flex items-center gap-2 text-red-600 text-sm">
          <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path
              strokeLinecap="round"
              strokeLinejoin="round"
              strokeWidth={2}
              d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"
            />
          </svg>
          {error}
        </div>
      )}

      {/* Upload Progress */}
      {isUploading && (
        <div className="space-y-2">
          <div className="flex justify-between text-sm text-gray-600">
            <span>업로드 중...</span>
            <span>{uploadProgress}%</span>
          </div>
          <div className="w-full bg-gray-200 rounded-full h-2">
            <div
              className="bg-blue-600 h-2 rounded-full transition-all duration-300"
              style={{ width: `${uploadProgress}%` }}
            />
          </div>
        </div>
      )}

      {/* Submit Button */}
      <button
        type="button"
        onClick={handleSubmit}
        disabled={!selectedFile || !studySetName.trim() || isUploading}
        className={`
          w-full py-3 px-4 rounded-lg font-medium transition-colors
          ${
            selectedFile && studySetName.trim() && !isUploading
              ? "bg-blue-600 text-white hover:bg-blue-700"
              : "bg-gray-100 text-gray-400 cursor-not-allowed"
          }
        `}
      >
        {isUploading ? "업로드 중..." : "업로드 시작"}
      </button>
    </div>
  );
}
