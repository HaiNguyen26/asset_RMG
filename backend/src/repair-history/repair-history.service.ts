import { Injectable, NotFoundException, ForbiddenException } from '@nestjs/common'
import { PrismaService } from '../prisma/prisma.service'
import { CreateRepairHistoryDto } from './dto/create-repair-history.dto'
import { UpdateRepairHistoryDto } from './dto/update-repair-history.dto'
import { RepairType, RepairStatus, Prisma } from '@prisma/client'

@Injectable()
export class RepairHistoryService {
  constructor(private readonly prisma: PrismaService) {}

  async findAll(filters: {
    assetId?: string
    categoryId?: string
    repairType?: RepairType
    status?: RepairStatus
    fromDate?: string
    toDate?: string
    search?: string
  }) {
    const where: Prisma.RepairHistoryWhereInput = {}

    if (filters.assetId) {
      where.assetId = filters.assetId
    }

    if (filters.categoryId) {
      where.asset = { categoryId: filters.categoryId }
    }

    if (filters.repairType) {
      where.repairType = filters.repairType
    }

    if (filters.status) {
      where.status = filters.status
    }

    if (filters.fromDate || filters.toDate) {
      where.errorDate = {}
      if (filters.fromDate) {
        where.errorDate.gte = new Date(filters.fromDate)
      }
      if (filters.toDate) {
        where.errorDate.lte = new Date(filters.toDate)
      }
    }

    if (filters.search?.trim()) {
      where.OR = [
        { asset: { code: { contains: filters.search.trim(), mode: 'insensitive' } } },
        { asset: { name: { contains: filters.search.trim(), mode: 'insensitive' } } },
        { description: { contains: filters.search.trim(), mode: 'insensitive' } },
      ]
    }

    return this.prisma.repairHistory.findMany({
      where,
      include: {
        asset: {
          include: {
            category: true,
            assignedUser: true,
          },
        },
        createdBy: true,
      },
      orderBy: { errorDate: 'desc' },
    })
  }

  async findOne(id: string) {
    const repair = await this.prisma.repairHistory.findUnique({
      where: { id },
      include: {
        asset: {
          include: {
            category: true,
            assignedUser: {
              include: { department: true },
            },
          },
        },
        createdBy: true,
      },
    })
    if (!repair) throw new NotFoundException('Repair history not found')
    return repair
  }

  async create(dto: CreateRepairHistoryDto, userId: string) {
    // Check if asset exists
    const asset = await this.prisma.asset.findUnique({
      where: { id: dto.assetId },
    })
    if (!asset) {
      throw new NotFoundException('Asset not found')
    }

    return this.prisma.repairHistory.create({
      data: {
        assetId: dto.assetId,
        errorDate: new Date(dto.errorDate),
        description: dto.description,
        repairType: dto.repairType as RepairType,
        repairUnit: dto.repairUnit,
        result: dto.result,
        status: (dto.status as RepairStatus) || RepairStatus.IN_PROGRESS,
        itNote: dto.itNote,
        createdById: userId,
      },
      include: {
        asset: {
          include: {
            category: true,
            assignedUser: true,
          },
        },
        createdBy: true,
      },
    })
  }

  async update(id: string, dto: UpdateRepairHistoryDto, userId: string) {
    await this.findOne(id)

    const updateData: Record<string, unknown> = {}
    if (dto.errorDate) updateData.errorDate = new Date(dto.errorDate)
    if (dto.description) updateData.description = dto.description
    if (dto.repairType) updateData.repairType = dto.repairType as RepairType
    if (dto.repairUnit !== undefined) updateData.repairUnit = dto.repairUnit
    if (dto.result !== undefined) updateData.result = dto.result
    if (dto.status) updateData.status = dto.status as RepairStatus
    if (dto.itNote !== undefined) updateData.itNote = dto.itNote

    return this.prisma.repairHistory.update({
      where: { id },
      data: updateData,
      include: {
        asset: {
          include: {
            category: true,
            assignedUser: true,
          },
        },
        createdBy: true,
      },
    })
  }

  async remove(id: string) {
    await this.findOne(id)
    // Note: According to requirements, no deletion allowed
    throw new ForbiddenException('Không được phép xóa dữ liệu lịch sử sửa chữa')
  }
}
