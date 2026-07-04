import crypto from 'crypto';
import { env } from '../config/env';
import { authSessions, otpChallenges, users } from '../config/db';
import { AuthUser } from '../models/auth.model';
import { User } from '../models/user.model';
import { generateOtp, hashOtp, isValidEmail } from '../utils/otp.util';
import { sendOtpEmail } from './email.service';

const defaultCompany = 'Sowaka';

const maxAttempts = 5;

export async function requestLoginOtp(emailInput: string): Promise<void> {
  const email = normalizeEmail(emailInput);
  if (!isValidEmail(email)) {
    throw new AuthError(400, 'Please enter a valid work email');
  }
  await requireEligibleUser(email);

  const otp = generateOtp();
  const now = Date.now();
  await otpChallenges().updateOne(
    { email },
    {
      $set: {
        email,
        otpHash: hashOtp(email, otp),
        expiresAt: now + env.otpTtlMinutes * 60 * 1000,
        attempts: 0,
        createdAt: now,
      },
    },
    { upsert: true },
  );

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

  const existingUser = await requireEligibleUser(email);

  const challenge = await otpChallenges().findOne({ email });
  if (!challenge) {
    throw new AuthError(400, 'Code expired or not requested');
  }

  if (challenge.expiresAt < Date.now()) {
    await otpChallenges().deleteOne({ email });
    throw new AuthError(400, 'Code expired');
  }

  if (challenge.attempts >= maxAttempts) {
    await otpChallenges().deleteOne({ email });
    throw new AuthError(429, 'Too many attempts. Request a new code');
  }

  const expectedHash = challenge.otpHash;
  const actualHash = hashOtp(email, otp);
  const valid =
    env.otpDevBypass && otp === '123456' ? true : timingSafeEqualHex(expectedHash, actualHash);

  if (!valid) {
    await otpChallenges().updateOne({ email }, { $inc: { attempts: 1 } });
    throw new AuthError(401, 'Incorrect code');
  }

  await otpChallenges().deleteOne({ email });

  const user = await completeLogin(existingUser);
  const token = crypto.randomBytes(32).toString('hex');
  await authSessions().insertOne({
    tokenHash: hashSessionToken(token),
    userId: user.id,
    createdAt: new Date(),
    expiresAt: new Date(Date.now() + env.authSessionTtlDays * 24 * 60 * 60 * 1000),
  });
  return { token, user };
}

export async function revokeSession(token: string): Promise<void> {
  if (token) {
    await authSessions().deleteOne({ tokenHash: hashSessionToken(token) });
  }
}

export function hashSessionToken(token: string): string {
  return crypto.createHash('sha256').update(token).digest('hex');
}

function normalizeEmail(email: string): string {
  return email.trim().toLowerCase();
}

async function requireEligibleUser(email: string): Promise<User> {
  const user = await users().findOne({ email });
  if (!user) {
    throw new AuthError(403, 'This email is not registered. Contact HR for access');
  }
  if (user.lifecycleStatus === 'offboarded' || user.lifecycleStatus === 'terminated') {
    throw new AuthError(403, 'This employee account is not active');
  }
  return user;
}

async function completeLogin(user: User): Promise<AuthUser> {
  const role = (await users().countDocuments({ managerUserId: user.userId }, { limit: 1 }))
    ? 'manager'
    : 'employee';

  const now = new Date();
  await users().updateOne(
    { userId: user.userId },
    { $set: { role, lastLoginAt: now, updatedAt: now } },
  );

  return toAuthUser({ ...user, role });
}

function toAuthUser(user: User): AuthUser {
  return {
    id: user.userId,
    email: user.email,
    name: user.name,
    role: user.role ?? 'employee',
    company: user.org ?? defaultCompany,
  };
}

function timingSafeEqualHex(a: string, b: string): boolean {
  const bufA = Buffer.from(a, 'hex');
  const bufB = Buffer.from(b, 'hex');
  if (bufA.length !== bufB.length) {
    return false;
  }
  return crypto.timingSafeEqual(bufA, bufB);
}

export class AuthError extends Error {
  constructor(
    public readonly statusCode: number,
    message: string,
  ) {
    super(message);
  }
}
