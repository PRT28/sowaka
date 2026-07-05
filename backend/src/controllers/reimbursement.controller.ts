import { NextFunction, Request, Response } from 'express';
import {
  createReimbursementClaim,
  decideReimbursement,
  getManagerReimbursementInbox,
  getMyReimbursementClaims,
  ReimbursementError,
} from '../services/reimbursement.service';

export async function createReimbursement(req: Request, res: Response, next: NextFunction) {
  try {
    const claim = await createReimbursementClaim(requireUserId(req), {
      expenseDate: String(req.body.expenseDate ?? ''),
      amount: req.body.amount,
      category: String(req.body.category ?? ''),
      receiptName: req.body.receiptName == null ? undefined : String(req.body.receiptName),
      note: req.body.note == null ? undefined : String(req.body.note),
    });
    res.status(201).json({ success: true, claim });
  } catch (error) {
    next(error);
  }
}

export async function listMyReimbursements(req: Request, res: Response, next: NextFunction) {
  try {
    res.status(200).json({ success: true, claims: await getMyReimbursementClaims(requireUserId(req)) });
  } catch (error) {
    next(error);
  }
}

export async function listReimbursementInbox(req: Request, res: Response, next: NextFunction) {
  try {
    res.status(200).json({ success: true, claims: await getManagerReimbursementInbox(requireUserId(req)) });
  } catch (error) {
    next(error);
  }
}

export async function updateReimbursementDecision(
  req: Request,
  res: Response,
  next: NextFunction,
) {
  try {
    const claim = await decideReimbursement(
      requireUserId(req),
      String(req.params.claimId ?? ''),
      String(req.body.decision ?? ''),
    );
    res.status(200).json({ success: true, claim });
  } catch (error) {
    next(error);
  }
}

function requireUserId(req: Request) {
  if (!req.auth?.userId) throw new ReimbursementError(401, 'Authentication required');
  return req.auth.userId;
}

