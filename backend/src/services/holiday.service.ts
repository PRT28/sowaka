import { ObjectId } from 'mongodb';
import { holidays, users } from '../config/db';
import { Holiday } from '../models/holiday.model';

export interface HolidayView {
  id: string;
  org: string;
  date: string;
  name: string;
}

export async function listCompanyHolidays(userId: string): Promise<HolidayView[]> {
  const user = await users().findOne({ userId });
  if (!user) throw new HolidayError(404, 'User not found');
  const org = user.org ?? 'default';
  const documents = await holidays().find({ org }).sort({ date: 1 }).toArray();
  return documents.map(toHolidayView);
}

export async function createCompanyHoliday(
  userId: string,
  input: { date: string; name: string; org?: string },
): Promise<HolidayView> {
  const user = await users().findOne({ userId });
  if (!user) throw new HolidayError(404, 'User not found');
  const org = input.org?.trim() || user.org || 'default';
  const date = parseDateOnly(input.date, 'date');
  const name = input.name.trim();
  if (name.length < 2) throw new HolidayError(400, 'Holiday name is required');
  if (name.length > 120) throw new HolidayError(400, 'Holiday name cannot exceed 120 characters');

  const now = Date.now();
  const document: Holiday = {
    org,
    date,
    name,
    createdByUserId: userId,
    createdAt: now,
    updatedAt: new Date(now),
  };
  try {
    const result = await holidays().insertOne(document);
    return toHolidayView({ ...document, _id: result.insertedId });
  } catch (error) {
    if (isDuplicateKey(error)) {
      throw new HolidayError(409, 'A holiday already exists for this date');
    }
    throw error;
  }
}

export async function deleteCompanyHoliday(userId: string, holidayIdInput: string): Promise<void> {
  if (!ObjectId.isValid(holidayIdInput)) throw new HolidayError(400, 'Invalid holiday ID');
  const user = await users().findOne({ userId });
  if (!user) throw new HolidayError(404, 'User not found');
  const result = await holidays().deleteOne({
    _id: new ObjectId(holidayIdInput),
    org: user.org ?? 'default',
  });
  if (result.deletedCount === 0) throw new HolidayError(404, 'Holiday not found');
}

function parseDateOnly(value: string, field: string): Date {
  if (!/^\d{4}-\d{2}-\d{2}$/.test(value)) {
    throw new HolidayError(400, `${field} must use YYYY-MM-DD format`);
  }
  const date = new Date(`${value}T00:00:00.000Z`);
  if (Number.isNaN(date.getTime()) || date.toISOString().slice(0, 10) !== value) {
    throw new HolidayError(400, `${field} is not a valid date`);
  }
  return date;
}

function toHolidayView(holiday: Holiday & { _id: ObjectId }): HolidayView {
  return {
    id: holiday._id.toHexString(),
    org: holiday.org,
    date: holiday.date.toISOString().slice(0, 10),
    name: holiday.name,
  };
}

function isDuplicateKey(error: unknown): boolean {
  return (
    typeof error === 'object' &&
    error !== null &&
    'code' in error &&
    (error as { code?: number }).code === 11000
  );
}

export class HolidayError extends Error {
  constructor(
    public readonly statusCode: number,
    message: string,
  ) {
    super(message);
  }
}
