import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common'
import { PrismaService } from '../prisma/prisma.service'
import { CreateAssetDto } from './dto/create-asset.dto'
import { UpdateAssetDto } from './dto/update-asset.dto'
import { AssetStatus } from '@prisma/client'
import * as XLSX from 'xlsx'
import * as bcrypt from 'bcrypt'

@Injectable()
export class AssetsService {
  constructor(private readonly prisma: PrismaService) {}

  async findAll(filters: {
    categoryId?: string
    status?: AssetStatus
    departmentId?: string
    search?: string
  }) {
    const where: Record<string, unknown> = {}
    if (filters.categoryId) where.categoryId = filters.categoryId
    if (filters.status) where.status = filters.status
    if (filters.departmentId) where.departmentId = filters.departmentId
    if (filters.search?.trim()) {
      where.OR = [
        { code: { contains: filters.search.trim(), mode: 'insensitive' } },
        { name: { contains: filters.search.trim(), mode: 'insensitive' } },
        { serialNumber: { contains: filters.search.trim(), mode: 'insensitive' } },
        { specification: { contains: filters.search.trim(), mode: 'insensitive' } },
      ]
    }
    return this.prisma.asset.findMany({
      where,
      include: {
        category: true,
        department: true,
        assignedUser: {
          include: { department: true },
        },
      },
      orderBy: { createdAt: 'desc' },
    })
  }

  async findOne(id: string) {
    const asset = await this.prisma.asset.findUnique({
      where: { id },
      include: {
        category: true,
        department: true,
        assignedUser: {
          include: { department: true },
        },
      },
    })
    if (!asset) throw new NotFoundException('Asset not found')
    return asset
  }

  async create(dto: CreateAssetDto) {
    return this.prisma.asset.create({
      data: {
        code: dto.code,
        name: dto.name,
        model: dto.model,
        serialNumber: dto.serialNumber,
        specification: dto.specification,
        assignedTo: dto.assignedTo,
        employeesCode: dto.employeesCode,
        departmentId: dto.departmentId,
        inspectionDate: dto.inspectionDate ? new Date(dto.inspectionDate) : null,
        status: (dto.status as AssetStatus) ?? 'AVAILABLE',
        note: dto.note,
        categoryId: dto.categoryId,
      },
      include: {
        category: true,
        department: true,
        assignedUser: {
          include: { department: true },
        },
      },
    })
  }

  async assignAsset(assetId: string, employeesCode: string) {
    const user = await this.prisma.user.findUnique({ where: { employeesCode } })
    if (!user) throw new NotFoundException('User not found')

    const asset = await this.findOne(assetId)
    return this.prisma.asset.update({
      where: { id: assetId },
      data: {
        assignedUserId: user.id,
        assignedTo: user.name,
        employeesCode: user.employeesCode,
        status: 'IN_USE' as AssetStatus,
        departmentId: user.departmentId,
      },
      include: {
        category: true,
        department: true,
        assignedUser: {
          include: { department: true },
        },
      },
    })
  }

  async returnAsset(assetId: string) {
    await this.findOne(assetId)
    return this.prisma.asset.update({
      where: { id: assetId },
      data: {
        assignedUserId: null,
        assignedTo: null,
        employeesCode: null,
        status: 'AVAILABLE' as AssetStatus,
      },
      include: {
        category: true,
        department: true,
        assignedUser: {
          include: { department: true },
        },
      },
    })
  }

  async update(id: string, dto: UpdateAssetDto) {
    await this.findOne(id)
    return this.prisma.asset.update({
      where: { id },
      data: {
        ...(dto.code != null && { code: dto.code }),
        ...(dto.name != null && { name: dto.name }),
        ...(dto.model != null && { model: dto.model }),
        ...(dto.serialNumber != null && { serialNumber: dto.serialNumber }),
        ...(dto.specification != null && { specification: dto.specification }),
        ...(dto.assignedTo != null && { assignedTo: dto.assignedTo }),
        ...(dto.employeesCode != null && { employeesCode: dto.employeesCode }),
        ...(dto.departmentId != null && { departmentId: dto.departmentId }),
        ...(dto.inspectionDate != null && {
          inspectionDate: new Date(dto.inspectionDate),
        }),
        ...(dto.status != null && { status: dto.status as AssetStatus }),
        ...(dto.note != null && { note: dto.note }),
      },
      include: {
        category: true,
        department: true,
        assignedUser: {
          include: { department: true },
        },
      },
    })
  }

  async delete(id: string) {
    await this.findOne(id)
    await this.prisma.asset.delete({
      where: { id },
    })
    return { message: 'Asset deleted successfully' }
  }

  async importExcel(file: Express.Multer.File, defaultCategoryId?: string) {
    if (!file) {
      throw new BadRequestException('No file uploaded')
    }

    try {
      const workbook = XLSX.read(file.buffer, { type: 'buffer' })
      const sheetName = workbook.SheetNames[0]
      const worksheet = workbook.Sheets[sheetName]
      const data = XLSX.utils.sheet_to_json(worksheet)

      if (!data || data.length === 0) {
        return {
          success: 0,
          errorCount: 0,
          errors: 1,
          results: [],
          errorDetails: [{ row: 1, error: 'File Excel không có dữ liệu hoặc chỉ có header' }],
          message: 'File Excel không có dữ liệu. Vui lòng kiểm tra lại file.',
        }
      }

      const results = []
      const errors = []

      // Get categories and departments for mapping
      const categories = await this.prisma.assetCategory.findMany()
      const departments = await this.prisma.department.findMany()
      const categoryMap = new Map(categories.map((c) => [c.slug.toLowerCase(), c.id]))
      // Also map by name for flexibility
      categories.forEach((c) => {
        categoryMap.set(c.name.toLowerCase().replace(/\s+/g, '_'), c.id)
      })
      
      // Get default category if provided
      let defaultCategory: string | undefined
      if (defaultCategoryId) {
        // Try to find category by slug first (most common case)
        const catBySlug = categories.find((c) => c.slug === defaultCategoryId || c.slug.toLowerCase() === defaultCategoryId.toLowerCase())
        if (catBySlug) {
          defaultCategory = catBySlug.id
          console.log(`✅ Found category by slug "${defaultCategoryId}": ${catBySlug.name} (ID: ${catBySlug.id})`)
        } else {
          // Try by ID
          const catById = categories.find((c) => c.id === defaultCategoryId)
          if (catById) {
            defaultCategory = catById.id
            console.log(`✅ Found category by ID "${defaultCategoryId}": ${catById.name}`)
          } else {
            console.log(`⚠️  Category not found: "${defaultCategoryId}". Available categories:`, categories.map(c => ({ slug: c.slug, id: c.id, name: c.name })))
          }
        }
      } else {
        console.log('⚠️  No defaultCategoryId provided. Will require "Loại" column or use fallback.')
      }
      // Simple map for quick lookup by name (case-insensitive)
      const deptNameMap = new Map<string, string>()
      departments.forEach((d) => {
        // Only map by exact name (case-insensitive)
        deptNameMap.set(d.name.toLowerCase().trim(), d.id)
      })
      
      // Log available departments for debugging
      if (departments.length > 0) {
        console.log('📋 Available departments:', departments.map(d => ({ code: d.code, name: d.name, id: d.id })))
      }

      // Get all available column names from first row
      const availableColumns = data.length > 0 ? Object.keys(data[0] as any) : []
      const columnMap = new Map<string, string>()
      
      // Create a flexible column mapping (normalize column names)
      availableColumns.forEach((col) => {
        const normalized = col.toLowerCase().trim().replace(/\s+/g, '').replace(/[^\w]/g, '')
        columnMap.set(normalized, col)
        // Also map with spaces preserved (lowercase)
        columnMap.set(col.toLowerCase().trim(), col)
      })

      // Log available columns for debugging
      if (data.length > 0) {
        console.log('📋 Available columns:', availableColumns)
        console.log('📋 First row sample:', data[0])
        console.log('📋 Available categories:', Array.from(categoryMap.keys()))
        console.log('📋 Available departments:', departments.map(d => ({ code: d.code, name: d.name, id: d.id })))
      }

      // Pre-count existing assets for each category to avoid duplicates during batch import
      const categoryCountMap = new Map<string, number>()
      for (const category of categories) {
        const count = await this.prisma.asset.count({
          where: { categoryId: category.id },
        })
        categoryCountMap.set(category.id, count)
      }

      // Track how many codes we've generated in this batch for each category
      const batchCountMap = new Map<string, number>()

      // Helper function to generate asset code based on category
      const generateAssetCode = (categoryId: string): string => {
        // Get category to determine prefix
        const category = categories.find((c) => c.id === categoryId)
        if (!category) {
          throw new Error(`Category not found: ${categoryId}`)
        }

        // Map category slug to prefix
        const prefixMap: Record<string, string> = {
          laptop: 'LT',
          it_accessory: 'PK',
          tech_equipment: 'TB',
        }
        const prefix = prefixMap[category.slug] || 'TS' // Default to 'TS' (Tài Sản)

        // Get base count (existing assets) and batch count (generated in this import)
        const baseCount = categoryCountMap.get(categoryId) || 0
        const batchCount = batchCountMap.get(categoryId) || 0

        // Generate code: PREFIX-XXX (e.g., LT-001, LT-002)
        const nextNumber = baseCount + batchCount + 1
        const code = `${prefix}-${String(nextNumber).padStart(3, '0')}`

        // Increment batch count for this category
        batchCountMap.set(categoryId, batchCount + 1)

        return code
      }

      // Helper function to find column value
      const getColumnValue = (row: any, possibleNames: string[]): string | undefined => {
        // First try exact match (case-sensitive)
        for (const name of possibleNames) {
          if (row[name] !== undefined && row[name] !== null && row[name] !== '') {
            const value = row[name]?.toString().trim()
            if (value) return value
          }
        }
        
        // Try case-insensitive exact match
        for (const name of possibleNames) {
          const nameLower = name.toLowerCase().trim()
          for (const col of availableColumns) {
            if (col.toLowerCase().trim() === nameLower) {
              const value = row[col]?.toString().trim()
              if (value) return value
            }
          }
        }
        
        // Try normalized search (remove spaces and special chars)
        for (const name of possibleNames) {
          const normalized = name.toLowerCase().trim().replace(/\s+/g, '').replace(/[^\w]/g, '')
          const actualCol = columnMap.get(normalized)
          if (actualCol) {
            const value = row[actualCol]?.toString().trim()
            if (value) return value
          }
        }
        
        return undefined
      }

      // Helper function to safely parse date from Excel
      const parseDate = (dateStr: string | undefined): Date | null => {
        if (!dateStr || !dateStr.trim()) {
          return null
        }

        const trimmed = dateStr.toString().trim()
        
        // Excel dates might come as numbers (serial date) or strings
        // Try parsing as number first (Excel serial date)
        const excelSerial = Number(trimmed)
        if (!isNaN(excelSerial) && excelSerial > 0) {
          // Excel serial date: days since 1900-01-01
          // Excel incorrectly treats 1900 as a leap year, so we need to adjust
          const excelEpoch = new Date(1899, 11, 30) // Dec 30, 1899
          const date = new Date(excelEpoch.getTime() + excelSerial * 24 * 60 * 60 * 1000)
          if (!isNaN(date.getTime())) {
            return date
          }
        }

        // Try parsing as ISO string or common date formats
        const date = new Date(trimmed)
        if (!isNaN(date.getTime())) {
          return date
        }

        // Try common Vietnamese date formats: DD/MM/YYYY, DD-MM-YYYY
        const vnDateMatch = trimmed.match(/^(\d{1,2})[\/\-](\d{1,2})[\/\-](\d{4})$/)
        if (vnDateMatch) {
          const [, day, month, year] = vnDateMatch
          const vnDate = new Date(parseInt(year), parseInt(month) - 1, parseInt(day))
          if (!isNaN(vnDate.getTime())) {
            return vnDate
          }
        }

        // If all parsing fails, return null
        return null
      }

      for (let i = 0; i < data.length; i++) {
        const row = data[i] as any
        try {
          // Try multiple column name variations for category
          const categorySlug = getColumnValue(row, [
            'Loại', 'Category', 'category', 'loại', 'CATEGORY', 
            'Loại tài sản', 'Loại tài sản', 'Type', 'type', 'TYPE'
          ])
          
          let categoryId: string | undefined
          
          if (categorySlug) {
            // If category column exists, use it
            const normalizedCategory = categorySlug.toLowerCase().trim().replace(/\s+/g, '_')
            categoryId = categoryMap.get(normalizedCategory)
            
            // Try mapping Vietnamese names if not found
            if (!categoryId) {
              const vnMap: Record<string, string> = {
                'laptop': 'laptop',
                'máy tính xách tay': 'laptop',
                'phụ kiện it': 'it_accessory',
                'phụ kiện': 'it_accessory',
                'thiết bị kỹ thuật': 'tech_equipment',
                'thiết bị': 'tech_equipment',
              }
              const mappedSlug = vnMap[normalizedCategory] || normalizedCategory
              categoryId = categoryMap.get(mappedSlug)
            }
            
            if (!categoryId) {
              errors.push({ 
                row: i + 2, 
                error: `Loại "${categorySlug}" không hợp lệ. Các loại hợp lệ: laptop, it_accessory, tech_equipment (hoặc: Laptop, Phụ kiện IT, Thiết bị Kỹ thuật)` 
              })
              continue
            }
          } else if (defaultCategory) {
            // If no category column but default category provided, use it
            categoryId = defaultCategory
          } else {
            // No category column and no default category - try to use first available category as fallback
            if (categories.length > 0) {
              categoryId = categories[0].id
              console.log(`⚠️  Không có cột "Loại" và không có defaultCategory, sử dụng category đầu tiên: ${categories[0].name}`)
            } else {
              errors.push({ 
                row: i + 2, 
                error: `Không tìm thấy cột "Loại" và không có category nào trong hệ thống. Các cột có sẵn: ${availableColumns.slice(0, 10).join(', ')}${availableColumns.length > 10 ? '...' : ''}. Vui lòng thêm cột "Loại" hoặc import từ trang category cụ thể.` 
              })
              continue
            }
          }

          // Get code and name (required fields) - prioritize exact column names from Excel
          // Try all possible variations including exact match from available columns
          let code = getColumnValue(row, ['Mã laptop', 'Mã', 'Code', 'mã', 'CODE', 'Mã tài sản', 'Mã Laptop'])
          let name = getColumnValue(row, ['Tên thiết bị', 'Tên', 'Name', 'tên', 'NAME', 'Tên tài sản', 'Tên Thiết Bị'])
          
          // If still not found, try direct lookup from available columns (case-insensitive)
          if (!code) {
            for (const col of availableColumns) {
              const colLower = col.toLowerCase().trim()
              if (colLower === 'mã laptop' || colLower === 'mã' || colLower === 'code' || colLower === 'mãlaptop') {
                const val = row[col]?.toString().trim()
                if (val && val !== 'N/A' && val !== 'n/a' && val !== '') {
                  code = val
                  break
                }
              }
            }
          }
          
          if (!name) {
            for (const col of availableColumns) {
              const colLower = col.toLowerCase().trim()
              if (colLower === 'tên thiết bị' || colLower === 'tên' || colLower === 'name' || colLower === 'tênthiếtbị') {
                const val = row[col]?.toString().trim()
                if (val) {
                  name = val
                  break
                }
              }
            }
          }

          // Auto-generate code if missing or invalid (N/A, empty, etc.)
          if (!code || code === 'N/A' || code === 'n/a' || code.trim() === '') {
            try {
              code = generateAssetCode(categoryId)
              console.log(`Auto-generated code for row ${i + 2}: ${code}`)
            } catch (error: any) {
              errors.push({ 
                row: i + 2, 
                error: `Không thể tự động sinh mã: ${error.message}` 
              })
              continue
            }
          }

          if (!name) {
            // Log first row for debugging
            if (i === 0) {
              console.log('First row data:', row)
              console.log('Available columns:', availableColumns)
            }
            errors.push({ 
              row: i + 2, 
              error: `Thiếu tên thiết bị. Tên: "${name || 'N/A'}". Các cột có sẵn: ${availableColumns.join(', ')}` 
            })
            continue
          }

          // Get department from Excel - simple approach: find or create
          const deptValue = getColumnValue(row, [
            'Phòng ban', 
            'Phòng Ban',
            'PHÒNG BAN',
            'phòng ban',
            'Phòng/Ban',
            'Phòng/Bộ phận',
            'Department', 
            'department', 
            'DEPARTMENT',
            'Phòng',
            'Dept',
            'dept',
            'Bộ phận'
          ])
          
          let departmentId: string | undefined
          
          if (deptValue) {
            const deptTrimmed = deptValue.trim()
            const deptLower = deptTrimmed.toLowerCase()
            
            // Generate department code from name (remove accents, special chars, uppercase)
            // Declare outside try-catch so it can be used in catch block
            const deptCode = deptTrimmed
              .normalize('NFD')
              .replace(/[\u0300-\u036f]/g, '') // Remove accents
              .replace(/[^A-Z0-9]/g, '') // Remove non-alphanumeric
              .toUpperCase()
              .substring(0, 10) || 'DEPT'
            
            // Simple lookup: find by exact name match (case-insensitive)
            const foundDeptId = deptNameMap.get(deptLower)
            
            if (foundDeptId) {
              // Found existing department with exact name match
              departmentId = foundDeptId
              if (i < 3) {
                const dept = departments.find(d => d.id === foundDeptId)
                console.log(`✅ Found existing department: "${deptValue}" -> ${dept?.name} (${foundDeptId})`)
              }
            } else {
              // Department not found, create new one with exact name from Excel
              try {
                // Check if code already exists in current batch (might have been created in previous rows)
                const existingInBatch = departments.find(d => d.code === deptCode)
                
                if (existingInBatch) {
                  departmentId = existingInBatch.id
                  if (i < 3) {
                    console.log(`✅ Found department in batch: "${deptValue}" -> ${deptCode} (${existingInBatch.id})`)
                  }
                } else {
                  // Create new department with exact name from Excel
                  const newDept = await this.prisma.department.create({
                    data: {
                      code: deptCode,
                      name: deptTrimmed, // Use EXACT name from Excel
                    },
                  })
                  departmentId = newDept.id
                  
                  // Add to local cache for subsequent rows in this import
                  departments.push(newDept)
                  deptNameMap.set(deptLower, newDept.id)
                  
                  if (i < 3) {
                    console.log(`✅ Created new department: "${deptValue}" -> Code: ${deptCode}, Name: "${newDept.name}" (${newDept.id})`)
                  }
                }
              } catch (error: any) {
                // If creation fails (e.g., duplicate code), try to find by code
                console.error(`⚠️  Error creating department "${deptValue}":`, error.message)
                try {
                  const foundByCode = await this.prisma.department.findUnique({
                    where: { code: deptCode },
                  })
                  if (foundByCode) {
                    departmentId = foundByCode.id
                    if (!departments.find(d => d.id === foundByCode.id)) {
                      departments.push(foundByCode)
                      deptNameMap.set(foundByCode.name.toLowerCase().trim(), foundByCode.id)
                    }
                  }
                } catch (findError) {
                  // Ignore find error, continue without department
                }
              }
            }
          }
          
          // Get employee code - prioritize exact column name
          const employeesCode = getColumnValue(row, ['Mã Nhân Viên', 'Mã NV', 'Employees Code', 'employees_code', 'Mã nhân viên', 'mã_nv'])
          let assignedUserId: string | undefined
          let assignedTo = getColumnValue(row, ['Người sử dụng', 'Assigned To', 'assigned_to', 'Người dùng'])
          let userDepartmentId: string | undefined // Store user's department for fallback
          
          // Get branch from Excel
          const branch = getColumnValue(row, ['Chi nhánh', 'Branch', 'branch', 'Chi Nhánh'])

          // Find or create user by employeesCode if provided
          // Use departmentId from Excel if available when creating user
          if (employeesCode) {
            const empCode = employeesCode.toString().trim()
            let user = await this.prisma.user.findUnique({
              where: { employeesCode: empCode },
              include: { department: true }, // Include department to get departmentId
            })
            
            if (!user) {
              // Create user if not exists, assign department if available
              // Set default password: RMG123@
              const defaultPassword = 'RMG123@'
              const hashedPassword = await bcrypt.hash(defaultPassword, 10)
              
              // Generate email from employeesCode if not provided
              const email = `${empCode.toLowerCase()}@rmg.vn`
              
              user = await this.prisma.user.create({
                data: {
                  employeesCode: empCode,
                  name: assignedTo || empCode,
                  password: hashedPassword,
                  email: email,
                  branch: branch || undefined,
                  departmentId: departmentId || undefined, // Assign department from Excel if available
                  role: 'USER', // Default role is USER
                },
                include: { department: true },
              })
              console.log(`✅ Created new user ${empCode} with default password RMG123@`)
              if (departmentId) {
                console.log(`✅ Assigned department to new user ${empCode}: ${departmentId}`)
              }
            } else {
              // Update user if needed
              const updateData: { branch?: string; departmentId?: string; password?: string } = {}
              
              if (branch && user.branch !== branch) {
                updateData.branch = branch
              }
              
              // Update department if Excel has it and user doesn't have one, or if different
              if (departmentId && (!user.departmentId || user.departmentId !== departmentId)) {
                updateData.departmentId = departmentId
                console.log(`✅ Updated department for user ${empCode}: ${departmentId}`)
              }
              
              // Set default password if user doesn't have one
              if (!user.password) {
                const defaultPassword = 'RMG123@'
                const hashedPassword = await bcrypt.hash(defaultPassword, 10)
                updateData.password = hashedPassword
                console.log(`✅ Set default password RMG123@ for existing user ${empCode}`)
              }
              
              if (Object.keys(updateData).length > 0) {
                user = await this.prisma.user.update({
                  where: { id: user.id },
                  data: updateData,
                  include: { department: true },
                })
              }
            }
            
            if (user) {
              assignedUserId = user.id
              if (!assignedTo) assignedTo = user.name
              // Store user's departmentId for fallback
              userDepartmentId = user.departmentId || undefined
            }
          }
          
          // If no department from Excel but user has department, use user's department
          if (!departmentId && userDepartmentId) {
            departmentId = userDepartmentId
            console.log(`✅ Auto-assigned department from user for row ${i + 2}: ${departmentId}`)
          }
          
          // Log if still no department
          if (!departmentId && i === 0) {
            console.log(`⚠️  Row ${i + 2}: Không có phòng ban. Excel value: "${deptValue || 'N/A'}", User dept: ${userDepartmentId || 'N/A'}`)
          }

          // Get other fields - prioritize exact column names from Excel
          const serialNumber = getColumnValue(row, ['Serial', 'Serial Number', 'serial_number', 'Số serial'])
          const specification = getColumnValue(row, ['Cấu hình', 'Specification', 'specification', 'Cấu Hình'])
          const statusValue = getColumnValue(row, ['Trạng thái', 'Status', 'status', 'Trạng Thái'])
          const note = getColumnValue(row, ['Ghi chú', 'Note', 'note', 'Ghi Chú'])
          const inspectionDateStr = getColumnValue(row, ['Ngày kiểm tra', 'Inspection Date', 'Ngày Kiểm Tra'])
          const inspectionDate = parseDate(inspectionDateStr)

          // Log department info before creating asset
          if (i === 0 || !departmentId) {
            console.log(`Row ${i + 2} - Department info: Excel value="${deptValue || 'N/A'}", departmentId="${departmentId || 'N/A'}", userDepartmentId="${userDepartmentId || 'N/A'}"`)
          }

          const asset = await this.prisma.asset.create({
            data: {
              code: code.toString().trim(),
              name: name.toString().trim(),
              model: getColumnValue(row, ['Model', 'model', 'MODEL']),
              serialNumber: serialNumber || undefined,
              specification: specification || undefined,
              employeesCode: employeesCode ? employeesCode.toString().trim() : undefined,
              assignedTo: assignedTo || undefined,
              assignedUserId,
              departmentId: departmentId || undefined, // Explicitly set, even if null
              status: this.mapStatus(statusValue || ''),
              note: note || undefined,
              categoryId,
              inspectionDate,
            },
            include: {
              department: true, // Include department to verify
            },
          })
          
          // Log created asset department
          if (i === 0 || !asset.department) {
            console.log(`Row ${i + 2} - Created asset department: ${asset.department?.name || 'N/A'} (departmentId: ${asset.departmentId || 'null'})`)
          }
          
          results.push(asset)
        } catch (error: any) {
          errors.push({ row: i + 2, error: error.message || 'Lỗi không xác định' })
        }
      }

      return {
        success: results.length,
        errorCount: errors.length,
        errors: errors.length,
        results,
        errorDetails: errors.slice(0, 20), // Show more errors
        message: errors.length > 0 
          ? `Import hoàn tất: ${results.length} thành công, ${errors.length} lỗi. Vui lòng kiểm tra chi tiết lỗi.`
          : `Import thành công ${results.length} bản ghi.`,
      }
    } catch (error: any) {
      throw new BadRequestException(`Failed to import Excel: ${error.message}`)
    }
  }

  private mapStatus(status: string): AssetStatus {
    const statusMap: Record<string, AssetStatus> = {
      'Dự phòng': 'AVAILABLE',
      'Đang sử dụng': 'IN_USE',
      'Bảo trì': 'MAINTENANCE',
      'Thanh lý': 'RETIRED',
      AVAILABLE: 'AVAILABLE',
      IN_USE: 'IN_USE',
      MAINTENANCE: 'MAINTENANCE',
      RETIRED: 'RETIRED',
    }
    return statusMap[status] || 'AVAILABLE'
  }
}
