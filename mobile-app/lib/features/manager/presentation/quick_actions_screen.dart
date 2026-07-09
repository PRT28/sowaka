import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../bloc/manager_bloc.dart';
import '../data/manager_models.dart';

class QuickActionsController extends ChangeNotifier {
  _QuickActionsScreenState? _state;

  bool get canGoBack => _state != null && _state!._page != _QuickPage.home;

  void handleBack() => _state?._back();

  void _attach(_QuickActionsScreenState state) {
    _state = state;
  }

  void _detach(_QuickActionsScreenState state) {
    if (identical(_state, state)) _state = null;
  }

  void _navigationChanged() => notifyListeners();
}

enum _QuickPage {
  home,
  leave,
  overtime,
  reimbursements,
  policies,
  policy,
  calendar,
  wizard,
  success,
}

enum _QuickFlow { leave, overtime, reimbursement }

const int _maxLeaveApplyDays = 30;

class QuickActionsScreen extends StatefulWidget {
  const QuickActionsScreen({
    super.key,
    required this.bloc,
    required this.dashboard,
    required this.controller,
    required this.profileAction,
  });

  final ManagerBloc bloc;
  final ManagerDashboard dashboard;
  final QuickActionsController controller;
  final Widget profileAction;

  @override
  State<QuickActionsScreen> createState() => _QuickActionsScreenState();
}

class _QuickActionsScreenState extends State<QuickActionsScreen> {
  _QuickPage _page = _QuickPage.home;
  _QuickFlow _flow = _QuickFlow.leave;
  int _step = 0;
  String? _choice;
  DateTime _from = DateTime.now();
  DateTime _to = DateTime.now();
  DateTime? _leaveFrom;
  DateTime? _leaveTo;
  bool _dateChosen = false;
  String? _uploadName;
  Uint8List? _uploadBytes;
  final _text = TextEditingController();
  final Map<String, String> _answers = {};
  _Policy? _policy;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    widget.controller._attach(this);
  }

  @override
  void dispose() {
    widget.controller._detach(this);
    _text.dispose();
    super.dispose();
  }

  void _open(_QuickPage page) {
    setState(() => _page = page);
    widget.controller._navigationChanged();
  }

  void _start(_QuickFlow flow) {
    setState(() {
      _flow = flow;
      _step = 0;
      _choice = null;
      _answers.clear();
      _text.clear();
      _dateChosen = false;
      _uploadName = null;
      _uploadBytes = null;
      _page = _QuickPage.wizard;
    });
    widget.controller._navigationChanged();
  }

  void _back() {
    setState(() {
      if (_page == _QuickPage.policy) {
        _page = _QuickPage.policies;
      } else if (_page == _QuickPage.wizard && _step > 0) {
        _step--;
        _restoreStepInput(_stepsForCurrentFlow()[_step]);
      } else if (_page == _QuickPage.wizard || _page == _QuickPage.success) {
        _page = switch (_flow) {
          _QuickFlow.leave => _QuickPage.leave,
          _QuickFlow.overtime => _QuickPage.overtime,
          _QuickFlow.reimbursement => _QuickPage.reimbursements,
        };
      } else {
        _page = _QuickPage.home;
      }
    });
    widget.controller._navigationChanged();
  }

  void _restoreStepInput(_FlowStep step) {
    _choice = step.kind == _StepKind.choice ? _answers[step.label] : null;
    _text.text = step.kind == _StepKind.text
        ? (_answers[step.label] ?? '')
        : '';
    _dateChosen = step.kind == _StepKind.date || step.kind == _StepKind.dates;
    if (step.kind == _StepKind.upload) {
      _uploadName = _answers[step.label];
    }
  }

  void _backToEdit() {
    setState(() {
      _step--;
      _restoreStepInput(_stepsForCurrentFlow()[_step]);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      child: switch (_page) {
        _QuickPage.home => _home(),
        _QuickPage.leave => _leaveHub(),
        _QuickPage.overtime => _overtimeHub(),
        _QuickPage.reimbursements => _reimbursementHub(),
        _QuickPage.policies => _policies(),
        _QuickPage.policy => _policyDetail(),
        _QuickPage.calendar => _calendar(),
        _QuickPage.wizard => _wizard(),
        _QuickPage.success => _success(),
      },
    );
  }

  Widget _home() {
    return ListView(
      key: const ValueKey('quick-home'),
      padding: const EdgeInsets.fromLTRB(18, 58, 18, 28),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('QUICK ACTIONS', style: _QText.eyebrow),
                  SizedBox(height: 6),
                  Text('What do you need?', style: _QText.hero),
                ],
              ),
            ),
            widget.profileAction,
          ],
        ),
        const SizedBox(height: 5),
        const Text('Everything you can do yourself.', style: _QText.subtitle),
        const SizedBox(height: 28),
        const _SectionLabel('Requests'),
        const SizedBox(height: 10),
        _ActionGroup(
          children: [
            _GroupedActionRow(
              icon: Icons.calendar_month_rounded,
              color: _Q.terra,
              tint: _Q.terraTint,
              title: 'Manage leave',
              subtitle: 'Apply · view requests',
              onTap: () => _open(_QuickPage.leave),
            ),
            // Overtime is hidden for teams where it's disabled by the company.
            if (widget.dashboard.overtimeEnabled)
              _GroupedActionRow(
                icon: Icons.schedule_rounded,
                color: _Q.gold,
                tint: _Q.goldTint,
                title: 'Overtime',
                subtitle: 'Apply · view requests',
                onTap: () => _open(_QuickPage.overtime),
              ),
            _GroupedActionRow(
              icon: Icons.receipt_long_rounded,
              color: _Q.teal,
              tint: _Q.tealTint,
              title: 'Reimbursements',
              subtitle: 'Claim · view claims',
              onTap: () => _open(_QuickPage.reimbursements),
              last: true,
            ),
          ],
        ),
        const SizedBox(height: 20),
        const _SectionLabel('Info & tools'),
        const SizedBox(height: 10),
        _ActionGroup(
          children: [
            _GroupedActionRow(
              icon: Icons.menu_book_rounded,
              color: _Q.plum,
              tint: _Q.plumTint,
              title: 'View policy',
              subtitle: 'Leave, payroll, POSH…',
              onTap: () => _open(_QuickPage.policies),
            ),
            _GroupedActionRow(
              icon: Icons.calendar_month_outlined,
              color: _Q.terraDeep,
              tint: _Q.terraTint,
              title: 'Download calendar',
              subtitle: 'Leaves + holidays .ics',
              onTap: () => _open(_QuickPage.calendar),
              last: true,
            ),
          ],
        ),
      ],
    );
  }

  Widget _leaveHub() {
    final requests = widget.dashboard.myLeaves;
    final days = _leaveFrom == null
        ? 0
        : ((_leaveTo ?? _leaveFrom!).difference(_leaveFrom!).inDays + 1);
    final range = _leaveFrom == null
        ? ''
        : _leaveTo != null && _leaveTo != _leaveFrom
        ? '${_short(_leaveFrom!)} – ${_short(_leaveTo!)}'
        : _short(_leaveFrom!);
    return _HubScaffold(
      key: const ValueKey('leave-hub'),
      title: 'Manage leave',
      onBack: _back,
      children: [
        const _SectionLabel('Apply for leave'),
        const SizedBox(height: 8),
        Text(
          _leaveFrom == null
              ? 'Tap a start and end date. Weekends and holidays are blocked.'
              : _leaveTo == null
              ? 'Now tap the end date (or continue for a single day).'
              : 'Dates selected — apply leave.',
          style: _QText.subtitle,
        ),
        const SizedBox(height: 11),
        _PaperCard(
          child: Column(
            children: [
              _MonthCalendar(
                from: _leaveFrom,
                to: _leaveTo,
                selectableDayPredicate: _canSelectLeaveDay,
                onPick: _pickLeaveDay,
              ),
              const Divider(height: 25, color: _Q.line),
              if (_leaveFrom == null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  decoration: BoxDecoration(
                    color: _Q.line,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.calendar_month_rounded,
                        color: _Q.inkFaint,
                        size: 18,
                      ),
                      SizedBox(width: 7),
                      Text(
                        'Select your dates',
                        style: TextStyle(
                          color: _Q.inkFaint,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$range · $days day${days == 1 ? '' : 's'}',
                            style: _QText.cardTitle,
                          ),
                          InkWell(
                            onTap: () => setState(() {
                              _leaveFrom = null;
                              _leaveTo = null;
                            }),
                            child: const Padding(
                              padding: EdgeInsets.only(top: 3),
                              child: Text(
                                'Clear',
                                style: TextStyle(
                                  color: _Q.terra,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: _Q.terra,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 13,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(13),
                        ),
                      ),
                      onPressed: _openLeaveSheet,
                      iconAlignment: IconAlignment.end,
                      icon: const Icon(Icons.arrow_forward_rounded, size: 17),
                      label: const Text(
                        'Apply leave',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const _SectionLabel('My requests'),
        const SizedBox(height: 10),
        _RequestGroup(
          children: requests.indexed
              .map(
                (entry) => _RequestRow(
                  '${_short(entry.$2.start)}–${_short(entry.$2.end)} · ${entry.$2.days} days',
                  entry.$2.managerNote.isEmpty
                      ? '${entry.$2.type} leave'
                      : '${entry.$2.type} leave · ${entry.$2.managerNote}',
                  _decision(entry.$2.decision),
                  icon: Icons.calendar_month_rounded,
                  color: _Q.terra,
                  tint: _Q.terraTint,
                  last: entry.$1 == requests.length - 1,
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  void _pickLeaveDay(DateTime day) {
    setState(() {
      if (_leaveFrom == null || _leaveTo != null) {
        _leaveFrom = day;
        _leaveTo = null;
      } else if (day.isBefore(_leaveFrom!)) {
        _leaveFrom = day;
      } else {
        final span = day.difference(_leaveFrom!).inDays + 1;
        if (span > _maxLeaveApplyDays ||
            _rangeHasBlockedLeaveDay(_leaveFrom!, day)) {
          _leaveFrom = day;
          _leaveTo = null;
          return;
        }
        _leaveTo = day;
      }
    });
  }

  Future<void> _openLeaveSheet() async {
    if (_leaveFrom == null) return;
    final from = _leaveFrom!;
    final to = _leaveTo ?? _leaveFrom!;
    _LeaveSheetResult? draft;
    while (mounted) {
      final result = await showModalBottomSheet<_LeaveSheetResult>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => _LeaveApplySheet(
          dashboard: widget.dashboard,
          from: from,
          to: to,
          initial: draft,
        ),
      );
      if (result == null || !mounted) return;
      draft = result;
      final confirmed = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => _LeaveConfirmationSheet(
          dashboard: widget.dashboard,
          from: from,
          to: to,
          result: result,
        ),
      );
      if (!mounted) return;
      if (confirmed != true) continue;
      final sent = await widget.bloc.add(
        SubmitLeaveApplication(
          type: result.type,
          startDate: from,
          endDate: to,
          reason: result.note,
        ),
      );
      if (!mounted || !sent) return;
      setState(() {
        _flow = _QuickFlow.leave;
        _page = _QuickPage.success;
      });
      widget.controller._navigationChanged();
      return;
    }
  }

  Widget _overtimeHub() {
    final requests = widget.dashboard.myOvertime;
    final now = DateTime.now();
    final thisMonth = requests.where(
      (request) =>
          request.workDate.year == now.year &&
          request.workDate.month == now.month,
    );
    final approvedHours = thisMonth
        .where((request) => request.decision == LeaveDecision.approved)
        .fold<double>(0, (sum, request) => sum + request.hours);
    final pending = requests
        .where((request) => request.decision == LeaveDecision.pending)
        .length;
    return _HubScaffold(
      key: const ValueKey('overtime-hub'),
      title: 'Overtime',
      onBack: _back,
      footer: _SingleActionFooter(
        color: _Q.gold,
        label: 'Log overtime',
        onTap: () => _start(_QuickFlow.overtime),
      ),
      children: [
        _StatStrip(
          stats: [
            ('${_number(approvedHours)}h', 'Approved this month', _Q.teal),
            ('$pending', 'Pending', _Q.gold),
          ],
        ),
        const SizedBox(height: 24),
        const _SectionLabel('My requests'),
        const SizedBox(height: 10),
        _RequestGroup(
          children: requests.indexed
              .map(
                (entry) => _RequestRow(
                  entry.$2.project,
                  entry.$2.managerNote.isEmpty
                      ? '${_short(entry.$2.workDate)} · ${entry.$2.duration}'
                      : '${_short(entry.$2.workDate)} · ${entry.$2.duration} · ${entry.$2.managerNote}',
                  _decision(entry.$2.decision),
                  icon: Icons.schedule_rounded,
                  color: _Q.gold,
                  tint: _Q.goldTint,
                  last: entry.$1 == requests.length - 1,
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 16),
        const _InfoCard(
          'Overtime is paid at 1.5× or taken as comp-off, settled the following month.',
        ),
      ],
    );
  }

  Widget _reimbursementHub() {
    final claims = widget.dashboard.myReimbursements;
    final now = DateTime.now();
    final thisMonth = claims.where(
      (claim) =>
          claim.expenseDate.year == now.year &&
          claim.expenseDate.month == now.month,
    );
    final claimed = thisMonth.fold<double>(
      0,
      (sum, claim) => sum + claim.amount,
    );
    final reimbursed = thisMonth
        .where((claim) => claim.status == 'Paid')
        .fold<double>(0, (sum, claim) => sum + claim.amount);
    final pending = thisMonth
        .where((claim) => claim.status == 'Pending')
        .fold<double>(0, (sum, claim) => sum + claim.amount);
    return _HubScaffold(
      key: const ValueKey('reimbursement-hub'),
      title: 'Reimbursements',
      onBack: _back,
      footer: _SingleActionFooter(
        color: _Q.teal,
        label: 'New claim',
        onTap: () => _start(_QuickFlow.reimbursement),
      ),
      children: [
        _StatStrip(
          stats: [
            (_money(claimed), 'Claimed this month', _Q.ink),
            (_money(reimbursed), 'Reimbursed', _Q.teal),
            (_money(pending), 'Pending', _Q.gold),
          ],
        ),
        const SizedBox(height: 24),
        const _SectionLabel('My claims'),
        const SizedBox(height: 10),
        _RequestGroup(
          children: claims.indexed
              .map(
                (entry) => _RequestRow(
                  '${entry.$2.category} · ${_money(entry.$2.amount)}',
                  '${entry.$2.note.isEmpty ? 'Expense claim' : entry.$2.note} · ${_short(entry.$2.expenseDate)}',
                  entry.$2.status,
                  statusLabel: entry.$2.statusLabel,
                  icon: Icons.receipt_long_rounded,
                  color: _Q.teal,
                  tint: _Q.tealTint,
                  last: entry.$1 == claims.length - 1,
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _policies() {
    return _HubScaffold(
      key: const ValueKey('policies'),
      title: 'Policies',
      onBack: _back,
      children: [
        ..._policiesData.map(
          (policy) => _ActionCard(
            icon: policy.icon,
            color: policy.color,
            tint: policy.tint,
            title: policy.title,
            subtitle: null,
            onTap: () => setState(() {
              _policy = policy;
              _page = _QuickPage.policy;
            }),
          ),
        ),
      ],
    );
  }

  Widget _policyDetail() {
    final policy = _policy!;
    return _HubScaffold(
      key: ValueKey('policy-${policy.title}'),
      title: '${policy.title} policy',
      onBack: _back,
      footer: _SingleActionFooter(
        color: policy.color,
        label: 'Open full document',
        onTap: () => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${policy.title} policy opened')),
        ),
        outlined: true,
      ),
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: policy.tint,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Icon(policy.icon, color: policy.color, size: 30),
        ),
        const SizedBox(height: 18),
        Text(policy.title, style: _QText.heroSmall),
        const SizedBox(height: 14),
        Text(
          policy.body,
          style: const TextStyle(color: _Q.ink, fontSize: 15, height: 1.65),
        ),
      ],
    );
  }

  Widget _calendar() {
    final year = widget.dashboard.leaveBalance.year;
    return _HubScaffold(
      key: const ValueKey('calendar'),
      title: 'Leave calendar',
      onBack: _back,
      children: [
        _RequestGroup(
          children: [
            _DownloadRow(
              icon: Icons.calendar_month_rounded,
              color: _Q.terra,
              tint: _Q.terraTint,
              name: 'Sowaka-$year.ics',
              subtitle: 'Your leaves + 14 company holidays',
              onAction: _fileAction,
            ),
            _DownloadRow(
              icon: Icons.description_rounded,
              color: _Q.plum,
              tint: _Q.plumTint,
              name: 'Holidays-$year.pdf',
              subtitle: 'Printable company holiday list',
              onAction: _fileAction,
              last: true,
            ),
          ],
        ),
      ],
    );
  }

  void _fileAction(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _wizard() {
    final steps = _stepsForCurrentFlow();
    final review = _step == steps.length;
    final step = review ? null : steps[_step];
    final color = _flowColor(_flow);
    return _HubScaffold(
      key: ValueKey('wizard-${_flow.name}-$_step'),
      title: _flowTitle(_flow),
      onBack: _back,
      footer: _WizardFooter(
        color: color,
        label: _submitting
            ? 'Submitting…'
            : review
            ? _flowCta(_flow)
            : step!.optional && !_hasStepValue(step)
            ? 'Skip'
            : _step == steps.length - 1
            ? 'Review'
            : 'Continue',
        secondary: review
            ? 'Back to edit'
            : _step > 0
            ? 'Back'
            : null,
        onSecondary: review
            ? _backToEdit
            : _step > 0
            ? _back
            : null,
        secondaryAfter: review || _step > 0,
        onTap: !_submitting && (review || _canContinue(step!))
            ? () => _advance(step)
            : null,
      ),
      children: [
        Row(
          children: List.generate(
            steps.length + 1,
            (index) => Expanded(
              child: Container(
                height: 4,
                margin: EdgeInsets.only(right: index == steps.length ? 0 : 5),
                decoration: BoxDecoration(
                  color: index <= _step ? color : _Q.line,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 28),
        if (review) ...[
          const Text('Review & confirm', style: _QText.heroSmall),
          const SizedBox(height: 6),
          const Text(
            'Check the details below before sending.',
            style: _QText.subtitle,
          ),
          const SizedBox(height: 20),
          _reviewCard(),
          const SizedBox(height: 14),
          _InfoCard(
            "You'll be able to track this under ${_trackLabel(_flow)}.",
          ),
        ] else ...[
          Text(step!.question, style: _QText.heroSmall),
          const SizedBox(height: 6),
          Text(step.subtitle, style: _QText.subtitle),
          const SizedBox(height: 24),
          _stepInput(step, color),
        ],
      ],
    );
  }

  bool _canContinue(_FlowStep step) {
    return switch (step.kind) {
      _StepKind.choice => _choice != null,
      _StepKind.text when step.money =>
        (double.tryParse(_text.text.replaceAll(',', '').trim()) ?? 0) > 0,
      _StepKind.text => _text.text.trim().isNotEmpty || step.optional,
      _StepKind.dates || _StepKind.date => _dateChosen,
      _StepKind.upload => true,
    };
  }

  bool _hasStepValue(_FlowStep step) {
    return switch (step.kind) {
      _StepKind.upload => _uploadBytes != null && _uploadName != null,
      _StepKind.text => _text.text.trim().isNotEmpty,
      _StepKind.choice => _choice != null,
      _StepKind.dates || _StepKind.date => _dateChosen,
    };
  }

  Future<void> _advance(_FlowStep? step, {bool skip = false}) async {
    final steps = _stepsForCurrentFlow();
    if (step == null) {
      setState(() => _submitting = true);
      bool submitted;
      if (_flow == _QuickFlow.leave) {
        submitted = await widget.bloc.add(
          SubmitLeaveApplication(
            type: _answers['Type'] ?? 'Casual',
            startDate: _from,
            endDate: _to,
            reason: _answers['Note'] ?? '',
          ),
        );
      } else if (_flow == _QuickFlow.overtime) {
        submitted = await widget.bloc.add(
          SubmitOvertimeApplication(
            workDate: _from,
            duration: _answers['Duration'] ?? 'Half day',
            project: _answers['Project'] ?? '',
            note: _answers['Note'] ?? '',
          ),
        );
      } else {
        submitted = await widget.bloc.add(
          SubmitReimbursementApplication(
            expenseDate: _from,
            amount: _answers['Amount'] ?? '',
            category: _answers['Type'] ?? 'Other',
            receiptName: _answers['Bill'] ?? '',
            receiptBytes: _uploadBytes,
            note: _answers['Note'] ?? '',
          ),
        );
      }
      if (!mounted) return;
      setState(() {
        _submitting = false;
        if (submitted) _page = _QuickPage.success;
      });
      if (submitted) widget.controller._navigationChanged();
      return;
    }
    if (!skip) {
      switch (step.kind) {
        case _StepKind.choice:
          _answers[step.label] = _choice!;
        case _StepKind.text:
          _answers[step.label] = _text.text.trim();
        case _StepKind.dates:
          _answers[step.label] = '${_short(_from)}–${_short(_to)}';
        case _StepKind.date:
          _answers[step.label] = _short(_from);
        case _StepKind.upload:
          _answers[step.label] = _uploadName ?? '';
      }
    }
    setState(() {
      _step = (_step + 1).clamp(0, steps.length);
      _choice = null;
      _text.clear();
      _dateChosen = false;
    });
  }

  Widget _stepInput(_FlowStep step, Color color) {
    return switch (step.kind) {
      _StepKind.choice => Column(
        children: step.options!
            .map(
              (option) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _ChoiceCard(
                  option: option,
                  selected: _choice == option.label,
                  color: color,
                  onTap: () {
                    setState(() => _choice = option.label);
                    Future<void>.delayed(const Duration(milliseconds: 160), () {
                      if (mounted && _choice == option.label) _advance(step);
                    });
                  },
                ),
              ),
            )
            .toList(),
      ),
      _StepKind.text => TextField(
        controller: _text,
        autofocus: true,
        onChanged: (_) => setState(() {}),
        keyboardType: step.money ? TextInputType.number : TextInputType.text,
        maxLines: step.money ? 1 : 4,
        decoration: InputDecoration(
          prefixText: step.money ? '₹  ' : null,
          hintText: step.placeholder,
          fillColor: Colors.white,
        ),
      ),
      _StepKind.dates => _PaperCard(
        child: _MonthCalendar(
          from: _dateChosen ? _from : null,
          to: _dateChosen ? _to : null,
          selectableDayPredicate: _canSelectLeaveDay,
          onPick: (day) => setState(() {
            if (!_dateChosen || !_sameDay(_from, _to)) {
              _from = day;
              _to = day;
              _dateChosen = true;
            } else if (day.isBefore(_from)) {
              _from = day;
            } else {
              final span = day.difference(_from).inDays + 1;
              if (span > _maxLeaveApplyDays ||
                  _rangeHasBlockedLeaveDay(_from, day)) {
                _from = day;
                _to = day;
                return;
              }
              _to = day;
            }
          }),
          selectionLabel: _dateChosen ? _rangeLabel(_from, _to) : null,
        ),
      ),
      _StepKind.date => _PaperCard(
        child: _MonthCalendar(
          from: _dateChosen ? _from : null,
          selectableDayPredicate: _flow == _QuickFlow.overtime
              ? _canSelectOvertimeDay
              : _flow == _QuickFlow.reimbursement
              ? (day) {
                  final now = DateTime.now();
                  final today = DateTime(now.year, now.month, now.day);
                  return !day.isAfter(today);
                }
              : null,
          onPick: (day) => setState(() {
            _from = day;
            _to = day;
            _dateChosen = true;
          }),
          selectionLabel: _dateChosen
              ? '${_short(_from)} · ${_weekday(_from.weekday)}'
              : null,
        ),
      ),
      _StepKind.upload => _UploadCard(
        color: color,
        tint: _Q.tealTint,
        value: _uploadName,
        bytes: _uploadBytes,
        onChanged: (file) => setState(() {
          _uploadName = file?.name;
          _uploadBytes = file?.bytes;
        }),
      ),
    };
  }

  bool get _hasBillPreview =>
      _flow == _QuickFlow.reimbursement && _uploadBytes != null && _uploadName != null;

  bool get _billIsImage {
    final n = (_uploadName ?? '').toLowerCase();
    return n.endsWith('.jpg') || n.endsWith('.jpeg') || n.endsWith('.png');
  }

  /// Formats a review value — reimbursement amounts get an "Rs." prefix.
  String _reviewValue(String key, String value) {
    if (value.isEmpty) return '—';
    if (key == 'Amount' && _flow == _QuickFlow.reimbursement) return 'Rs. $value';
    return value;
  }

  Widget _reviewCard() {
    // The Bill row is rendered separately as a viewable preview.
    final entries = <MapEntry<String, String>>[
      ..._answers.entries.where((e) => !(_hasBillPreview && e.key == 'Bill')),
      if (_flow == _QuickFlow.leave)
        MapEntry('Approver', widget.dashboard.approverName),
      if (_flow == _QuickFlow.overtime)
        MapEntry('Approver', widget.dashboard.approverName),
    ];
    return _PaperCard(
      child: Column(
        children: [
          ...entries.indexed.map((entry) {
            final isLast = entry.$1 == entries.length - 1 && !_hasBillPreview;
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                border: isLast ? null : const Border(bottom: BorderSide(color: _Q.line)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(width: 88, child: Text(entry.$2.key, style: _QText.mini)),
                  Expanded(
                    child: Text(
                      _reviewValue(entry.$2.key, entry.$2.value),
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        color: _Q.ink,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
          if (_hasBillPreview) _billReviewRow(),
        ],
      ),
    );
  }

  Widget _billReviewRow() {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Bill', style: _QText.mini),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _showBillPreview,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _Q.line),
              ),
              clipBehavior: Clip.antiAlias,
              child: _billIsImage
                  ? Column(
                      children: [
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 200),
                          child: Image.memory(
                            Uint8List.fromList(_uploadBytes!),
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                        _billCaption(Icons.zoom_out_map_rounded, 'Tap to view full bill'),
                      ],
                    )
                  : _billCaption(Icons.picture_as_pdf_rounded, _uploadName ?? 'Bill.pdf'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _billCaption(IconData icon, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      child: Row(
        children: [
          Icon(icon, size: 18, color: _Q.inkFaint),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: _Q.inkSoft, fontSize: 12.5, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  void _showBillPreview() {
    if (_uploadBytes == null) return;
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.82),
      builder: (context) => GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: _billIsImage
                ? InteractiveViewer(
                    child: Image.memory(Uint8List.fromList(_uploadBytes!), fit: BoxFit.contain),
                  )
                : Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.picture_as_pdf_rounded, size: 48, color: _Q.ink),
                        const SizedBox(height: 12),
                        Text(
                          _uploadName ?? 'Bill.pdf',
                          style: const TextStyle(color: _Q.ink, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'PDF preview opens after submission',
                          style: TextStyle(color: _Q.inkSoft, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _success() {
    return Center(
      key: ValueKey('success-${_flow.name}'),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _flow == _QuickFlow.leave
                    ? _Q.terraTint
                    : _flow == _QuickFlow.overtime
                    ? _Q.goldTint
                    : _Q.tealTint,
              ),
              child: Icon(
                Icons.check_circle_rounded,
                color: _flowColor(_flow),
                size: 52,
              ),
            ),
            const SizedBox(height: 24),
            const Text('Request sent!', style: _QText.heroSmall),
            const SizedBox(height: 10),
            Text(
              _flow == _QuickFlow.reimbursement
                  ? "Sent to finance. You'll get a notification when it's actioned."
                  : "Sent to ${widget.dashboard.approverName}. You'll get a notification when it's actioned.",
              textAlign: TextAlign.center,
              style: _QText.subtitle,
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: _Q.line),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    color: _flowColor(_flow),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Track it under ${_trackLabel(_flow)}',
                      style: const TextStyle(color: _Q.ink, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 26),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: _flowColor(_flow),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: _back,
                child: const Text(
                  'View my requests',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
            TextButton(
              onPressed: () => _open(_QuickPage.home),
              child: const Text('Back to dashboard'),
            ),
          ],
        ),
      ),
    );
  }

  List<_FlowStep> _stepsForCurrentFlow() {
    if (_flow != _QuickFlow.leave) return _flowSteps[_flow]!;
    final leaveSteps = _flowSteps[_QuickFlow.leave]!;
    return [
      _FlowStep(
        label: leaveSteps.first.label,
        kind: leaveSteps.first.kind,
        question: leaveSteps.first.question,
        subtitle: leaveSteps.first.subtitle,
        options: [
          _FlowOption('Sick', Icons.thermostat_rounded),
          _FlowOption('Casual', Icons.coffee_rounded),
          _FlowOption('Earned', Icons.flight_takeoff_rounded),
        ],
      ),
      ...leaveSteps.skip(1),
    ];
  }

  bool _canSelectLeaveDay(DateTime day) {
    final today = _dateOnly(DateTime.now());
    return !day.isBefore(today) &&
        day.weekday != DateTime.saturday &&
        day.weekday != DateTime.sunday &&
        !_isCompanyHoliday(day);
  }

  bool _rangeHasBlockedLeaveDay(DateTime from, DateTime to) {
    for (
      var day = from;
      !day.isAfter(to);
      day = day.add(const Duration(days: 1))
    ) {
      if (!_canSelectLeaveDay(day)) return true;
    }
    return false;
  }

  bool _isCompanyHoliday(DateTime day) {
    return widget.dashboard.holidays.any(
      (holiday) => _sameDay(holiday.date, day),
    );
  }

  // dashboard.weekoffDays uses 0=Sun..6=Sat (JS getDay); Dart weekday is
  // 1=Mon..7=Sun, so `weekday % 7` maps Sun(7)->0 and the rest 1:1.
  bool _isOvertimeWeekoff(DateTime day) =>
      widget.dashboard.weekoffDays.contains(day.weekday % 7);

  // Overtime day rules: any *past* day for half-day; only a week-off or
  // company holiday for full-day. Duration was chosen on the previous step.
  bool _canSelectOvertimeDay(DateTime day) {
    final today = _dateOnly(DateTime.now());
    if (!day.isBefore(today)) return false;
    final fullDay = (_answers['Duration'] ?? _choice) == 'Full day';
    if (!fullDay) return true;
    return _isOvertimeWeekoff(day) || _isCompanyHoliday(day);
  }
}

class _HubScaffold extends StatelessWidget {
  const _HubScaffold({
    super.key,
    required this.title,
    required this.onBack,
    required this.children,
    this.footer,
  });

  final String title;
  final VoidCallback onBack;
  final List<Widget> children;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SafeArea(
          bottom: false,
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 18, 12),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: _Q.line)),
            ),
            child: Row(
              children: [
                Material(
                  color: _Q.bg,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    onTap: onBack,
                    borderRadius: BorderRadius.circular(12),
                    child: const SizedBox(
                      width: 38,
                      height: 38,
                      child: Icon(Icons.chevron_left_rounded, size: 23),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(title, style: _QText.topbar)),
              ],
            ),
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 28),
            children: children,
          ),
        ),
        ?footer,
      ],
    );
  }
}

class _ActionGroup extends StatelessWidget {
  const _ActionGroup({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: _Q.line),
      borderRadius: BorderRadius.circular(18),
    ),
    clipBehavior: Clip.antiAlias,
    child: Column(children: children),
  );
}

class _GroupedActionRow extends StatelessWidget {
  const _GroupedActionRow({
    required this.icon,
    required this.color,
    required this.tint,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.last = false,
  });

  final IconData icon;
  final Color color;
  final Color tint;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool last;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      decoration: BoxDecoration(
        border: last ? null : const Border(bottom: BorderSide(color: _Q.line)),
      ),
      child: Row(
        children: [
          _IconTile(icon: icon, color: color, tint: tint, size: 40),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: _QText.cardTitle),
                const SizedBox(height: 2),
                Text(subtitle, style: _QText.cardSubtitleFaint),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: _Q.inkFaint, size: 20),
        ],
      ),
    ),
  );
}

class _RequestGroup extends StatelessWidget {
  const _RequestGroup({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: _Q.line),
      borderRadius: BorderRadius.circular(18),
    ),
    clipBehavior: Clip.antiAlias,
    child: Column(children: children),
  );
}

class _StatStrip extends StatelessWidget {
  const _StatStrip({required this.stats});
  final List<(String, String, Color)> stats;

  @override
  Widget build(BuildContext context) => _PaperCard(
    child: Row(
      children: stats.indexed.map((entry) {
        final stat = entry.$2;
        return Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              border: entry.$1 == 0
                  ? null
                  : const Border(left: BorderSide(color: _Q.line)),
            ),
            child: Column(
              children: [
                Text(
                  stat.$1,
                  style: TextStyle(
                    color: stat.$3,
                    fontSize: 22,
                    height: 1,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  stat.$2,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: _Q.inkFaint,
                    fontSize: 11,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    ),
  );
}

class _SingleActionFooter extends StatelessWidget {
  const _SingleActionFooter({
    required this.color,
    required this.label,
    required this.onTap,
    this.outlined = false,
  });
  final Color color;
  final String label;
  final VoidCallback onTap;
  final bool outlined;

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    bottom: false,
    child: Container(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: _Q.line)),
      ),
      child: SizedBox(
        width: double.infinity,
        child: outlined
            ? OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: color,
                  side: BorderSide(color: color, width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                onPressed: onTap,
                child: Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              )
            : FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: color,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                onPressed: onTap,
                child: Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
      ),
    ),
  );
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.color,
    required this.tint,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final Color tint;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              border: Border.all(color: _Q.line),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                _IconTile(icon: icon, color: color, tint: tint),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: _QText.cardTitle),
                      if (subtitle != null) ...[
                        const SizedBox(height: 3),
                        Text(subtitle!, style: _QText.cardSubtitle),
                      ],
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: _Q.inkFaint),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RequestRow extends StatelessWidget {
  const _RequestRow(
    this.title,
    this.subtitle,
    this.status, {
    this.statusLabel,
    this.icon,
    this.color = _Q.terra,
    this.tint = _Q.terraTint,
    this.last = true,
  });

  final String title;
  final String subtitle;
  final String status;
  // Optional display text (e.g. "Approved by admin"); color still keys off `status`.
  final String? statusLabel;
  final IconData? icon;
  final Color color;
  final Color tint;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (status) {
      'Approved' || 'Paid' => _Q.teal,
      'Declined' => _Q.live,
      'Holiday' => _Q.plum,
      _ => _Q.gold,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: last ? null : const Border(bottom: BorderSide(color: _Q.line)),
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            _IconTile(icon: icon!, color: color, tint: tint, size: 38),
            const SizedBox(width: 13),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: _QText.cardTitle),
                const SizedBox(height: 3),
                Text(subtitle, style: _QText.cardSubtitle),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(
              statusLabel ?? status,
              style: TextStyle(
                color: statusColor,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({
    required this.option,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  final _FlowOption option;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? color.withValues(alpha: .1) : Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            border: Border.all(color: selected ? color : _Q.line, width: 1.5),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Icon(option.icon, color: selected ? color : _Q.inkSoft),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(option.label, style: _QText.cardTitle),
                    if (option.hint != null) ...[
                      const SizedBox(height: 2),
                      Text(option.hint!, style: _QText.cardSubtitle),
                    ],
                  ],
                ),
              ),
              Icon(
                selected ? Icons.check_circle_rounded : Icons.circle_outlined,
                color: selected ? color : _Q.inkFaint,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MonthCalendar extends StatefulWidget {
  const _MonthCalendar({
    required this.onPick,
    this.from,
    this.to,
    this.selectionLabel,
    this.selectableDayPredicate,
  });

  final DateTime? from;
  final DateTime? to;
  final ValueChanged<DateTime> onPick;
  final String? selectionLabel;
  final bool Function(DateTime day)? selectableDayPredicate;

  @override
  State<_MonthCalendar> createState() => _MonthCalendarState();
}

class _MonthCalendarState extends State<_MonthCalendar> {
  late DateTime _month = DateTime(
    widget.from?.year ?? DateTime.now().year,
    widget.from?.month ?? DateTime.now().month,
  );

  void _shift(int delta) {
    setState(() => _month = DateTime(_month.year, _month.month + delta));
  }

  @override
  Widget build(BuildContext context) {
    final leading = DateTime(_month.year, _month.month).weekday % 7;
    final count = DateTime(_month.year, _month.month + 1, 0).day;
    final cells = leading + count;
    return Column(
      children: [
        Row(
          children: [
            _CalendarArrow(
              icon: Icons.chevron_left_rounded,
              onTap: () => _shift(-1),
            ),
            Expanded(
              child: Text(
                '${_monthName(_month.month)} ${_month.year}',
                textAlign: TextAlign.center,
                style: _QText.cardTitle,
              ),
            ),
            _CalendarArrow(
              icon: Icons.chevron_right_rounded,
              onTap: () => _shift(1),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: const ['S', 'M', 'T', 'W', 'T', 'F', 'S']
              .map(
                (day) => Expanded(
                  child: Text(
                    day,
                    textAlign: TextAlign.center,
                    style: _QText.mini,
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 5),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: ((cells + 6) ~/ 7) * 7,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisExtent: 40,
            mainAxisSpacing: 3,
            crossAxisSpacing: 3,
          ),
          itemBuilder: (context, index) {
            final number = index - leading + 1;
            if (number < 1 || number > count) return const SizedBox();
            final day = DateTime(_month.year, _month.month, number);
            final enabled = widget.selectableDayPredicate?.call(day) ?? true;
            final selected =
                _sameDay(day, widget.from) || _sameDay(day, widget.to);
            final between =
                widget.from != null &&
                widget.to != null &&
                day.isAfter(widget.from!) &&
                day.isBefore(widget.to!);
            return InkWell(
              onTap: enabled ? () => widget.onPick(day) : null,
              borderRadius: BorderRadius.circular(11),
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected
                      ? _Q.terra
                      : between
                      ? _Q.terraTint
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(between ? 0 : 11),
                ),
                child: Text(
                  '$number',
                  style: TextStyle(
                    color: !enabled
                        ? _Q.inkFaint.withValues(alpha: .45)
                        : selected
                        ? Colors.white
                        : _Q.ink,
                    fontSize: 14,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
              ),
            );
          },
        ),
        if (widget.selectionLabel != null) ...[
          const SizedBox(height: 14),
          Text(
            widget.selectionLabel!,
            style: const TextStyle(
              color: _Q.terra,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ],
    );
  }
}

class _CalendarArrow extends StatelessWidget {
  const _CalendarArrow({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: _Q.terraTint,
    borderRadius: BorderRadius.circular(10),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: 32,
        height: 32,
        child: Icon(icon, color: _Q.terra, size: 19),
      ),
    ),
  );
}

class _DownloadRow extends StatelessWidget {
  const _DownloadRow({
    required this.icon,
    required this.color,
    required this.tint,
    required this.name,
    required this.subtitle,
    required this.onAction,
    this.last = false,
  });
  final IconData icon;
  final Color color;
  final Color tint;
  final String name;
  final String subtitle;
  final ValueChanged<String> onAction;
  final bool last;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
    decoration: BoxDecoration(
      border: last ? null : const Border(bottom: BorderSide(color: _Q.line)),
    ),
    child: Row(
      children: [
        _IconTile(icon: icon, color: color, tint: tint, size: 46),
        const SizedBox(width: 13),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _QText.cardTitle,
              ),
              const SizedBox(height: 2),
              Text(subtitle, style: _QText.cardSubtitle),
            ],
          ),
        ),
        const SizedBox(width: 8),
        _FileButton(
          icon: Icons.visibility_outlined,
          onTap: () => onAction('Preview · $name'),
        ),
        const SizedBox(width: 8),
        _FileButton(
          icon: Icons.download_rounded,
          onTap: () => onAction('Downloaded · $name'),
        ),
      ],
    ),
  );
}

class _FileButton extends StatelessWidget {
  const _FileButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(12),
    child: Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        border: Border.all(color: _Q.line, width: 1.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, size: 19, color: _Q.inkSoft),
    ),
  );
}

class _LeaveSheetResult {
  const _LeaveSheetResult(this.type, this.note);
  final String type;
  final String note;
}

class _LeaveApplySheet extends StatefulWidget {
  const _LeaveApplySheet({
    required this.dashboard,
    required this.from,
    required this.to,
    this.initial,
  });
  final ManagerDashboard dashboard;
  final DateTime from;
  final DateTime to;
  final _LeaveSheetResult? initial;

  @override
  State<_LeaveApplySheet> createState() => _LeaveApplySheetState();
}

class _LeaveApplySheetState extends State<_LeaveApplySheet> {
  String? _type;
  final _note = TextEditingController();

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    if (initial != null) {
      _type = '${initial.type} leave';
      _note.text = initial.note;
    }
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final days = widget.to.difference(widget.from).inDays + 1;
    final options = <_FlowOption>[
      _FlowOption('Sick leave', Icons.thermostat_rounded),
      _FlowOption('Casual leave', Icons.coffee_rounded),
      _FlowOption('Earned leave', Icons.flight_takeoff_rounded),
    ];
    final range = _sameDay(widget.from, widget.to)
        ? _short(widget.from)
        : '${_short(widget.from)} – ${_short(widget.to)}';
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * .9,
        ),
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _Q.line,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Apply for leave', style: _QText.topbar),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: _Q.terraTint,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.event_available_rounded,
                      color: _Q.terra,
                      size: 19,
                    ),
                    const SizedBox(width: 9),
                    Text(
                      '$range · $days day${days == 1 ? '' : 's'}',
                      style: _QText.cardTitle,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const _SectionLabel('Leave type'),
              const SizedBox(height: 9),
              ...options.map(
                (option) => Padding(
                  padding: const EdgeInsets.only(bottom: 9),
                  child: _ChoiceCard(
                    option: option,
                    selected: _type == option.label,
                    color: _Q.terra,
                    onTap: () => setState(() => _type = option.label),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              const _SectionLabel('Note · optional'),
              const SizedBox(height: 9),
              TextField(
                controller: _note,
                decoration: const InputDecoration(
                  hintText: 'e.g. Family function out of town…',
                  fillColor: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: _Q.terra,
                    disabledBackgroundColor: _Q.line,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  onPressed: _type == null
                      ? null
                      : () => Navigator.pop(
                          context,
                          _LeaveSheetResult(
                            _type!.replaceAll(' leave', ''),
                            _note.text.trim(),
                          ),
                        ),
                  child: Text(
                    _type == null ? 'Choose a leave type' : 'Review request',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LeaveConfirmationSheet extends StatelessWidget {
  const _LeaveConfirmationSheet({
    required this.dashboard,
    required this.from,
    required this.to,
    required this.result,
  });

  final ManagerDashboard dashboard;
  final DateTime from;
  final DateTime to;
  final _LeaveSheetResult result;

  @override
  Widget build(BuildContext context) {
    final days = to.difference(from).inDays + 1;
    final range = _sameDay(from, to)
        ? _short(from)
        : '${_short(from)} – ${_short(to)}';
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: _Q.line,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text('Confirm leave request', style: _QText.topbar),
            const SizedBox(height: 6),
            Text(
              'Review the details before sending this to ${dashboard.approverName}.',
              style: _QText.subtitle,
            ),
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _Q.terraTint,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                children: [
                  const Icon(Icons.event_available_rounded, color: _Q.terra),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '$range · $days day${days == 1 ? '' : 's'}',
                      style: _QText.cardTitle,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _ConfirmationRow(label: 'Leave type', value: result.type),
            _ConfirmationRow(label: 'Approver', value: dashboard.approverName),
            if (result.note.isNotEmpty)
              _ConfirmationRow(label: 'Note', value: result.note),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Go back'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: _Q.terra),
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Send request'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ConfirmationRow extends StatelessWidget {
  const _ConfirmationRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 92, child: Text(label, style: _QText.mini)),
        Expanded(child: Text(value, style: _QText.cardTitle)),
      ],
    ),
  );
}

class _UploadCard extends StatelessWidget {
  const _UploadCard({
    required this.color,
    required this.tint,
    required this.value,
    required this.bytes,
    required this.onChanged,
  });
  final Color color;
  final Color tint;
  final String? value;
  final Uint8List? bytes;
  final ValueChanged<PlatformFile?> onChanged;

  bool get _canPreviewImage {
    return bytes != null &&
        (_extension == 'jpg' || _extension == 'jpeg' || _extension == 'png');
  }

  String? get _extension => value?.split('.').last.toLowerCase();

  Future<void> _pickFile(BuildContext context) async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png'],
        withData: true,
      );
      if (result == null || result.files.isEmpty || !context.mounted) return;
      final file = result.files.single;
      if (file.size > 5 * 1024 * 1024) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Choose a file smaller than 5 MB.')),
        );
        return;
      }
      if (file.bytes == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not read the selected file.')),
        );
        return;
      }
      onChanged(file);
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the file picker.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _pickFile(context),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 16),
            decoration: BoxDecoration(
              color: value == null ? Colors.white : tint,
              border: Border.all(
                color: value == null ? _Q.line : color,
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                if (_canPreviewImage) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 220),
                      child: Image.memory(
                        bytes!,
                        width: double.infinity,
                        fit: BoxFit.contain,
                        errorBuilder: (_, _, _) => const SizedBox.shrink(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: tint,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(
                    value == null
                        ? Icons.add_a_photo_rounded
                        : _extension == 'pdf'
                        ? Icons.picture_as_pdf_rounded
                        : Icons.image_rounded,
                    color: color,
                    size: 26,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  value ?? 'Tap to upload bill',
                  style: _QText.cardTitle.copyWith(
                    color: value == null ? _Q.ink : color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value == null
                      ? 'Photo or PDF, up to 5 MB'
                      : _extension == 'pdf'
                      ? 'PDF selected · Tap to replace'
                      : 'Image selected · Tap to replace',
                  style: _QText.cardSubtitleFaint,
                ),
              ],
            ),
          ),
        ),
        if (value != null)
          TextButton(
            onPressed: () => onChanged(null),
            child: const Text('Remove'),
          ),
      ],
    );
  }
}

class _WizardFooter extends StatelessWidget {
  const _WizardFooter({
    required this.color,
    required this.label,
    required this.onTap,
    this.secondary,
    this.onSecondary,
    this.secondaryAfter = false,
  });

  final Color color;
  final String label;
  final VoidCallback? onTap;
  final String? secondary;
  final VoidCallback? onSecondary;
  final bool secondaryAfter;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      bottom: false,
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (secondary != null && !secondaryAfter)
              TextButton(onPressed: onSecondary, child: Text(secondary!)),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: color,
                  disabledBackgroundColor: _Q.line,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: onTap,
                child: Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
            if (secondary != null && secondaryAfter)
              TextButton(onPressed: onSecondary, child: Text(secondary!)),
          ],
        ),
      ),
    );
  }
}

class _PaperCard extends StatelessWidget {
  const _PaperCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _Q.line),
        borderRadius: BorderRadius.circular(18),
      ),
      child: child,
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _Q.terraTint,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded, color: _Q.terra, size: 20),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: _Q.ink, fontSize: 13, height: 1.45),
            ),
          ),
        ],
      ),
    );
  }
}

class _IconTile extends StatelessWidget {
  const _IconTile({
    required this.icon,
    required this.color,
    required this.tint,
    this.size = 44,
  });
  final IconData icon;
  final Color color;
  final Color tint;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: tint,
      borderRadius: BorderRadius.circular(13),
    ),
    child: Icon(icon, color: color, size: 22),
  );
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) =>
      Text(text.toUpperCase(), style: _QText.section);
}

enum _StepKind { choice, dates, date, text, upload }

class _FlowStep {
  const _FlowStep({
    required this.label,
    required this.kind,
    required this.question,
    required this.subtitle,
    this.options,
    this.placeholder,
    this.optional = false,
    this.money = false,
  });

  final String label;
  final _StepKind kind;
  final String question;
  final String subtitle;
  final List<_FlowOption>? options;
  final String? placeholder;
  final bool optional;
  final bool money;
}

class _FlowOption {
  const _FlowOption(this.label, this.icon, [this.hint]);
  final String label;
  final IconData icon;
  final String? hint;
}

class _Policy {
  const _Policy(this.title, this.icon, this.color, this.tint, this.body);
  final String title;
  final IconData icon;
  final Color color;
  final Color tint;
  final String body;
}

const _flowSteps = <_QuickFlow, List<_FlowStep>>{
  _QuickFlow.leave: [
    _FlowStep(
      label: 'Type',
      kind: _StepKind.choice,
      question: 'What type of leave?',
      subtitle: 'Pick the category that fits.',
      options: [
        _FlowOption('Sick', Icons.thermostat_rounded),
        _FlowOption('Casual', Icons.coffee_rounded),
        _FlowOption('Earned', Icons.flight_takeoff_rounded),
      ],
    ),
    _FlowStep(
      label: 'Dates',
      kind: _StepKind.dates,
      question: 'Which dates?',
      subtitle: 'Pick a start and end date.',
    ),
    _FlowStep(
      label: 'Note',
      kind: _StepKind.text,
      question: 'Add a note',
      subtitle: 'Optional — helps your manager.',
      placeholder: 'e.g. Family function out of town…',
      optional: true,
    ),
  ],
  _QuickFlow.overtime: [
    _FlowStep(
      label: 'Duration',
      kind: _StepKind.choice,
      question: 'How long?',
      subtitle: 'Half day is 4h, full day is 8h.',
      options: [
        _FlowOption('Full day', Icons.schedule_rounded, '8 hours'),
        _FlowOption('Half day', Icons.timelapse_rounded, '4 hours'),
      ],
    ),
    _FlowStep(
      label: 'Day',
      kind: _StepKind.date,
      question: 'Which day did you work overtime?',
      subtitle: 'Full day: week-offs & holidays only. Half day: any past day.',
    ),
    _FlowStep(
      label: 'Project',
      kind: _StepKind.text,
      question: 'Which project?',
      subtitle: 'The project this overtime was for.',
      placeholder: 'e.g. Apollo',
    ),
    _FlowStep(
      label: 'Note',
      kind: _StepKind.text,
      question: 'Add a note',
      subtitle: 'Optional — what did you work on?',
      placeholder: 'e.g. Release hotfix for Apollo…',
      optional: true,
    ),
  ],
  _QuickFlow.reimbursement: [
    _FlowStep(
      label: 'Date',
      kind: _StepKind.date,
      question: 'When was the expense?',
      subtitle: 'Pick the date on the bill.',
    ),
    _FlowStep(
      label: 'Amount',
      kind: _StepKind.text,
      question: 'How much?',
      subtitle: 'Amount you paid.',
      money: true,
    ),
    _FlowStep(
      label: 'Type',
      kind: _StepKind.choice,
      question: 'What type of expense?',
      subtitle: 'Pick a category.',
      options: [
        _FlowOption('Travel', Icons.directions_car_rounded),
        _FlowOption('Meals', Icons.restaurant_rounded),
        _FlowOption('Internet', Icons.wifi_rounded),
        _FlowOption('Other', Icons.more_horiz_rounded),
      ],
    ),
    _FlowStep(
      label: 'Bill',
      kind: _StepKind.upload,
      question: 'Upload your receipt',
      subtitle: 'Optional — choose a photo or PDF up to 5 MB.',
      optional: true,
    ),
    _FlowStep(
      label: 'Note',
      kind: _StepKind.text,
      question: 'Add a note',
      subtitle: 'Optional.',
      placeholder: 'e.g. Cab to client office…',
      optional: true,
    ),
  ],
};

const _policiesData = <_Policy>[
  _Policy(
    'Leave',
    Icons.calendar_month_rounded,
    _Q.terra,
    _Q.terraTint,
    '12 sick + 12 casual + 18 earned days a year. Apply at least 2 days ahead for planned leave; your manager approves within 48 hours. Unused earned leave carries over up to 30 days.',
  ),
  _Policy(
    'Attendance',
    Icons.access_time_filled_rounded,
    _Q.gold,
    _Q.goldTint,
    'Core hours are 11am–4pm, 9 hours a day. Mark in/out on the tracker. Three late marks in a month need a manager note. Work-from-home up to 8 days a month.',
  ),
  _Policy(
    'Payroll',
    Icons.payments_rounded,
    _Q.teal,
    _Q.tealTint,
    'Salary is credited on the last working day of the month. Payslips live on the Payroll tab. Raise any discrepancy within 7 days of credit and finance will resolve it.',
  ),
  _Policy(
    'POSH',
    Icons.shield_rounded,
    _Q.plum,
    _Q.plumTint,
    'Sowaka has zero tolerance for harassment. Complaints go to the Internal Committee and are handled confidentially, with resolution within 90 days. You can raise one anonymously.',
  ),
  _Policy(
    'Overtime',
    Icons.schedule_rounded,
    _Q.sage,
    _Q.sageTint,
    'Overtime needs prior manager approval. Full day = 8h, half day = 4h. Comp-off or pay-out is settled the following month at 1.5× the hourly rate.',
  ),
];

class _Q {
  static const bg = Color(0xFFF8F4EE);
  static const ink = Color(0xFF2A2420);
  static const inkSoft = Color(0xFF6E655C);
  static const inkFaint = Color(0xFFA79D92);
  static const line = Color(0xFFF0E8DD);
  static const terra = Color(0xFFBE5A36);
  static const terraDeep = Color(0xFF7C3318);
  static const terraTint = Color(0xFFF6E5DB);
  static const gold = Color(0xFFC98A2E);
  static const goldTint = Color(0xFFF4ECDD);
  static const teal = Color(0xFF4F8C89);
  static const tealTint = Color(0xFFDEEBE9);
  static const plum = Color(0xFF8A6AA0);
  static const plumTint = Color(0xFFEEE6F0);
  static const sage = Color(0xFF4C5840);
  static const sageTint = Color(0xFFE7EFE4);
  static const live = Color(0xFFC0392B);
}

class _QText {
  static const eyebrow = TextStyle(
    color: _Q.terra,
    fontSize: 11,
    fontWeight: FontWeight.w800,
    letterSpacing: 1.45,
  );
  static const hero = TextStyle(
    color: _Q.ink,
    fontSize: 29,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.8,
  );
  static const heroSmall = TextStyle(
    color: _Q.ink,
    fontSize: 23,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.4,
  );
  static const topbar = TextStyle(
    color: _Q.ink,
    fontSize: 19,
    fontWeight: FontWeight.w800,
  );
  static const section = TextStyle(
    color: _Q.inkFaint,
    fontSize: 12,
    fontWeight: FontWeight.w800,
    letterSpacing: .9,
  );
  static const subtitle = TextStyle(
    color: _Q.inkSoft,
    fontSize: 13.5,
    height: 1.45,
  );
  static const cardTitle = TextStyle(
    color: _Q.ink,
    fontSize: 15,
    fontWeight: FontWeight.w800,
  );
  static const cardSubtitle = TextStyle(
    color: _Q.inkSoft,
    fontSize: 12.5,
    height: 1.35,
  );
  static const cardSubtitleFaint = TextStyle(
    color: _Q.inkFaint,
    fontSize: 12.5,
    height: 1.35,
  );
  static const mini = TextStyle(
    color: _Q.inkFaint,
    fontSize: 11.5,
    fontWeight: FontWeight.w700,
  );
}

String _short(DateTime date) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${date.day} ${months[date.month - 1]}';
}

String _monthName(int month) {
  const months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  return months[month - 1];
}

bool _sameDay(DateTime? a, DateTime? b) =>
    a != null &&
    b != null &&
    a.year == b.year &&
    a.month == b.month &&
    a.day == b.day;

DateTime _dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);

String _rangeLabel(DateTime from, DateTime to) {
  final days = to.difference(from).inDays + 1;
  return _sameDay(from, to)
      ? '${_short(from)} · 1 day'
      : '${_short(from)} – ${_short(to)} · $days days';
}

String _weekday(int weekday) =>
    const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][weekday - 1];

String _decision(LeaveDecision decision) => switch (decision) {
  LeaveDecision.approved => 'Approved',
  LeaveDecision.declined => 'Declined',
  LeaveDecision.pending => 'Pending',
};

String _number(double value) {
  return value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toStringAsFixed(1);
}

String _money(double value) {
  final digits = value.round().toString();
  final buffer = StringBuffer();
  for (var index = 0; index < digits.length; index++) {
    if (index > 0 && (digits.length - index) % 3 == 0) buffer.write(',');
    buffer.write(digits[index]);
  }
  return '₹$buffer';
}

Color _flowColor(_QuickFlow flow) => switch (flow) {
  _QuickFlow.leave => _Q.terra,
  _QuickFlow.overtime => _Q.gold,
  _QuickFlow.reimbursement => _Q.teal,
};

String _flowTitle(_QuickFlow flow) => switch (flow) {
  _QuickFlow.leave => 'Apply for leave',
  _QuickFlow.overtime => 'Apply for overtime',
  _QuickFlow.reimbursement => 'Claim reimbursement',
};

String _flowCta(_QuickFlow flow) => switch (flow) {
  _QuickFlow.leave || _QuickFlow.overtime => 'Send to manager',
  _QuickFlow.reimbursement => 'Send to finance',
};

String _trackLabel(_QuickFlow flow) => switch (flow) {
  _QuickFlow.leave => 'Manage leave → My requests',
  _QuickFlow.overtime => 'Overtime → My requests',
  _QuickFlow.reimbursement => 'Reimbursements → My claims',
};
