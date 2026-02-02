import { IsString, IsInt, IsOptional } from 'class-validator'

export class CreatePolicyDto {
  @IsString()
  category: string

  @IsString()
  title: string

  @IsString()
  content: string

  @IsOptional()
  @IsInt()
  order?: number
}
