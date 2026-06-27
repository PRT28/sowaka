import { Router } from 'express';
import { requestOtp, verifyOtp } from '../controllers/auth.controller';

export const authRouter = Router();

authRouter.post('/request-otp', requestOtp);
authRouter.post('/verify-otp', verifyOtp);
