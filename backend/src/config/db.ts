import { webcrypto } from 'node:crypto';

// MongoDB's SCRAM auth relies on the Web Crypto global, which Node < 20 does not
// expose by default. Polyfill it before any driver connection runs. (Harmless on Node 20+.)
if (!globalThis.crypto) {
  (globalThis as typeof globalThis & { crypto: Crypto }).crypto = webcrypto as unknown as Crypto;
}

import { Collection, Db, MongoClient } from 'mongodb';
import { env } from './env';
import { OtpChallenge } from '../models/auth.model';
import { User } from '../models/user.model';
import { Leave } from '../models/leave.model';
import { Company } from '../models/company.model';

let client: MongoClient | null = null;
let db: Db | null = null;

export async function connectDb(): Promise<Db> {
  if (db) return db;
  if (!env.mongoUri) {
    throw new Error('MONGODB_URI is not configured');
  }

  client = new MongoClient(env.mongoUri);
  await client.connect();
  db = client.db(env.mongoDbName);
  await ensureIndexes(db);
  return db;
}

export function getDb(): Db {
  if (!db) {
    throw new Error('Database not connected. Call connectDb() first.');
  }
  return db;
}

export function otpChallenges(): Collection<OtpChallenge> {
  return getDb().collection<OtpChallenge>('otp_challenges');
}

export function users(): Collection<User> {
  return getDb().collection<User>('users');
}

export function leaves(): Collection<Leave> {
  return getDb().collection<Leave>('leaves');
}

export function companies(): Collection<Company> {
  return getDb().collection<Company>('companies');
}

async function ensureIndexes(database: Db): Promise<void> {
  await database
    .collection<OtpChallenge>('otp_challenges')
    .createIndex({ email: 1 }, { unique: true });

  const usersCollection = database.collection<User>('users');
  // Legacy index from the earlier auth-only schema (keyed on `id`); replaced by `userId`.
  await usersCollection.dropIndex('id_1').catch(() => undefined);
  await usersCollection.createIndex({ email: 1 }, { unique: true });
  await usersCollection.createIndex({ userId: 1 }, { unique: true });
  await usersCollection.createIndex({ employeeId: 1 }, { unique: true, sparse: true });
  await usersCollection.createIndex({ managerUserId: 1 });
  await usersCollection.createIndex({ org: 1 });
  await usersCollection.createIndex({ department: 1 });

  const leavesCollection = database.collection<Leave>('leaves');
  await leavesCollection.createIndex({ userId: 1 });
  await leavesCollection.createIndex({ status: 1 });
  await leavesCollection.createIndex({ userId: 1, startDate: -1 });

  await database.collection<Company>('companies').createIndex({ id: 1 }, { unique: true });
}

export async function closeDb(): Promise<void> {
  if (client) {
    await client.close();
    client = null;
    db = null;
  }
}
