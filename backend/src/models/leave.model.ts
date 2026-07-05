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
  decidedAt?: Date;
  createdAt?: number;
  updatedAt?: Date;
}
