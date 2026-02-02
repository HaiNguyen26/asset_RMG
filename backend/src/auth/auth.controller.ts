import { Controller, Post, Body, HttpException, HttpStatus } from '@nestjs/common'
import { IsString, IsNotEmpty } from 'class-validator'
import { AuthService } from './auth.service'

export class LoginDto {
  @IsString()
  @IsNotEmpty()
  employeesCode: string

  @IsString()
  @IsNotEmpty()
  password: string
}

@Controller('auth')
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  @Post('login')
  async login(@Body() loginDto: LoginDto) {
    try {
      return await this.authService.login(loginDto.employeesCode, loginDto.password)
    } catch (error: any) {
      if (error.status === HttpStatus.UNAUTHORIZED) {
        throw error
      }
      console.error('Login error:', error)
      throw new HttpException(
        error.message || 'Đăng nhập thất bại',
        error.status || HttpStatus.INTERNAL_SERVER_ERROR,
      )
    }
  }
}
