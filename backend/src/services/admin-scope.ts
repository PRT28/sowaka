import { users } from '../config/db';
import { User } from '../models/user.model';

/**
 * All users in the same organization as the given dashboard user — the scope of
 * "org-wide" for the HR dashboard. If the admin has no org set, falls back to
 * every user (single-tenant deployments).
 */
export async function orgUsers(adminUserId: string): Promise<User[]> {
  const admin = await users().findOne({ userId: adminUserId });
  if (!admin) return [];
  const filter = admin.org ? { org: admin.org } : {};
  return users().find(filter).toArray();
}
