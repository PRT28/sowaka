export interface OtpChallenge {
  email: string;
  otpHash: string;
  expiresAt: number;
  attempts: number;
  createdAt: number;
}

/** Shape returned to clients (mobile app) on successful auth. */
export interface AuthUser {
  id: string;
  email: string;
  name: string;
  role: 'manager' | 'employee';
  company: string;
}
