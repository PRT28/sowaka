import crypto from 'crypto';
import { Filter } from 'mongodb';
import { users } from '../config/db';
import { User } from '../models/user.model';
import { ApiError } from '../utils/api-error';

const projection = { _id: 0 } as const;

export interface UserFilter {
  org?: string;
  department?: string;
  managerUserId?: string;
  lifecycleStatus?: string;
  employeeType?: string;
}

export async function createUser(input: Partial<User>): Promise<User> {
  const email = normalizeEmail(input.email);
  if (!email) throw new ApiError(400, 'email is required');
  if (!input.name) throw new ApiError(400, 'name is required');

  const userId =
    input.userId ?? crypto.createHash('sha1').update(email).digest('hex').slice(0, 12);

  const existing = await users().findOne({ $or: [{ email }, { userId }] });
  if (existing) throw new ApiError(409, 'A user with this email or userId already exists');

  const doc: User = {
    ...stripImmutable(input),
    email,
    userId,
    name: input.name,
    lifecycleStatus: input.lifecycleStatus ?? 'active',
    createdAt: Date.now(),
  };

  await users().insertOne(doc);
  return getUser(userId);
}

export async function listUsers(filter: UserFilter): Promise<User[]> {
  const query: Filter<User> = {};
  if (filter.org) query.org = filter.org;
  if (filter.department) query.department = filter.department;
  if (filter.managerUserId) query.managerUserId = filter.managerUserId;
  if (filter.lifecycleStatus) query.lifecycleStatus = filter.lifecycleStatus as User['lifecycleStatus'];
  if (filter.employeeType) query.employeeType = filter.employeeType as User['employeeType'];

  return users().find(query, { projection }).toArray();
}

export async function getUser(userId: string): Promise<User> {
  const user = await users().findOne({ userId }, { projection });
  if (!user) throw new ApiError(404, 'User not found');
  return user;
}

export async function updateUser(userId: string, updates: Partial<User>): Promise<User> {
  const set = stripImmutable(updates);
  if (set.email) set.email = normalizeEmail(set.email);

  const result = await users().findOneAndUpdate(
    { userId },
    { $set: { ...set, updatedAt: new Date() } },
    { returnDocument: 'after', projection },
  );

  if (!result) throw new ApiError(404, 'User not found');
  return result;
}

export async function deleteUser(userId: string): Promise<void> {
  const result = await users().deleteOne({ userId });
  if (result.deletedCount === 0) throw new ApiError(404, 'User not found');
}

function normalizeEmail(email?: string): string {
  return (email ?? '').trim().toLowerCase();
}

/** Identity / server-managed fields can't be set through the API body. */
function stripImmutable(input: Partial<User>): Partial<User> {
  const copy = { ...input } as Partial<User> & { _id?: unknown };
  delete copy._id;
  delete copy.userId;
  delete copy.createdAt;
  return copy;
}
