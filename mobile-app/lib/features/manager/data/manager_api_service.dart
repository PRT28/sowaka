import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../services/api_config.dart';
import '../../auth/data/auth_models.dart';
import 'manager_models.dart';

class ManagerApiService {
  ManagerApiService({
    required this.session,
    String? baseUrl,
    http.Client? client,
  }) : _baseUrl = baseUrl ?? ApiConfig.baseUrl,
       _client = client ?? http.Client();

  final AuthSession session;
  final String _baseUrl;
  final http.Client _client;

  Future<ManagerDashboard> fetchDashboard() async {
    final workspaceFuture = _request('GET', '/manager/workspace');
    final myLeavesFuture = fetchMyLeaves();
    final managerLeavesFuture = fetchManagerLeaves();
    final balanceFuture = _request('GET', '/leaves/balance');
    final myOvertimeFuture = fetchMyOvertime();
    final overtimeFuture = fetchManagerOvertime();
    final reimbursementsFuture = fetchMyReimbursements();
    final workspace = await workspaceFuture;
    final teamValues = workspace['team'] as List<dynamic>? ?? const [];
    final team = teamValues.indexed.map((entry) {
      return TeamMember.fromJson(
        entry.$2 as Map<String, dynamic>,
        entry.$1 + 1,
      );
    }).toList();
    final candidateValues =
        workspace['recognitionCandidates'] as List<dynamic>? ?? const [];
    final recognitionCandidates = candidateValues.indexed.map((entry) {
      return TeamMember.fromJson(
        entry.$2 as Map<String, dynamic>,
        entry.$1 + 1,
      );
    }).toList();
    final nominations = workspace['nominations'] as List<dynamic>? ?? const [];
    final nomineeByCategory = <String, int>{};
    for (final value in nominations) {
      final nomination = value as Map<String, dynamic>;
      final userId = nomination['employeeUserId'] as String?;
      final member = recognitionCandidates
          .where((item) => item.userId == userId)
          .firstOrNull;
      if (member != null) {
        nomineeByCategory[nomination['category'] as String] = member.id;
      }
    }

    return ManagerDashboard(
      managerName: session.user.name,
      managerInitial: session.user.name.isEmpty ? '?' : session.user.name[0],
      managerTeam: session.user.company,
      approverName: workspace['approverName'] as String? ?? 'Your manager',
      managerScore: (workspace['managerScore'] as num?)?.toDouble() ?? 0,
      today: DateTime.now(),
      team: team,
      recognitionCandidates: recognitionCandidates,
      leaves: await managerLeavesFuture,
      myLeaves: await myLeavesFuture,
      awards: _awardDefinitions
          .map(
            (award) => award.copyWith(nomineeId: nomineeByCategory[award.key]),
          )
          .toList(),
      leaveBalance: LeaveBalance.fromJson(
        (await balanceFuture)['balance'] as Map<String, dynamic>,
      ),
      overtime: await overtimeFuture,
      myOvertime: await myOvertimeFuture,
      myReimbursements: await reimbursementsFuture,
    );
  }

  Future<List<LeaveRequest>> fetchMyLeaves() async {
    final json = await _request('GET', '/leaves/mine');
    return _parseLeaves(json);
  }

  Future<List<LeaveRequest>> fetchManagerLeaves() async {
    final json = await _request('GET', '/leaves/inbox');
    return _parseLeaves(json);
  }

  Future<void> saveFeedback({
    required TeamMember member,
    required FeedbackStatus status,
    required List<FeedbackParam> params,
    required String extra,
  }) async {
    await _request(
      'PUT',
      '/manager/feedback/${member.userId}',
      body: {
        'status': status.name,
        'parameters': params
            .map(
              (param) => {
                'name': param.name,
                'score': param.score,
                'note': param.note,
              },
            )
            .toList(),
        'extra': extra,
      },
    );
  }

  Future<LeaveRequest> decideLeave(
    String leaveId,
    LeaveDecision decision,
  ) async {
    final json = await _request(
      'PATCH',
      '/leaves/$leaveId/decision',
      body: {'decision': decision.name},
    );
    return LeaveRequest.fromJson(json['leave'] as Map<String, dynamic>);
  }

  Future<void> nominateAward(String awardKey, TeamMember member) async {
    await _request(
      'PUT',
      '/manager/recognition/$awardKey',
      body: {'employeeUserId': member.userId},
    );
  }

  Future<LeaveRequest> submitLeaveApplication({
    required String type,
    required DateTime startDate,
    required DateTime endDate,
    required String reason,
  }) async {
    final json = await _request(
      'POST',
      '/leaves',
      body: {
        'type': type.toLowerCase(),
        'startDate': _dateOnly(startDate),
        'endDate': _dateOnly(endDate),
        'reason': reason,
      },
    );
    return LeaveRequest.fromJson(json['leave'] as Map<String, dynamic>);
  }

  Future<List<OvertimeRequest>> fetchMyOvertime() async {
    final json = await _request('GET', '/overtime/mine');
    return _parseOvertime(json);
  }

  Future<List<OvertimeRequest>> fetchManagerOvertime() async {
    final json = await _request('GET', '/overtime/inbox');
    return _parseOvertime(json);
  }

  Future<OvertimeRequest> submitOvertime({
    required DateTime workDate,
    required String duration,
    required String project,
    required String note,
  }) async {
    final json = await _request(
      'POST',
      '/overtime',
      body: {
        'workDate': _dateOnly(workDate),
        'duration': duration == 'Full day' ? 'full_day' : 'half_day',
        'project': project,
        'note': note,
      },
    );
    return OvertimeRequest.fromJson(json['overtime'] as Map<String, dynamic>);
  }

  Future<OvertimeRequest> decideOvertimeRequest(
    String overtimeId,
    LeaveDecision decision,
  ) async {
    final json = await _request(
      'PATCH',
      '/overtime/$overtimeId/decision',
      body: {'decision': decision.name},
    );
    return OvertimeRequest.fromJson(json['overtime'] as Map<String, dynamic>);
  }

  Future<List<ReimbursementClaim>> fetchMyReimbursements() async {
    final json = await _request('GET', '/reimbursements/mine');
    final values = json['claims'] as List<dynamic>? ?? const [];
    return values
        .map(
          (value) => ReimbursementClaim.fromJson(value as Map<String, dynamic>),
        )
        .toList();
  }

  Future<ReimbursementClaim> submitReimbursement({
    required DateTime expenseDate,
    required String amount,
    required String category,
    required String receiptName,
    required String note,
  }) async {
    final json = await _request(
      'POST',
      '/reimbursements',
      body: {
        'expenseDate': _dateOnly(expenseDate),
        'amount': double.tryParse(amount.replaceAll(',', '')),
        'category': category.toLowerCase(),
        'receiptName': receiptName,
        'note': note,
      },
    );
    return ReimbursementClaim.fromJson(json['claim'] as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final request = http.Request(method, Uri.parse('$_baseUrl$path'))
      ..headers.addAll({
        'Authorization': 'Bearer ${session.token}',
        'Content-Type': 'application/json',
      });
    if (body != null) request.body = jsonEncode(body);

    final streamed = await _client.send(request);
    final response = await http.Response.fromStream(streamed);
    final json = response.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ManagerApiException(json['message'] as String? ?? 'Request failed');
    }
    return json;
  }
}

List<LeaveRequest> _parseLeaves(Map<String, dynamic> json) {
  final values = json['leaves'] as List<dynamic>? ?? const [];
  return values
      .map((value) => LeaveRequest.fromJson(value as Map<String, dynamic>))
      .toList();
}

List<OvertimeRequest> _parseOvertime(Map<String, dynamic> json) {
  final values = json['overtime'] as List<dynamic>? ?? const [];
  return values
      .map((value) => OvertimeRequest.fromJson(value as Map<String, dynamic>))
      .toList();
}

String _dateOnly(DateTime value) {
  final date = DateTime(value.year, value.month, value.day);
  return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

class ManagerApiException implements Exception {
  const ManagerApiException(this.message);
  final String message;

  @override
  String toString() => message;
}

const List<AwardNomination> _awardDefinitions = <AwardNomination>[
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
