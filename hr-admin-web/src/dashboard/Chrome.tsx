// Sidebar, topbar and toast — the persistent shell around the views.
import type { ReactNode } from 'react';
import type { View } from './theme';
import { TITLES } from './theme';
import { IconBell, IconCheck, IconLogout, IconSearch, Logo, navIcon } from './icons';
import { useStore } from './store';

type NavItem = { key: View; label: string };

const PEOPLE_OPS: NavItem[] = [
  { key: 'overview', label: 'Overview' },
  { key: 'leave', label: 'Leave requests' },
  { key: 'overtime', label: 'Overtime' },
  { key: 'attendance', label: 'Attendance' },
  { key: 'feedback', label: 'Feedback' },
  { key: 'reimbursements', label: 'Reimbursements' },
  { key: 'onboarding', label: 'Onboarding' },
  { key: 'exit', label: 'Exit' },
  { key: 'payroll', label: 'Payroll' },
];
const ORGANISATION: NavItem[] = [
  { key: 'employees', label: 'Employees' },
  { key: 'orgchart', label: 'Org chart' },
];
const SOON: Partial<Record<View, boolean>> = { attendance: true, onboarding: true, exit: true, payroll: true };

function CountBadge({ value, danger }: { value: number; danger?: boolean }) {
  return (
    <span
      style={{
        marginLeft: 'auto',
        fontSize: 11,
        fontWeight: 700,
        background: danger ? '#C4382E' : '#EEE3D2',
        color: danger ? '#fff' : '#9A6B25',
        borderRadius: 20,
        padding: '1px 7px',
      }}
    >
      {value}
    </span>
  );
}

function SoonBadge() {
  return (
    <span
      style={{
        marginLeft: 'auto',
        fontSize: 9.5,
        fontWeight: 700,
        letterSpacing: '.4px',
        color: '#B7AC9B',
        border: '1px solid #E2D8C8',
        borderRadius: 20,
        padding: '1px 7px',
      }}
    >
      SOON
    </span>
  );
}

function NavButton({ item, badge }: { item: NavItem; badge?: ReactNode }) {
  const { view, setView } = useStore();
  const active = view === item.key;
  const soon = SOON[item.key];
  return (
    <button
      onClick={() => setView(item.key)}
      style={{
        display: 'flex',
        alignItems: 'center',
        gap: 11,
        width: '100%',
        padding: '9px 12px',
        border: 'none',
        borderRadius: 11,
        cursor: 'pointer',
        fontSize: 13.5,
        textAlign: 'left',
        transition: 'background .15s',
        background: active ? '#F7E7DE' : 'transparent',
        color: active ? '#A34B2B' : soon ? '#B7AC9B' : '#6E6457',
        fontWeight: active ? 700 : 600,
      }}
    >
      {navIcon[item.key]}
      {item.label}
      {badge}
    </button>
  );
}

export function Sidebar() {
  const { leaves, ots, rbs, fbMgrs, user, signOut } = useStore();
  const displayName = user?.name ?? 'HR Admin';
  const roleLabel = user ? `${user.role[0].toUpperCase()}${user.role.slice(1)} · ${user.company}` : 'HR Admin';
  const userInitials = displayName
    .trim()
    .split(/\s+/)
    .slice(0, 2)
    .map((p) => p[0])
    .join('')
    .toUpperCase();
  const leavesPending = leaves.filter((l) => l.status === 'Pending').length;
  const otPending = ots.filter((o) => o.status === 'Pending').length;
  const claims = rbs.filter((r) => r.status === 'Pending').length;
  const reviewsPending = fbMgrs.reduce((s, m) => s + (m.total - m.done), 0);

  const badgeFor = (key: View): ReactNode => {
    switch (key) {
      case 'leave':
        return <CountBadge value={leavesPending} />;
      case 'overtime':
        return <CountBadge value={otPending} />;
      case 'feedback':
        return <CountBadge value={reviewsPending} />;
      case 'reimbursements':
        return <CountBadge value={claims} danger />;
      default:
        return SOON[key] ? <SoonBadge /> : null;
    }
  };

  return (
    <aside
      style={{
        width: 244,
        flexShrink: 0,
        background: '#FBF7F0',
        borderRight: '1px solid #ECE2D4',
        display: 'flex',
        flexDirection: 'column',
        padding: '20px 14px 14px',
      }}
    >
      <div style={{ display: 'flex', alignItems: 'center', gap: 11, padding: '6px 8px 18px' }}>
        <div
          style={{
            width: 34,
            height: 34,
            borderRadius: 10,
            background: '#BE5A36',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            flexShrink: 0,
            boxShadow: '0 2px 6px rgba(190,90,54,.28)',
          }}
        >
          <Logo />
        </div>
        <div>
          <div style={{ fontSize: 15.5, fontWeight: 800, letterSpacing: '-.3px', lineHeight: 1 }}>Sowaka</div>
          <div style={{ fontSize: 11, fontWeight: 600, color: '#A89C8B', marginTop: 3, letterSpacing: '.2px' }}>Convrse Spaces</div>
        </div>
      </div>

      <div className="scry" style={{ flex: 1, overflowY: 'auto', display: 'flex', flexDirection: 'column', gap: 2, paddingTop: 4 }}>
        <div style={{ fontSize: 10.5, fontWeight: 700, letterSpacing: '.7px', color: '#BCB1A0', padding: '8px 12px 6px' }}>PEOPLE OPS</div>
        {PEOPLE_OPS.map((item) => (
          <NavButton key={item.key} item={item} badge={badgeFor(item.key)} />
        ))}
        <div style={{ fontSize: 10.5, fontWeight: 700, letterSpacing: '.7px', color: '#BCB1A0', padding: '16px 12px 6px' }}>ORGANISATION</div>
        {ORGANISATION.map((item) => (
          <NavButton key={item.key} item={item} badge={badgeFor(item.key)} />
        ))}
      </div>

      <button
        onClick={() => void signOut()}
        title="Sign out"
        style={{ display: 'flex', alignItems: 'center', gap: 10, padding: '11px 10px', marginTop: 8, width: '100%', background: 'none', border: 'none', borderTop: '1px solid #ECE2D4', cursor: 'pointer', textAlign: 'left' }}
      >
        <div
          style={{
            width: 33,
            height: 33,
            borderRadius: '50%',
            background: '#7C7A52',
            color: '#fff',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            fontWeight: 700,
            fontSize: 13,
            flexShrink: 0,
          }}
        >
          {userInitials}
        </div>
        <div style={{ minWidth: 0, flex: 1 }}>
          <div style={{ fontSize: 13, fontWeight: 700, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{displayName}</div>
          <div style={{ fontSize: 11, color: '#A89C8B', fontWeight: 500, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{roleLabel}</div>
        </div>
        <IconLogout />
      </button>
    </aside>
  );
}

export function Topbar() {
  const { view } = useStore();
  const [title, meta] = TITLES[view];
  return (
    <header
      style={{
        position: 'sticky',
        top: 0,
        zIndex: 30,
        background: 'rgba(243,237,227,.82)',
        backdropFilter: 'blur(10px)',
        borderBottom: '1px solid #E9DFD0',
        padding: '15px 34px',
        display: 'flex',
        alignItems: 'center',
        gap: 20,
      }}
    >
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{ fontSize: 11.5, fontWeight: 600, color: '#A89C8B', letterSpacing: '.2px' }}>{meta}</div>
        <div style={{ fontSize: 19, fontWeight: 800, letterSpacing: '-.4px', marginTop: 1 }}>{title}</div>
      </div>
      <div style={{ display: 'flex', alignItems: 'center', background: '#fff', border: '1px solid #EBE1D2', borderRadius: 11, padding: '8px 13px', gap: 9, width: 248 }}>
        <IconSearch />
        <input placeholder="Search people, requests…" style={{ border: 'none', outline: 'none', background: 'none', fontSize: 13, width: '100%', color: '#2A2420' }} />
      </div>
      <button
        style={{
          position: 'relative',
          width: 40,
          height: 40,
          borderRadius: 11,
          border: '1px solid #EBE1D2',
          background: '#fff',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          cursor: 'pointer',
        }}
      >
        <IconBell />
        <span style={{ position: 'absolute', top: 9, right: 10, width: 7, height: 7, background: '#BE5A36', borderRadius: '50%', border: '1.5px solid #fff' }} />
      </button>
    </header>
  );
}

export function Toast() {
  const { toast } = useStore();
  if (!toast) return null;
  return (
    <div
      style={{
        position: 'fixed',
        bottom: 26,
        left: '50%',
        transform: 'translateX(-50%)',
        zIndex: 90,
        background: '#2A2420',
        color: '#fff',
        borderRadius: 13,
        padding: '13px 20px',
        fontSize: 13.5,
        fontWeight: 600,
        boxShadow: '0 12px 30px rgba(42,36,32,.32)',
        display: 'flex',
        alignItems: 'center',
        gap: 10,
        animation: 'tst .24s ease both',
      }}
    >
      <IconCheck size={17} stroke="#7FBF82" />
      {toast}
    </div>
  );
}
