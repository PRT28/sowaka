import { Router } from 'express';
import {
  createOvertime,
  listMyOvertime,
  listOvertimeInbox,
  updateOvertimeDecision,
} from '../controllers/overtime.controller';
import { requireAuth } from '../middleware/auth.middleware';

export const overtimeRouter = Router();
overtimeRouter.use(requireAuth);
overtimeRouter.post('/', createOvertime);
overtimeRouter.get('/mine', listMyOvertime);
overtimeRouter.get('/inbox', listOvertimeInbox);
overtimeRouter.patch('/:overtimeId/decision', updateOvertimeDecision);
