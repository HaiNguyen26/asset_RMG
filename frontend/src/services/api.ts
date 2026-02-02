const API_URL = import.meta.env.VITE_API_URL || 'http://localhost:3000/api'

export interface LoginResponse {
  access_token: string
  user: {
    id: string
    employeesCode: string
    name: string
    email?: string
    branch?: string
    role: string
    departmentId?: string
  }
}

export interface Asset {
  id: string
  code: string
  name: string
  model?: string
  serialNumber?: string
  specification?: string
  employeesCode?: string
  assignedTo?: string
  assignedUser?: {
    id: string
    employeesCode: string
    name: string
    branch?: string
  }
  departmentId?: string
  department?: {
    id: string
    name: string
  }
  inspectionDate?: string
  status: 'AVAILABLE' | 'IN_USE' | 'MAINTENANCE' | 'RETIRED'
  note?: string
  categoryId: string
  category?: {
    id: string
    slug: string
    name: string
  }
  createdAt: string
}

export interface Department {
  id: string
  code: string
  name: string
}

export interface Category {
  id: string
  slug: string
  name: string
  description?: string
}

class ApiService {
  private getToken(): string | null {
    return localStorage.getItem('token')
  }

  private async request<T>(
    endpoint: string,
    options: RequestInit = {},
  ): Promise<T> {
    const token = this.getToken()
    const headers: Record<string, string> = {
      ...(options.headers as Record<string, string>),
    }

    // Only set Content-Type for non-FormData requests
    if (!(options.body instanceof FormData)) {
      headers['Content-Type'] = 'application/json'
    }

    if (token) {
      headers['Authorization'] = `Bearer ${token}`
    }

    try {
      const response = await fetch(`${API_URL}${endpoint}`, {
        ...options,
        headers: headers as HeadersInit,
      })

      if (!response.ok) {
        const error = await response.json().catch(() => ({ message: 'Request failed' }))
        throw new Error(error.message || `HTTP error! status: ${response.status}`)
      }

      return response.json()
    } catch (error: any) {
      if (error.message === 'Failed to fetch') {
        throw new Error('Không thể kết nối đến server. Vui lòng kiểm tra backend đang chạy.')
      }
      throw error
    }
  }

  async login(employeesCode: string, password: string): Promise<LoginResponse> {
    return this.request<LoginResponse>('/auth/login', {
      method: 'POST',
      body: JSON.stringify({ employeesCode, password }),
    })
  }

  async getAssets(params?: {
    categoryId?: string
    status?: string
    departmentId?: string
    search?: string
  }): Promise<Asset[]> {
    const query = new URLSearchParams()
    if (params?.categoryId) query.append('categoryId', params.categoryId)
    if (params?.status) query.append('status', params.status)
    if (params?.departmentId) query.append('departmentId', params.departmentId)
    if (params?.search) query.append('search', params.search)

    return this.request<Asset[]>(`/assets?${query.toString()}`)
  }

  async getAsset(id: string): Promise<Asset> {
    return this.request<Asset>(`/assets/${id}`)
  }

  async createAsset(data: Partial<Asset>): Promise<Asset> {
    return this.request<Asset>('/assets', {
      method: 'POST',
      body: JSON.stringify(data),
    })
  }

  async updateAsset(id: string, data: Partial<Asset>): Promise<Asset> {
    return this.request<Asset>(`/assets/${id}`, {
      method: 'PATCH',
      body: JSON.stringify(data),
    })
  }

  async assignAsset(id: string, employeesCode: string): Promise<Asset> {
    return this.request<Asset>(`/assets/${id}/assign`, {
      method: 'POST',
      body: JSON.stringify({ employeesCode }),
    })
  }

  async returnAsset(id: string): Promise<Asset> {
    return this.request<Asset>(`/assets/${id}/return`, {
      method: 'POST',
    })
  }

  async deleteAsset(id: string): Promise<void> {
    return this.request<void>(`/assets/${id}/delete`, {
      method: 'POST',
    })
  }

  async getDepartments(): Promise<Department[]> {
    return this.request<Department[]>('/departments')
  }

  async getCategories(): Promise<Category[]> {
    return this.request<Category[]>('/categories')
  }

  async importExcel(file: File, categoryId?: string): Promise<any> {
    const token = this.getToken()
    const formData = new FormData()
    formData.append('file', file)

    const url = categoryId 
      ? `${API_URL}/assets/import?categoryId=${encodeURIComponent(categoryId)}`
      : `${API_URL}/assets/import`

    const response = await fetch(url, {
      method: 'POST',
      headers: {
        Authorization: token ? `Bearer ${token}` : '',
      },
      body: formData,
    })

    if (!response.ok) {
      const error = await response.json().catch(() => ({ message: 'Import failed' }))
      throw new Error(error.message || 'Import failed')
    }

    return response.json()
  }

  // Repair History APIs
  async getRepairHistory(params?: {
    assetId?: string
    categoryId?: string
    repairType?: 'INTERNAL_IT' | 'EXTERNAL_VENDOR'
    status?: 'IN_PROGRESS' | 'COMPLETED' | 'CANCELLED'
    fromDate?: string
    toDate?: string
    search?: string
  }): Promise<any[]> {
    const queryParams = new URLSearchParams()
    if (params?.assetId) queryParams.append('assetId', params.assetId)
    if (params?.categoryId) queryParams.append('categoryId', params.categoryId)
    if (params?.repairType) queryParams.append('repairType', params.repairType)
    if (params?.status) queryParams.append('status', params.status)
    if (params?.fromDate) queryParams.append('fromDate', params.fromDate)
    if (params?.toDate) queryParams.append('toDate', params.toDate)
    if (params?.search) queryParams.append('search', params.search)

    return this.request<any[]>(`/repair-history?${queryParams.toString()}`)
  }

  async getRepairHistoryById(id: string): Promise<any> {
    return this.request<any>(`/repair-history/${id}`)
  }

  async createRepairHistory(data: any): Promise<any> {
    return this.request<any>('/repair-history', {
      method: 'POST',
      body: JSON.stringify(data),
    })
  }

  async updateRepairHistory(id: string, data: any): Promise<any> {
    return this.request<any>(`/repair-history/${id}`, {
      method: 'PATCH',
      body: JSON.stringify(data),
    })
  }

  // Policies APIs
  async getPolicies(): Promise<any[]> {
    return this.request<any[]>('/policies')
  }

  async getPolicyByCategory(category: string): Promise<any> {
    return this.request<any>(`/policies/category/${category}`)
  }

  async getPolicy(id: string): Promise<any> {
    return this.request<any>(`/policies/${id}`)
  }

  async createPolicy(data: any): Promise<any> {
    return this.request<any>('/policies', {
      method: 'POST',
      body: JSON.stringify(data),
    })
  }

  async updatePolicy(id: string, data: any): Promise<any> {
    return this.request<any>(`/policies/${id}`, {
      method: 'PATCH',
      body: JSON.stringify(data),
    })
  }
}

export const api = new ApiService()
