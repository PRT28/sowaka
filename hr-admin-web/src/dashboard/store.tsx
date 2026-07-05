// Central state + handlers for the HR dashboard. Data is loaded from the
// live manager-scoped API and mutated through it (approve/decline).
import { createContext, useCallback, useContext, useEffect, useRef, useState } from 'react';
import type { ReactNode } from 'react';
import type { View, ReqStatus, FeedbackStatus } from './theme';
import { emptyForm } from './seed';
import type { Emp, Feedback, FbMgr, Leave, Overtime, Reimb, UserForm } from './seed';
import { adaptLeave, adaptOvertime, adaptReimb, adaptWorkspace } from './adapters';
import {
  decideLeave,
  decideOvertime,
  decideReimb,
  getLeaveInbox,
  getOvertimeInbox,
  getReimbInbox,
  getWorkspace,
} from '../services/hrms';
import { ApiError } from '../services/http';
import { useAuth } from './auth/AuthContext';

type LeaveStatusFilter = ReqStatus | 'all';
type FbStatusFilter = FeedbackStatus | 'all';

export type Store = ReturnType<typeof useProvideStore>;

const first = (name: string) => name.split(' ')[0];

function useProvideStore() {
  const { user, signOut } = useAuth();
  const managerName = user?.name ?? '';

  const [view, setViewRaw] = useState<View>('overview');
  const [toast, setToast] = useState('');
  const [loading, setLoading] = useState(true);
  const [loaded, setLoaded] = useState(false);
  const toastTimer = useRef<ReturnType<typeof setTimeout> | null>(null);

  // leave
  const [leaves, setLeaves] = useState<Leave[]>([]);
  const [leaveSearch, setLeaveSearch] = useState('');
  const [leaveStatus, setLeaveStatus] = useState<LeaveStatusFilter>('all');
  const [leaveType, setLeaveType] = useState('all');
  const [leaveSort, setLeaveSort] = useState('recent');
  const [drawerId, setDrawerId] = useState<string | null>(null);
  const [declineId, setDeclineId] = useState<string | null>(null);
  const [declineText, setDeclineText] = useState('');

  // feedback
  const [fbs, setFbs] = useState<Feedback[]>([]);
  const [fbSearch, setFbSearch] = useState('');
  const [fbStatus, setFbStatus] = useState<FbStatusFilter>('all');
  const [fbDrawerId, setFbDrawerId] = useState<string | null>(null);
  const [fbMgrs, setFbMgrs] = useState<FbMgr[]>([]);

  // reimbursements
  const [rbs, setRbs] = useState<Reimb[]>([]);
  const [rbSearch, setRbSearch] = useState('');
  const [rbStatus, setRbStatus] = useState<LeaveStatusFilter>('all');
  const [rbType, setRbType] = useState('all');
  const [rbSort, setRbSort] = useState('recent');
  const [rbDrawerId, setRbDrawerId] = useState<string | null>(null);
  const [rbDeclineId, setRbDeclineId] = useState<string | null>(null);
  const [rbDeclineText, setRbDeclineText] = useState('');

  // overtime
  const [ots, setOts] = useState<Overtime[]>([]);
  const [otSearch, setOtSearch] = useState('');
  const [otStatus, setOtStatus] = useState<LeaveStatusFilter>('all');
  const [otDrawerId, setOtDrawerId] = useState<string | null>(null);
  const [otDeclineId, setOtDeclineId] = useState<string | null>(null);
  const [otDeclineText, setOtDeclineText] = useState('');

  // employees
  const [emps, setEmps] = useState<Emp[]>([]);
  const [empSearch, setEmpSearch] = useState('');
  const [empTeam, setEmpTeam] = useState('all');
  const [empDrawerId, setEmpDrawerId] = useState<string | null>(null);
  const [addOpen, setAddOpen] = useState(false);
  const [form, setForm] = useState<UserForm>(emptyForm);

  const flash = useCallback((msg: string) => {
    setToast(msg);
    if (toastTimer.current) clearTimeout(toastTimer.current);
    toastTimer.current = setTimeout(() => setToast(''), 2600);
  }, []);

  const handleError = useCallback(
    (e: unknown) => {
      if (e instanceof ApiError && e.status === 401) {
        void signOut();
        return;
      }
      flash(e instanceof ApiError ? e.message : 'Something went wrong. Try again.');
    },
    [flash, signOut],
  );

  const reload = useCallback(async () => {
    if (!user) return;
    setLoading(true);
    try {
      const [lv, ot, rb, ws] = await Promise.all([
        getLeaveInbox(),
        getOvertimeInbox(),
        getReimbInbox(),
        getWorkspace(),
      ]);
      setLeaves(lv.map((d) => adaptLeave(d, user.name)));
      setOts(ot.map((d) => adaptOvertime(d, user.name)));
      setRbs(rb.map((d) => adaptReimb(d, user.name)));
      const w = adaptWorkspace(ws, user);
      setFbMgrs(w.fbMgrs);
      setFbs(w.fbs);
      setEmps(w.emps);
      setLoaded(true);
    } catch (e) {
      handleError(e);
    } finally {
      setLoading(false);
    }
  }, [user, handleError]);

  useEffect(() => {
    void reload();
  }, [reload]);

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

  // ---- leave ----
  const approve = async (id: string) => {
    const r = leaves.find((l) => l.id === id);
    setDrawerId(null);
    setDeclineId(null);
    try {
      const updated = await decideLeave(id, 'approved');
      setLeaves((s) => s.map((l) => (l.id === id ? adaptLeave(updated, managerName) : l)));
      flash(`${r ? first(r.name) : 'Leave'}’s leave approved`);
    } catch (e) {
      handleError(e);
    }
  };
  const openDecline = (id: string) => {
    setDeclineId(id);
    setDeclineText('');
  };
  const cancelDecline = () => {
    setDeclineId(null);
    setDeclineText('');
  };
  const confirmDecline = async (id: string) => {
    const txt = declineText.trim();
    const r = leaves.find((l) => l.id === id);
    setDeclineId(null);
    setDeclineText('');
    setDrawerId(null);
    try {
      const updated = await decideLeave(id, 'declined', txt || undefined);
      setLeaves((s) => s.map((l) => (l.id === id ? adaptLeave(updated, managerName) : l)));
      flash(`${r ? first(r.name) : 'Leave'}’s leave declined`);
    } catch (e) {
      handleError(e);
    }
  };

  // ---- reimbursements ----
  const rbApprove = async (id: string) => {
    const r = rbs.find((x) => x.id === id);
    setRbDrawerId(null);
    setRbDeclineId(null);
    try {
      const updated = await decideReimb(id, 'approved');
      setRbs((s) => s.map((x) => (x.id === id ? adaptReimb(updated, managerName) : x)));
      flash(`${r ? first(r.name) : 'Claim'}’s claim approved`);
    } catch (e) {
      handleError(e);
    }
  };
  const rbOpenDecline = (id: string) => {
    setRbDeclineId(id);
    setRbDeclineText('');
  };
  const rbCancelDecline = () => {
    setRbDeclineId(null);
    setRbDeclineText('');
  };
  const rbConfirmDecline = async (id: string) => {
    const r = rbs.find((x) => x.id === id);
    setRbDeclineId(null);
    setRbDeclineText('');
    setRbDrawerId(null);
    try {
      const updated = await decideReimb(id, 'declined');
      setRbs((s) => s.map((x) => (x.id === id ? adaptReimb(updated, managerName) : x)));
      flash(`${r ? first(r.name) : 'Claim'}’s claim declined`);
    } catch (e) {
      handleError(e);
    }
  };

  // ---- feedback reminders (client-side — no backend reminder endpoint) ----
  const remindMgr = (id: string) => {
    const m = fbMgrs.find((x) => x.id === id);
    setFbMgrs((s) => s.map((x) => (x.id === id ? { ...x, reminded: true } : x)));
    flash(`Reminder sent to ${m ? first(m.name) : 'manager'}`);
  };
  const remindAll = () => {
    const pend = fbMgrs.filter((m) => m.done < m.total);
    setFbMgrs((s) => s.map((m) => (m.done < m.total ? { ...m, reminded: true } : m)));
    flash(`Reminder sent to ${pend.length} manager${pend.length === 1 ? '' : 's'}`);
  };

  // ---- overtime ----
  const otApprove = async (id: string) => {
    const r = ots.find((x) => x.id === id);
    setOtDrawerId(null);
    setOtDeclineId(null);
    try {
      const updated = await decideOvertime(id, 'approved');
      setOts((s) => s.map((x) => (x.id === id ? adaptOvertime(updated, managerName) : x)));
      flash(`${r ? first(r.name) : 'Overtime'}’s overtime approved`);
    } catch (e) {
      handleError(e);
    }
  };
  const otOpenDecline = (id: string) => {
    setOtDeclineId(id);
    setOtDeclineText('');
  };
  const otCancelDecline = () => {
    setOtDeclineId(null);
    setOtDeclineText('');
  };
  const otConfirmDecline = async (id: string) => {
    const r = ots.find((x) => x.id === id);
    setOtDeclineId(null);
    setOtDeclineText('');
    setOtDrawerId(null);
    try {
      const updated = await decideOvertime(id, 'declined');
      setOts((s) => s.map((x) => (x.id === id ? adaptOvertime(updated, managerName) : x)));
      flash(`${r ? first(r.name) : 'Overtime'}’s overtime declined`);
    } catch (e) {
      handleError(e);
    }
  };

  // ---- employees (Add user is client-side; no create-employee endpoint yet) ----
  const setFormField = (k: keyof UserForm, v: string) => setForm((s) => ({ ...s, [k]: v }));
  const saveUser = () => {
    const f = form;
    if (!f.name.trim()) {
      flash('Please enter a name');
      return;
    }
    const emp: Emp = {
      id: `local-${emps.length + 1}`,
      name: f.name.trim(),
      role: f.role.trim() || '—',
      team: f.team,
      location: f.location,
      empType: f.empType,
      manager: f.manager,
      managerId: user?.id ?? '—',
      dob: f.dob.trim() || '—',
      joining: f.joining.trim() || '—',
      docs: 0,
    };
    setEmps((s) => [emp, ...s]);
    setAddOpen(false);
    setForm(emptyForm());
    flash(`${emp.name} added (local only — not yet saved to server)`);
  };

  // overview cross-navigation
  const goOvertimeRow = (id: string) => {
    closeAllOverlays();
    setViewRaw('overtime');
    setOtDrawerId(id);
  };
  const goReimbRow = (id: string) => {
    closeAllOverlays();
    setViewRaw('reimbursements');
    setRbDrawerId(id);
  };

  return {
    view, setView,
    toast, flash, loading, loaded, reload,
    user, signOut,
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
  return <Ctx.Provider value={store}>{children}</Ctx.Provider>;
}

export function useStore(): Store {
  const s = useContext(Ctx);
  if (!s) throw new Error('useStore must be used within StoreProvider');
  return s;
}
