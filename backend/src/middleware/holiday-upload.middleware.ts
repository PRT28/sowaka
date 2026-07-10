import type { NextFunction, Request, Response } from 'express';
import multer from 'multer';
import { HolidayError } from '../services/holiday.service';

const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 5 * 1024 * 1024, files: 1 },
}).single('file');

export function uploadHolidayFile(request: Request, response: Response, next: NextFunction) {
  upload(request, response, (error) => {
    if (!error) {
      if (request.file && !isAllowedHolidayFile(request.file)) {
        next(new HolidayError(400, 'Holiday upload must be a CSV or XLSX file'));
        return;
      }
      next();
      return;
    }
    if (error instanceof multer.MulterError && error.code === 'LIMIT_FILE_SIZE') {
      next(new HolidayError(413, 'Holiday upload must be 5 MB or smaller'));
      return;
    }
    next(new HolidayError(400, error instanceof Error ? error.message : 'Holiday upload is invalid'));
  });
}

function isAllowedHolidayFile(file: Express.Multer.File) {
  const name = file.originalname.toLowerCase();
  return (
    name.endsWith('.csv') ||
    name.endsWith('.xlsx') ||
    file.mimetype === 'text/csv' ||
    file.mimetype === 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
  );
}
