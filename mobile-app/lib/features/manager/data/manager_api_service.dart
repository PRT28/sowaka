import 'manager_models.dart';

class ManagerApiService {
  const ManagerApiService();

  Future<ManagerDashboard> fetchDashboard() async {
    await Future<void>.delayed(const Duration(milliseconds: 450));

    return ManagerDashboard(
      managerName: 'Arjun Mehta',
      managerInitial: 'A',
      managerTeam: 'Engineering',
      managerScore: 4.4,
      today: DateTime(2026, 6, 24),
      team: _team,
      leaves: _leaves,
      awards: _awards,
    );
  }

  Future<void> saveFeedback() async {
    await Future<void>.delayed(const Duration(milliseconds: 280));
  }

  Future<void> decideLeave() async {
    await Future<void>.delayed(const Duration(milliseconds: 220));
  }

  Future<void> nominateAward() async {
    await Future<void>.delayed(const Duration(milliseconds: 220));
  }

  Future<void> submitLeaveApplication() async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
  }
}

final List<TeamMember> _team = <TeamMember>[
  _member(1, 'Prashant Kumar', 'Engineering', 4.5, '2026-07-05', 'sent', 0),
  _member(2, 'Sneha Sharma', 'Design', 3.4, '2026-05-02', 'missed', 2),
  _member(3, 'Rahul Mehta', 'Engineering', 4.1, '2026-06-25', 'pending', 0),
  _member(4, 'Kabir Singh', 'Sales', 3.9, '2026-06-26', 'pending', 0),
  _member(5, 'Tara Nair', 'Marketing', 4.3, '2026-06-27', 'pending', 0),
  _member(6, 'Aditya Rao', 'Engineering', 4.0, '2026-05-30', 'missed', 1),
  _member(7, 'Meera Iyer', 'Design', 4.6, '2026-07-12', 'sent', 0),
  _member(8, 'Vikram Joshi', 'Sales', 3.7, '2026-06-28', 'pending', 0),
  _member(9, 'Ananya Bose', 'Support', 4.2, '2026-05-28', 'missed', 1),
  _member(10, 'Rohan Gupta', 'Engineering', 4.4, '2026-07-02', 'pending', 0),
  _member(11, 'Priya Menon', 'Marketing', 3.8, '2026-06-26', 'pending', 0),
  _member(12, 'Arjun Reddy', 'Operations', 4.1, '2026-07-09', 'sent', 0),
  _member(13, 'Isha Kapoor', 'Design', 4.5, '2026-07-14', 'pending', 0),
  _member(14, 'Karthik Nair', 'Engineering', 3.6, '2026-06-27', 'pending', 0),
  _member(15, 'Divya Pillai', 'Support', 4.0, '2026-07-03', 'pending', 0),
  _member(16, 'Nikhil Verma', 'Sales', 4.2, '2026-05-29', 'missed', 1),
  _member(17, 'Sanya Malhotra', 'Finance', 4.7, '2026-07-16', 'pending', 0),
  _member(18, 'Aman Khanna', 'Engineering', 3.9, '2026-06-28', 'pending', 0),
  _member(19, 'Riya Sen', 'People', 4.3, '2026-07-06', 'sent', 0),
  _member(20, 'Siddharth Jain', 'Operations', 4.0, '2026-07-11', 'pending', 0),
  _member(21, 'Pooja Desai', 'Marketing', 4.4, '2026-07-15', 'pending', 0),
  _member(22, 'Varun Shetty', 'Engineering', 3.5, '2026-06-25', 'pending', 0),
  _member(23, 'Neha Aggarwal', 'Support', 4.1, '2026-07-04', 'pending', 0),
  _member(24, 'Manish Tiwari', 'Sales', 3.8, '2026-07-08', 'pending', 0),
  _member(25, 'Lakshmi Krishnan', 'Finance', 4.6, '2026-07-07', 'sent', 0),
  _member(26, 'Gaurav Bhatt', 'Engineering', 4.0, '2026-07-13', 'pending', 0),
  _member(27, 'Tanvi Shah', 'Design', 4.5, '2026-07-10', 'sent', 0),
  _member(28, 'Harsh Patel', 'Operations', 3.7, '2026-07-17', 'pending', 0),
  _member(29, 'Aisha Khan', 'People', 4.2, '2026-07-18', 'pending', 0),
  _member(30, 'Dev Saxena', 'Engineering', 4.3, '2026-06-26', 'pending', 0),
];

TeamMember _member(
  int id,
  String name,
  String team,
  double score,
  String next,
  String status,
  int missed,
) {
  final feedbackStatus = switch (status) {
    'sent' => FeedbackStatus.sent,
    'missed' => FeedbackStatus.missed,
    'saved' => FeedbackStatus.saved,
    _ => FeedbackStatus.pending,
  };
  return TeamMember(
    id: id,
    name: name,
    initial: name[0],
    team: team,
    score: score,
    next: DateTime.parse(next),
    status: feedbackStatus,
    missedMonths: missed,
    avatarIndex: (id - 1) % 7,
    params: _params(feedbackStatus),
    extra: '',
  );
}

List<FeedbackParam> _params(FeedbackStatus status) {
  final started = status != FeedbackStatus.pending;
  return <FeedbackParam>[
    FeedbackParam(
      name: 'Ownership Mindset',
      score: started ? 4.0 : 0,
      note: started ? 'Took responsibility for key follow-through items.' : '',
    ),
    FeedbackParam(
      name: 'Communication Clarity',
      score: started ? 3.5 : 0,
      note: started ? 'Written updates were clear and timely.' : '',
    ),
    FeedbackParam(
      name: 'Quality of Work',
      score: started ? 4.0 : 0,
      note: started ? 'Reliable output with few rework loops.' : '',
    ),
    FeedbackParam(
      name: 'Collaboration',
      score: started ? 4.0 : 0,
      note: started ? 'Supported teammates during delivery pressure.' : '',
    ),
  ];
}

final List<LeaveRequest> _leaves = <LeaveRequest>[
  LeaveRequest(
    id: 'l1',
    who: 'Sneha Sharma',
    initial: 'S',
    avatarIndex: 5,
    type: 'Sick',
    start: DateTime(2026, 6, 25),
    end: DateTime(2026, 6, 26),
    days: 2,
    reason: 'Down with fever',
    requestedOn: DateTime(2026, 6, 23),
    decision: LeaveDecision.pending,
  ),
  LeaveRequest(
    id: 'l2',
    who: 'Tara Nair',
    initial: 'T',
    avatarIndex: 4,
    type: 'Casual',
    start: DateTime(2026, 7, 1),
    end: DateTime(2026, 7, 3),
    days: 3,
    reason: 'Family function out of town',
    requestedOn: DateTime(2026, 6, 22),
    decision: LeaveDecision.pending,
  ),
  LeaveRequest(
    id: 'l3',
    who: 'Prashant Kumar',
    initial: 'P',
    avatarIndex: 1,
    type: 'Earned',
    start: DateTime(2026, 7, 14),
    end: DateTime(2026, 7, 18),
    days: 5,
    reason: 'Planned vacation',
    requestedOn: DateTime(2026, 6, 20),
    decision: LeaveDecision.pending,
  ),
];

const List<AwardNomination> _awards = <AwardNomination>[
  AwardNomination(
    key: 'artist',
    title: 'Best Artist',
    subtitle: 'Standout craft this month',
    icon: 'palette',
  ),
  AwardNomination(
    key: 'mentor',
    title: 'Best Mentor',
    subtitle: 'Lifted others up',
    icon: 'school',
  ),
  AwardNomination(
    key: 'culture',
    title: 'Culture Champion',
    subtitle: 'Lived the team values',
    icon: 'heart',
  ),
  AwardNomination(
    key: 'rising',
    title: 'Rising Star',
    subtitle: 'Fastest growth',
    icon: 'star',
  ),
];
