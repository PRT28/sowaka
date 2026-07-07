import { Router } from 'express';
import { createHoliday, listHolidays, removeHoliday } from '../controllers/holiday.controller';
import { requireAuth } from '../middleware/auth.middleware';
import { requireHrAdmin } from '../middleware/admin.middleware';

export const holidayRouter = Router();

holidayRouter.use(requireAuth);
holidayRouter.get('/', listHolidays);
holidayRouter.post('/', requireHrAdmin, createHoliday);
holidayRouter.delete('/:holidayId', requireHrAdmin, removeHoliday);
