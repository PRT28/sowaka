export type LeaveStatus = 'pending' | 'approved' | 'declined';

export interface Leave {
  userId: string; // -> User.userId
  type: 'sick' | 'casual' | 'earned';
  startDate: Date;
  endDate: Date;
  reason: string;
  status: LeaveStatus;
  managerNote?: string;
  decidedByUserId?: string; // -> User.userId
  decidedByRole?: 'manager' | 'admin'; // 'admin' = overridden from the HR dashboard
  decidedAt?: Date;
  createdAt?: number;
  updatedAt?: Date;
}
