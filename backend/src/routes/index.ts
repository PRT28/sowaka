import { Router } from 'express';
import { authRouter } from './auth.routes';
import { companyRouter } from './company.routes';
import { healthRouter } from './health.routes';
import { leaveRouter } from './leave.routes';
import { userRouter } from './user.routes';

export const router = Router();

router.use('/auth', authRouter);
router.use('/health', healthRouter);
router.use('/users', userRouter);
router.use('/leaves', leaveRouter);
router.use('/companies', companyRouter);
