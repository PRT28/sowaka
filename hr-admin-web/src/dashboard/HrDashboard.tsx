import { StoreProvider, useStore } from './store';
import { AuthProvider, useAuth } from './auth/AuthContext';
import { LoginScreen } from './auth/LoginScreen';
import { Sidebar, Topbar, Toast } from './Chrome';
import { Overview } from './views/Overview';
import { LeaveRequests } from './views/LeaveRequests';
import { Overtime } from './views/Overtime';
import { Feedback } from './views/Feedback';
import { Reimbursements } from './views/Reimbursements';
import { Employees } from './views/Employees';
import { Placeholder } from './views/Placeholder';
import { Drawers } from './drawers';

function CurrentView() {
  const { view } = useStore();
  switch (view) {
    case 'overview':
      return <Overview />;
    case 'leave':
      return <LeaveRequests />;
    case 'overtime':
      return <Overtime />;
    case 'feedback':
      return <Feedback />;
    case 'reimbursements':
      return <Reimbursements />;
    case 'employees':
      return <Employees />;
    default:
      return <Placeholder />;
  }
}

function LoadingBar() {
  return (
    <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'center', minHeight: 400, color: '#A89C8B', fontSize: 13.5, fontWeight: 600 }}>
      <span style={{ width: 16, height: 16, border: '2px solid #E2D8C8', borderTopColor: '#BE5A36', borderRadius: '50%', display: 'inline-block', marginRight: 10, animation: 'spin .7s linear infinite' }} />
      Loading…
    </div>
  );
}

function Shell() {
  const { loading, loaded } = useStore();
  return (
    <div style={{ display: 'flex', height: '100vh', width: '100%', background: '#F3EDE3', overflow: 'hidden' }}>
      <Sidebar />
      <main className="scry" style={{ flex: 1, overflowY: 'auto', display: 'flex', flexDirection: 'column' }}>
        <Topbar />
        <div style={{ padding: '28px 34px 60px', flex: 1 }}>
          {loading && !loaded ? <LoadingBar /> : <CurrentView />}
        </div>
      </main>
      <Drawers />
      <Toast />
    </div>
  );
}

function AccessDenied() {
  const { user, signOut } = useAuth();
  return (
    <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', height: '100vh', background: '#F3EDE3', color: '#4A4034', textAlign: 'center', padding: 24 }}>
      <div style={{ fontSize: 44, marginBottom: 12 }}>🔒</div>
      <h1 style={{ fontSize: 22, fontWeight: 800, margin: 0 }}>No dashboard access</h1>
      <p style={{ maxWidth: 420, marginTop: 10, fontSize: 14.5, lineHeight: 1.5, color: '#8A7E6C' }}>
        Your account{user?.email ? ` (${user.email})` : ''} isn’t authorized to use the HR dashboard.
        Ask an administrator to grant you dashboard access.
      </p>
      <button
        onClick={() => void signOut()}
        style={{ marginTop: 22, padding: '10px 20px', borderRadius: 10, border: '1px solid #E2D8C8', background: '#fff', color: '#4A4034', fontWeight: 700, fontSize: 13.5, cursor: 'pointer' }}
      >
        Sign out
      </button>
    </div>
  );
}

function Gate() {
  const { user } = useAuth();
  if (!user) return <LoginScreen />;
  // Rule 4: the dashboard is only for select users granted dashboard access.
  if (!user.dashboardAccess) return <AccessDenied />;
  return (
    <StoreProvider>
      <Shell />
    </StoreProvider>
  );
}

export function HrDashboard() {
  return (
    <AuthProvider>
      <Gate />
    </AuthProvider>
  );
}
