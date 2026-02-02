import { IsString, IsOptional, IsIn, IsDateString } from 'class-validator'

export class UpdateAssetDto {
  @IsOptional()
  @IsString()
  code?: string

  @IsOptional()
  @IsString()
  name?: string

  @IsOptional()
  @IsString()
  model?: string

  @IsOptional()
  @IsString()
  serialNumber?: string

  @IsOptional()
  @IsString()
  specification?: string

  @IsOptional()
  @IsString()
  assignedTo?: string

  @IsOptional()
  @IsString()
  employeesCode?: string

  @IsOptional()
  @IsString()
  departmentId?: string

  @IsOptional()
  @IsDateString()
  inspectionDate?: string

  @IsOptional()
  @IsIn(['AVAILABLE', 'IN_USE', 'MAINTENANCE', 'RETIRED'])
  status?: string

  @IsOptional()
  @IsString()
  note?: string
}
