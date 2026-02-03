-- AlterTable: Add password column (nullable first, will be updated via seed/script)
ALTER TABLE "users" ADD COLUMN "password" TEXT;

-- AlterTable: Add branch column (nullable)
ALTER TABLE "users" ADD COLUMN "branch" TEXT;
