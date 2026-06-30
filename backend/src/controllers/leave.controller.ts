import { Request, Response } from 'express';
import {
  createLeave,
  deleteLeave,
  getLeave,
  LeaveFilter,
  listLeaves,
  updateLeave,
} from '../services/leave.service';
import { asyncHandler } from '../utils/async-handler';

export const create = asyncHandler(async (req: Request, res: Response) => {
  const leave = await createLeave(req.body ?? {});
  res.status(201).json({ success: true, data: leave });
});

export const list = asyncHandler(async (req: Request, res: Response) => {
  const filter: LeaveFilter = {
    userId: req.query.userId as string | undefined,
    status: req.query.status as string | undefined,
  };
  const data = await listLeaves(filter);
  res.status(200).json({ success: true, count: data.length, data });
});

export const getOne = asyncHandler(async (req: Request, res: Response) => {
  const leave = await getLeave(String(req.params.id));
  res.status(200).json({ success: true, data: leave });
});

export const update = asyncHandler(async (req: Request, res: Response) => {
  const leave = await updateLeave(String(req.params.id), req.body ?? {});
  res.status(200).json({ success: true, data: leave });
});

export const remove = asyncHandler(async (req: Request, res: Response) => {
  await deleteLeave(String(req.params.id));
  res.status(204).send();
});
