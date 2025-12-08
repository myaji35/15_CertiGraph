// Certification types matching backend models

export type ExamType = 'written' | 'practical' | 'interview';

export type CertificationCategory =
  | 'national'
  | 'national_professional'
  | 'private'
  | 'international';

export type CertificationLevel =
  | 'technician'
  | 'industrial_engineer'
  | 'engineer'
  | 'master'
  | 'level_1'
  | 'level_2'
  | 'level_3'
  | 'single';

export interface ExamSchedule {
  exam_type: ExamType;
  round: number;
  application_start: string;
  application_end: string;
  exam_date: string;
  result_date: string;
  description?: string;
}

export interface Certification {
  id: string;
  name: string;
  category: CertificationCategory;
  level?: CertificationLevel;
  organization: string;
  description?: string;
  exam_subjects: string[];
  passing_criteria?: string;
  exam_fee?: {
    written?: number;
    practical?: number;
    regular?: number;
    special?: number;
    basic?: number;
    advanced?: number;
  };
  schedules_2025: ExamSchedule[];
  website?: string;
}

export interface CertificationListResponse {
  certifications: Certification[];
  total: number;
}

export interface UpcomingExam {
  certification_id: string;
  certification_name: string;
  exam_type: ExamType;
  round: number;
  exam_date: string;
  application_start: string;
  application_end: string;
  result_date: string;
  days_until: number;
  is_application_open: boolean;
}

export interface MonthlyCalendar {
  year: number;
  month: number;
  calendar: {
    [day: number]: Array<{
      certification_id: string;
      certification_name: string;
      exam_type: ExamType;
      round: number;
      organization: string;
    }>;
  };
}