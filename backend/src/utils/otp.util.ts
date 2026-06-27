import crypto from 'crypto';

export function generateOtp(): string {
  return crypto.randomInt(100000, 999999).toString();
}

export function hashOtp(email: string, otp: string): string {
  return crypto.createHash('sha256').update(`${email.toLowerCase()}:${otp}`).digest('hex');
}

export function isValidEmail(email: string): boolean {
  return /^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(email);
}
