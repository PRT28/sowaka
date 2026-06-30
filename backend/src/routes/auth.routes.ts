import { Router } from 'express';
import { me, requestOtp, verifyOtp } from '../controllers/auth.controller';
import { requireAuth } from '../middleware/auth.middleware';

export const authRouter = Router();

authRouter.post('/request-otp', requestOtp);
authRouter.post('/verify-otp', verifyOtp);
authRouter.get('/me', requireAuth, me);
