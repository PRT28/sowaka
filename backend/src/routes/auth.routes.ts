import { Router } from 'express';
import { logout, requestOtp, verifyOtp } from '../controllers/auth.controller';
import { requireAuth } from '../middleware/auth.middleware';

export const authRouter = Router();

authRouter.post('/request-otp', requestOtp);
authRouter.post('/verify-otp', verifyOtp);
authRouter.post('/logout', requireAuth, logout);
