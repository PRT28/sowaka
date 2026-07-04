// Seed data — mirrors the design handoff exactly.
import type {
  EmpType,
  FeedbackStatus,
  LeaveType,
  OtDuration,
  ReqStatus,
} from './theme';

export type Leave = {
  id: number;
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
  id: number;
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
  id: number;
  name: string;
  scope: string;
  done: number;
  total: number;
  reminded: boolean;
};

export type Feedback = {
  id: number;
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
  id: number;
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

export const seedLeaves = (): Leave[] => [
  { id: 1, name: 'Sneha Sharma', team: 'Design', type: 'Sick', from: '25 Jun', to: '26 Jun', days: '2 days', dayN: 2, status: 'Pending', manager: 'Aanya Verma', applied: '24 Jun', ord: 9, eRemark: 'Down with a fever, will share the medical note by evening.', mRemark: '' },
  { id: 2, name: 'Rahul Mehta', team: 'Engineering', type: 'Casual', from: '1 Jul', to: '3 Jul', days: '3 days', dayN: 3, status: 'Pending', manager: 'Aanya Verma', applied: '22 Jun', ord: 7, eRemark: 'Family function out of town, travelling with parents.', mRemark: '' },
  { id: 3, name: 'Kabir Singh', team: 'Sales', type: 'Earned', from: '8 Jul', to: '12 Jul', days: '5 days', dayN: 5, status: 'Approved', manager: 'Imran Qureshi', applied: '20 Jun', ord: 5, eRemark: 'Annual trip — flights already booked.', mRemark: 'Approved. Please complete a handover note before you leave.' },
  { id: 4, name: 'Prashant Kumar', team: 'Engineering', type: 'WFH', from: '30 Jun', to: '30 Jun', days: '1 day', dayN: 1, status: 'Pending', manager: 'Aanya Verma', applied: '28 Jun', ord: 10, eRemark: 'Plumber visit at home, will be fully available online.', mRemark: '' },
  { id: 5, name: 'Tara Nair', team: 'Marketing', type: 'Casual', from: '18 Jun', to: '18 Jun', days: '1 day', dayN: 1, status: 'Declined', manager: 'Imran Qureshi', applied: '16 Jun', ord: 3, eRemark: 'Personal errand in the afternoon.', mRemark: 'Campaign launch week — please reschedule to after the 25th.' },
  { id: 6, name: 'Meera Reddy', team: 'Operations', type: 'Earned', from: '15 Jul', to: '19 Jul', days: '5 days', dayN: 5, status: 'Approved', manager: 'Aanya Verma', applied: '19 Jun', ord: 4, eRemark: 'Wedding in the family.', mRemark: 'Approved — enjoy the celebrations!' },
  { id: 7, name: 'Arjun Pillai', team: 'Finance', type: 'Sick', from: '26 Jun', to: '26 Jun', days: '1 day', dayN: 1, status: 'Approved', manager: 'Imran Qureshi', applied: '26 Jun', ord: 8, eRemark: 'Severe migraine, unable to work today.', mRemark: 'Approved. Get well soon.' },
  { id: 8, name: 'Nikhil Rao', team: 'Design', type: 'Unpaid', from: '22 Jul', to: '26 Jul', days: '5 days', dayN: 5, status: 'Pending', manager: 'Aanya Verma', applied: '27 Jun', ord: 6, eRemark: 'Extended personal leave to attend to family matters.', mRemark: '' },
];

export const seedOt = (): Overtime[] => [
  { id: 1, name: 'Rahul Mehta', team: 'Engineering', appliedOn: '24 Jun', otDate: '22 Jun', duration: 'Full day', day: 'Sat', status: 'Pending', manager: 'Aanya Verma', mRemark: '', ord: 9 },
  { id: 2, name: 'Kabir Singh', team: 'Sales', appliedOn: '20 Jun', otDate: '19 Jun', duration: 'Half day', day: 'Wed', status: 'Approved', manager: 'Imran Qureshi', mRemark: 'Approved — client demo prep.', ord: 6 },
  { id: 3, name: 'Prashant Kumar', team: 'Engineering', appliedOn: '28 Jun', otDate: '27 Jun', duration: 'Full day', day: 'Fri', status: 'Pending', manager: 'Aanya Verma', mRemark: '', ord: 10 },
  { id: 4, name: 'Meera Reddy', team: 'Operations', appliedOn: '18 Jun', otDate: '16 Jun', duration: 'Half day', day: 'Sun', status: 'Approved', manager: 'Aanya Verma', mRemark: 'Approved.', ord: 5 },
  { id: 5, name: 'Tara Nair', team: 'Marketing', appliedOn: '15 Jun', otDate: '14 Jun', duration: 'Full day', day: 'Sat', status: 'Declined', manager: 'Imran Qureshi', mRemark: 'Comp-off was already taken for this date.', ord: 3 },
  { id: 6, name: 'Arjun Pillai', team: 'Finance', appliedOn: '26 Jun', otDate: '25 Jun', duration: 'Half day', day: 'Wed', status: 'Pending', manager: 'Imran Qureshi', mRemark: '', ord: 8 },
];

export const seedFbMgrs = (): FbMgr[] => [
  { id: 1, name: 'Aanya Verma', scope: 'Design · Engineering · Ops', done: 6, total: 8, reminded: false },
  { id: 2, name: 'Imran Qureshi', scope: 'Sales · Marketing · Finance', done: 2, total: 7, reminded: false },
  { id: 3, name: 'Devika Iyer', scope: 'Product · Data', done: 5, total: 5, reminded: false },
  { id: 4, name: 'Rohan Bhatia', scope: 'Customer Success', done: 0, total: 4, reminded: false },
];

export const seedFb = (): Feedback[] => [
  { id: 1, name: 'Sneha Sharma', team: 'Design', manager: 'Aanya Verma', parameter: 'Craft', rating: 4.7, status: 'Submitted', date: '24 Jun', ord: 9, text: 'Visual quality is consistently exceptional and raises the bar for the whole team. Next, push on documenting design decisions so engineering can self-serve.' },
  { id: 2, name: 'Meera Reddy', team: 'Operations', manager: 'Aanya Verma', parameter: 'Ownership', rating: 4.6, status: 'Acknowledged', date: '20 Jun', ord: 7, text: 'Takes end-to-end accountability without being asked. Handled the vendor escalation calmly and kept everyone informed.' },
  { id: 3, name: 'Rahul Mehta', team: 'Engineering', manager: 'Aanya Verma', parameter: 'Communication', rating: 3.8, status: 'Submitted', date: '22 Jun', ord: 8, text: 'Clear and concise in standups. Would like to see decisions written down in the RFC doc rather than only in chat.' },
  { id: 4, name: 'Kabir Singh', team: 'Sales', manager: 'Imran Qureshi', parameter: 'Delivery', rating: 4.2, status: 'Acknowledged', date: '19 Jun', ord: 5, text: 'Closed the quarter strong and beat the target by 12%. Strong follow-through on the enterprise pipeline.' },
  { id: 5, name: 'Tara Nair', team: 'Marketing', manager: 'Imran Qureshi', parameter: 'Collaboration', rating: 3.5, status: 'Pending', date: '16 Jun', ord: 3, text: 'Great peer support across the launch. Keep an eye on timelines — two deliverables slipped this cycle.' },
  { id: 6, name: 'Prashant Kumar', team: 'Engineering', manager: 'Aanya Verma', parameter: 'Initiative', rating: 4.0, status: 'Pending', date: '18 Jun', ord: 4, text: 'Proactively picked up the infra migration nobody owned. Document the runbook so it is not a single point of failure.' },
  { id: 7, name: 'Arjun Pillai', team: 'Finance', manager: 'Imran Qureshi', parameter: 'Ownership', rating: 4.4, status: 'Draft', date: '26 Jun', ord: 6, text: 'Owns the monthly books cleanly and is dependable on close. Draft — pending review before sharing.' },
];

export const seedRb = (): Reimb[] => [
  { id: 1, name: 'Rahul Mehta', team: 'Engineering', manager: 'Aanya Verma', type: 'Travel', amount: '₹4,200', amountN: 4200, billDate: '12 Jun', applyDate: '14 Jun', status: 'Pending', bill: 'cab-invoice.pdf', ord: 9, mRemark: '' },
  { id: 2, name: 'Sneha Sharma', team: 'Design', manager: 'Aanya Verma', type: 'Software', amount: '₹1,899', amountN: 1899, billDate: '1 Jun', applyDate: '2 Jun', status: 'Approved', bill: 'figma-receipt.pdf', ord: 4, mRemark: 'Approved — recurring tool.' },
  { id: 3, name: 'Kabir Singh', team: 'Sales', manager: 'Imran Qureshi', type: 'Meals', amount: '₹2,650', amountN: 2650, billDate: '10 Jun', applyDate: '11 Jun', status: 'Pending', bill: 'client-dinner.jpg', ord: 7, mRemark: '' },
  { id: 4, name: 'Meera Reddy', team: 'Operations', manager: 'Aanya Verma', type: 'Internet', amount: '₹999', amountN: 999, billDate: '5 Jun', applyDate: '6 Jun', status: 'Approved', bill: 'broadband.pdf', ord: 5, mRemark: 'Approved.' },
  { id: 5, name: 'Tara Nair', team: 'Marketing', manager: 'Imran Qureshi', type: 'Training', amount: '₹7,500', amountN: 7500, billDate: '28 May', applyDate: '30 May', status: 'Declined', bill: 'course-invoice.pdf', ord: 2, mRemark: 'Out of the L&D budget this quarter — resubmit next quarter.' },
  { id: 6, name: 'Prashant Kumar', team: 'Engineering', manager: 'Aanya Verma', type: 'Hardware', amount: '₹3,400', amountN: 3400, billDate: '8 Jun', applyDate: '9 Jun', status: 'Pending', bill: 'keyboard.pdf', ord: 8, mRemark: '' },
  { id: 7, name: 'Arjun Pillai', team: 'Finance', manager: 'Imran Qureshi', type: 'Travel', amount: '₹5,120', amountN: 5120, billDate: '15 Jun', applyDate: '16 Jun', status: 'Pending', bill: 'flight-ticket.pdf', ord: 10, mRemark: '' },
  { id: 8, name: 'Nikhil Rao', team: 'Design', manager: 'Aanya Verma', type: 'Software', amount: '₹2,499', amountN: 2499, billDate: '3 Jun', applyDate: '4 Jun', status: 'Approved', bill: 'license.pdf', ord: 3, mRemark: 'Approved.' },
];

export const seedEmp = (): Emp[] => [
  { id: 'EMP-014', name: 'Sneha Sharma', role: 'Product Designer', team: 'Design', location: 'Bengaluru', empType: 'Full-time', manager: 'Aanya Verma', managerId: 'EMP-001', dob: '12 Mar 1995', joining: '4 Aug 2022', docs: 5 },
  { id: 'EMP-021', name: 'Rahul Mehta', role: 'Software Engineer', team: 'Engineering', location: 'Bengaluru', empType: 'Full-time', manager: 'Aanya Verma', managerId: 'EMP-001', dob: '8 Jul 1993', joining: '18 Jan 2021', docs: 6 },
  { id: 'EMP-033', name: 'Kabir Singh', role: 'Account Executive', team: 'Sales', location: 'Mumbai', empType: 'Full-time', manager: 'Imran Qureshi', managerId: 'EMP-002', dob: '22 Nov 1990', joining: '9 Mar 2020', docs: 4 },
  { id: 'EMP-045', name: 'Prashant Kumar', role: 'DevOps Engineer', team: 'Engineering', location: 'Remote', empType: 'Full-time', manager: 'Aanya Verma', managerId: 'EMP-001', dob: '2 Feb 1992', joining: '12 Jun 2023', docs: 5 },
  { id: 'EMP-052', name: 'Tara Nair', role: 'Marketing Lead', team: 'Marketing', location: 'Delhi', empType: 'Full-time', manager: 'Imran Qureshi', managerId: 'EMP-002', dob: '30 Sep 1991', joining: '1 Feb 2019', docs: 7 },
  { id: 'EMP-061', name: 'Meera Reddy', role: 'Operations Manager', team: 'Operations', location: 'Bengaluru', empType: 'Full-time', manager: 'Aanya Verma', managerId: 'EMP-001', dob: '14 May 1988', joining: '20 Jul 2018', docs: 8 },
  { id: 'EMP-070', name: 'Arjun Pillai', role: 'Finance Analyst', team: 'Finance', location: 'Mumbai', empType: 'Contract', manager: 'Imran Qureshi', managerId: 'EMP-002', dob: '6 Dec 1994', joining: '5 Sep 2023', docs: 3 },
  { id: 'EMP-078', name: 'Nikhil Rao', role: 'UX Designer', team: 'Design', location: 'Remote', empType: 'Intern', manager: 'Aanya Verma', managerId: 'EMP-001', dob: '19 Aug 2000', joining: '15 Jan 2024', docs: 2 },
];

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
