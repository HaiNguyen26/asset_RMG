import { IsString, IsDateString, IsEnum, IsOptional } from 'class-validator'

export enum RepairType {
  INTERNAL_IT = 'INTERNAL_IT',
  EXTERNAL_VENDOR = 'EXTERNAL_VENDOR',
}

export enum RepairStatus {
  IN_PROGRESS = 'IN_PROGRESS',
  COMPLETED = 'COMPLETED',
  CANCELLED = 'CANCELLED',
}

export class CreateRepairHistoryDto {
  @IsString()
  assetId: string

  @IsDateString()
  errorDate: string

  @IsString()
  description: string

  @IsEnum(RepairType)
  repairType: RepairType

  @IsOptional()
  @IsString()
  repairUnit?: string

  @IsOptional()
  @IsString()
  result?: string

  @IsOptional()
  @IsEnum(RepairStatus)
  status?: RepairStatus

  @IsOptional()
  @IsString()
  itNote?: string
}
