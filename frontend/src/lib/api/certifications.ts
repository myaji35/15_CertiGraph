import { apiClient } from './client';
import type {
  Certification,
  CertificationListResponse,
  CertificationCategory,
  MonthlyCalendar,
  UpcomingExam
} from '@/types/certification';

/**
 * 자격증 목록 조회
 */
export async function getCertifications(params?: {
  category?: CertificationCategory;
  month?: number;
  year?: number;
}): Promise<CertificationListResponse> {
  const queryParams = new URLSearchParams();

  if (params?.category) {
    queryParams.append('category', params.category);
  }
  if (params?.month) {
    queryParams.append('month', params.month.toString());
  }
  if (params?.year) {
    queryParams.append('year', params.year.toString());
  }

  const response = await apiClient.get(`/certifications?${queryParams}`);

  if (!response.ok) {
    throw new Error('Failed to fetch certifications');
  }

  return response.json();
}

/**
 * 특정 자격증 상세 조회
 */
export async function getCertificationDetail(
  certificationId: string
): Promise<Certification> {
  const response = await apiClient.get(`/certifications/${certificationId}`);

  if (!response.ok) {
    throw new Error('Failed to fetch certification detail');
  }

  return response.json();
}

/**
 * 월별 시험 달력 조회
 */
export async function getMonthlyCalendar(
  year: number,
  month: number
): Promise<MonthlyCalendar> {
  const response = await apiClient.get(
    `/certifications/calendar/${year}/${month}`
  );

  if (!response.ok) {
    throw new Error('Failed to fetch monthly calendar');
  }

  return response.json();
}

/**
 * 다가오는 시험 일정 조회
 */
export async function getUpcomingExams(
  days: number = 30
): Promise<{ total: number; exams: UpcomingExam[] }> {
  const response = await apiClient.get(
    `/certifications/calendar/upcoming?days=${days}`
  );

  if (!response.ok) {
    throw new Error('Failed to fetch upcoming exams');
  }

  return response.json();
}

/**
 * 사용자 자격증 선택 저장
 */
export async function saveCertificationPreference(
  certificationId: string,
  targetExamDate?: string
): Promise<{ message: string; preference: any }> {
  const body = {
    certification_id: certificationId,
    ...(targetExamDate && { target_exam_date: targetExamDate })
  };

  const response = await apiClient.post('/certifications/preferences', {
    body: JSON.stringify(body)
  });

  if (!response.ok) {
    throw new Error('Failed to save certification preference');
  }

  return response.json();
}