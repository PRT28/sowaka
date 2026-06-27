import crypto from 'crypto';
import { env } from '../config/env';
import { AuthUser, OtpChallenge } from '../models/auth.model';
import { generateOtp, hashOtp, isValidEmail } from '../utils/otp.util';
import { sendOtpEmail } from './email.service';

const otpChallenges = new Map<string, OtpChallenge>();
const maxAttempts = 5;

export async function requestLoginOtp(emailInput: string): Promise<void> {
  const email = normalizeEmail(emailInput);
  if (!isValidEmail(email)) {
    throw new AuthError(400, 'Please enter a valid work email');
  }

  const otp = generateOtp();
  otpChallenges.set(email, {
    email,
    otpHash: hashOtp(email, otp),
    expiresAt: Date.now() + env.otpTtlMinutes * 60 * 1000,
    attempts: 0,
    createdAt: Date.now(),
  });

  await sendOtpEmail(email, otp);
}

export async function verifyLoginOtp(
  emailInput: string,
  otpInput: string,
): Promise<{ token: string; user: AuthUser }> {
  const email = normalizeEmail(emailInput);
  const otp = otpInput.trim();

  if (!isValidEmail(email) || !/^\d{6}$/.test(otp)) {
    throw new AuthError(400, 'Invalid email or code');
  }

  const challenge = otpChallenges.get(email);
  if (!challenge) {
    throw new AuthError(400, 'Code expired or not requested');
  }

  if (challenge.expiresAt < Date.now()) {
    otpChallenges.delete(email);
    throw new AuthError(400, 'Code expired');
  }

  if (challenge.attempts >= maxAttempts) {
    otpChallenges.delete(email);
    throw new AuthError(429, 'Too many attempts. Request a new code');
  }

  const expectedHash = challenge.otpHash;
  const actualHash = hashOtp(email, otp);
  const valid =
    env.otpDevBypass && otp === '123456'
      ? true
      : crypto.timingSafeEqual(Buffer.from(expectedHash, 'hex'), Buffer.from(actualHash, 'hex'));

  if (!valid) {
    otpChallenges.set(email, {
      ...challenge,
      attempts: challenge.attempts + 1,
    });
    throw new AuthError(401, 'Incorrect code');
  }

  otpChallenges.delete(email);

  const user = buildUser(email);
  const token = crypto.randomBytes(32).toString('hex');
  return { token, user };
}

function normalizeEmail(email: string): string {
  return email.trim().toLowerCase();
}

function buildUser(email: string): AuthUser {
  const local = email.split('@')[0] || 'user';
  const name = local
    .split(/[._-]/)
    .filter(Boolean)
    .map((part) => part[0].toUpperCase() + part.slice(1))
    .join(' ');

  return {
    id: crypto.createHash('sha1').update(email).digest('hex').slice(0, 12),
    email,
    name: name || 'Manager',
    role: 'manager',
    company: 'Sowaka',
  };
}

export class AuthError extends Error {
  constructor(
    public readonly statusCode: number,
    message: string,
  ) {
    super(message);
  }
}
