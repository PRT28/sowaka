export type OvertimeStatus = 'pending' | 'approved' | 'declined';

export interface OvertimeRequest {
  userId: string;
  managerUserId: string;
  workDate: Date;
  duration: 'half_day' | 'full_day';
  hours: number;
  project: string;
  note?: string;
  managerNote?: string;
  status: OvertimeStatus;
  decidedByUserId?: string;
  decidedByRole?: 'manager' | 'admin'; // 'admin' = overridden from the HR dashboard
  decidedAt?: Date;
  createdAt: Date;
  updatedAt: Date;
}
