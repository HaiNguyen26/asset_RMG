import {
  Controller,
  Get,
  Post,
  Patch,
  Delete,
  Body,
  Param,
  UseGuards,
  Request,
  ForbiddenException,
} from '@nestjs/common'
import { JwtAuthGuard } from '../auth/jwt-auth.guard'
import { PoliciesService } from './policies.service'
import { CreatePolicyDto } from './dto/create-policy.dto'
import { UpdatePolicyDto } from './dto/update-policy.dto'

@Controller('policies')
@UseGuards(JwtAuthGuard)
export class PoliciesController {
  constructor(private readonly policiesService: PoliciesService) {}

  @Get()
  findAll() {
    return this.policiesService.findAll()
  }

  @Get('category/:category')
  findByCategory(@Param('category') category: string) {
    return this.policiesService.findByCategory(category)
  }

  @Get(':id')
  findOne(@Param('id') id: string) {
    return this.policiesService.findOne(id)
  }

  @Post()
  create(@Body() dto: CreatePolicyDto, @Request() req: any) {
    // Only ADMIN can create
    if (req.user.role !== 'ADMIN') {
      throw new ForbiddenException('Chỉ IT Admin mới được tạo chính sách')
    }
    return this.policiesService.create(dto, req.user.userId)
  }

  @Patch(':id')
  update(@Param('id') id: string, @Body() dto: UpdatePolicyDto, @Request() req: any) {
    // Only ADMIN can update
    if (req.user.role !== 'ADMIN') {
      throw new ForbiddenException('Chỉ IT Admin mới được cập nhật chính sách')
    }
    return this.policiesService.update(id, dto, req.user.userId)
  }

  @Delete(':id')
  remove(@Param('id') id: string, @Request() req: any) {
    // Only ADMIN can delete
    if (req.user.role !== 'ADMIN') {
      throw new ForbiddenException('Chỉ IT Admin mới được xóa chính sách')
    }
    return this.policiesService.remove(id)
  }
}
