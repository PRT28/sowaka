import { ObjectId } from 'mongodb';
import { leaves, users } from '../config/db';
import { Leave, LeaveStatus } from '../models/leave.model';
import { User } from '../models/user.model';

const leaveTypes = new Set<Leave['type']>(['sick', 'casual', 'earned']);
const decisionStatuses = new Set<LeaveStatus>(['approved', 'declined']);

export interface LeaveView {
  id: string;
  userId: string;
  employee: {
    name: string;
    email: string;
    department?: string;
    designation?: string;
  };
  type: Leave['type'];
  startDate: string;
  endDate: string;
  days: number;
  reason: string;
  status: LeaveStatus;
  managerNote?: string;
  createdAt: string;
  decidedAt?: string;
}

export async function applyForLeave(
  userId: string,
  input: { type: string; startDate: string; endDate: string; reason: string },
): Promise<LeaveView> {
  const employee = await users().findOne({ userId });
  if (!employee) {
    throw new LeaveError(404, 'Employee not found');
  }
  if (!employee.managerUserId) {
    throw new LeaveError(409, 'A manager must be assigned before applying for leave');
  }

  const manager = await users().findOne({ userId: employee.managerUserId });
  if (
    !manager ||
    manager.lifecycleStatus === 'offboarded' ||
    manager.lifecycleStatus === 'terminated'
  ) {
    throw new LeaveError(409, 'The assigned manager is not active');
  }

  const type = input.type.trim().toLowerCase() as Leave['type'];
  if (!leaveTypes.has(type)) {
    throw new LeaveError(400, 'Leave type must be sick, casual, or earned');
  }

  const startDate = parseDateOnly(input.startDate, 'startDate');
  const endDate = parseDateOnly(input.endDate, 'endDate');
  if (endDate < startDate) {
    throw new LeaveError(400, 'End date cannot be before start date');
  }

  const today = startOfUtcDay(new Date());
  if (startDate < today) {
    throw new LeaveError(400, 'Leave cannot start in the past');
  }
  if (inclusiveDays(startDate, endDate) > 365) {
    throw new LeaveError(400, 'Leave cannot exceed 365 days');
  }

  const reason = input.reason.trim();
  if (reason.length > 500) {
    throw new LeaveError(400, 'Reason cannot exceed 500 characters');
  }

  const overlap = await leaves().findOne({
    userId,
    status: { $in: ['pending', 'approved'] },
    startDate: { $lte: endDate },
    endDate: { $gte: startDate },
  });
  if (overlap) {
    throw new LeaveError(409, 'A pending or approved leave already overlaps these dates');
  }

  const createdAt = Date.now();
  const result = await leaves().insertOne({
    userId,
    type,
    startDate,
    endDate,
    reason,
    status: 'pending',
    createdAt,
    updatedAt: new Date(createdAt),
  });

  return toLeaveView(
    {
      _id: result.insertedId,
      userId,
      type,
      startDate,
      endDate,
      reason,
      status: 'pending',
      createdAt,
    },
    employee,
  );
}

export async function getMyLeaves(userId: string): Promise<LeaveView[]> {
  const employee = await users().findOne({ userId });
  if (!employee) {
    throw new LeaveError(404, 'Employee not found');
  }

  const documents = await leaves().find({ userId }).sort({ createdAt: -1 }).toArray();
  return documents.map((leave) => toLeaveView(leave, employee));
}

export async function getMyLeaveBalance(userId: string, year = new Date().getUTCFullYear()) {
  const employee = await users().findOne({ userId });
  if (!employee) throw new LeaveError(404, 'Employee not found');
  if (!Number.isInteger(year) || year < 2000 || year > 2100) {
    throw new LeaveError(400, 'Invalid balance year');
  }
  const yearStart = new Date(Date.UTC(year, 0, 1));
  const yearEnd = new Date(Date.UTC(year, 11, 31));
  const approved = await leaves()
    .find({ userId, status: 'approved', startDate: { $lte: yearEnd }, endDate: { $gte: yearStart } })
    .toArray();
  const totals: Record<Leave['type'], number> = { sick: 12, casual: 12, earned: 18 };
  const used: Record<Leave['type'], number> = { sick: 0, casual: 0, earned: 0 };
  for (const leave of approved) {
    const start = leave.startDate < yearStart ? yearStart : leave.startDate;
    const end = leave.endDate > yearEnd ? yearEnd : leave.endDate;
    used[leave.type] += inclusiveDays(start, end);
  }
  return {
    year,
    sick: balanceItem(totals.sick, used.sick),
    casual: balanceItem(totals.casual, used.casual),
    earned: balanceItem(totals.earned, used.earned),
  };
}

export async function getManagerLeaveInbox(managerUserId: string): Promise<LeaveView[]> {
  const reports = await users()
    .find({ managerUserId })
    .project<Pick<User, 'userId' | 'name' | 'email' | 'department' | 'designation'>>({
      userId: 1,
      name: 1,
      email: 1,
      department: 1,
      designation: 1,
    })
    .toArray();

  if (reports.length === 0) {
    return [];
  }

  const employeeById = new Map(reports.map((employee) => [employee.userId, employee]));
  const documents = await leaves()
    .find({ userId: { $in: reports.map((employee) => employee.userId) } })
    .sort({ status: -1, createdAt: -1 })
    .toArray();

  return documents.map((leave) => {
    const employee = employeeById.get(leave.userId);
    if (!employee) {
      throw new LeaveError(409, 'Leave has an invalid employee reference');
    }
    return toLeaveView(leave, employee as User);
  });
}

export async function decideLeave(
  managerUserId: string,
  leaveIdInput: string,
  input: { decision: string; managerNote?: string },
): Promise<LeaveView> {
  if (!ObjectId.isValid(leaveIdInput)) {
    throw new LeaveError(400, 'Invalid leave ID');
  }

  const decision = input.decision.trim().toLowerCase() as LeaveStatus;
  if (!decisionStatuses.has(decision)) {
    throw new LeaveError(400, 'Decision must be approved or declined');
  }

  const leaveId = new ObjectId(leaveIdInput);
  const leave = await leaves().findOne({ _id: leaveId });
  if (!leave) {
    throw new LeaveError(404, 'Leave request not found');
  }

  const employee = await users().findOne({ userId: leave.userId });
  if (!employee || employee.managerUserId !== managerUserId) {
    throw new LeaveError(403, 'Only the employee’s current manager can decide this leave');
  }
  if (leave.status !== 'pending') {
    throw new LeaveError(409, 'Leave request has already been decided');
  }

  const managerNote = input.managerNote?.trim();
  if (managerNote && managerNote.length > 500) {
    throw new LeaveError(400, 'Manager note cannot exceed 500 characters');
  }

  const decidedAt = new Date();
  const updateFields: Partial<Leave> = {
    status: decision,
    decidedByUserId: managerUserId,
    decidedAt,
    updatedAt: decidedAt,
  };
  if (managerNote) updateFields.managerNote = managerNote;
  const updated = await leaves().findOneAndUpdate(
    { _id: leaveId, status: 'pending' },
    {
      $set: updateFields,
    },
    { returnDocument: 'after' },
  );
  if (!updated) {
    throw new LeaveError(409, 'Leave request has already been decided');
  }

  return toLeaveView(updated, employee);
}

function parseDateOnly(value: string, field: string): Date {
  if (!/^\d{4}-\d{2}-\d{2}$/.test(value)) {
    throw new LeaveError(400, `${field} must use YYYY-MM-DD format`);
  }
  const date = new Date(`${value}T00:00:00.000Z`);
  if (Number.isNaN(date.getTime()) || date.toISOString().slice(0, 10) !== value) {
    throw new LeaveError(400, `${field} is not a valid date`);
  }
  return date;
}

function startOfUtcDay(date: Date): Date {
  return new Date(Date.UTC(date.getUTCFullYear(), date.getUTCMonth(), date.getUTCDate()));
}

function inclusiveDays(startDate: Date, endDate: Date): number {
  return Math.floor((endDate.getTime() - startDate.getTime()) / 86_400_000) + 1;
}

function balanceItem(total: number, used: number) {
  return { total, used, remaining: Math.max(0, total - used) };
}

function toLeaveView(leave: Leave & { _id: ObjectId }, employee: User): LeaveView {
  const createdAt = leave.createdAt ? new Date(leave.createdAt) : (leave.updatedAt ?? new Date());
  return {
    id: leave._id.toHexString(),
    userId: leave.userId,
    employee: {
      name: employee.name,
      email: employee.email,
      department: employee.department,
      designation: employee.designation,
    },
    type: leave.type,
    startDate: leave.startDate.toISOString().slice(0, 10),
    endDate: leave.endDate.toISOString().slice(0, 10),
    days: inclusiveDays(leave.startDate, leave.endDate),
    reason: leave.reason,
    status: leave.status,
    managerNote: leave.managerNote,
    createdAt: createdAt.toISOString(),
    decidedAt: leave.decidedAt?.toISOString(),
  };
}

export class LeaveError extends Error {
  constructor(
    public readonly statusCode: number,
    message: string,
  ) {
    super(message);
  }
}
