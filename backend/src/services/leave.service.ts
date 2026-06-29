import { Filter, ObjectId, WithId } from 'mongodb';
import { leaves } from '../config/db';
import { Leave, LeaveStatus } from '../models/leave.model';
import { ApiError } from '../utils/api-error';

const leaveStatuses: LeaveStatus[] = ['pending', 'approved', 'declined'];

export interface LeaveDto extends Omit<Leave, never> {
  id: string;
}

export interface LeaveFilter {
  userId?: string;
  status?: string;
}

export async function createLeave(input: Partial<Leave>): Promise<LeaveDto> {
  if (!input.userId) throw new ApiError(400, 'userId is required');
  const startDate = parseDate(input.startDate, 'startDate');
  const endDate = parseDate(input.endDate, 'endDate');
  if (endDate < startDate) throw new ApiError(400, 'endDate must be on or after startDate');

  const status = input.status ?? 'pending';
  assertStatus(status);

  const doc: Leave = {
    userId: input.userId,
    startDate,
    endDate,
    status,
    managerNote: input.managerNote,
    createdAt: Date.now(),
  };

  const result = await leaves().insertOne(doc);
  return serialize({ ...doc, _id: result.insertedId });
}

export async function listLeaves(filter: LeaveFilter): Promise<LeaveDto[]> {
  const query: Filter<Leave> = {};
  if (filter.userId) query.userId = filter.userId;
  if (filter.status) {
    assertStatus(filter.status);
    query.status = filter.status as LeaveStatus;
  }

  const docs = await leaves().find(query).sort({ startDate: -1 }).toArray();
  return docs.map(serialize);
}

export async function getLeave(id: string): Promise<LeaveDto> {
  const doc = await leaves().findOne({ _id: toObjectId(id) });
  if (!doc) throw new ApiError(404, 'Leave not found');
  return serialize(doc);
}

export async function updateLeave(id: string, updates: Partial<Leave>): Promise<LeaveDto> {
  const set: Partial<Leave> = {};
  if (updates.userId !== undefined) set.userId = updates.userId;
  if (updates.managerNote !== undefined) set.managerNote = updates.managerNote;
  if (updates.startDate !== undefined) set.startDate = parseDate(updates.startDate, 'startDate');
  if (updates.endDate !== undefined) set.endDate = parseDate(updates.endDate, 'endDate');
  if (updates.status !== undefined) {
    assertStatus(updates.status);
    set.status = updates.status;
  }

  const result = await leaves().findOneAndUpdate(
    { _id: toObjectId(id) },
    { $set: { ...set, updatedAt: new Date() } },
    { returnDocument: 'after' },
  );

  if (!result) throw new ApiError(404, 'Leave not found');
  return serialize(result);
}

export async function deleteLeave(id: string): Promise<void> {
  const result = await leaves().deleteOne({ _id: toObjectId(id) });
  if (result.deletedCount === 0) throw new ApiError(404, 'Leave not found');
}

function serialize(doc: WithId<Leave>): LeaveDto {
  const { _id, ...rest } = doc;
  return { id: _id.toString(), ...rest };
}

function toObjectId(id: string): ObjectId {
  if (!ObjectId.isValid(id)) throw new ApiError(400, 'Invalid leave id');
  return new ObjectId(id);
}

function parseDate(value: unknown, field: string): Date {
  if (value instanceof Date) return value;
  const date = new Date(String(value));
  if (Number.isNaN(date.getTime())) throw new ApiError(400, `${field} must be a valid date`);
  return date;
}

function assertStatus(status: string): asserts status is LeaveStatus {
  if (!leaveStatuses.includes(status as LeaveStatus)) {
    throw new ApiError(400, `status must be one of: ${leaveStatuses.join(', ')}`);
  }
}
