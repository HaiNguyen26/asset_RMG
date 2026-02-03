import { Injectable, OnModuleInit, OnModuleDestroy } from '@nestjs/common'
import { PrismaClient } from '@prisma/client'
import { Pool } from 'pg'
import { PrismaPg } from '@prisma/adapter-pg'

@Injectable()
export class PrismaService extends PrismaClient implements OnModuleInit, OnModuleDestroy {
  constructor() {
    // Get DATABASE_URL from environment
    // Try multiple sources: process.env, then dotenv
    let databaseUrl = process.env.DATABASE_URL
    
    // If not found, try loading from .env file
    if (!databaseUrl) {
      try {
        require('dotenv').config({ path: require('path').join(__dirname, '../../.env') })
        databaseUrl = process.env.DATABASE_URL
      } catch (e) {
        // Ignore dotenv errors
      }
    }
    
    // Remove quotes if present
    if (databaseUrl && typeof databaseUrl === 'string') {
      databaseUrl = databaseUrl.trim().replace(/^["']|["']$/g, '')
    }
    
    if (!databaseUrl || typeof databaseUrl !== 'string') {
      console.error('❌ DATABASE_URL not found. process.env.DATABASE_URL:', process.env.DATABASE_URL)
      console.error('❌ Current working directory:', process.cwd())
      console.error('❌ __dirname:', __dirname)
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
