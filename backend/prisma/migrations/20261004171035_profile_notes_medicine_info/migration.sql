/*
  Warnings:

  - You are about to drop the column `note` on the `Medicine` table. All the data in the column will be lost.
  - You are about to drop the column `timing` on the `Medicine` table. All the data in the column will be lost.

*/
-- CreateEnum
CREATE TYPE "Sex" AS ENUM ('FEMALE', 'MALE', 'OTHER');

-- AlterTable
ALTER TABLE "Medicine" DROP COLUMN "note",
DROP COLUMN "timing";

-- AlterTable
ALTER TABLE "User" ADD COLUMN     "bloodGroup" TEXT,
ADD COLUMN     "conditions" TEXT,
ADD COLUMN     "dateOfBirth" TEXT,
ADD COLUMN     "emergencyName" TEXT,
ADD COLUMN     "emergencyPhone" TEXT,
ADD COLUMN     "heightCm" DOUBLE PRECISION,
ADD COLUMN     "name" TEXT,
ADD COLUMN     "sex" "Sex",
ADD COLUMN     "weightKg" DOUBLE PRECISION;

-- CreateTable
CREATE TABLE "Note" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "text" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Note_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "MedicineInfo" (
    "id" TEXT NOT NULL,
    "nameKey" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "summary" TEXT NOT NULL,
    "source" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "MedicineInfo_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "Note_userId_idx" ON "Note"("userId");

-- CreateIndex
CREATE UNIQUE INDEX "MedicineInfo_nameKey_key" ON "MedicineInfo"("nameKey");

-- AddForeignKey
ALTER TABLE "Note" ADD CONSTRAINT "Note_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;
