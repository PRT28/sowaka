// View-model types for the dashboard. Data now comes from the live API
// (see services/hrms.ts + adapters.ts); ids are backend ObjectId hex / userId strings.
import type { EmpType, FeedbackStatus, LeaveType, OtDuration, ReqStatus } from './theme';

export type Leave = {
  id: string;
  name: string;
  team: string;
  type: LeaveType;
  from: string;
  to: string;
  days: string;
  dayN: number;
  status: ReqStatus;
  manager: string;
  applied: string;
  ord: number;
  eRemark: string;
  mRemark: string;
};

export type Overtime = {
  id: string;
  name: string;
  team: string;
  appliedOn: string;
  otDate: string;
  duration: OtDuration;
  day: string;
  status: ReqStatus;
  manager: string;
  mRemark: string;
  ord: number;
};

export type FbMgr = {
  id: string;
  name: string;
  scope: string;
  done: number;
  total: number;
  reminded: boolean;
};

export type Feedback = {
  id: string;
  name: string;
  team: string;
  manager: string;
  parameter: string;
  rating: number;
  status: FeedbackStatus;
  date: string;
  ord: number;
  text: string;
};

export type Reimb = {
  id: string;
  name: string;
  team: string;
  manager: string;
  type: string;
  amount: string;
  amountN: number;
  billDate: string;
  applyDate: string;
  status: ReqStatus;
  bill: string;
  hasBill?: boolean;
  ord: number;
  mRemark: string;
};

export type Emp = {
  id: string;
  name: string;
  role: string;
  team: string;
  location: string;
  empType: EmpType;
  manager: string;
  managerId: string;
  dob: string;
  joining: string;
  docs: number;
};

export type UserForm = {
  name: string;
  role: string;
  team: string;
  location: string;
  empType: EmpType;
  manager: string;
  joining: string;
  dob: string;
};

export const DOCS = [
  'Offer letter.pdf',
  'Aadhaar card.pdf',
  'PAN card.pdf',
  'Bank details.pdf',
  'Education certificate.pdf',
  'Experience letter.pdf',
  'Address proof.pdf',
  'Form 16.pdf',
];

export const emptyForm = (): UserForm => ({
  name: '',
  role: '',
  team: 'Design',
  location: 'Bengaluru',
  empType: 'Full-time',
  manager: 'Aanya Verma',
  joining: '',
  dob: '',
});
