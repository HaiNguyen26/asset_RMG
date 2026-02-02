import { Injectable } from '@nestjs/common'
import { PrismaService } from '../prisma/prisma.service'

@Injectable()
export class UsersService {
  constructor(private prisma: PrismaService) {}

  async findByEmployeesCode(employeesCode: string) {
    try {
      return await this.prisma.user.findUnique({
        where: { employeesCode },
        include: { department: true },
      })
    } catch (error: any) {
      console.error('Error finding user by employeesCode:', error)
      throw error
    }
  }

  findAll() {
    return this.prisma.user.findMany({
      include: { department: true },
      orderBy: { name: 'asc' },
    })
  }

  create(data: { employeesCode: string; name: string; email?: string; branch?: string; departmentId?: string; role?: string }) {
    return this.prisma.user.create({
      data: {
        employeesCode: data.employeesCode,
        name: data.name,
        email: data.email,
        branch: data.branch,
        departmentId: data.departmentId,
        role: data.role as any,
      },
      include: { department: true },
    })
  }
}
