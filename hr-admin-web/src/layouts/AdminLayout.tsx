import { NavLink, Outlet } from 'react-router-dom';

export function AdminLayout() {
  return (
    <div className="admin-shell">
      <aside className="sidebar">
        <h1>HR Admin</h1>
        <nav>
          <NavLink to="/dashboard">Dashboard</NavLink>
        </nav>
      </aside>
      <main className="content">
        <Outlet />
      </main>
    </div>
  );
}
