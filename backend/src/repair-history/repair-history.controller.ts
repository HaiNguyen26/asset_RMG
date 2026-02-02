import {
  Controller,
  Get,
  Post,
  Patch,
  Delete,
  Body,
  Param,
  Query,
  UseGuards,
  Request,
  ForbiddenException,
} from '@nestjs/common'
import { JwtAuthGuard } from '../auth/jwt-auth.guard'
import { RepairHistoryService } from './repair-history.service'
import { CreateRepairHistoryDto } from './dto/create-repair-history.dto'
import { UpdateRepairHistoryDto } from './dto/update-repair-history.dto'
import { RepairType, RepairStatus } from '@prisma/client'

@Controller('repair-history')
@UseGuards(JwtAuthGuard)
export class RepairHistoryController {
  constructor(private readonly repairHistoryService: RepairHistoryService) {}

  @Get()
  findAll(
    @Query('assetId') assetId?: string,
    @Query('categoryId') categoryId?: string,
    @Query('repairType') repairType?: RepairType,
    @Query('status') status?: RepairStatus,
    @Query('fromDate') fromDate?: string,
    @Query('toDate') toDate?: string,
    @Query('search') search?: string,
  ) {
    return this.repairHistoryService.findAll({
      assetId,
      categoryId,
      repairType,
      status,
      fromDate,
      toDate,
      search,
    })
  }

  @Get(':id')
  findOne(@Param('id') id: string) {
    return this.repairHistoryService.findOne(id)
  }

  @Post()
  create(@Body() dto: CreateRepairHistoryDto, @Request() req: any) {
    // Only ADMIN can create
    if (req.user.role !== 'ADMIN') {
      throw new ForbiddenException('Chỉ IT Admin mới được tạo lịch sử sửa chữa')
    }
    return this.repairHistoryService.create(dto, req.user.userId)
  }

  @Patch(':id')
  update(@Param('id') id: string, @Body() dto: UpdateRepairHistoryDto, @Request() req: any) {
    // Only ADMIN can update
    if (req.user.role !== 'ADMIN') {
      throw new ForbiddenException('Chỉ IT Admin mới được cập nhật lịch sử sửa chữa')
    }
    return this.repairHistoryService.update(id, dto, req.user.userId)
  }

  @Delete(':id')
  remove(@Param('id') id: string) {
    // No deletion allowed
    return this.repairHistoryService.remove(id)
  }
}
