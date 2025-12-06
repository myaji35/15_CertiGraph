// Common types for CertiGraph

export interface User {
  id: string;
  email: string;
  created_at: string;
}

export interface ApiError {
  error: {
    code: string;
    message: string;
    details?: Record<string, unknown>;
  };
}
