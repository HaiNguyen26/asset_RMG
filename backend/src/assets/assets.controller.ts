import {
  Controller,
  Get,
  Post,
  Patch,
  Param,
  Body,
  Query,
  UseInterceptors,
  UploadedFile,
} from '@nestjs/common'
import { FileInterceptor } from '@nestjs/platform-express'
import { AssetsService } from './assets.service'
import { CreateAssetDto } from './dto/create-asset.dto'
import { UpdateAssetDto } from './dto/update-asset.dto'
import { AssetStatus } from '@prisma/client'

@Controller('assets')
export class AssetsController {
  constructor(private readonly assetsService: AssetsService) {}

  @Get()
  findAll(
    @Query('categoryId') categoryId?: string,
    @Query('status') status?: AssetStatus,
    @Query('departmentId') departmentId?: string,
    @Query('search') search?: string,
  ) {
    return this.assetsService.findAll({ categoryId, status, departmentId, search })
  }

  @Get(':id')
  findOne(@Param('id') id: string) {
    return this.assetsService.findOne(id)
  }

  @Post()
  create(@Body() dto: CreateAssetDto) {
    return this.assetsService.create(dto)
  }

  @Patch(':id')
  update(@Param('id') id: string, @Body() dto: UpdateAssetDto) {
    return this.assetsService.update(id, dto)
  }

  @Post(':id/assign')
  assignAsset(@Param('id') id: string, @Body() body: { employeesCode: string }) {
    return this.assetsService.assignAsset(id, body.employeesCode)
  }

  @Post(':id/return')
  returnAsset(@Param('id') id: string) {
    return this.assetsService.returnAsset(id)
  }

  @Post(':id/delete')
  delete(@Param('id') id: string) {
    return this.assetsService.delete(id)
  }

  @Post('import')
  @UseInterceptors(FileInterceptor('file'))
  importExcel(
    @UploadedFile() file: Express.Multer.File,
    @Query('categoryId') categoryId?: string,
  ) {
    return this.assetsService.importExcel(file, categoryId)
  }
}
