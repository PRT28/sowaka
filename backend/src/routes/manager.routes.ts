import { Router } from 'express';
import {
  managerWorkspace,
  saveManagerFeedback,
  saveRecognitionNomination,
} from '../controllers/manager.controller';
import { requireAuth } from '../middleware/auth.middleware';

export const managerRouter = Router();
managerRouter.use(requireAuth);
managerRouter.get('/workspace', managerWorkspace);
managerRouter.put('/feedback/:employeeUserId', saveManagerFeedback);
managerRouter.put('/recognition/:category', saveRecognitionNomination);

