# Cấu hình Prisma 7

## Thay đổi chính

Trong Prisma 7, connection URL đã được di chuyển từ `schema.prisma` sang `prisma.config.ts`.

## File cấu hình

### `prisma/config.ts`
File này chứa cấu hình database connection:
```typescript
import 'dotenv/config'

export default {
  schema: 'prisma/schema.prisma',
  datasource: {
    url: process.env.DATABASE_URL,
  },
}
```

### `prisma/schema.prisma`
File schema không còn chứa `url` trong datasource block:
```prisma
datasource db {
  provider = "postgresql"
  // url đã được di chuyển sang prisma.config.ts
}
```

## Cài đặt

```bash
npm install
```

## Chạy migration

```bash
npx prisma migrate dev --name init
```

## Generate Prisma Client

```bash
npx prisma generate
```

## Seed database

```bash
npx prisma db seed
```
