import { IsString, IsInt, IsOptional } from 'class-validator'

export class UpdatePolicyDto {
  @IsOptional()
  @IsString()
  title?: string

  @IsOptional()
  @IsString()
  content?: string

  @IsOptional()
  @IsInt()
  order?: number
}
