-- CreateEnum
CREATE TYPE "RepairType" AS ENUM ('INTERNAL_IT', 'EXTERNAL_VENDOR');

-- CreateEnum
CREATE TYPE "RepairStatus" AS ENUM ('IN_PROGRESS', 'COMPLETED', 'CANCELLED');

-- CreateTable
CREATE TABLE "repair_history" (
    "id" TEXT NOT NULL,
    "assetId" TEXT NOT NULL,
    "error_date" TIMESTAMP(3) NOT NULL,
    "description" TEXT NOT NULL,
    "repair_type" "RepairType" NOT NULL,
    "repair_unit" TEXT,
    "result" TEXT,
    "status" "RepairStatus" NOT NULL DEFAULT 'IN_PROGRESS',
    "it_note" TEXT,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,
    "created_by_id" TEXT,

    CONSTRAINT "repair_history_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "policies" (
    "id" TEXT NOT NULL,
    "category" TEXT NOT NULL,
    "title" TEXT NOT NULL,
    "content" TEXT NOT NULL,
    "order" INTEGER NOT NULL DEFAULT 0,
    "created_at" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMP(3) NOT NULL,
    "updated_by_id" TEXT,

    CONSTRAINT "policies_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "repair_history_assetId_idx" ON "repair_history"("assetId");

-- CreateIndex
CREATE INDEX "repair_history_error_date_idx" ON "repair_history"("error_date");

-- CreateIndex
CREATE INDEX "repair_history_status_idx" ON "repair_history"("status");

-- CreateIndex
CREATE UNIQUE INDEX "policies_category_key" ON "policies"("category");

-- CreateIndex
CREATE INDEX "policies_category_idx" ON "policies"("category");

-- CreateIndex
CREATE INDEX "policies_order_idx" ON "policies"("order");

-- AddForeignKey
ALTER TABLE "repair_history" ADD CONSTRAINT "repair_history_assetId_fkey" FOREIGN KEY ("assetId") REFERENCES "assets"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "repair_history" ADD CONSTRAINT "repair_history_created_by_id_fkey" FOREIGN KEY ("created_by_id") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "policies" ADD CONSTRAINT "policies_updated_by_id_fkey" FOREIGN KEY ("updated_by_id") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;
