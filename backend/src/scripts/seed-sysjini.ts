import crypto from 'node:crypto';
import { closeDb, companies, connectDb, users } from '../config/db';
import { User } from '../models/user.model';
import { assignManager } from '../services/reporting.service';
import { logger } from '../utils/logger';

const companyId = 'sysjini';
const employeeEmail = 'prithvirajtiwari28@gmail.com';
const managerEmail = 'prithvi.raj@sysjini.in';

async function seed(): Promise<void> {
  await connectDb();
  const now = new Date();

  await companies().updateOne(
    { id: companyId },
    {
      $set: { name: 'sysjini', updatedAt: now },
      $setOnInsert: { id: companyId, createdAt: Date.now() },
    },
    { upsert: true },
  );

  const employee = createUser({
    email: employeeEmail,
    name: 'Prithviraj Tiwari',
    employeeId: 'SYS-001',
    role: 'employee',
  });
  const manager = createUser({
    email: managerEmail,
    name: 'Prithvi Raj',
    employeeId: 'SYS-002',
    role: 'manager',
  });

  for (const user of [employee, manager]) {
    await users().updateOne(
      { email: user.email },
      {
        $set: {
          userId: user.userId,
          employeeId: user.employeeId,
          name: user.name,
          email: user.email,
          lifecycleStatus: user.lifecycleStatus,
          onboardingStatus: user.onboardingStatus,
          role: user.role,
          org: user.org,
          updatedAt: now,
        },
        $setOnInsert: { createdAt: Date.now() },
      },
      { upsert: true },
    );
  }

  await assignManager(employee.userId, manager.userId);

  logger.info('Sysjini seed completed', {
    companyId,
    employeeUserId: employee.userId,
    managerUserId: manager.userId,
  });
}

function createUser(input: {
  email: string;
  name: string;
  employeeId: string;
  role: 'manager' | 'employee';
}): User {
  return {
    ...input,
    userId: crypto.createHash('sha1').update(input.email).digest('hex').slice(0, 12),
    lifecycleStatus: 'active',
    onboardingStatus: 'completed',
    noticeStatus: 'none',
    employeeType: 'full_time',
    org: companyId,
  };
}

seed()
  .catch((error) => {
    logger.error('Sysjini seed failed', {}, error);
    process.exitCode = 1;
  })
  .finally(async () => {
    await closeDb();
  });
