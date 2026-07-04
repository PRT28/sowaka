export type ReimbursementStatus = 'pending' | 'approved' | 'declined' | 'paid';

export interface ReimbursementClaim {
  userId: string;
  managerUserId: string;
  expenseDate: Date;
  amount: number;
  category: 'travel' | 'meals' | 'internet' | 'other';
  receiptName?: string;
  note?: string;
  status: ReimbursementStatus;
  decidedByUserId?: string;
  decidedAt?: Date;
  paidAt?: Date;
  createdAt: Date;
  updatedAt: Date;
}

