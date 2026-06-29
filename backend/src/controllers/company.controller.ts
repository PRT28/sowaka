import { Request, Response } from 'express';
import {
  createCompany,
  deleteCompany,
  getCompany,
  listCompanies,
  updateCompany,
} from '../services/company.service';
import { asyncHandler } from '../utils/async-handler';

export const create = asyncHandler(async (req: Request, res: Response) => {
  const company = await createCompany(req.body ?? {});
  res.status(201).json({ success: true, data: company });
});

export const list = asyncHandler(async (_req: Request, res: Response) => {
  const data = await listCompanies();
  res.status(200).json({ success: true, count: data.length, data });
});

export const getOne = asyncHandler(async (req: Request, res: Response) => {
  const company = await getCompany(String(req.params.id));
  res.status(200).json({ success: true, data: company });
});

export const update = asyncHandler(async (req: Request, res: Response) => {
  const company = await updateCompany(String(req.params.id), req.body ?? {});
  res.status(200).json({ success: true, data: company });
});

export const remove = asyncHandler(async (req: Request, res: Response) => {
  await deleteCompany(String(req.params.id));
  res.status(204).send();
});
