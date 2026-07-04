// Central state + handlers for the HR dashboard, exposed via context.
import { createContext, useContext, useMemo, useRef, useState } from 'react';
import type { ReactNode } from 'react';
import type { View, ReqStatus, FeedbackStatus } from './theme';
import {
  emptyForm,
  seedEmp,
  seedFb,
  seedFbMgrs,
  seedLeaves,
  seedOt,
  seedRb,
} from './seed';
import type { Emp, Feedback, FbMgr, Leave, Overtime, Reimb, UserForm } from './seed';

type LeaveStatusFilter = ReqStatus | 'all';
type FbStatusFilter = FeedbackStatus | 'all';

export type Store = ReturnType<typeof useProvideStore>;

const first = (name: string) => name.split(' ')[0];

function useProvideStore() {
  const [view, setViewRaw] = useState<View>('overview');
  const [toast, setToast] = useState('');
  const toastTimer = useRef<ReturnType<typeof setTimeout> | null>(null);

  // leave
  const [leaves, setLeaves] = useState<Leave[]>(seedLeaves);
  const [leaveSearch, setLeaveSearch] = useState('');
  const [leaveStatus, setLeaveStatus] = useState<LeaveStatusFilter>('all');
  const [leaveType, setLeaveType] = useState('all');
  const [leaveSort, setLeaveSort] = useState('recent');
  const [drawerId, setDrawerId] = useState<number | null>(null);
  const [declineId, setDeclineId] = useState<number | null>(null);
  const [declineText, setDeclineText] = useState('');

  // feedback
  const [fbs] = useState<Feedback[]>(seedFb);
  const [fbSearch, setFbSearch] = useState('');
  const [fbStatus, setFbStatus] = useState<FbStatusFilter>('all');
  const [fbDrawerId, setFbDrawerId] = useState<number | null>(null);
  const [fbMgrs, setFbMgrs] = useState<FbMgr[]>(seedFbMgrs);

  // reimbursements
  const [rbs, setRbs] = useState<Reimb[]>(seedRb);
  const [rbSearch, setRbSearch] = useState('');
  const [rbStatus, setRbStatus] = useState<LeaveStatusFilter>('all');
  const [rbType, setRbType] = useState('all');
  const [rbSort, setRbSort] = useState('recent');
  const [rbDrawerId, setRbDrawerId] = useState<number | null>(null);
  const [rbDeclineId, setRbDeclineId] = useState<number | null>(null);
  const [rbDeclineText, setRbDeclineText] = useState('');

  // overtime
  const [ots, setOts] = useState<Overtime[]>(seedOt);
  const [otSearch, setOtSearch] = useState('');
  const [otStatus, setOtStatus] = useState<LeaveStatusFilter>('all');
  const [otDrawerId, setOtDrawerId] = useState<number | null>(null);
  const [otDeclineId, setOtDeclineId] = useState<number | null>(null);
  const [otDeclineText, setOtDeclineText] = useState('');

  // employees
  const [emps, setEmps] = useState<Emp[]>(seedEmp);
  const [empSearch, setEmpSearch] = useState('');
  const [empTeam, setEmpTeam] = useState('all');
  const [empDrawerId, setEmpDrawerId] = useState<string | null>(null);
  const [addOpen, setAddOpen] = useState(false);
  const [form, setForm] = useState<UserForm>(emptyForm);

  const closeAllOverlays = () => {
    setDrawerId(null);
    setDeclineId(null);
    setFbDrawerId(null);
    setRbDrawerId(null);
    setRbDeclineId(null);
    setOtDrawerId(null);
    setEmpDrawerId(null);
    setAddOpen(false);
  };

  const setView = (v: View) => {
    closeAllOverlays();
    setViewRaw(v);
  };

  const flash = (msg: string) => {
    setToast(msg);
    if (toastTimer.current) clearTimeout(toastTimer.current);
    toastTimer.current = setTimeout(() => setToast(''), 2600);
  };

  // ---- leave ----
  const approve = (id: number) => {
    const r = leaves.find((l) => l.id === id);
    setLeaves((s) => s.map((l) => (l.id === id ? { ...l, status: 'Approved', mRemark: l.mRemark || 'Approved.' } : l)));
    setDrawerId(null);
    setDeclineId(null);
    flash(`${r ? first(r.name) : 'Leave'}’s leave approved`);
  };
  const openDecline = (id: number) => {
    setDeclineId(id);
    setDeclineText('');
  };
  const cancelDecline = () => {
    setDeclineId(null);
    setDeclineText('');
  };
  const confirmDecline = (id: number) => {
    const txt = declineText.trim() || 'Declined.';
    const r = leaves.find((l) => l.id === id);
    setLeaves((s) => s.map((l) => (l.id === id ? { ...l, status: 'Declined', mRemark: txt } : l)));
    setDeclineId(null);
    setDeclineText('');
    setDrawerId(null);
    flash(`${r ? first(r.name) : 'Leave'}’s leave declined`);
  };

  // ---- reimbursements ----
  const rbApprove = (id: number) => {
    const r = rbs.find((x) => x.id === id);
    setRbs((s) => s.map((x) => (x.id === id ? { ...x, status: 'Approved', mRemark: x.mRemark || 'Approved.' } : x)));
    setRbDrawerId(null);
    setRbDeclineId(null);
    flash(`${r ? first(r.name) : 'Claim'}’s claim approved`);
  };
  const rbOpenDecline = (id: number) => {
    setRbDeclineId(id);
    setRbDeclineText('');
  };
  const rbCancelDecline = () => {
    setRbDeclineId(null);
    setRbDeclineText('');
  };
  const rbConfirmDecline = (id: number) => {
    const txt = rbDeclineText.trim() || 'Declined.';
    const r = rbs.find((x) => x.id === id);
    setRbs((s) => s.map((x) => (x.id === id ? { ...x, status: 'Declined', mRemark: txt } : x)));
    setRbDeclineId(null);
    setRbDeclineText('');
    setRbDrawerId(null);
    flash(`${r ? first(r.name) : 'Claim'}’s claim declined`);
  };

  // ---- feedback reminders ----
  const remindMgr = (id: number) => {
    const m = fbMgrs.find((x) => x.id === id);
    setFbMgrs((s) => s.map((x) => (x.id === id ? { ...x, reminded: true } : x)));
    flash(`Reminder sent to ${m ? first(m.name) : 'manager'}`);
  };
  const remindAll = () => {
    const pend = fbMgrs.filter((m) => m.done < m.total);
    setFbMgrs((s) => s.map((m) => (m.done < m.total ? { ...m, reminded: true } : m)));
    flash(`Reminder sent to ${pend.length} managers`);
  };

  // ---- overtime ----
  const otApprove = (id: number) => {
    const r = ots.find((x) => x.id === id);
    setOts((s) => s.map((x) => (x.id === id ? { ...x, status: 'Approved', mRemark: x.mRemark || 'Approved (HR override).' } : x)));
    setOtDrawerId(null);
    setOtDeclineId(null);
    flash(`${r ? first(r.name) : 'Overtime'}’s overtime approved`);
  };
  const otOpenDecline = (id: number) => {
    setOtDeclineId(id);
    setOtDeclineText('');
  };
  const otCancelDecline = () => {
    setOtDeclineId(null);
    setOtDeclineText('');
  };
  const otConfirmDecline = (id: number) => {
    const txt = otDeclineText.trim() || 'Declined (HR override).';
    const r = ots.find((x) => x.id === id);
    setOts((s) => s.map((x) => (x.id === id ? { ...x, status: 'Declined', mRemark: txt } : x)));
    setOtDeclineId(null);
    setOtDeclineText('');
    setOtDrawerId(null);
    flash(`${r ? first(r.name) : 'Overtime'}’s overtime declined`);
  };

  // ---- employees ----
  const setFormField = (k: keyof UserForm, v: string) => setForm((s) => ({ ...s, [k]: v }));
  const saveUser = () => {
    const f = form;
    if (!f.name.trim()) {
      flash('Please enter a name');
      return;
    }
    const n = emps.length;
    const id = 'EMP-0' + (80 + n);
    const emp: Emp = {
      id,
      name: f.name.trim(),
      role: f.role.trim() || '—',
      team: f.team,
      location: f.location,
      empType: f.empType,
      manager: f.manager,
      managerId: f.manager === 'Imran Qureshi' ? 'EMP-002' : 'EMP-001',
      dob: f.dob.trim() || '—',
      joining: f.joining.trim() || '—',
      docs: 0,
    };
    setEmps((s) => [emp, ...s]);
    setAddOpen(false);
    setForm(emptyForm());
    flash(`${emp.name} added to the directory`);
  };

  // overview cross-navigation
  const goOvertimeRow = (id: number) => {
    closeAllOverlays();
    setViewRaw('overtime');
    setOtDrawerId(id);
  };
  const goReimbRow = (id: number) => {
    closeAllOverlays();
    setViewRaw('reimbursements');
    setRbDrawerId(id);
  };

  return {
    view, setView,
    toast, flash,
    // leave
    leaves, leaveSearch, setLeaveSearch, leaveStatus, setLeaveStatus, leaveType, setLeaveType,
    leaveSort, setLeaveSort, drawerId, setDrawerId, declineId, declineText, setDeclineText,
    approve, openDecline, cancelDecline, confirmDecline,
    // feedback
    fbs, fbSearch, setFbSearch, fbStatus, setFbStatus, fbDrawerId, setFbDrawerId, fbMgrs,
    remindMgr, remindAll,
    // reimbursements
    rbs, rbSearch, setRbSearch, rbStatus, setRbStatus, rbType, setRbType, rbSort, setRbSort,
    rbDrawerId, setRbDrawerId, rbDeclineId, rbDeclineText, setRbDeclineText,
    rbApprove, rbOpenDecline, rbCancelDecline, rbConfirmDecline,
    // overtime
    ots, otSearch, setOtSearch, otStatus, setOtStatus, otDrawerId, setOtDrawerId,
    otDeclineId, otDeclineText, setOtDeclineText,
    otApprove, otOpenDecline, otCancelDecline, otConfirmDecline,
    // employees
    emps, empSearch, setEmpSearch, empTeam, setEmpTeam, empDrawerId, setEmpDrawerId,
    addOpen, setAddOpen, form, setFormField, saveUser,
    // cross-nav
    goOvertimeRow, goReimbRow,
  };
}

const Ctx = createContext<Store | null>(null);

export function StoreProvider({ children }: { children: ReactNode }) {
  const store = useProvideStore();
  const value = useMemo(() => store, [store]);
  return <Ctx.Provider value={value}>{children}</Ctx.Provider>;
}

export function useStore(): Store {
  const s = useContext(Ctx);
  if (!s) throw new Error('useStore must be used within StoreProvider');
  return s;
}
