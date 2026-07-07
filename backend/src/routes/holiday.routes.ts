import { Router } from 'express';
import { createHoliday, listHolidays, removeHoliday } from '../controllers/holiday.controller';
import { requireAuth } from '../middleware/auth.middleware';
import { requireDashboardAccess } from '../middleware/admin.middleware';

export const holidayRouter = Router();

holidayRouter.use(requireAuth);
holidayRouter.get('/', listHolidays);
holidayRouter.post('/', requireDashboardAccess, createHoliday);
holidayRouter.delete('/:holidayId', requireDashboardAccess, removeHoliday);
