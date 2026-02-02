import { Injectable, OnModuleInit, OnModuleDestroy } from '@nestjs/common'
import { PrismaClient } from '@prisma/client'
import { Pool } from 'pg'
import { PrismaPg } from '@prisma/adapter-pg'

@Injectable()
export class PrismaService extends PrismaClient implements OnModuleInit, OnModuleDestroy {
  constructor() {
    // Get DATABASE_URL from environment
    let databaseUrl = process.env.DATABASE_URL
    
    // Remove quotes if present
    if (databaseUrl && typeof databaseUrl === 'string') {
      databaseUrl = databaseUrl.trim().replace(/^["']|["']$/g, '')
    }
    
    if (!databaseUrl || typeof databaseUrl !== 'string') {
      throw new Error('DATABASE_URL environment variable is not set or invalid')
    }

    // Ensure connection string is properly formatted
    const connectionString = databaseUrl.trim()
    
    if (!connectionString.startsWith('postgresql://')) {
      throw new Error('Invalid DATABASE_URL format. Must start with postgresql://')
    }
    
    try {
      const pool = new Pool({
        connectionString,
        // Explicitly set ssl to false for local development
        ssl: false,
      })
      const adapter = new PrismaPg(pool)
      super({ adapter })
    } catch (error: any) {
      console.error('Error creating Prisma client:', error.message)
      throw new Error(`Failed to initialize database connection: ${error.message}`)
    }
  }

  async onModuleInit() {
    await this.$connect()
  }

  async onModuleDestroy() {
    await this.$disconnect()
  }
}
