import 'dotenv/config'
import { NestFactory } from '@nestjs/core'
import { ValidationPipe } from '@nestjs/common'
import { AppModule } from './app.module'

async function bootstrap() {
  try {
    const app = await NestFactory.create(AppModule)
    app.setGlobalPrefix('api')
    app.useGlobalPipes(
      new ValidationPipe({
        whitelist: true,
        transform: true,
        forbidNonWhitelisted: false,
      }),
    )
    app.enableCors({ origin: ['http://localhost:5173'], credentials: true })
    
    const port = process.env.PORT ?? 3000
    await app.listen(port)
    console.log(`🚀 Backend running on http://localhost:${port}/api`)
  } catch (error) {
    console.error('❌ Failed to start server:', error)
    process.exit(1)
  }
}
bootstrap()
