import { Router } from 'express';
import { requireAuth } from '../middleware/auth.middleware';
import { authRouter } from './auth.routes';
import { companyRouter } from './company.routes';
import { healthRouter } from './health.routes';
import { leaveRouter } from './leave.routes';
import { userRouter } from './user.routes';

export const router = Router();

// Public
router.use('/auth', authRouter);
router.use('/health', healthRouter);

// Protected
router.use('/users', requireAuth, userRouter);
router.use('/leaves', requireAuth, leaveRouter);
router.use('/companies', requireAuth, companyRouter);
