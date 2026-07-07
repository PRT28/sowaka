import { Router } from 'express';
import {
  createReimbursement,
  getReimbursementReceiptUrl,
  listMyReimbursements,
  listReimbursementInbox,
} from '../controllers/reimbursement.controller';
import { requireAuth } from '../middleware/auth.middleware';
import { uploadReimbursementReceipt } from '../middleware/reimbursement-upload.middleware';

export const reimbursementRouter = Router();
reimbursementRouter.use(requireAuth);
reimbursementRouter.post('/', uploadReimbursementReceipt, createReimbursement);
reimbursementRouter.get('/mine', listMyReimbursements);
reimbursementRouter.get('/inbox', listReimbursementInbox);
reimbursementRouter.get('/:claimId/receipt-url', getReimbursementReceiptUrl);
// Reimbursement decisions are made ONLY from the HR dashboard — see /admin routes.
