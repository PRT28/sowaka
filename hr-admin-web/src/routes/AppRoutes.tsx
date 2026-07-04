import { Navigate, Route, Routes } from 'react-router-dom';
import { HrDashboard } from '../dashboard/HrDashboard';
import { Login } from '../pages/Login';

export function AppRoutes() {
  return (
    <Routes>
      <Route path="/login" element={<Login />} />
      <Route path="/dashboard" element={<HrDashboard />} />
      <Route path="*" element={<Navigate to="/dashboard" replace />} />
    </Routes>
  );
}
