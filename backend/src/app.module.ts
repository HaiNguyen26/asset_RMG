import { Module } from '@nestjs/common'
import { PrismaModule } from './prisma/prisma.module'
import { AssetsModule } from './assets/assets.module'
import { DepartmentsModule } from './departments/departments.module'
import { CategoriesModule } from './categories/categories.module'
import { AuthModule } from './auth/auth.module'
import { UsersModule } from './users/users.module'
import { RepairHistoryModule } from './repair-history/repair-history.module'
import { PoliciesModule } from './policies/policies.module'

@Module({
  imports: [
    PrismaModule,
    CategoriesModule,
    DepartmentsModule,
    AssetsModule,
    AuthModule,
    UsersModule,
    RepairHistoryModule,
    PoliciesModule,
  ],
})
export class AppModule {}
