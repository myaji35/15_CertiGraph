import { auth } from '@clerk/nextjs/server';

const API_BASE_URL = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8015/api/v1';

interface RequestOptions extends RequestInit {
  headers?: Record<string, string>;
}

class ApiClient {
  private baseUrl: string;

  constructor(baseUrl: string) {
    this.baseUrl = baseUrl;
  }

  private async getHeaders(): Promise<Headers> {
    const headers = new Headers({
      'Content-Type': 'application/json',
    });

    // Add authentication token if available (server-side)
    if (typeof window === 'undefined') {
      try {
        const { getToken } = await auth();
        const token = await getToken();
        if (token) {
          headers.append('Authorization', `Bearer ${token}`);
        }
      } catch (error) {
        // Auth may not be available in some contexts
        console.debug('Auth not available:', error);
      }
    } else {
      // Client-side: Get token from Clerk
      try {
        const { Clerk } = await import('@clerk/nextjs');
        // @ts-ignore - Clerk is available globally in client
        const token = await window.Clerk?.session?.getToken();
        if (token) {
          headers.append('Authorization', `Bearer ${token}`);
        }
      } catch (error) {
        console.debug('Client auth not available:', error);
      }
    }

    return headers;
  }

  async request(endpoint: string, options: RequestOptions = {}): Promise<Response> {
    const url = `${this.baseUrl}${endpoint}`;
    const headers = await this.getHeaders();

    // Merge custom headers with default headers
    if (options.headers) {
      Object.entries(options.headers).forEach(([key, value]) => {
        headers.set(key, value);
      });
    }

    const response = await fetch(url, {
      ...options,
      headers,
    });

    return response;
  }

  async get(endpoint: string, options?: RequestOptions): Promise<Response> {
    return this.request(endpoint, {
      ...options,
      method: 'GET',
    });
  }

  async post(endpoint: string, options?: RequestOptions): Promise<Response> {
    return this.request(endpoint, {
      ...options,
      method: 'POST',
    });
  }

  async put(endpoint: string, options?: RequestOptions): Promise<Response> {
    return this.request(endpoint, {
      ...options,
      method: 'PUT',
    });
  }

  async patch(endpoint: string, options?: RequestOptions): Promise<Response> {
    return this.request(endpoint, {
      ...options,
      method: 'PATCH',
    });
  }

  async delete(endpoint: string, options?: RequestOptions): Promise<Response> {
    return this.request(endpoint, {
      ...options,
      method: 'DELETE',
    });
  }
}

export const apiClient = new ApiClient(API_BASE_URL);

// Helper function for multipart/form-data requests (like file uploads)
export async function uploadFile(endpoint: string, formData: FormData): Promise<Response> {
  const headers = await apiClient['getHeaders']();
  headers.delete('Content-Type'); // Let browser set the boundary for multipart

  const response = await fetch(`${API_BASE_URL}${endpoint}`, {
    method: 'POST',
    headers,
    body: formData,
  });

  return response;
}