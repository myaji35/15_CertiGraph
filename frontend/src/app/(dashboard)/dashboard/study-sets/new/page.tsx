"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { useAuth } from "@clerk/nextjs";
import PdfUploader from "@/components/study-sets/PdfUploader";

export default function NewStudySetPage() {
  const router = useRouter();
  const { getToken } = useAuth();
  const [isUploading, setIsUploading] = useState(false);
  const [uploadProgress, setUploadProgress] = useState(0);

  const handleUpload = async (file: File, name: string) => {
    setIsUploading(true);
    setUploadProgress(0);

    try {
      const token = await getToken();
      if (!token) {
        throw new Error("인증이 필요합니다");
      }

      const formData = new FormData();
      formData.append("file", file);
      formData.append("name", name);

      // Create XMLHttpRequest for progress tracking
      const xhr = new XMLHttpRequest();

      const uploadPromise = new Promise<{ id: string }>((resolve, reject) => {
        xhr.upload.onprogress = (event) => {
          if (event.lengthComputable) {
            const percent = Math.round((event.loaded / event.total) * 100);
            setUploadProgress(percent);
          }
        };

        xhr.onload = () => {
          if (xhr.status >= 200 && xhr.status < 300) {
            const response = JSON.parse(xhr.responseText);
            resolve(response.data);
          } else {
            const error = JSON.parse(xhr.responseText);
            reject(new Error(error.error?.message || "업로드 실패"));
          }
        };

        xhr.onerror = () => reject(new Error("네트워크 오류"));

        xhr.open("POST", `${process.env.NEXT_PUBLIC_API_URL}/api/v1/study-sets/upload`);
        xhr.setRequestHeader("Authorization", `Bearer ${token}`);
        xhr.send(formData);
      });

      const result = await uploadPromise;

      // Redirect to the study set detail page
      router.push(`/dashboard/study-sets/${result.id}`);
    } catch (error) {
      setIsUploading(false);
      setUploadProgress(0);
      throw error;
    }
  };

  return (
    <div className="max-w-2xl mx-auto">
      <div className="mb-8">
        <h1 className="text-2xl font-bold text-gray-900">새 학습 세트 만들기</h1>
        <p className="mt-2 text-gray-600">
          사회복지사 1급 기출문제 PDF를 업로드하면 AI가 자동으로 문제를 분석합니다.
        </p>
      </div>

      <div className="bg-white rounded-lg shadow-sm border border-gray-200 p-6">
        <PdfUploader
          onUpload={handleUpload}
          isUploading={isUploading}
          uploadProgress={uploadProgress}
        />
      </div>

      <div className="mt-6 p-4 bg-gray-50 rounded-lg">
        <h3 className="text-sm font-medium text-gray-900 mb-2">💡 업로드 팁</h3>
        <ul className="text-sm text-gray-600 space-y-1">
          <li>• 스캔된 PDF도 지원됩니다 (OCR 자동 적용)</li>
          <li>• 문제, 보기, 해설이 포함된 PDF를 권장합니다</li>
          <li>• 여러 년도의 기출문제는 개별 파일로 업로드해주세요</li>
        </ul>
      </div>
    </div>
  );
}
