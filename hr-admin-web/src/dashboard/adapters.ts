// Map backend DTOs to the dashboard's view-model types.
import type { EmpType, FeedbackStatus, LeaveType, OtDuration, ReqStatus } from './theme';
import type { Emp, Feedback, FbMgr, Leave, Overtime, Reimb } from './seed';
import type { AuthUser } from '../services/auth';
import type {
  ClaimDTO,
  EmployeeDTO,
  FeedbackDTO,
  LeaveDTO,
  OvertimeDTO,
  WorkspaceDTO,
} from '../services/hrms';

const MON = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
const WD = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

/** "2026-07-10" / ISO timestamp -> "10 Jul". */
export function fmtDay(input: string): string {
  const [y, m, d] = input.slice(0, 10).split('-').map(Number);
  if (!y || !m || !d) return input;
  return `${d} ${MON[m - 1]}`;
}

function weekday(dateOnly: string): string {
  const [y, m, d] = dateOnly.slice(0, 10).split('-').map(Number);
  return WD[new Date(Date.UTC(y, m - 1, d)).getUTCDay()];
}

function ts(iso: string): number {
  const n = Date.parse(iso);
  return Number.isNaN(n) ? 0 : n;
}

const cap = (s: string): string => (s ? s[0].toUpperCase() + s.slice(1) : s);

export function adaptLeave(dto: LeaveDTO, managerName: string): Leave {
  const byAdmin = dto.decidedByRole === 'admin';
  return {
    id: dto.id,
    name: dto.employee.name,
    team: dto.employee.department || 'Team',
    type: cap(dto.type) as LeaveType,
    from: fmtDay(dto.startDate),
    to: fmtDay(dto.endDate),
    days: `${dto.days} day${dto.days === 1 ? '' : 's'}`,
    dayN: dto.days,
    status: cap(dto.status) as ReqStatus,
    manager: managerName,
    applied: fmtDay(dto.createdAt),
    ord: ts(dto.createdAt),
    eRemark: dto.reason,
    mRemark: dto.managerNote || '',
    submitterId: dto.userId,
    byAdmin,
  };
}

export function adaptOvertime(dto: OvertimeDTO, managerName: string): Overtime {
  const byAdmin = dto.decidedByRole === 'admin';
  return {
    id: dto.id,
    name: dto.employee.name,
    team: dto.employee.department || 'Team',
    appliedOn: fmtDay(dto.createdAt),
    otDate: fmtDay(dto.workDate),
    duration: (dto.duration === 'full_day' ? 'Full day' : 'Half day') as OtDuration,
    day: weekday(dto.workDate),
    status: cap(dto.status) as ReqStatus,
    manager: managerName,
    mRemark: '',
    ord: ts(dto.createdAt),
    submitterId: dto.userId,
    byAdmin,
  };
}

export function adaptReimb(dto: ClaimDTO, managerName: string): Reimb {
  const byAdmin = dto.decidedByRole === 'admin';
  return {
    id: dto.id,
    name: dto.employee.name,
    team: dto.employee.department || 'Team',
    manager: managerName,
    type: cap(dto.category),
    amount: '₹' + dto.amount.toLocaleString('en-IN'),
    amountN: dto.amount,
    billDate: fmtDay(dto.expenseDate),
    applyDate: fmtDay(dto.createdAt),
    status: cap(dto.status) as ReqStatus,
    bill: dto.receiptName || '—',
    hasBill: Boolean(dto.hasReceipt),
    ord: ts(dto.createdAt),
    mRemark: '',
    submitterId: dto.userId,
    byAdmin,
  };
}

const FB_STATUS: Record<string, FeedbackStatus> = {
  sent: 'Submitted',
  saved: 'Draft',
  pending: 'Pending',
};

/** Org-wide employee directory (rule 5). */
export function adaptEmployees(dtos: EmployeeDTO[]): Emp[] {
  return dtos.map((e) => ({
    id: e.userId,
    name: e.name,
    role: e.isLeadership ? 'Leadership' : cap(e.role),
    team: e.department || 'Team',
    location: '—',
    empType: 'Full-time' as EmpType,
    manager: e.managerName || (e.isLeadership ? '—' : '—'),
    managerId: e.managerUserId || '',
    dob: '—',
    joining: '—',
    docs: 0,
  }));
}

/** Org-wide feedback list + per-manager rollup (rule 5). */
export function adaptFeedbackList(records: FeedbackDTO[]): { fbs: Feedback[]; fbMgrs: FbMgr[] } {
  const fbs: Feedback[] = records.map((r, i) => ({
    id: r.id,
    name: r.employeeName,
    team: r.department || 'Team',
    manager: r.managerName || '—',
    parameter: 'Overall',
    rating: r.overallScore,
    status: FB_STATUS[r.status] ?? 'Pending',
    date: fmtDay(r.updatedAt || r.sentAt || ''),
    ord: records.length - i,
    text: r.extra || 'No feedback submitted for this period yet.',
  }));

  const byMgr = new Map<string, { name: string; done: number; total: number; scopes: Set<string> }>();
  for (const r of records) {
    const g = byMgr.get(r.managerUserId) ?? {
      name: r.managerName || '—',
      done: 0,
      total: 0,
      scopes: new Set<string>(),
    };
    g.total += 1;
    if (r.status === 'sent') g.done += 1;
    if (r.department) g.scopes.add(r.department);
    byMgr.set(r.managerUserId, g);
  }
  const fbMgrs: FbMgr[] = [...byMgr.entries()].map(([id, g]) => ({
    id,
    name: g.name,
    scope: g.scopes.size ? [...g.scopes].join(' · ') : 'Team',
    done: g.done,
    total: g.total,
    reminded: false,
  }));

  return { fbs, fbMgrs };
}

export function adaptWorkspace(ws: WorkspaceDTO, user: AuthUser): {
  fbMgrs: FbMgr[];
  fbs: Feedback[];
  emps: Emp[];
} {
  const team = ws.team ?? [];
  const done = team.filter((t) => t.feedbackStatus === 'sent').length;
  const scopes = Array.from(new Set(team.map((t) => t.department).filter(Boolean)));

  const fbMgrs: FbMgr[] = [
    {
      id: user.id,
      name: user.name,
      scope: scopes.length ? scopes.join(' · ') : 'Your team',
      done,
      total: team.length,
      reminded: false,
    },
  ];

  const fbs: Feedback[] = team.map((t, i) => ({
    id: t.userId,
    name: t.name,
    team: t.department || 'Team',
    manager: user.name,
    parameter: 'Overall',
    rating: t.score,
    status: FB_STATUS[t.feedbackStatus] ?? 'Pending',
    date: fmtDay(t.nextDate),
    ord: team.length - i,
    text: t.extra || 'No feedback submitted for this period yet.',
  }));

  const emps: Emp[] = team.map((t) => ({
    id: t.userId,
    name: t.name,
    role: '—',
    team: t.department || 'Team',
    location: '—',
    empType: 'Full-time' as EmpType,
    manager: user.name,
    managerId: user.id,
    dob: '—',
    joining: '—',
    docs: 0,
  }));

  return { fbMgrs, fbs, emps };
}
