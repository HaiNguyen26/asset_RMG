import { IsString, IsDateString, IsEnum, IsOptional } from 'class-validator'

export class UpdateRepairHistoryDto {
  @IsOptional()
  @IsDateString()
  errorDate?: string

  @IsOptional()
  @IsString()
  description?: string

  @IsOptional()
  @IsEnum(['INTERNAL_IT', 'EXTERNAL_VENDOR'])
  repairType?: string

  @IsOptional()
  @IsString()
  repairUnit?: string

  @IsOptional()
  @IsString()
  result?: string

  @IsOptional()
  @IsEnum(['IN_PROGRESS', 'COMPLETED', 'CANCELLED'])
  status?: string

  @IsOptional()
  @IsString()
  itNote?: string
}
