import 'dart:async';

import '../../auth/data/auth_models.dart';
import '../data/manager_api_service.dart';
import '../data/manager_models.dart';

enum ManagerLoadStatus { initial, loading, ready, failure }

enum FeedbackFilter { all, overdue, soon }

class ManagerState {
  const ManagerState({
    required this.status,
    required this.tab,
    required this.view,
    required this.canManage,
    this.dashboard,
    this.selectedMemberId,
    this.recordParams = const <FeedbackParam>[],
    this.recordExtra = '',
    this.feedbackFilter = FeedbackFilter.all,
    this.searchQuery = '',
    this.showGiven = false,
    this.awardPickerKey,
    this.applyLeaveOpen = false,
    this.applyLeaveSent = false,
    this.message,
    this.error,
  });

  factory ManagerState.initial({required bool canManage}) {
    return ManagerState(
      status: ManagerLoadStatus.initial,
      tab: canManage ? ManagerTab.manage : ManagerTab.grow,
      view: ManagerView.home,
      canManage: canManage,
    );
  }

  final ManagerLoadStatus status;
  final ManagerTab tab;
  final ManagerView view;
  final bool canManage;
  final ManagerDashboard? dashboard;
  final int? selectedMemberId;
  final List<FeedbackParam> recordParams;
  final String recordExtra;
  final FeedbackFilter feedbackFilter;
  final String searchQuery;
  final bool showGiven;
  final String? awardPickerKey;
  final bool applyLeaveOpen;
  final bool applyLeaveSent;
  final String? message;
  final String? error;

  TeamMember? get selectedMember {
    final data = dashboard;
    final id = selectedMemberId;
    if (data == null || id == null) return null;
    for (final member in data.team) {
      if (member.id == id) return member;
    }
    return null;
  }

  ManagerState copyWith({
    ManagerLoadStatus? status,
    ManagerTab? tab,
    ManagerView? view,
    bool? canManage,
    ManagerDashboard? dashboard,
    int? selectedMemberId,
    bool clearSelectedMember = false,
    List<FeedbackParam>? recordParams,
    String? recordExtra,
    FeedbackFilter? feedbackFilter,
    String? searchQuery,
    bool? showGiven,
    String? awardPickerKey,
    bool clearAwardPicker = false,
    bool? applyLeaveOpen,
    bool? applyLeaveSent,
    String? message,
    bool clearMessage = false,
    String? error,
  }) {
    return ManagerState(
      status: status ?? this.status,
      tab: tab ?? this.tab,
      view: view ?? this.view,
      canManage: canManage ?? this.canManage,
      dashboard: dashboard ?? this.dashboard,
      selectedMemberId: clearSelectedMember
          ? null
          : selectedMemberId ?? this.selectedMemberId,
      recordParams: recordParams ?? this.recordParams,
      recordExtra: recordExtra ?? this.recordExtra,
      feedbackFilter: feedbackFilter ?? this.feedbackFilter,
      searchQuery: searchQuery ?? this.searchQuery,
      showGiven: showGiven ?? this.showGiven,
      awardPickerKey: clearAwardPicker
          ? null
          : awardPickerKey ?? this.awardPickerKey,
      applyLeaveOpen: applyLeaveOpen ?? this.applyLeaveOpen,
      applyLeaveSent: applyLeaveSent ?? this.applyLeaveSent,
      message: clearMessage ? null : message ?? this.message,
      error: error ?? this.error,
    );
  }
}

sealed class ManagerEvent {
  const ManagerEvent();
}

class LoadManagerDashboard extends ManagerEvent {
  const LoadManagerDashboard();
}

class ChangeManagerTab extends ManagerEvent {
  const ChangeManagerTab(this.tab);
  final ManagerTab tab;
}

class OpenFeedbackList extends ManagerEvent {
  const OpenFeedbackList();
}

class CloseFeedbackList extends ManagerEvent {
  const CloseFeedbackList();
}

class OpenFeedbackRecord extends ManagerEvent {
  const OpenFeedbackRecord(this.memberId);
  final int memberId;
}

class CloseFeedbackRecord extends ManagerEvent {
  const CloseFeedbackRecord();
}

class ChangeFeedbackFilter extends ManagerEvent {
  const ChangeFeedbackFilter(this.filter);
  final FeedbackFilter filter;
}

class ChangeFeedbackSearch extends ManagerEvent {
  const ChangeFeedbackSearch(this.query);
  final String query;
}

class ToggleGivenFeedback extends ManagerEvent {
  const ToggleGivenFeedback();
}

class UpdateFeedbackScore extends ManagerEvent {
  const UpdateFeedbackScore(this.index, this.score);
  final int index;
  final double score;
}

class UpdateFeedbackNote extends ManagerEvent {
  const UpdateFeedbackNote(this.index, this.note);
  final int index;
  final String note;
}

class UpdateFeedbackExtra extends ManagerEvent {
  const UpdateFeedbackExtra(this.extra);
  final String extra;
}

class SaveFeedback extends ManagerEvent {
  const SaveFeedback();
}

class SendFeedback extends ManagerEvent {
  const SendFeedback();
}

class DecideLeave extends ManagerEvent {
  const DecideLeave(this.leaveId, this.decision);
  final String leaveId;
  final LeaveDecision decision;
}

class DecideOvertime extends ManagerEvent {
  const DecideOvertime(this.overtimeId, this.decision);
  final String overtimeId;
  final LeaveDecision decision;
}

class OpenAwardPicker extends ManagerEvent {
  const OpenAwardPicker(this.awardKey);
  final String awardKey;
}

class CloseAwardPicker extends ManagerEvent {
  const CloseAwardPicker();
}

class NominateAward extends ManagerEvent {
  const NominateAward(this.awardKey, this.memberId);
  final String awardKey;
  final int memberId;
}

class OpenApplyLeave extends ManagerEvent {
  const OpenApplyLeave();
}

class CloseApplyLeave extends ManagerEvent {
  const CloseApplyLeave();
}

class SubmitLeaveApplication extends ManagerEvent {
  const SubmitLeaveApplication({
    required this.type,
    required this.startDate,
    required this.endDate,
    required this.reason,
  });

  final String type;
  final DateTime startDate;
  final DateTime endDate;
  final String reason;
}

class SubmitOvertimeApplication extends ManagerEvent {
  const SubmitOvertimeApplication({
    required this.workDate,
    required this.duration,
    required this.project,
    required this.note,
  });
  final DateTime workDate;
  final String duration;
  final String project;
  final String note;
}

class SubmitReimbursementApplication extends ManagerEvent {
  const SubmitReimbursementApplication({
    required this.expenseDate,
    required this.amount,
    required this.category,
    required this.receiptName,
    required this.note,
  });
  final DateTime expenseDate;
  final String amount;
  final String category;
  final String receiptName;
  final String note;
}

class ClearManagerMessage extends ManagerEvent {
  const ClearManagerMessage();
}

class ManagerBloc {
  ManagerBloc({required AuthSession session, ManagerApiService? service})
    : _service = service ?? ManagerApiService(session: session),
      _state = ManagerState.initial(canManage: session.user.role == 'manager');

  final ManagerApiService _service;
  final StreamController<ManagerState> _controller =
      StreamController<ManagerState>.broadcast();

  ManagerState _state;

  ManagerState get state => _state;

  Stream<ManagerState> get stream => _controller.stream;

  void add(ManagerEvent event) {
    _handle(event);
  }

  void dispose() {
    _controller.close();
  }

  void _emit(ManagerState state) {
    _state = state;
    if (!_controller.isClosed) {
      _controller.add(state);
    }
  }

  Future<void> _handle(ManagerEvent event) async {
    try {
      switch (event) {
        case LoadManagerDashboard():
          _emit(_state.copyWith(status: ManagerLoadStatus.loading));
          final dashboard = await _service.fetchDashboard();
          _emit(
            _state.copyWith(
              status: ManagerLoadStatus.ready,
              dashboard: dashboard,
              error: null,
            ),
          );
        case ChangeManagerTab(:final tab):
          if (tab == ManagerTab.manage && !_state.canManage) return;
          _emit(
            _state.copyWith(
              tab: tab,
              view: ManagerView.home,
              clearSelectedMember: true,
              clearAwardPicker: true,
              applyLeaveOpen: false,
            ),
          );
        case OpenFeedbackList():
          _emit(_state.copyWith(view: ManagerView.feedbackList));
        case CloseFeedbackList():
          _emit(
            _state.copyWith(
              view: ManagerView.home,
              searchQuery: '',
              feedbackFilter: FeedbackFilter.all,
            ),
          );
        case OpenFeedbackRecord(:final memberId):
          final member = _state.dashboard?.team
              .where((item) => item.id == memberId)
              .firstOrNull;
          if (member == null) return;
          _emit(
            _state.copyWith(
              view: ManagerView.feedbackRecord,
              selectedMemberId: member.id,
              recordParams: member.params
                  .map((param) => param.copyWith())
                  .toList(),
              recordExtra: member.extra,
            ),
          );
        case CloseFeedbackRecord():
          _emit(
            _state.copyWith(
              view: ManagerView.feedbackList,
              clearSelectedMember: true,
              recordParams: const <FeedbackParam>[],
              recordExtra: '',
            ),
          );
        case ChangeFeedbackFilter(:final filter):
          _emit(_state.copyWith(feedbackFilter: filter));
        case ChangeFeedbackSearch(:final query):
          _emit(_state.copyWith(searchQuery: query));
        case ToggleGivenFeedback():
          _emit(_state.copyWith(showGiven: !_state.showGiven));
        case UpdateFeedbackScore(:final index, :final score):
          final next = _state.recordParams.indexed.map((entry) {
            return entry.$1 == index
                ? entry.$2.copyWith(score: score)
                : entry.$2;
          }).toList();
          _emit(_state.copyWith(recordParams: next));
        case UpdateFeedbackNote(:final index, :final note):
          final next = _state.recordParams.indexed.map((entry) {
            return entry.$1 == index ? entry.$2.copyWith(note: note) : entry.$2;
          }).toList();
          _emit(_state.copyWith(recordParams: next));
        case UpdateFeedbackExtra(:final extra):
          _emit(_state.copyWith(recordExtra: extra));
        case SaveFeedback():
          await _persistFeedback(
            FeedbackStatus.saved,
            'Saved — ready for the session',
          );
        case SendFeedback():
          final member = _state.selectedMember;
          await _persistFeedback(
            FeedbackStatus.sent,
            member == null ? 'Sent' : 'Sent to ${member.name.split(' ').first}',
          );
        case DecideLeave(:final leaveId, :final decision):
          final updatedLeave = await _service.decideLeave(leaveId, decision);
          final data = _state.dashboard;
          if (data == null) return;
          final leaves = data.leaves.map((leave) {
            return leave.id == leaveId ? updatedLeave : leave;
          }).toList();
          _emit(
            _state.copyWith(
              dashboard: data.copyWith(leaves: leaves),
              message: decision == LeaveDecision.approved
                  ? 'Leave approved'
                  : 'Leave declined',
            ),
          );
        case DecideOvertime(:final overtimeId, :final decision):
          final updated = await _service.decideOvertimeRequest(
            overtimeId,
            decision,
          );
          final data = _state.dashboard;
          if (data == null) return;
          final overtime = data.overtime.map((request) {
            return request.id == overtimeId ? updated : request;
          }).toList();
          _emit(
            _state.copyWith(
              dashboard: data.copyWith(overtime: overtime),
              message: decision == LeaveDecision.approved
                  ? 'Overtime approved'
                  : 'Overtime declined',
            ),
          );
        case OpenAwardPicker(:final awardKey):
          _emit(_state.copyWith(awardPickerKey: awardKey));
        case CloseAwardPicker():
          _emit(_state.copyWith(clearAwardPicker: true));
        case NominateAward(:final awardKey, :final memberId):
          final data = _state.dashboard;
          if (data == null) return;
          final member = data.recognitionCandidates
              .where((item) => item.id == memberId)
              .firstOrNull;
          if (member == null) return;
          await _service.nominateAward(awardKey, member);
          final awards = data.awards.map((award) {
            return award.key == awardKey
                ? award.copyWith(nomineeId: memberId)
                : award;
          }).toList();
          _emit(
            _state.copyWith(
              dashboard: data.copyWith(awards: awards),
              clearAwardPicker: true,
              message: 'Nomination saved',
            ),
          );
        case OpenApplyLeave():
          _emit(_state.copyWith(applyLeaveOpen: true, applyLeaveSent: false));
        case CloseApplyLeave():
          _emit(_state.copyWith(applyLeaveOpen: false, applyLeaveSent: false));
        case SubmitLeaveApplication(
          :final type,
          :final startDate,
          :final endDate,
          :final reason,
        ):
          final leave = await _service.submitLeaveApplication(
            type: type,
            startDate: startDate,
            endDate: endDate,
            reason: reason,
          );
          final data = _state.dashboard;
          _emit(
            _state.copyWith(
              dashboard: data?.copyWith(myLeaves: [leave, ...data.myLeaves]),
              applyLeaveSent: true,
              message: 'Leave request submitted',
            ),
          );
        case SubmitOvertimeApplication(
          :final workDate,
          :final duration,
          :final project,
          :final note,
        ):
          final request = await _service.submitOvertime(
            workDate: workDate,
            duration: duration,
            project: project,
            note: note,
          );
          final data = _state.dashboard;
          _emit(
            _state.copyWith(
              dashboard: data?.copyWith(
                myOvertime: [request, ...data.myOvertime],
              ),
              message: 'Overtime request submitted',
            ),
          );
        case SubmitReimbursementApplication(
          :final expenseDate,
          :final amount,
          :final category,
          :final receiptName,
          :final note,
        ):
          final claim = await _service.submitReimbursement(
            expenseDate: expenseDate,
            amount: amount,
            category: category,
            receiptName: receiptName,
            note: note,
          );
          final data = _state.dashboard;
          _emit(
            _state.copyWith(
              dashboard: data?.copyWith(
                myReimbursements: [claim, ...data.myReimbursements],
              ),
              message: 'Reimbursement claim submitted',
            ),
          );
        case ClearManagerMessage():
          _emit(_state.copyWith(clearMessage: true));
      }
    } catch (error) {
      _emit(
        _state.copyWith(
          status: _state.dashboard == null
              ? ManagerLoadStatus.failure
              : ManagerLoadStatus.ready,
          error: _state.dashboard == null ? error.toString() : null,
          message: _state.dashboard == null ? null : error.toString(),
        ),
      );
    }
  }

  Future<void> _persistFeedback(FeedbackStatus status, String message) async {
    final data = _state.dashboard;
    final selected = _state.selectedMember;
    if (data == null || selected == null) return;

    final params = _state.recordParams;
    final overall = params.isEmpty
        ? selected.score
        : params.fold<double>(0, (sum, item) => sum + item.score) /
              params.length;
    await _service.saveFeedback(
      member: selected,
      status: status,
      params: params,
      extra: _state.recordExtra,
    );
    final team = data.team.map((member) {
      if (member.id != selected.id) return member;
      return member.copyWith(
        status: status,
        params: params,
        extra: _state.recordExtra,
        score: overall,
      );
    }).toList();
    _emit(
      _state.copyWith(
        dashboard: data.copyWith(team: team),
        view: ManagerView.feedbackList,
        clearSelectedMember: true,
        recordParams: const <FeedbackParam>[],
        recordExtra: '',
        message: message,
      ),
    );
  }
}
