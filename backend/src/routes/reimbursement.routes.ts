import { Router } from 'express';
import {
  createReimbursement,
  listMyReimbursements,
  listReimbursementInbox,
  updateReimbursementDecision,
} from '../controllers/reimbursement.controller';
import { requireAuth } from '../middleware/auth.middleware';

export const reimbursementRouter = Router();
reimbursementRouter.use(requireAuth);
reimbursementRouter.post('/', createReimbursement);
reimbursementRouter.get('/mine', listMyReimbursements);
reimbursementRouter.get('/inbox', listReimbursementInbox);
reimbursementRouter.patch('/:claimId/decision', updateReimbursementDecision);

