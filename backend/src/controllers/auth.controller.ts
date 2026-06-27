import { NextFunction, Request, Response } from 'express';
import { AuthError, requestLoginOtp, verifyLoginOtp } from '../services/auth.service';

export async function requestOtp(req: Request, res: Response, next: NextFunction) {
  try {
    const email = String(req.body.email ?? '');
    await requestLoginOtp(email);
    res.status(200).json({
      success: true,
      message: 'If the email is valid, a sign-in code has been sent.',
    });
  } catch (error) {
    handleAuthError(error, res, next);
  }
}

export async function verifyOtp(req: Request, res: Response, next: NextFunction) {
  try {
    const email = String(req.body.email ?? '');
    const otp = String(req.body.otp ?? '');
    const result = await verifyLoginOtp(email, otp);
    res.status(200).json({ success: true, ...result });
  } catch (error) {
    handleAuthError(error, res, next);
  }
}

function handleAuthError(error: unknown, res: Response, next: NextFunction) {
  if (error instanceof AuthError) {
    res.status(error.statusCode).json({ success: false, message: error.message });
    return;
  }
  next(error);
}
