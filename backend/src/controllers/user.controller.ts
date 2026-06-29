import { Request, Response } from 'express';
import {
  createUser,
  deleteUser,
  getUser,
  listUsers,
  updateUser,
  UserFilter,
} from '../services/user.service';
import { asyncHandler } from '../utils/async-handler';

export const create = asyncHandler(async (req: Request, res: Response) => {
  const user = await createUser(req.body ?? {});
  res.status(201).json({ success: true, data: user });
});

export const list = asyncHandler(async (req: Request, res: Response) => {
  const filter: UserFilter = {
    org: req.query.org as string | undefined,
    department: req.query.department as string | undefined,
    managerUserId: req.query.managerUserId as string | undefined,
    lifecycleStatus: req.query.lifecycleStatus as string | undefined,
    employeeType: req.query.employeeType as string | undefined,
  };
  const data = await listUsers(filter);
  res.status(200).json({ success: true, count: data.length, data });
});

export const getOne = asyncHandler(async (req: Request, res: Response) => {
  const user = await getUser(String(req.params.userId));
  res.status(200).json({ success: true, data: user });
});

export const update = asyncHandler(async (req: Request, res: Response) => {
  const user = await updateUser(String(req.params.userId), req.body ?? {});
  res.status(200).json({ success: true, data: user });
});

export const remove = asyncHandler(async (req: Request, res: Response) => {
  await deleteUser(String(req.params.userId));
  res.status(204).send();
});
