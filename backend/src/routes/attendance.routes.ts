import { Router } from 'express';
import { createRegularization, listInbox, listMine, updateDecision } from '../controllers/attendance.controller';

export const attendanceRouter = Router();
attendanceRouter.get('/mine', listMine);
attendanceRouter.post('/regularizations', createRegularization);
attendanceRouter.get('/regularizations/inbox', listInbox);
attendanceRouter.patch('/regularizations/:id/decision', updateDecision);
