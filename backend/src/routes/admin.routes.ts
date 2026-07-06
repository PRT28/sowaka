import { Router } from 'express';
import {
  decideLeave,
  decideOvertime,
  decideReimbursement,
  listEmployees,
  listFeedback,
  listLeaves,
  listOvertime,
  listReimbursements,
} from '../controllers/admin.controller';
import { requireAuth } from '../middleware/auth.middleware';
import { requireDashboardAccess } from '../middleware/admin.middleware';

// HR dashboard surface: org-wide reads + request overrides. Every route requires
// an authenticated user (requireAuth) who additionally has dashboardAccess.
export const adminRouter = Router();
adminRouter.use(requireAuth, requireDashboardAccess);

// Org-wide lists (rule 5)
adminRouter.get('/leaves', listLeaves);
adminRouter.get('/overtime', listOvertime);
adminRouter.get('/reimbursements', listReimbursements);
adminRouter.get('/feedback', listFeedback);
adminRouter.get('/employees', listEmployees);

// Overrides / dashboard-only decisions (rules 3, 6, 7, 8)
adminRouter.patch('/leaves/:leaveId/decision', decideLeave);
adminRouter.patch('/overtime/:overtimeId/decision', decideOvertime);
adminRouter.patch('/reimbursements/:claimId/decision', decideReimbursement);
