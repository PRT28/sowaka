import { feedbackRecords } from '../config/db';
import { orgUsers } from './admin-scope';

/** Org-wide list of every feedback record, for the HR dashboard (rule 5). */
export async function listAllFeedbackForAdmin(adminUserId: string) {
  const employees = await orgUsers(adminUserId);
  if (employees.length === 0) return [];
  const userById = new Map(employees.map((e) => [e.userId, e]));
  const records = await feedbackRecords()
    .find({ employeeUserId: { $in: employees.map((e) => e.userId) } })
    .sort({ period: -1, updatedAt: -1 })
    .toArray();
  return records.map((record) => {
    const employee = userById.get(record.employeeUserId);
    const manager = userById.get(record.managerUserId);
    return {
      id: record._id.toHexString(),
      employeeUserId: record.employeeUserId,
      employeeName: employee?.name ?? 'Unknown',
      department: employee?.department ?? employee?.designation,
      managerUserId: record.managerUserId,
      managerName: manager?.name,
      period: record.period,
      status: record.status,
      overallScore: record.overallScore,
      parameters: record.parameters,
      extra: record.extra,
      updatedAt: record.updatedAt?.toISOString?.() ?? undefined,
      sentAt: record.sentAt?.toISOString?.() ?? undefined,
    };
  });
}

/** Org-wide employee directory, for the HR dashboard. */
export async function listAllEmployeesForAdmin(adminUserId: string) {
  const employees = await orgUsers(adminUserId);
  const nameById = new Map(employees.map((e) => [e.userId, e.name]));
  return employees.map((e) => ({
    userId: e.userId,
    name: e.name,
    email: e.email,
    department: e.department,
    designation: e.designation,
    state: e.state,
    role: e.role ?? 'employee',
    isLeadership: e.isLeadership === true,
    dashboardAccess: e.dashboardAccess === true,
    managerUserId: e.managerUserId,
    managerName: e.managerUserId ? nameById.get(e.managerUserId) : undefined,
    lifecycleStatus: e.lifecycleStatus,
  }));
}
