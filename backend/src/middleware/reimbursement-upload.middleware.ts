import type { NextFunction, Request, Response } from 'express';
import multer from 'multer';
import { ReimbursementError } from '../services/reimbursement.service';

const receiptUpload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 5 * 1024 * 1024, files: 1 },
}).single('receipt');

export function uploadReimbursementReceipt(
  request: Request,
  response: Response,
  next: NextFunction,
) {
  receiptUpload(request, response, (error) => {
    if (!error) {
      if (request.file) {
        const contentType = detectContentType(request.file.buffer);
        if (!contentType) {
          next(new ReimbursementError(400, 'Receipt must be a PDF, JPEG, or PNG file'));
          return;
        }
        request.file.mimetype = contentType;
      }
      next();
      return;
    }
    if (error instanceof multer.MulterError && error.code === 'LIMIT_FILE_SIZE') {
      next(new ReimbursementError(413, 'Receipt must be 5 MB or smaller'));
      return;
    }
    next(
      new ReimbursementError(
        400,
        error instanceof Error ? error.message : 'Receipt upload is invalid',
      ),
    );
  });
}

function detectContentType(bytes: Buffer) {
  if (bytes.subarray(0, 5).toString('ascii') === '%PDF-') return 'application/pdf';
  if (bytes.length >= 3 && bytes[0] === 0xff && bytes[1] === 0xd8 && bytes[2] === 0xff) {
    return 'image/jpeg';
  }
  const pngSignature = Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]);
  if (bytes.subarray(0, pngSignature.length).equals(pngSignature)) return 'image/png';
  return undefined;
}
