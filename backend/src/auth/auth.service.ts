import { Injectable, UnauthorizedException } from '@nestjs/common'
import { JwtService } from '@nestjs/jwt'
import * as bcrypt from 'bcrypt'
import { UsersService } from '../users/users.service'

@Injectable()
export class AuthService {
  constructor(
    private usersService: UsersService,
    private jwtService: JwtService,
  ) {}

  async login(employeesCode: string, password: string) {
    try {
      if (!employeesCode || !employeesCode.trim()) {
        throw new UnauthorizedException('Vui lòng nhập mã nhân viên')
      }
      if (!password || !password.trim()) {
        throw new UnauthorizedException('Vui lòng nhập mật khẩu')
      }

      const user = await this.usersService.findByEmployeesCode(employeesCode.trim())
      if (!user) {
        throw new UnauthorizedException('Mã nhân viên hoặc mật khẩu không đúng')
      }

      if (!user.password) {
        throw new UnauthorizedException('Tài khoản chưa được thiết lập mật khẩu. Vui lòng liên hệ quản trị viên.')
      }

      const isPasswordValid = await bcrypt.compare(password.trim(), user.password)
      if (!isPasswordValid) {
        throw new UnauthorizedException('Mã nhân viên hoặc mật khẩu không đúng')
      }

      const payload = { sub: user.id, employeesCode: user.employeesCode, role: user.role }
      return {
        access_token: this.jwtService.sign(payload),
        user: {
          id: user.id,
          employeesCode: user.employeesCode,
          name: user.name,
          email: user.email,
          branch: user.branch,
          role: user.role,
          departmentId: user.departmentId,
        },
      }
    } catch (error: any) {
      console.error('AuthService login error:', error)
      if (error instanceof UnauthorizedException) {
        throw error
      }
      throw new UnauthorizedException('Đăng nhập thất bại. Vui lòng thử lại.')
    }
  }

  async validateUser(employeesCode: string) {
    return this.usersService.findByEmployeesCode(employeesCode)
  }
}
