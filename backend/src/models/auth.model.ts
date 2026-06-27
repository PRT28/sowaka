export interface OtpChallenge {
  email: string;
  otpHash: string;
  expiresAt: number;
  attempts: number;
  createdAt: number;
}

export interface AuthUser {
  id: string;
  email: string;
  name: string;
  role: 'manager' | 'employee';
  company: string;
}
