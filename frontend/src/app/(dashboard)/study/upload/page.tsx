"use client";

import { useState, useEffect } from "react";
import { useRouter } from "next/navigation";
import { useAuth } from "@clerk/nextjs";
import { Upload, FileText, AlertCircle, Check, X } from "lucide-react";

interface Certification {
    id: string;
    name: string;
}

export default function UploadPDFPage() {
    const router = useRouter();
    const { getToken } = useAuth();
    const [file, setFile] = useState<File | null>(null);
    const [uploading, setUploading] = useState(false);
    const [uploadProgress, setUploadProgress] = useState(0);
    const [studySetName, setStudySetName] = useState("");
    const [certifications, setCertifications] = useState<Certification[]>([]);
    const [certification, setCertification] = useState<string>("");
    const [examYear, setExamYear] = useState<number>(new Date().getFullYear());
    const [examSession, setExamSession] = useState<string>("");
    const [loadingCerts, setLoadingCerts] = useState(true);
    const [error, setError] = useState<string>("");
    const [dragActive, setDragActive] = useState(false);

    // 자격증 목록 가져오기
    useEffect(() => {
        const fetchCertifications = async () => {
            try {
                const response = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/certifications`);
                if (response.ok) {
                    const data = await response.json();
                    setCertifications(data.certifications || []);
                }
            } catch (error) {
                console.error("Failed to fetch certifications:", error);
                setError("자격증 목록을 불러올 수 없습니다");
            } finally {
                setLoadingCerts(false);
            }
        };
        fetchCertifications();
    }, []);

    const handleDrag = (e: React.DragEvent) => {
        e.preventDefault();
        e.stopPropagation();
        if (e.type === "dragenter" || e.type === "dragover") {
            setDragActive(true);
        } else if (e.type === "dragleave") {
            setDragActive(false);
        }
    };

    const handleDrop = (e: React.DragEvent) => {
        e.preventDefault();
        e.stopPropagation();
        setDragActive(false);

        if (e.dataTransfer.files && e.dataTransfer.files[0]) {
            const selectedFile = e.dataTransfer.files[0];
            if (selectedFile.type === "application/pdf") {
                setFile(selectedFile);
                if (!studySetName) {
                    setStudySetName(selectedFile.name.replace(".pdf", ""));
                }
                setError("");
            } else {
                setError("PDF 파일만 업로드 가능합니다");
            }
        }
    };

    const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
        if (e.target.files && e.target.files[0]) {
            const selectedFile = e.target.files[0];
            if (selectedFile.type === "application/pdf") {
                setFile(selectedFile);
                if (!studySetName) {
                    setStudySetName(selectedFile.name.replace(".pdf", ""));
                }
                setError("");
            } else {
                setError("PDF 파일만 업로드 가능합니다");
            }
        }
    };

    const handleUpload = async () => {
        if (!file) {
            setError("PDF 파일을 선택해주세요");
            return;
        }

        if (!studySetName.trim()) {
            setError("학습 세트 이름을 입력해주세요");
            return;
        }

        if (!certification) {
            setError("자격증을 선택해주세요");
            return;
        }

        setUploading(true);
        setUploadProgress(0);
        setError("");

        try {
            const token = await getToken();
            if (!token) throw new Error("인증 토큰이 없습니다");

            const formData = new FormData();
            formData.append("file", file);
            formData.append("name", studySetName);
            formData.append("certification_id", certification);

            if (examYear) {
                formData.append("exam_year", examYear.toString());
            }

            if (examSession) {
                formData.append("exam_round", examSession);
            }

            // Simulate progress
            const progressInterval = setInterval(() => {
                setUploadProgress((prev) => {
                    if (prev >= 90) {
                        clearInterval(progressInterval);
                        return prev;
                    }
                    return prev + 10;
                });
            }, 200);

            const response = await fetch(`${process.env.NEXT_PUBLIC_API_URL}/study-sets/upload`, {
                method: "POST",
                headers: {
                    Authorization: `Bearer ${token}`,
                },
                body: formData,
            });

            clearInterval(progressInterval);
            setUploadProgress(100);

            if (!response.ok) {
                const errorData = await response.json();
                throw new Error(errorData.detail || errorData.error?.message || "업로드 실패");
            }

            const result = await response.json();

            // Redirect to study sets list page
            setTimeout(() => {
                router.push(`/dashboard/study-sets`);
            }, 1000);
        } catch (error: any) {
            console.error("Upload failed:", error);
            setError(error.message || "파일 업로드 중 오류가 발생했습니다");
            setUploadProgress(0);
        } finally {
            setUploading(false);
        }
    };

    return (
        <div className="max-w-4xl mx-auto px-6 py-8">
            <div className="mb-8">
                <h1 className="text-3xl font-bold text-gray-900 dark:text-gray-100 mb-2">
                    PDF 업로드
                </h1>
                <p className="text-gray-600 dark:text-gray-400">
                    기출문제 PDF를 업로드하면 AI가 자동으로 문제를 분석합니다
                </p>
            </div>

            {/* Error Alert */}
            {error && (
                <div className="mb-6 bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-lg p-4 flex items-start gap-3">
                    <AlertCircle className="w-5 h-5 text-red-600 dark:text-red-400 flex-shrink-0 mt-0.5" />
                    <p className="text-sm text-red-800 dark:text-red-200">{error}</p>
                </div>
            )}

            {/* File Upload Zone */}
            <div className="bg-white dark:bg-gray-800 rounded-lg shadow-sm p-6 mb-6">
                <div
                    className={`border-2 border-dashed rounded-lg p-12 text-center transition-colors ${
                        dragActive
                            ? "border-blue-500 bg-blue-50 dark:bg-blue-900/20"
                            : "border-gray-300 dark:border-gray-700 hover:border-gray-400 dark:hover:border-gray-600"
                    }`}
                    onDragEnter={handleDrag}
                    onDragLeave={handleDrag}
                    onDragOver={handleDrag}
                    onDrop={handleDrop}
                >
                    <input
                        type="file"
                        accept="application/pdf"
                        onChange={handleFileChange}
                        className="hidden"
                        id="file-upload"
                        disabled={uploading}
                    />
                    <label htmlFor="file-upload" className="cursor-pointer">
                        <FileText className="w-16 h-16 mx-auto mb-4 text-gray-400" />
                        <p className="text-xl font-semibold text-gray-900 dark:text-gray-100 mb-2">
                            PDF 파일을 드래그하거나 클릭하여 선택하세요
                        </p>
                        <p className="text-sm text-gray-500 dark:text-gray-400">
                            PDF 파일만 가능 (최대 50MB)
                        </p>
                    </label>
                </div>

                {/* Selected File */}
                {file && (
                    <div className="mt-4 bg-blue-50 dark:bg-blue-900/20 border border-blue-200 dark:border-blue-800 rounded-lg p-4 flex items-center justify-between">
                        <div className="flex items-center gap-3">
                            <FileText className="w-5 h-5 text-blue-600 dark:text-blue-400" />
                            <div>
                                <p className="text-sm font-medium text-gray-900 dark:text-gray-100">
                                    {file.name}
                                </p>
                                <p className="text-xs text-gray-500 dark:text-gray-400">
                                    {(file.size / 1024 / 1024).toFixed(2)} MB
                                </p>
                            </div>
                        </div>
                        {!uploading && (
                            <button
                                onClick={() => setFile(null)}
                                className="p-1 hover:bg-red-100 dark:hover:bg-red-900/20 rounded transition-colors"
                            >
                                <X className="w-5 h-5 text-red-600 dark:text-red-400" />
                            </button>
                        )}
                    </div>
                )}

                {/* Upload Progress */}
                {uploading && (
                    <div className="mt-4">
                        <div className="flex items-center justify-between mb-2">
                            <p className="text-sm font-medium text-gray-700 dark:text-gray-300">
                                업로드 중...
                            </p>
                            <p className="text-sm text-gray-500 dark:text-gray-400">
                                {uploadProgress}%
                            </p>
                        </div>
                        <div className="w-full bg-gray-200 dark:bg-gray-700 rounded-full h-2">
                            <div
                                className="bg-blue-600 h-2 rounded-full transition-all duration-300"
                                style={{ width: `${uploadProgress}%` }}
                            />
                        </div>
                    </div>
                )}
            </div>

            {/* Metadata Form */}
            <div className="bg-white dark:bg-gray-800 rounded-lg shadow-sm p-6 mb-6">
                <div className="space-y-4">
                    <div>
                        <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                            학습 세트 이름 <span className="text-red-500">*</span>
                        </label>
                        <input
                            type="text"
                            value={studySetName}
                            onChange={(e) => setStudySetName(e.target.value)}
                            placeholder="예: 2024년 사회복지사 1급 1회차"
                            disabled={uploading}
                            className="w-full px-4 py-2 border border-gray-300 dark:border-gray-700 rounded-lg bg-white dark:bg-gray-900 text-gray-900 dark:text-gray-100 focus:outline-none focus:ring-2 focus:ring-blue-500 disabled:opacity-50"
                        />
                    </div>

                    <div>
                        <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                            자격증 종류 <span className="text-red-500">*</span>
                        </label>
                        <select
                            value={certification}
                            onChange={(e) => setCertification(e.target.value)}
                            disabled={uploading || loadingCerts}
                            className="w-full px-4 py-2 border border-gray-300 dark:border-gray-700 rounded-lg bg-white dark:bg-gray-900 text-gray-900 dark:text-gray-100 focus:outline-none focus:ring-2 focus:ring-blue-500 disabled:opacity-50"
                        >
                            <option value="">자격증 선택</option>
                            {certifications.map((cert) => (
                                <option key={cert.id} value={cert.id}>
                                    {cert.name}
                                </option>
                            ))}
                        </select>
                    </div>

                    <div className="grid grid-cols-2 gap-4">
                        <div>
                            <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                                시험 연도
                            </label>
                            <input
                                type="number"
                                value={examYear}
                                onChange={(e) => setExamYear(parseInt(e.target.value))}
                                min={2000}
                                max={new Date().getFullYear() + 1}
                                disabled={uploading}
                                className="w-full px-4 py-2 border border-gray-300 dark:border-gray-700 rounded-lg bg-white dark:bg-gray-900 text-gray-900 dark:text-gray-100 focus:outline-none focus:ring-2 focus:ring-blue-500 disabled:opacity-50"
                            />
                        </div>

                        <div>
                            <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                                회차
                            </label>
                            <select
                                value={examSession}
                                onChange={(e) => setExamSession(e.target.value)}
                                disabled={uploading}
                                className="w-full px-4 py-2 border border-gray-300 dark:border-gray-700 rounded-lg bg-white dark:bg-gray-900 text-gray-900 dark:text-gray-100 focus:outline-none focus:ring-2 focus:ring-blue-500 disabled:opacity-50"
                            >
                                <option value="">회차 선택</option>
                                <option value="1">1회차</option>
                                <option value="2">2회차</option>
                                <option value="3">3회차</option>
                            </select>
                        </div>
                    </div>
                </div>
            </div>

            {/* Action Buttons */}
            <div className="flex items-center justify-between">
                <button
                    onClick={() => router.back()}
                    disabled={uploading}
                    className="px-6 py-2 text-gray-700 dark:text-gray-300 hover:bg-gray-100 dark:hover:bg-gray-700 rounded-lg transition-colors disabled:opacity-50"
                >
                    취소
                </button>

                <button
                    onClick={handleUpload}
                    disabled={!file || uploading}
                    className="flex items-center gap-2 px-6 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
                >
                    {uploading ? (
                        <>
                            <div className="w-5 h-5 border-2 border-white border-t-transparent rounded-full animate-spin" />
                            업로드 중...
                        </>
                    ) : (
                        <>
                            <Upload className="w-5 h-5" />
                            업로드 시작
                        </>
                    )}
                </button>
            </div>

            {/* Info Alert */}
            <div className="mt-6 bg-blue-50 dark:bg-blue-900/20 border border-blue-200 dark:border-blue-800 rounded-lg p-4">
                <div className="flex gap-3">
                    <AlertCircle className="w-5 h-5 text-blue-600 dark:text-blue-400 flex-shrink-0 mt-0.5" />
                    <div className="space-y-2">
                        <p className="text-sm font-medium text-blue-900 dark:text-blue-100">
                            💡 업로드 안내
                        </p>
                        <ul className="text-sm text-blue-800 dark:text-blue-200 space-y-1">
                            <li>• PDF 파일이 업로드되면 AI가 자동으로 문제를 추출합니다 (약 2-5분 소요)</li>
                            <li>• 파싱 진행 상황은 학습 세트 상세 페이지에서 확인할 수 있습니다</li>
                            <li>• 동일한 PDF는 자동으로 감지되어 캐시에서 빠르게 불러옵니다</li>
                        </ul>
                    </div>
                </div>
            </div>
        </div>
    );
}
