import { NextFunction, Request, Response } from 'express';
import { adminDecideLeave, listAllLeavesForAdmin } from '../services/leave.service';
import { adminDecideOvertime, listAllOvertimeForAdmin } from '../services/overtime.service';
import {
  adminDecideReimbursement,
  listAllReimbursementsForAdmin,
} from '../services/reimbursement.service';
import { listAllEmployeesForAdmin, listAllFeedbackForAdmin } from '../services/admin.service';

function adminUserId(req: Request): string {
  // requireAuth + requireDashboardAccess guarantee this is present.
  return req.auth!.userId;
}

// ---- Org-wide lists (rule 5) ----
export async function listLeaves(req: Request, res: Response, next: NextFunction) {
  try {
    res.status(200).json({ success: true, leaves: await listAllLeavesForAdmin(adminUserId(req)) });
  } catch (error) {
    next(error);
  }
}

export async function listOvertime(req: Request, res: Response, next: NextFunction) {
  try {
    res
      .status(200)
      .json({ success: true, overtime: await listAllOvertimeForAdmin(adminUserId(req)) });
  } catch (error) {
    next(error);
  }
}

export async function listReimbursements(req: Request, res: Response, next: NextFunction) {
  try {
    res
      .status(200)
      .json({ success: true, claims: await listAllReimbursementsForAdmin(adminUserId(req)) });
  } catch (error) {
    next(error);
  }
}

export async function listFeedback(req: Request, res: Response, next: NextFunction) {
  try {
    res
      .status(200)
      .json({ success: true, feedback: await listAllFeedbackForAdmin(adminUserId(req)) });
  } catch (error) {
    next(error);
  }
}

export async function listEmployees(req: Request, res: Response, next: NextFunction) {
  try {
    res
      .status(200)
      .json({ success: true, employees: await listAllEmployeesForAdmin(adminUserId(req)) });
  } catch (error) {
    next(error);
  }
}

// ---- Overrides (rules 6, 7, 8) ----
export async function decideLeave(req: Request, res: Response, next: NextFunction) {
  try {
    const leave = await adminDecideLeave(adminUserId(req), String(req.params.leaveId ?? ''), {
      decision: String(req.body.decision ?? ''),
      managerNote: req.body.managerNote == null ? undefined : String(req.body.managerNote),
    });
    res.status(200).json({ success: true, leave });
  } catch (error) {
    next(error);
  }
}

export async function decideOvertime(req: Request, res: Response, next: NextFunction) {
  try {
    const overtime = await adminDecideOvertime(
      adminUserId(req),
      String(req.params.overtimeId ?? ''),
      {
        decision: String(req.body.decision ?? ''),
        managerNote: req.body.managerNote == null ? undefined : String(req.body.managerNote),
      },
    );
    res.status(200).json({ success: true, overtime });
  } catch (error) {
    next(error);
  }
}

export async function decideReimbursement(req: Request, res: Response, next: NextFunction) {
  try {
    const claim = await adminDecideReimbursement(
      adminUserId(req),
      String(req.params.claimId ?? ''),
      String(req.body.decision ?? ''),
    );
    res.status(200).json({ success: true, claim });
  } catch (error) {
    next(error);
  }
}
