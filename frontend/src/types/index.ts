export type AssetStatus = 'available' | 'in_use' | 'maintenance' | 'retired'
export type AssetCategoryId = 'laptop' | 'it_accessory' | 'tech_equipment'

export interface AssetCategory {
  id: AssetCategoryId
  name: string
  description: string
  icon: string
}

export interface Department {
  id: string
  name: string
}

export interface Asset {
  id: string
  code: string // asset_code
  name: string // asset_name
  model?: string
  serialNumber?: string // serial_number
  specification?: string // specification (cấu hình)
  assignedTo?: string // assigned_to
  departmentId?: string
  departmentName?: string
  inspectionDate?: string // inspection_date (ngày kiểm tra)
  status: AssetStatus
  note?: string // note (ghi chú)
  categoryId: AssetCategoryId
  createdAt: string
}

export const ASSET_CATEGORIES: AssetCategory[] = [
  { id: 'laptop', name: 'Laptop', description: 'Máy tính xách tay', icon: 'Laptop' },
  { id: 'it_accessory', name: 'Phụ kiện IT', description: 'Chuột, bàn phím, màn hình...', icon: 'Mouse' },
  { id: 'tech_equipment', name: 'Thiết bị Kỹ thuật', description: 'Máy in, máy chiếu, thiết bị đo...', icon: 'Wrench' },
]

export const STATUS_LABELS: Record<AssetStatus, string> = {
  available: 'Dự phòng',
  in_use: 'Đang sử dụng',
  maintenance: 'Bảo trì',
  retired: 'Thanh lý',
}

export const STATUS_STYLES: Record<AssetStatus, string> = {
  available: 'bg-blue-100 text-blue-800 border-blue-200',
  in_use: 'bg-emerald-100 text-emerald-800 border-emerald-200',
  maintenance: 'bg-amber-100 text-amber-800 border-amber-200',
  retired: 'bg-red-100 text-red-800 border-red-200',
}
