import { Router } from 'express';
import { currentUser, logout, requestOtp, verifyOtp } from '../controllers/auth.controller';
import { requireAuth } from '../middleware/auth.middleware';

export const authRouter = Router();

authRouter.post('/request-otp', requestOtp);
authRouter.post('/verify-otp', verifyOtp);
authRouter.get('/me', requireAuth, currentUser);
authRouter.post('/logout', requireAuth, logout);
