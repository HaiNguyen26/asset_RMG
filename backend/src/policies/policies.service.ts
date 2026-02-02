import { Injectable, NotFoundException, ForbiddenException } from '@nestjs/common'
import { PrismaService } from '../prisma/prisma.service'
import { CreatePolicyDto } from './dto/create-policy.dto'
import { UpdatePolicyDto } from './dto/update-policy.dto'

@Injectable()
export class PoliciesService {
  constructor(private readonly prisma: PrismaService) {}

  async findAll() {
    return this.prisma.policy.findMany({
      orderBy: { order: 'asc' },
      include: {
        updatedBy: {
          select: {
            id: true,
            name: true,
            employeesCode: true,
          },
        },
      },
    })
  }

  async findOne(id: string) {
    const policy = await this.prisma.policy.findUnique({
      where: { id },
      include: {
        updatedBy: {
          select: {
            id: true,
            name: true,
            employeesCode: true,
          },
        },
      },
    })
    if (!policy) throw new NotFoundException('Policy not found')
    return policy
  }

  async findByCategory(category: string) {
    const policy = await this.prisma.policy.findUnique({
      where: { category },
      include: {
        updatedBy: {
          select: {
            id: true,
            name: true,
            employeesCode: true,
          },
        },
      },
    })
    if (!policy) throw new NotFoundException('Policy not found')
    return policy
  }

  async create(dto: CreatePolicyDto, userId: string) {
    return this.prisma.policy.create({
      data: {
        category: dto.category,
        title: dto.title,
        content: dto.content,
        order: dto.order || 0,
        updatedById: userId,
      },
      include: {
        updatedBy: {
          select: {
            id: true,
            name: true,
            employeesCode: true,
          },
        },
      },
    })
  }

  async update(id: string, dto: UpdatePolicyDto, userId: string) {
    await this.findOne(id)

    const updateData: Record<string, unknown> = {}
    if (dto.title) updateData.title = dto.title
    if (dto.content) updateData.content = dto.content
    if (dto.order !== undefined) updateData.order = dto.order
    updateData.updatedById = userId

    return this.prisma.policy.update({
      where: { id },
      data: updateData,
      include: {
        updatedBy: {
          select: {
            id: true,
            name: true,
            employeesCode: true,
          },
        },
      },
    })
  }

  async remove(id: string) {
    await this.findOne(id)
    await this.prisma.policy.delete({
      where: { id },
    })
    return { message: 'Policy deleted successfully' }
  }
}
