import { Router } from 'express';
import {
  createHoliday,
  listHolidays,
  removeHoliday,
  uploadHolidays,
} from '../controllers/holiday.controller';
import { requireAuth } from '../middleware/auth.middleware';
import { requireDashboardAccess } from '../middleware/admin.middleware';
import { uploadHolidayFile } from '../middleware/holiday-upload.middleware';

export const holidayRouter = Router();

holidayRouter.use(requireAuth);
holidayRouter.get('/', listHolidays);
holidayRouter.post('/', requireDashboardAccess, createHoliday);
holidayRouter.post('/upload', requireDashboardAccess, uploadHolidayFile, uploadHolidays);
holidayRouter.delete('/:holidayId', requireDashboardAccess, removeHoliday);
