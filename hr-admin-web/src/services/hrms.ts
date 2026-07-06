// Typed calls against the manager-scoped HRMS endpoints.
import { api } from './http';

export type LeaveDTO = {
  id: string;
  userId: string;
  employee: { name: string; email?: string; department?: string; designation?: string };
  type: 'sick' | 'casual' | 'earned';
  startDate: string;
  endDate: string;
  days: number;
  reason: string;
  status: 'pending' | 'approved' | 'declined';
  managerNote?: string;
  createdAt: string;
  decidedAt?: string;
};

export type OvertimeDTO = {
  id: string;
  userId: string;
  employee: { name: string; department?: string };
  workDate: string;
  duration: 'half_day' | 'full_day';
  hours: number;
  project: string;
  note?: string;
  status: 'pending' | 'approved' | 'declined';
  createdAt: string;
  decidedAt?: string;
};

export type ClaimDTO = {
  id: string;
  userId: string;
  employee: { name: string; department?: string };
  expenseDate: string;
  amount: number;
  category: 'travel' | 'meals' | 'internet' | 'other';
  receiptName?: string;
  note?: string;
  status: 'pending' | 'approved' | 'declined' | 'paid';
  createdAt: string;
  decidedAt?: string;
  paidAt?: string;
};

export type TeamMember = {
  userId: string;
  name: string;
  department: string;
  score: number;
  nextDate: string;
  feedbackStatus: 'pending' | 'saved' | 'sent';
  missedMonths: number;
  parameters: { name: string; score: number; note: string }[];
  extra: string;
};

export type WorkspaceDTO = {
  period: string;
  approverName: string;
  managerScore: number;
  team: TeamMember[];
  recognitionCandidates: TeamMember[];
  nominations: { category: string; employeeUserId: string }[];
};

// ---- Leaves ----
export const getLeaveInbox = () =>
  api<{ leaves: LeaveDTO[] }>('/leaves/inbox').then((r) => r.leaves);

export const decideLeave = (id: string, decision: 'approved' | 'declined', managerNote?: string) =>
  api<{ leave: LeaveDTO }>(`/leaves/${id}/decision`, {
    method: 'PATCH',
    body: { decision, ...(managerNote ? { managerNote } : {}) },
  }).then((r) => r.leave);

// ---- Overtime ----
export const getOvertimeInbox = () =>
  api<{ overtime: OvertimeDTO[] }>('/overtime/inbox').then((r) => r.overtime);

export const decideOvertime = (id: string, decision: 'approved' | 'declined') =>
  api<{ overtime: OvertimeDTO }>(`/overtime/${id}/decision`, {
    method: 'PATCH',
    body: { decision },
  }).then((r) => r.overtime);

// ---- Reimbursements ----
export const getReimbInbox = () =>
  api<{ claims: ClaimDTO[] }>('/reimbursements/inbox').then((r) => r.claims);

export const decideReimb = (id: string, decision: 'approved' | 'declined' | 'paid') =>
  api<{ claim: ClaimDTO }>(`/reimbursements/${id}/decision`, {
    method: 'PATCH',
    body: { decision },
  }).then((r) => r.claim);

// ---- Manager workspace (feedback + team) ----
export const getWorkspace = () => api<WorkspaceDTO>('/manager/workspace');
