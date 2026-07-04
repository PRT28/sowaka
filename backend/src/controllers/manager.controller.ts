import { NextFunction, Request, Response } from 'express';
import {
  getManagerWorkspace,
  ManagerError,
  nominateForRecognition,
  upsertFeedback,
} from '../services/manager.service';

export async function managerWorkspace(req: Request, res: Response, next: NextFunction) {
  try {
    const workspace = await getManagerWorkspace(requireUserId(req));
    res.status(200).json({ success: true, ...workspace });
  } catch (error) {
    next(error);
  }
}

export async function saveManagerFeedback(req: Request, res: Response, next: NextFunction) {
  try {
    const feedback = await upsertFeedback(
      requireUserId(req),
      String(req.params.employeeUserId ?? ''),
      {
        status: String(req.body.status ?? ''),
        parameters: req.body.parameters,
        extra: req.body.extra == null ? undefined : String(req.body.extra),
      },
    );
    res.status(200).json({ success: true, feedback });
  } catch (error) {
    next(error);
  }
}

export async function saveRecognitionNomination(
  req: Request,
  res: Response,
  next: NextFunction,
) {
  try {
    const nomination = await nominateForRecognition(
      requireUserId(req),
      String(req.params.category ?? ''),
      String(req.body.employeeUserId ?? ''),
    );
    res.status(200).json({ success: true, nomination });
  } catch (error) {
    next(error);
  }
}

function requireUserId(req: Request) {
  if (!req.auth?.userId) throw new ManagerError(401, 'Authentication required');
  return req.auth.userId;
}

