export type FeedbackRecordStatus = 'saved' | 'sent';

export interface FeedbackParameter {
  name: string;
  score: number;
  note: string;
}

export interface FeedbackRecord {
  managerUserId: string;
  employeeUserId: string;
  period: string;
  status: FeedbackRecordStatus;
  parameters: FeedbackParameter[];
  extra: string;
  overallScore: number;
  createdAt: Date;
  updatedAt: Date;
  sentAt?: Date;
}

