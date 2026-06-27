enum ManagerTab { manage, grow, games, attendance }

enum ManagerView { home, feedbackList, feedbackRecord }

enum FeedbackStatus { pending, saved, sent, missed }

enum LeaveDecision { pending, approved, declined }

class FeedbackParam {
  const FeedbackParam({
    required this.name,
    required this.score,
    required this.note,
  });

  final String name;
  final double score;
  final String note;

  FeedbackParam copyWith({String? name, double? score, String? note}) {
    return FeedbackParam(
      name: name ?? this.name,
      score: score ?? this.score,
      note: note ?? this.note,
    );
  }
}

class TeamMember {
  const TeamMember({
    required this.id,
    required this.name,
    required this.initial,
    required this.team,
    required this.score,
    required this.next,
    required this.status,
    required this.missedMonths,
    required this.avatarIndex,
    required this.params,
    required this.extra,
  });

  final int id;
  final String name;
  final String initial;
  final String team;
  final double score;
  final DateTime next;
  final FeedbackStatus status;
  final int missedMonths;
  final int avatarIndex;
  final List<FeedbackParam> params;
  final String extra;

  TeamMember copyWith({
    double? score,
    FeedbackStatus? status,
    List<FeedbackParam>? params,
    String? extra,
  }) {
    return TeamMember(
      id: id,
      name: name,
      initial: initial,
      team: team,
      score: score ?? this.score,
      next: next,
      status: status ?? this.status,
      missedMonths: missedMonths,
      avatarIndex: avatarIndex,
      params: params ?? this.params,
      extra: extra ?? this.extra,
    );
  }
}

class LeaveRequest {
  const LeaveRequest({
    required this.id,
    required this.who,
    required this.initial,
    required this.avatarIndex,
    required this.type,
    required this.start,
    required this.end,
    required this.days,
    required this.reason,
    required this.requestedOn,
    required this.decision,
  });

  final String id;
  final String who;
  final String initial;
  final int avatarIndex;
  final String type;
  final DateTime start;
  final DateTime end;
  final int days;
  final String reason;
  final DateTime requestedOn;
  final LeaveDecision decision;

  LeaveRequest copyWith({LeaveDecision? decision}) {
    return LeaveRequest(
      id: id,
      who: who,
      initial: initial,
      avatarIndex: avatarIndex,
      type: type,
      start: start,
      end: end,
      days: days,
      reason: reason,
      requestedOn: requestedOn,
      decision: decision ?? this.decision,
    );
  }
}

class AwardNomination {
  const AwardNomination({
    required this.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.nomineeId,
  });

  final String key;
  final String title;
  final String subtitle;
  final String icon;
  final int? nomineeId;

  AwardNomination copyWith({int? nomineeId}) {
    return AwardNomination(
      key: key,
      title: title,
      subtitle: subtitle,
      icon: icon,
      nomineeId: nomineeId ?? this.nomineeId,
    );
  }
}

class ManagerDashboard {
  const ManagerDashboard({
    required this.managerName,
    required this.managerInitial,
    required this.managerTeam,
    required this.managerScore,
    required this.today,
    required this.team,
    required this.leaves,
    required this.awards,
  });

  final String managerName;
  final String managerInitial;
  final String managerTeam;
  final double managerScore;
  final DateTime today;
  final List<TeamMember> team;
  final List<LeaveRequest> leaves;
  final List<AwardNomination> awards;

  ManagerDashboard copyWith({
    List<TeamMember>? team,
    List<LeaveRequest>? leaves,
    List<AwardNomination>? awards,
  }) {
    return ManagerDashboard(
      managerName: managerName,
      managerInitial: managerInitial,
      managerTeam: managerTeam,
      managerScore: managerScore,
      today: today,
      team: team ?? this.team,
      leaves: leaves ?? this.leaves,
      awards: awards ?? this.awards,
    );
  }
}
