// Map backend DTOs to the dashboard's view-model types.
import type { EmpType, FeedbackStatus, LeaveType, OtDuration, ReqStatus } from './theme';
import type { Emp, Feedback, FbMgr, Leave, Overtime, Reimb } from './seed';
import type { AuthUser } from '../services/auth';
import type { ClaimDTO, LeaveDTO, OvertimeDTO, WorkspaceDTO } from '../services/hrms';

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
  };
}

export function adaptOvertime(dto: OvertimeDTO, managerName: string): Overtime {
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
  };
}

export function adaptReimb(dto: ClaimDTO, managerName: string): Reimb {
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
  };
}

const FB_STATUS: Record<string, FeedbackStatus> = {
  sent: 'Submitted',
  saved: 'Draft',
  pending: 'Pending',
};

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
