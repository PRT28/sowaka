export interface Company {
  id: string;
  name: string;
  address?: string;
  // Weekly off days as JS weekday numbers (0 = Sunday .. 6 = Saturday).
  // Used to decide which days count as a "week-off" for full-day overtime.
  // Absent/empty is treated as the default [0] (Sunday) by consumers.
  weekoffDays?: number[];
  // Departments (User.department) for which the overtime feature is hidden/disabled.
  overtimeDisabledDepartments?: string[];
  createdAt?: number;
  updatedAt?: Date;
}
