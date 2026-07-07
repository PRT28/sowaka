import { Router } from 'express';
import { requireDashboardAccess } from '../middleware/admin.middleware';
import { requireAuth } from '../middleware/auth.middleware';
import {
  clearEmployeeManager,
  getEmployeeManager,
  listManagerEmployees,
  setEmployeeManager,
} from '../controllers/reporting.controller';

export const reportingRouter = Router();

reportingRouter.use(requireAuth, requireDashboardAccess);
reportingRouter.get('/employees/:employeeUserId/manager', getEmployeeManager);
reportingRouter.put('/employees/:employeeUserId/manager', setEmployeeManager);
reportingRouter.delete('/employees/:employeeUserId/manager', clearEmployeeManager);
reportingRouter.get('/managers/:managerUserId/employees', listManagerEmployees);
