import { companies, holidays, users } from '../config/db';
import { Company } from '../models/company.model';

// Default week-off when a company has none configured: Sunday only.
export const DEFAULT_WEEKOFF_DAYS = [0];

export class CompanySettingsError extends Error {
  constructor(
    public status: number,
    message: string,
  ) {
    super(message);
    this.name = 'CompanySettingsError';
  }
}

export interface CompanySettingsView {
  weekoffDays: number[];
  overtimeDisabledDepartments: string[];
  departments: string[]; // all departments in the org, for building toggles
}

async function requireAdminOrg(adminUserId: string): Promise<string> {
  const admin = await users().findOne({ userId: adminUserId });
  if (!admin) throw new CompanySettingsError(404, 'User not found');
  if (!admin.org) throw new CompanySettingsError(409, 'User is not attached to a company');
  return admin.org;
}

/** Raw config for an org, with defaults applied. Used by the overtime rules. */
export async function getCompanyConfig(
  org: string | undefined,
): Promise<{ weekoffDays: number[]; overtimeDisabledDepartments: string[] }> {
  if (!org) return { weekoffDays: DEFAULT_WEEKOFF_DAYS, overtimeDisabledDepartments: [] };
  const company = await companies().findOne({ id: org });
  return {
    weekoffDays:
      company?.weekoffDays && company.weekoffDays.length
        ? company.weekoffDays
        : DEFAULT_WEEKOFF_DAYS,
    overtimeDisabledDepartments: company?.overtimeDisabledDepartments ?? [],
  };
}

/** Settings for the HR dashboard, including the list of departments to toggle. */
export async function getCompanySettings(adminUserId: string): Promise<CompanySettingsView> {
  const org = await requireAdminOrg(adminUserId);
  const config = await getCompanyConfig(org);
  const orgEmployees = await users().find({ org }).project({ department: 1 }).toArray();
  const departments = [
    ...new Set(
      orgEmployees
        .map((employee) => (employee as { department?: string }).department?.trim())
        .filter((department): department is string => Boolean(department)),
    ),
  ].sort((a, b) => a.localeCompare(b));
  return { ...config, departments };
}

export async function updateCompanySettings(
  adminUserId: string,
  patch: { weekoffDays?: unknown; overtimeDisabledDepartments?: unknown },
): Promise<CompanySettingsView> {
  const org = await requireAdminOrg(adminUserId);
  const update: Partial<Company> = { updatedAt: new Date() };

  if (patch.weekoffDays !== undefined) {
    if (
      !Array.isArray(patch.weekoffDays) ||
      !patch.weekoffDays.every((day) => Number.isInteger(day) && day >= 0 && day <= 6)
    ) {
      throw new CompanySettingsError(400, 'weekoffDays must be an array of weekday numbers (0-6)');
    }
    update.weekoffDays = [...new Set(patch.weekoffDays as number[])].sort((a, b) => a - b);
  }

  if (patch.overtimeDisabledDepartments !== undefined) {
    if (
      !Array.isArray(patch.overtimeDisabledDepartments) ||
      !patch.overtimeDisabledDepartments.every((dep) => typeof dep === 'string')
    ) {
      throw new CompanySettingsError(400, 'overtimeDisabledDepartments must be an array of strings');
    }
    update.overtimeDisabledDepartments = [
      ...new Set((patch.overtimeDisabledDepartments as string[]).map((dep) => dep.trim()).filter(Boolean)),
    ];
  }

  await companies().updateOne({ id: org }, { $set: update }, { upsert: true });
  return getCompanySettings(adminUserId);
}

/** True when `date` falls on a configured week-off weekday (UTC). */
export function isWeekoffDay(date: Date, weekoffDays: number[]): boolean {
  return weekoffDays.includes(date.getUTCDay());
}

/** Distinct YYYY-MM-DD holiday dates for an org (UTC day granularity). */
export async function getOrgHolidayDates(org: string | undefined): Promise<Set<string>> {
  if (!org) return new Set();
  const rows = await holidays().find({ org }).project({ date: 1 }).toArray();
  return new Set(
    rows.map((row) => (row as { date: Date }).date.toISOString().slice(0, 10)),
  );
}
