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
  balance,
  calendar,
  wizard,
  success,
}

enum _QuickFlow { leave, overtime, reimbursement }

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
        _choice = null;
        _text.clear();
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
        _QuickPage.balance => _balance(),
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
        _ActionCard(
          icon: Icons.calendar_month_rounded,
          color: _Q.terra,
          tint: _Q.terraTint,
          title: 'Manage leave',
          subtitle: 'Apply · view requests',
          onTap: () => _open(_QuickPage.leave),
        ),
        _ActionCard(
          icon: Icons.schedule_rounded,
          color: _Q.gold,
          tint: _Q.goldTint,
          title: 'Overtime',
          subtitle: 'Apply · view requests',
          onTap: () => _open(_QuickPage.overtime),
        ),
        _ActionCard(
          icon: Icons.receipt_long_rounded,
          color: _Q.teal,
          tint: _Q.tealTint,
          title: 'Reimbursements',
          subtitle: 'Claim · view claims',
          onTap: () => _open(_QuickPage.reimbursements),
        ),
        const SizedBox(height: 20),
        const _SectionLabel('Info & tools'),
        const SizedBox(height: 10),
        _ActionCard(
          icon: Icons.menu_book_rounded,
          color: _Q.plum,
          tint: _Q.plumTint,
          title: 'View policy',
          subtitle: 'Leave, payroll, POSH…',
          onTap: () => _open(_QuickPage.policies),
        ),
        _ActionCard(
          icon: Icons.calendar_month_outlined,
          color: _Q.terraDeep,
          tint: _Q.terraTint,
          title: 'Download calendar',
          subtitle: 'Leaves + holidays .ics',
          onTap: () => _open(_QuickPage.calendar),
        ),
      ],
    );
  }

  Widget _leaveHub() {
    final requests = widget.dashboard.myLeaves;
    final balance = widget.dashboard.leaveBalance;
    return _HubScaffold(
      key: const ValueKey('leave-hub'),
      title: 'Manage leave',
      onBack: _back,
      children: [
        const Text('Leave balance', style: _QText.section),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _BalanceTile(
                'Sick',
                balance.sick.remaining,
                balance.sick.total,
                _Q.live,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _BalanceTile(
                'Casual',
                balance.casual.remaining,
                balance.casual.total,
                _Q.gold,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _BalanceTile(
                'Earned',
                balance.earned.remaining,
                balance.earned.total,
                _Q.teal,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _WideAction(
          icon: Icons.donut_large_rounded,
          title: 'View full balance',
          subtitle: 'Your balance for ${balance.year}',
          color: _Q.sage,
          tint: _Q.sageTint,
          onTap: () => _open(_QuickPage.balance),
        ),
        const SizedBox(height: 28),
        const Text('Apply for leave', style: _QText.section),
        const SizedBox(height: 10),
        _PrimaryAction(
          icon: Icons.add_rounded,
          label: 'New leave request',
          onTap: () => _start(_QuickFlow.leave),
        ),
        const SizedBox(height: 28),
        const Text('My requests', style: _QText.section),
        const SizedBox(height: 10),
        ...requests.map(
          (r) => _RequestRow(
            '${r.type} leave',
            '${_short(r.start)}–${_short(r.end)} · ${r.days} days',
            _decision(r.decision),
          ),
        ),
      ],
    );
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
    final compDays = approvedHours / 8;
    return _HubScaffold(
      key: const ValueKey('overtime-hub'),
      title: 'Overtime',
      onBack: _back,
      children: [
        Row(
          children: [
            Expanded(
              child: _StatTile(
                '${_number(approvedHours)}h',
                'Approved this month',
                _Q.teal,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(child: _StatTile('$pending', 'Pending', _Q.gold)),
            const SizedBox(width: 8),
            Expanded(
              child: _StatTile(
                '${_number(compDays)} day',
                'Comp-off due',
                _Q.terra,
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),
        _PrimaryAction(
          icon: Icons.add_rounded,
          label: 'Apply for overtime',
          color: _Q.gold,
          onTap: () => _start(_QuickFlow.overtime),
        ),
        const SizedBox(height: 28),
        const Text('My requests', style: _QText.section),
        const SizedBox(height: 10),
        ...requests.map(
          (request) => _RequestRow(
            request.project,
            '${_short(request.workDate)} · ${request.duration}',
            _decision(request.decision),
          ),
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
      children: [
        Row(
          children: [
            Expanded(
              child: _StatTile(_money(claimed), 'Claimed this month', _Q.ink),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _StatTile(_money(reimbursed), 'Reimbursed', _Q.teal),
            ),
            const SizedBox(width: 8),
            Expanded(child: _StatTile(_money(pending), 'Pending', _Q.gold)),
          ],
        ),
        const SizedBox(height: 22),
        _PrimaryAction(
          icon: Icons.add_rounded,
          label: 'New reimbursement claim',
          color: _Q.teal,
          onTap: () => _start(_QuickFlow.reimbursement),
        ),
        const SizedBox(height: 28),
        const Text('My claims', style: _QText.section),
        const SizedBox(height: 10),
        ...claims.map(
          (claim) => _RequestRow(
            '${claim.category} · ${_money(claim.amount)}',
            '${claim.note.isEmpty ? 'Expense claim' : claim.note} · ${_short(claim.expenseDate)}',
            claim.status,
          ),
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
        const Text(
          'Everything you need to know about working at Sowaka.',
          style: _QText.subtitle,
        ),
        const SizedBox(height: 18),
        ..._policiesData.map(
          (policy) => _ActionCard(
            icon: policy.icon,
            color: policy.color,
            tint: policy.tint,
            title: policy.title,
            subtitle: 'Read ${policy.title.toLowerCase()} policy',
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
      children: [
        Center(
          child: Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: policy.tint,
              borderRadius: BorderRadius.circular(23),
            ),
            child: Icon(policy.icon, color: policy.color, size: 34),
          ),
        ),
        const SizedBox(height: 22),
        Text(
          policy.title,
          textAlign: TextAlign.center,
          style: _QText.heroSmall,
        ),
        const SizedBox(height: 16),
        _PaperCard(
          child: Text(
            policy.body,
            style: const TextStyle(
              color: _Q.inkSoft,
              fontSize: 15,
              height: 1.65,
            ),
          ),
        ),
        const SizedBox(height: 14),
        const _InfoCard('Questions? Speak to your manager or People Ops.'),
      ],
    );
  }

  Widget _balance() {
    final balance = widget.dashboard.leaveBalance;
    return _HubScaffold(
      key: const ValueKey('balance'),
      title: 'Leave balance',
      onBack: _back,
      children: [
        Text('Your balance for ${balance.year}.', style: _QText.subtitle),
        const SizedBox(height: 18),
        _LargeBalance(
          'Sick leave',
          balance.sick.remaining,
          balance.sick.total,
          _Q.live,
        ),
        _LargeBalance(
          'Casual leave',
          balance.casual.remaining,
          balance.casual.total,
          _Q.gold,
        ),
        _LargeBalance(
          'Earned leave',
          balance.earned.remaining,
          balance.earned.total,
          _Q.teal,
        ),
        const SizedBox(height: 18),
        _PrimaryAction(
          icon: Icons.add_rounded,
          label: 'Apply for leave',
          onTap: () => _start(_QuickFlow.leave),
        ),
      ],
    );
  }

  Widget _calendar() {
    const days = <String>['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final today = DateTime.now();
    final firstDay = DateTime(today.year, today.month);
    final leadingDays = firstDay.weekday - 1;
    final daysInMonth = DateTime(today.year, today.month + 1, 0).day;
    final markedDays = <int>{};
    for (final leave in widget.dashboard.myLeaves) {
      var date = DateTime(leave.start.year, leave.start.month, leave.start.day);
      final end = DateTime(leave.end.year, leave.end.month, leave.end.day);
      while (!date.isAfter(end)) {
        if (date.year == today.year && date.month == today.month) {
          markedDays.add(date.day);
        }
        date = date.add(const Duration(days: 1));
      }
    }
    return _HubScaffold(
      key: const ValueKey('calendar'),
      title: 'Leave calendar',
      onBack: _back,
      children: [
        Text('${_monthName(today.month)} ${today.year}', style: _QText.section),
        const SizedBox(height: 14),
        _PaperCard(
          child: Column(
            children: [
              Row(
                children: days
                    .map(
                      (day) => Expanded(
                        child: Center(child: Text(day, style: _QText.mini)),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 10),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 35,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  mainAxisSpacing: 4,
                  crossAxisSpacing: 4,
                ),
                itemBuilder: (context, index) {
                  final day = index - leadingDays + 1;
                  if (day < 1 || day > daysInMonth) {
                    return const SizedBox();
                  }
                  final marked = markedDays.contains(day);
                  return Container(
                    decoration: BoxDecoration(
                      color: marked ? _Q.terraTint : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$day',
                      style: TextStyle(
                        color: marked ? _Q.terra : _Q.ink,
                        fontSize: 12.5,
                        fontWeight: marked ? FontWeight.w800 : FontWeight.w600,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        const Text('Upcoming holidays', style: _QText.section),
        const SizedBox(height: 10),
        const _RequestRow('Independence Day', '15 Aug · Fri', 'Holiday'),
        const _RequestRow('Ganesh Chaturthi', '27 Aug · Wed', 'Holiday'),
        const _RequestRow('Gandhi Jayanti', '2 Oct · Fri', 'Holiday'),
        const SizedBox(height: 18),
        _PrimaryAction(
          icon: Icons.download_rounded,
          label: 'Download .ics calendar',
          onTap: () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Calendar download prepared')),
          ),
        ),
      ],
    );
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
            : 'Continue',
        secondary: step?.optional == true ? 'Skip for now' : null,
        onSecondary: () => _advance(step!, skip: true),
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
      _StepKind.dates || _StepKind.date || _StepKind.upload => true,
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
          _answers[step.label] = '';
      }
    }
    setState(() {
      _step = (_step + 1).clamp(0, steps.length);
      _choice = null;
      _text.clear();
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
                  onTap: () => setState(() => _choice = option.label),
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
      _StepKind.dates => Row(
        children: [
          Expanded(child: _DateTile('From', _from, (d) => _pickDate(true, d))),
          const SizedBox(width: 10),
          Expanded(child: _DateTile('To', _to, (d) => _pickDate(false, d))),
        ],
      ),
      _StepKind.date => _DateTile('Date', _from, (d) => _pickDate(true, d)),
      _StepKind.upload => _UploadCard(color: color),
    };
  }

  Future<void> _pickDate(bool from, DateTime initial) async {
    final today = DateTime.now();
    final historical = _flow != _QuickFlow.leave;
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2025),
      lastDate: historical ? today : DateTime(today.year + 2, 12, 31),
    );
    if (date == null || !mounted) return;
    setState(() {
      if (from) {
        _from = date;
        if (_to.isBefore(_from)) _to = _from;
      } else {
        _to = date;
      }
    });
  }

  Widget _reviewCard() {
    final entries = <MapEntry<String, String>>[
      ..._answers.entries,
      if (_flow == _QuickFlow.leave)
        MapEntry('Approver', widget.dashboard.approverName),
      if (_flow == _QuickFlow.overtime)
        MapEntry('Approver', widget.dashboard.approverName),
    ];
    return _PaperCard(
      child: Column(
        children: entries.indexed.map((entry) {
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              border: entry.$1 == entries.length - 1
                  ? null
                  : const Border(bottom: BorderSide(color: _Q.line)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 88,
                  child: Text(entry.$2.key, style: _QText.mini),
                ),
                Expanded(
                  child: Text(
                    entry.$2.value.isEmpty ? '—' : entry.$2.value,
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
        }).toList(),
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
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: _Q.sageTint,
              ),
              child: const Icon(Icons.check_rounded, color: _Q.sage, size: 38),
            ),
            const SizedBox(height: 20),
            const Text('Request sent!', style: _QText.heroSmall),
            const SizedBox(height: 8),
            Text(
              _flow == _QuickFlow.reimbursement
                  ? 'Sent to finance'
                  : 'Sent to ${widget.dashboard.approverName}',
              style: _QText.subtitle,
            ),
            const SizedBox(height: 8),
            Text(
              'Track it under ${_trackLabel(_flow)}.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: _Q.inkSoft, fontSize: 13),
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
              onPressed: () => setState(() => _page = _QuickPage.home),
              child: const Text('Back to Quick Actions'),
            ),
          ],
        ),
      ),
    );
  }

  List<_FlowStep> _stepsForCurrentFlow() {
    if (_flow != _QuickFlow.leave) return _flowSteps[_flow]!;
    final balance = widget.dashboard.leaveBalance;
    final leaveSteps = _flowSteps[_QuickFlow.leave]!;
    return [
      _FlowStep(
        label: leaveSteps.first.label,
        kind: leaveSteps.first.kind,
        question: leaveSteps.first.question,
        subtitle: leaveSteps.first.subtitle,
        options: [
          _FlowOption(
            'Sick',
            Icons.thermostat_rounded,
            '${balance.sick.remaining} of ${balance.sick.total} left',
          ),
          _FlowOption(
            'Casual',
            Icons.coffee_rounded,
            '${balance.casual.remaining} of ${balance.casual.total} left',
          ),
          _FlowOption(
            'Earned',
            Icons.flight_takeoff_rounded,
            '${balance.earned.remaining} of ${balance.earned.total} left',
          ),
        ],
      ),
      ...leaveSteps.skip(1),
    ];
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
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 18, 8),
            child: Row(
              children: [
                IconButton(
                  onPressed: onBack,
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
                const SizedBox(width: 4),
                Expanded(child: Text(title, style: _QText.topbar)),
              ],
            ),
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
            children: children,
          ),
        ),
        ?footer,
      ],
    );
  }
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
  final String subtitle;
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
                      const SizedBox(height: 3),
                      Text(subtitle, style: _QText.cardSubtitle),
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

class _WideAction extends StatelessWidget {
  const _WideAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.tint,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final Color tint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => _ActionCard(
    icon: icon,
    color: color,
    tint: tint,
    title: title,
    subtitle: subtitle,
    onTap: onTap,
  );
}

class _PrimaryAction extends StatelessWidget {
  const _PrimaryAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = _Q.terra,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      style: FilledButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      onPressed: onTap,
      icon: Icon(icon, size: 20),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
    );
  }
}

class _RequestRow extends StatelessWidget {
  const _RequestRow(this.title, this.subtitle, this.status);

  final String title;
  final String subtitle;
  final String status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'Approved' || 'Paid' => _Q.teal,
      'Declined' => _Q.live,
      'Holiday' => _Q.plum,
      _ => _Q.gold,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: _Q.line)),
      ),
      child: Row(
        children: [
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
              color: color.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(
              status,
              style: TextStyle(
                color: color,
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

class _BalanceTile extends StatelessWidget {
  const _BalanceTile(this.label, this.left, this.total, this.color);

  final String label;
  final int left;
  final int total;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _Q.line),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: _QText.mini),
          const SizedBox(height: 5),
          RichText(
            text: TextSpan(
              style: TextStyle(
                color: color,
                fontSize: 21,
                fontWeight: FontWeight.w800,
                fontFamily: 'Plus Jakarta Sans',
              ),
              text: '$left',
              children: [
                TextSpan(
                  text: ' / $total',
                  style: const TextStyle(color: _Q.inkFaint, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LargeBalance extends StatelessWidget {
  const _LargeBalance(this.label, this.left, this.total, this.color);

  final String label;
  final int left;
  final int total;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _PaperCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(label, style: _QText.cardTitle)),
                Text('$left of $total left', style: _QText.cardSubtitle),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: left / total,
                minHeight: 8,
                color: color,
                backgroundColor: color.withValues(alpha: .13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile(this.value, this.label, this.color);

  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 104,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _Q.line),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const Spacer(),
          Text(label, maxLines: 2, style: _QText.mini),
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

class _DateTile extends StatelessWidget {
  const _DateTile(this.label, this.date, this.onTap);

  final String label;
  final DateTime date;
  final ValueChanged<DateTime> onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => onTap(date),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: _Q.line),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: _QText.mini),
            const SizedBox(height: 5),
            Row(
              children: [
                Expanded(child: Text(_short(date), style: _QText.cardTitle)),
                const Icon(
                  Icons.calendar_today_rounded,
                  size: 17,
                  color: _Q.terra,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _UploadCard extends StatelessWidget {
  const _UploadCard({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: _Q.line),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Icon(Icons.upload_file_rounded, color: color, size: 36),
          const SizedBox(height: 10),
          const Text('Tap to attach a bill', style: _QText.cardTitle),
          const SizedBox(height: 4),
          const Text(
            'PDF, JPG or PNG · up to 10 MB',
            style: _QText.cardSubtitle,
          ),
        ],
      ),
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
  });

  final Color color;
  final String label;
  final VoidCallback? onTap;
  final String? secondary;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (secondary != null)
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
  });
  final IconData icon;
  final Color color;
  final Color tint;

  @override
  Widget build(BuildContext context) => Container(
    width: 44,
    height: 44,
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
  Widget build(BuildContext context) => Text(text, style: _QText.section);
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
        _FlowOption('Sick', Icons.thermostat_rounded, '8 of 12 left'),
        _FlowOption('Casual', Icons.coffee_rounded, '7 of 12 left'),
        _FlowOption('Earned', Icons.flight_takeoff_rounded, '16 of 18 left'),
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
      label: 'Day',
      kind: _StepKind.date,
      question: 'Which day did you work overtime?',
      subtitle: 'Pick the date.',
    ),
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
      placeholder: '1,200',
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
      kind: _StepKind.text,
      question: 'Add a receipt reference',
      subtitle: 'Optional — enter the receipt or bill filename.',
      placeholder: 'e.g. cab-receipt-12-jun.pdf',
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
    color: _Q.ink,
    fontSize: 18,
    fontWeight: FontWeight.w800,
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
