-- AlterTable
ALTER TABLE "Document" ALTER COLUMN "storagePath" DROP NOT NULL;

-- CreateTable
CREATE TABLE "DocumentBlob" (
    "documentId" TEXT NOT NULL,
    "data" BYTEA NOT NULL,

    CONSTRAINT "DocumentBlob_pkey" PRIMARY KEY ("documentId")
);

-- AddForeignKey
ALTER TABLE "DocumentBlob" ADD CONSTRAINT "DocumentBlob_documentId_fkey" FOREIGN KEY ("documentId") REFERENCES "Document"("id") ON DELETE CASCADE ON UPDATE CASCADE;
