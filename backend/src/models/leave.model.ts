export type LeaveStatus = 'pending' | 'approved' | 'declined';

export interface Leave {
  userId: string; // -> User.userId
  startDate: Date;
  endDate: Date;
  status: LeaveStatus;
  managerNote?: string;
  createdAt?: number;
  updatedAt?: Date;
}
