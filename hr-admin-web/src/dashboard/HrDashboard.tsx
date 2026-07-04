import { StoreProvider, useStore } from './store';
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

function Shell() {
  return (
    <div style={{ display: 'flex', height: '100vh', width: '100%', background: '#F3EDE3', overflow: 'hidden' }}>
      <Sidebar />
      <main className="scry" style={{ flex: 1, overflowY: 'auto', display: 'flex', flexDirection: 'column' }}>
        <Topbar />
        <div style={{ padding: '28px 34px 60px', flex: 1 }}>
          <CurrentView />
        </div>
      </main>
      <Drawers />
      <Toast />
    </div>
  );
}

export function HrDashboard() {
  return (
    <StoreProvider>
      <Shell />
    </StoreProvider>
  );
}
