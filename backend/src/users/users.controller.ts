import { Controller, Get, Post, Body } from '@nestjs/common'
import { UsersService } from './users.service'

@Controller('users')
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  @Get()
  findAll() {
    return this.usersService.findAll()
  }

  @Post()
  create(@Body() data: { employeesCode: string; name: string; email?: string; departmentId?: string }) {
    return this.usersService.create(data)
  }
}
