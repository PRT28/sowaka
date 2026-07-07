import { NextFunction, Request, Response } from 'express';
import {
  createCompanyHoliday,
  deleteCompanyHoliday,
  HolidayError,
  listCompanyHolidays,
} from '../services/holiday.service';

export async function listHolidays(req: Request, res: Response, next: NextFunction) {
  try {
    res.status(200).json({ success: true, holidays: await listCompanyHolidays(requireUserId(req)) });
  } catch (error) {
    handleHolidayError(error, res, next);
  }
}

export async function createHoliday(req: Request, res: Response, next: NextFunction) {
  try {
    const holiday = await createCompanyHoliday(requireUserId(req), {
      date: String(req.body.date ?? ''),
      name: String(req.body.name ?? ''),
      org: req.body.org == null ? undefined : String(req.body.org),
    });
    res.status(201).json({ success: true, holiday });
  } catch (error) {
    handleHolidayError(error, res, next);
  }
}

export async function removeHoliday(req: Request, res: Response, next: NextFunction) {
  try {
    await deleteCompanyHoliday(requireUserId(req), String(req.params.holidayId ?? ''));
    res.status(204).send();
  } catch (error) {
    handleHolidayError(error, res, next);
  }
}

function requireUserId(req: Request): string {
  if (!req.auth?.userId) {
    throw new HolidayError(401, 'Authentication required');
  }
  return req.auth.userId;
}

function handleHolidayError(error: unknown, res: Response, next: NextFunction) {
  void res;
  next(error);
}
