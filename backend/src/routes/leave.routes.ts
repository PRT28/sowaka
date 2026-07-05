import { Router } from 'express';
import {
  createLeave,
  listManagerLeaves,
  leaveBalance,
  listMyLeaves,
  updateLeaveDecision,
} from '../controllers/leave.controller';
import { requireAuth } from '../middleware/auth.middleware';

export const leaveRouter = Router();

leaveRouter.use(requireAuth);
leaveRouter.post('/', createLeave);
leaveRouter.get('/mine', listMyLeaves);
leaveRouter.get('/balance', leaveBalance);
leaveRouter.get('/inbox', listManagerLeaves);
leaveRouter.patch('/:leaveId/decision', updateLeaveDecision);
