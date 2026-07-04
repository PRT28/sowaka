import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../routes/app_routes.dart';
import '../../auth/data/auth_models.dart';
import '../../auth/data/auth_session_store.dart';
import '../bloc/manager_bloc.dart';
import '../data/manager_models.dart';
import 'quick_actions_screen.dart';

class ManagerScreen extends StatefulWidget {
  const ManagerScreen({super.key, required this.session});

  final AuthSession session;

  @override
  State<ManagerScreen> createState() => _ManagerScreenState();
}

class _ManagerScreenState extends State<ManagerScreen> {
  late final ManagerBloc _bloc;
  late final QuickActionsController _quickActionsController;

  @override
  void initState() {
    super.initState();
    _quickActionsController = QuickActionsController()
      ..addListener(_refreshBackState);
    _bloc = ManagerBloc(session: widget.session)
      ..add(const LoadManagerDashboard());
  }

  @override
  void dispose() {
    _quickActionsController
      ..removeListener(_refreshBackState)
      ..dispose();
    _bloc.dispose();
    super.dispose();
  }

  void _refreshBackState() {
    if (mounted) setState(() {});
  }

  ManagerTab get _defaultTab => widget.session.user.role == 'manager'
      ? ManagerTab.manage
      : ManagerTab.grow;

  bool _hasBackTarget(ManagerState state) {
    return state.awardPickerKey != null ||
        state.applyLeaveOpen ||
        state.view != ManagerView.home ||
        (state.tab == ManagerTab.quick && _quickActionsController.canGoBack) ||
        state.tab != _defaultTab;
  }

  void _handleBack(ManagerState state) {
    if (state.awardPickerKey != null) {
      _bloc.add(const CloseAwardPicker());
    } else if (state.applyLeaveOpen) {
      _bloc.add(const CloseApplyLeave());
    } else if (state.view == ManagerView.feedbackRecord) {
      _bloc.add(const CloseFeedbackRecord());
    } else if (state.view == ManagerView.feedbackList) {
      _bloc.add(const CloseFeedbackList());
    } else if (state.tab == ManagerTab.quick &&
        _quickActionsController.canGoBack) {
      _quickActionsController.handleBack();
    } else if (state.tab != _defaultTab) {
      _bloc.add(ChangeManagerTab(_defaultTab));
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('You will need to sign in again to continue.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Log out'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await AuthSessionStore().clear();
    if (!mounted) return;
    Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(AppRoutes.login, (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ManagerState>(
      stream: _bloc.stream,
      initialData: _bloc.state,
      builder: (context, snapshot) {
        final state = snapshot.data ?? _bloc.state;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final message = state.message;
          if (!mounted || message == null) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              behavior: SnackBarBehavior.floating,
              backgroundColor: MColors.ink,
            ),
          );
          _bloc.add(const ClearManagerMessage());
        });

        if (state.status == ManagerLoadStatus.loading ||
            state.status == ManagerLoadStatus.initial) {
          return const Scaffold(
            backgroundColor: MColors.bg,
            body: Center(
              child: CircularProgressIndicator(color: MColors.terra),
            ),
          );
        }

        if (state.status == ManagerLoadStatus.failure ||
            state.dashboard == null) {
          return Scaffold(
            backgroundColor: MColors.bg,
            body: Center(
              child: Text(state.error ?? 'Could not load manager view'),
            ),
          );
        }

        return PopScope(
          canPop: !_hasBackTarget(state),
          onPopInvokedWithResult: (didPop, result) {
            if (!didPop) _handleBack(state);
          },
          child: Scaffold(
            backgroundColor: MColors.bg,
            body: Stack(
              children: [
                Column(
                  children: [
                    Expanded(
                      child: _TabContent(
                        state: state,
                        bloc: _bloc,
                        quickActionsController: _quickActionsController,
                        onLogout: _logout,
                      ),
                    ),
                    _BottomTabs(state: state, bloc: _bloc),
                  ],
                ),
                if (state.awardPickerKey != null)
                  _AwardPicker(state: state, bloc: _bloc),
                if (state.applyLeaveOpen)
                  _ApplyLeaveSheet(state: state, bloc: _bloc),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TabContent extends StatelessWidget {
  const _TabContent({
    required this.state,
    required this.bloc,
    required this.quickActionsController,
    required this.onLogout,
  });

  final ManagerState state;
  final ManagerBloc bloc;
  final QuickActionsController quickActionsController;
  final Future<void> Function() onLogout;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      child: switch (state.tab) {
        ManagerTab.manage => _ManageContent(state: state, bloc: bloc),
        ManagerTab.grow => _GrowTab(state: state),
        ManagerTab.connect => const _ComingSoonTab(
          key: ValueKey('connect'),
          icon: Icons.newspaper_rounded,
          title: 'Connect',
          body: 'Company feed, shout-outs and updates — coming soon.',
        ),
        ManagerTab.quick => QuickActionsScreen(
          key: const ValueKey('quick-actions'),
          bloc: bloc,
          dashboard: state.dashboard!,
          controller: quickActionsController,
          onLogout: onLogout,
        ),
      },
    );
  }
}

class _ManageContent extends StatelessWidget {
  const _ManageContent({required this.state, required this.bloc});

  final ManagerState state;
  final ManagerBloc bloc;

  @override
  Widget build(BuildContext context) {
    return switch (state.view) {
      ManagerView.home => _ManagerHome(state: state, bloc: bloc),
      ManagerView.feedbackList => _FeedbackList(state: state, bloc: bloc),
      ManagerView.feedbackRecord => _RecordFeedback(state: state, bloc: bloc),
    };
  }
}

class _ManagerHome extends StatelessWidget {
  const _ManagerHome({required this.state, required this.bloc});

  final ManagerState state;
  final ManagerBloc bloc;

  @override
  Widget build(BuildContext context) {
    final data = state.dashboard!;
    final open = data.team
        .where(
          (item) =>
              item.status != FeedbackStatus.sent &&
              item.status != FeedbackStatus.missed,
        )
        .length;
    final given = data.team.length - open;
    final pendingLeaves = data.leaves
        .where((leave) => leave.decision == LeaveDecision.pending)
        .length;
    final named = data.awards.where((award) => award.nomineeId != null).length;
    final pendingOvertime = data.overtime
        .where((request) => request.decision == LeaveDecision.pending)
        .toList();

    return ListView(
      key: const ValueKey('manager-home'),
      padding: const EdgeInsets.fromLTRB(16, 60, 16, 34),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_monthName(data.today.month)} · for you to action',
                      style: const TextStyle(
                        color: MColors.inkSoft,
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Your Team',
                      style: TextStyle(
                        color: MColors.ink,
                        fontWeight: FontWeight.w800,
                        fontSize: 27,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
              ),
              AvatarBadge(initial: data.managerInitial, index: 1, size: 42),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                value: '$open',
                label: 'feedback to give',
                color: MColors.terra,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MetricCard(
                value: '$pendingLeaves',
                label: 'leaves pending',
                color: pendingLeaves == 0 ? MColors.sageDeep : MColors.gold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _SectionTitle(
          title: 'Feedback',
          trailing: '$given of ${data.team.length} given',
        ),
        const SizedBox(height: 10),
        _ProgressBar(
          value: data.team.isEmpty ? 0 : given / data.team.length,
          color: MColors.terra,
        ),
        const SizedBox(height: 14),
        PressableCard(
          onTap: () => bloc.add(const OpenFeedbackList()),
          padding: const EdgeInsets.all(15),
          child: Row(
            children: [
              const IconBox(
                icon: Icons.checklist_rounded,
                color: MColors.terra,
                tint: MColors.terraTint,
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$open still to give',
                      style: const TextStyle(
                        color: MColors.ink,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    const Text(
                      'Review your team and record this month’s feedback',
                      style: TextStyle(
                        color: MColors.inkSoft,
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const Text(
                'View all',
                style: TextStyle(
                  color: MColors.terra,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        _SectionTitle(
          title: 'Leave requests',
          trailing: pendingLeaves == 0 ? 'All clear' : '$pendingLeaves pending',
        ),
        const SizedBox(height: 12),
        ...data.leaves.map(
          (leave) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _LeaveCard(leave: leave, bloc: bloc),
          ),
        ),
        const SizedBox(height: 14),
        _SectionTitle(
          title: 'Overtime requests',
          trailing: '${pendingOvertime.length} pending',
        ),
        const SizedBox(height: 12),
        ...pendingOvertime.map(
          (request) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _OvertimeRequestCard(
              request: request,
              onDecide: (decision) =>
                  bloc.add(DecideOvertime(request.id, decision)),
            ),
          ),
        ),
        const SizedBox(height: 14),
        _SectionTitle(
          title: 'Recognition',
          trailing: '$named of ${data.awards.length} named',
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            'Nominate someone for ${_monthName(data.today.month)}’s awards.',
            style: const TextStyle(color: MColors.inkSoft, fontSize: 13.5),
          ),
        ),
        const SizedBox(height: 13),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: data.awards.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.08,
          ),
          itemBuilder: (context, index) {
            return _AwardCard(
              award: data.awards[index],
              team: data.recognitionCandidates,
              onTap: () => bloc.add(OpenAwardPicker(data.awards[index].key)),
            );
          },
        ),
      ],
    );
  }
}

class _FeedbackList extends StatelessWidget {
  const _FeedbackList({required this.state, required this.bloc});

  final ManagerState state;
  final ManagerBloc bloc;

  @override
  Widget build(BuildContext context) {
    final data = state.dashboard!;
    final open = data.team
        .where(
          (item) =>
              item.status != FeedbackStatus.sent &&
              item.status != FeedbackStatus.missed,
        )
        .toList();
    final given = data.team
        .where(
          (item) =>
              item.status == FeedbackStatus.sent ||
              item.status == FeedbackStatus.missed,
        )
        .toList();
    final overdue = open.where((item) => item.missedMonths > 0).toList();
    final soon = open
        .where((item) => _daysUntil(data.today, item.next) <= 4)
        .toList();

    var visible = open.where((item) {
      final query = state.searchQuery.trim().toLowerCase();
      if (query.isEmpty) return true;
      return item.name.toLowerCase().contains(query) ||
          item.team.toLowerCase().contains(query);
    }).toList();
    visible = switch (state.feedbackFilter) {
      FeedbackFilter.overdue =>
        visible.where((item) => item.missedMonths > 0).toList(),
      FeedbackFilter.soon =>
        visible
            .where(
              (item) =>
                  item.missedMonths == 0 &&
                  _daysUntil(data.today, item.next) <= 4,
            )
            .toList(),
      FeedbackFilter.all => visible,
    };
    visible.sort((a, b) {
      final ar = a.missedMonths > 0
          ? 0
          : _daysUntil(data.today, a.next) <= 4
          ? 1
          : 2;
      final br = b.missedMonths > 0
          ? 0
          : _daysUntil(data.today, b.next) <= 4
          ? 1
          : 2;
      return ar == br ? a.next.compareTo(b.next) : ar.compareTo(br);
    });

    return Column(
      key: const ValueKey('feedback-list'),
      children: [
        _TopBar(
          title: 'Monthly Check-ins',
          sub: '${_monthName(data.today.month)} · for you to action',
          onBack: () => bloc.add(const CloseFeedbackList()),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 34),
            children: [
              Row(
                children: [
                  Expanded(
                    child: _MetricCard(
                      value: '${open.length}',
                      label: 'feedback to give',
                      color: MColors.terra,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _MetricCard(
                      value: '${overdue.length}',
                      label: 'overdue',
                      color: overdue.isEmpty ? MColors.sageDeep : MColors.live,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _SectionTitle(
                title: 'Feedback',
                trailing: '${given.length} of ${data.team.length} given',
              ),
              const SizedBox(height: 10),
              _ProgressBar(
                value: given.length / data.team.length,
                color: MColors.terra,
              ),
              const SizedBox(height: 14),
              _SearchBox(
                value: state.searchQuery,
                onChanged: (value) => bloc.add(ChangeFeedbackSearch(value)),
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _FilterChip(
                      label: 'All',
                      count: open.length,
                      selected: state.feedbackFilter == FeedbackFilter.all,
                      onTap: () => bloc.add(
                        const ChangeFeedbackFilter(FeedbackFilter.all),
                      ),
                    ),
                    _FilterChip(
                      label: 'Overdue',
                      count: overdue.length,
                      dot: MColors.live,
                      selected: state.feedbackFilter == FeedbackFilter.overdue,
                      onTap: () => bloc.add(
                        const ChangeFeedbackFilter(FeedbackFilter.overdue),
                      ),
                    ),
                    _FilterChip(
                      label: 'Due soon',
                      count: soon.length,
                      dot: MColors.gold,
                      selected: state.feedbackFilter == FeedbackFilter.soon,
                      onTap: () => bloc.add(
                        const ChangeFeedbackFilter(FeedbackFilter.soon),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (visible.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      'Nothing here — nicely done.',
                      style: TextStyle(color: MColors.inkFaint),
                    ),
                  ),
                )
              else ...[
                if (state.feedbackFilter == FeedbackFilter.all &&
                    state.searchQuery.isEmpty) ...[
                  _GroupRows(
                    label: 'Overdue',
                    count: overdue.length,
                    color: MColors.live,
                    rows: visible
                        .where((item) => item.missedMonths > 0)
                        .toList(),
                    today: data.today,
                    bloc: bloc,
                  ),
                  _GroupRows(
                    label: 'Due soon',
                    count: soon.length,
                    color: MColors.gold,
                    rows: visible
                        .where(
                          (item) =>
                              item.missedMonths == 0 &&
                              _daysUntil(data.today, item.next) <= 4,
                        )
                        .toList(),
                    today: data.today,
                    bloc: bloc,
                  ),
                  _GroupRows(
                    label: 'Later this cycle',
                    count: visible
                        .where(
                          (item) =>
                              item.missedMonths == 0 &&
                              _daysUntil(data.today, item.next) > 4,
                        )
                        .length,
                    color: MColors.inkFaint,
                    rows: visible
                        .where(
                          (item) =>
                              item.missedMonths == 0 &&
                              _daysUntil(data.today, item.next) > 4,
                        )
                        .toList(),
                    today: data.today,
                    bloc: bloc,
                  ),
                ] else
                  _RowsCard(rows: visible, today: data.today, bloc: bloc),
              ],
              if (given.isNotEmpty) ...[
                const SizedBox(height: 20),
                PressableCard(
                  color: const Color(0xFFEFE7DA),
                  borderColor: Colors.transparent,
                  padding: const EdgeInsets.all(12),
                  onTap: () => bloc.add(const ToggleGivenFeedback()),
                  child: Row(
                    children: [
                      const IconBox(
                        icon: Icons.check_rounded,
                        color: Colors.white,
                        tint: MColors.sage,
                        size: 22,
                        iconSize: 14,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '${given.length} given this cycle',
                          style: const TextStyle(
                            color: MColors.inkSoft,
                            fontWeight: FontWeight.w800,
                            fontSize: 14.5,
                          ),
                        ),
                      ),
                      Icon(
                        state.showGiven
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        color: MColors.inkSoft,
                      ),
                    ],
                  ),
                ),
                if (state.showGiven) ...[
                  const SizedBox(height: 10),
                  _GivenRows(rows: given),
                ],
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _OwnLeaveCard extends StatelessWidget {
  const _OwnLeaveCard({required this.leave});

  final LeaveRequest leave;

  @override
  Widget build(BuildContext context) {
    final (label, color, icon) = switch (leave.decision) {
      LeaveDecision.approved => (
        'Approved',
        MColors.sageDeep,
        Icons.check_circle_rounded,
      ),
      LeaveDecision.declined => (
        'Declined',
        MColors.live,
        Icons.cancel_rounded,
      ),
      LeaveDecision.pending => (
        'Pending',
        MColors.gold,
        Icons.schedule_rounded,
      ),
    };
    return PressableCard(
      padding: const EdgeInsets.all(15),
      child: Row(
        children: [
          IconBox(
            icon: Icons.beach_access_outlined,
            color: leavePalette(leave.type).$1,
            tint: leavePalette(leave.type).$2,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${leave.type} · ${leave.days} ${leave.days == 1 ? 'day' : 'days'}',
                  style: const TextStyle(
                    color: MColors.ink,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${shortDate(leave.start)}–${shortDate(leave.end)}',
                  style: const TextStyle(
                    color: MColors.inkSoft,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecordFeedback extends StatelessWidget {
  const _RecordFeedback({required this.state, required this.bloc});

  final ManagerState state;
  final ManagerBloc bloc;

  @override
  Widget build(BuildContext context) {
    final member = state.selectedMember;
    if (member == null) {
      return const SizedBox.shrink();
    }
    final locked =
        member.status == FeedbackStatus.sent ||
        member.status == FeedbackStatus.missed;
    final complete = state.recordParams.every((item) => item.score > 0);
    final overall = state.recordParams.isEmpty
        ? 0.0
        : state.recordParams.fold<double>(0, (sum, item) => sum + item.score) /
              state.recordParams.length;
    final overallColor = scoreColor(overall == 0 ? 1 : overall);
    final avatarColor = avatarColors[member.avatarIndex % avatarColors.length];

    return Stack(
      key: const ValueKey('record-feedback'),
      children: [
        Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Color.alphaBlend(
                  avatarColor.withValues(alpha: .12),
                  MColors.bg,
                ),
                border: const Border(bottom: BorderSide(color: MColors.line)),
              ),
              padding: const EdgeInsets.fromLTRB(18, 52, 18, 14),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      RoundIconButton(
                        icon: Icons.chevron_left_rounded,
                        onTap: () => bloc.add(const CloseFeedbackRecord()),
                      ),
                      _StatusPill(status: member.status),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      AvatarBadge(
                        initial: member.initial,
                        index: member.avatarIndex,
                        size: 58,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              member.name,
                              style: const TextStyle(
                                color: MColors.ink,
                                fontSize: 25,
                                height: 1.1,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${member.team} · 1-on-1',
                              style: const TextStyle(
                                color: MColors.inkSoft,
                                fontSize: 14.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            'OVERALL',
                            style: TextStyle(
                              color: MColors.inkFaint,
                              fontSize: 10,
                              letterSpacing: 1.1,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 3),
                          RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: overall == 0
                                      ? '—'
                                      : overall.toStringAsFixed(1),
                                  style: TextStyle(
                                    color: overallColor,
                                    fontFamily: 'Plus Jakarta Sans',
                                    fontSize: 38,
                                    height: .9,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const TextSpan(
                                  text: '/5',
                                  style: TextStyle(
                                    color: MColors.inkFaint,
                                    fontFamily: 'Plus Jakarta Sans',
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  PressableCard(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        IconBox(
                          icon: Icons.show_chart_rounded,
                          color: avatarColor,
                          tint: avatarColor.withValues(alpha: .14),
                          size: 38,
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Past Feedbacks',
                                style: TextStyle(
                                  color: MColors.ink,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'View Journey',
                                style: TextStyle(
                                  color: MColors.inkSoft,
                                  fontSize: 12.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right_rounded, color: avatarColor),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(16, 18, 16, locked ? 34 : 124),
                children: [
                  if (!locked) const _FeedbackGuide(),
                  if (!locked) const SizedBox(height: 18),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      'Parameters',
                      style: TextStyle(
                        color: MColors.ink,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...state.recordParams.indexed.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _ParamCard(
                        param: entry.$2,
                        locked: locked,
                        onScore: (value) =>
                            bloc.add(UpdateFeedbackScore(entry.$1, value)),
                        onNote: (value) =>
                            bloc.add(UpdateFeedbackNote(entry.$1, value)),
                      ),
                    );
                  }),
                  PressableCard(
                    color: Colors.transparent,
                    borderColor: MColors.line,
                    dashed: true,
                    padding: const EdgeInsets.all(14),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_rounded,
                          color: MColors.inkSoft,
                          size: 18,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Add / edit parameters',
                          style: TextStyle(
                            color: MColors.inkSoft,
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      'Anything else',
                      style: TextStyle(
                        color: MColors.ink,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  PressableCard(
                    padding: const EdgeInsets.all(17),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Additional feedback',
                          style: TextStyle(
                            color: MColors.ink,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 5),
                        const Text(
                          "Context, wins or concerns the parameters above don't capture.",
                          style: TextStyle(
                            color: MColors.inkSoft,
                            fontSize: 13,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          initialValue: state.recordExtra,
                          enabled: !locked,
                          maxLines: 4,
                          onChanged: (value) =>
                              bloc.add(UpdateFeedbackExtra(value)),
                          decoration: _fieldDecoration(
                            "e.g. Took on the on-call rotation when the team was short-staffed…",
                            suffix: Icons.mic_none_rounded,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (!locked)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: MColors.line)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: ActionButton(
                        label: 'Save',
                        icon: Icons.save_outlined,
                        background: Colors.white,
                        foreground: MColors.ink,
                        border: MColors.line,
                        onTap: () => bloc.add(const SaveFeedback()),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: ActionButton(
                        label: 'Send to ${member.name.split(' ').first}',
                        icon: Icons.send_rounded,
                        background: complete ? MColors.terra : MColors.line,
                        foreground: complete ? Colors.white : MColors.inkFaint,
                        onTap: complete
                            ? () => _confirmSend(context, bloc, member)
                            : null,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _confirmSend(BuildContext context, ManagerBloc bloc, TeamMember member) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _ConfirmSendSheet(
          member: member,
          onSend: () {
            Navigator.of(context).pop();
            bloc.add(const SendFeedback());
          },
        );
      },
    );
  }
}

// Kept as a reusable surface for a future standalone attendance route.
// ignore: unused_element
class _AttendanceTab extends StatelessWidget {
  const _AttendanceTab({required this.state, required this.bloc});

  final ManagerState state;
  final ManagerBloc bloc;

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const ValueKey('attendance'),
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 34),
      children: [
        Text(
          _monthName(state.dashboard!.today.month),
          style: const TextStyle(
            color: MColors.inkSoft,
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        const Text(
          'Attendance',
          style: TextStyle(
            color: MColors.ink,
            fontSize: 27,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 110),
        const _ComingSoonBlock(
          icon: Icons.calendar_month_outlined,
          title: 'Attendance tracking',
          body: 'Clock-ins, shifts and monthly summaries land here soon.',
        ),
        const SizedBox(height: 90),
        PressableCard(
          onTap: () => bloc.add(const OpenApplyLeave()),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const IconBox(
                icon: Icons.beach_access_outlined,
                color: MColors.terra,
                tint: MColors.terraTint,
              ),
              const SizedBox(width: 13),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Apply for leave',
                      style: TextStyle(
                        color: MColors.ink,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Available now — request time off',
                      style: TextStyle(color: MColors.inkSoft, fontSize: 13),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: MColors.inkFaint),
            ],
          ),
        ),
        const SizedBox(height: 28),
        _SectionTitle(
          title: 'My leave requests',
          trailing: state.dashboard!.myLeaves.isEmpty
              ? 'None yet'
              : '${state.dashboard!.myLeaves.length} total',
        ),
        const SizedBox(height: 12),
        if (state.dashboard!.myLeaves.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'Your submitted leave requests will appear here.',
              style: TextStyle(color: MColors.inkSoft, fontSize: 13.5),
            ),
          )
        else
          ...state.dashboard!.myLeaves.map(
            (leave) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _OwnLeaveCard(leave: leave),
            ),
          ),
      ],
    );
  }
}

class _GrowTab extends StatelessWidget {
  const _GrowTab({required this.state});

  final ManagerState state;

  @override
  Widget build(BuildContext context) {
    final data = state.dashboard!;
    return ListView(
      key: const ValueKey('grow'),
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 34),
      children: [
        Text(
          _monthName(data.today.month),
          style: const TextStyle(
            color: MColors.inkSoft,
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        const Text(
          'Grow',
          style: TextStyle(
            color: MColors.ink,
            fontSize: 27,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 18),
        PressableCard(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              AvatarBadge(initial: data.managerInitial, index: 1, size: 58),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.managerName,
                      style: const TextStyle(
                        color: MColors.ink,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${data.managerTeam} · Your feedback journey',
                      style: const TextStyle(
                        color: MColors.inkSoft,
                        fontSize: 13.5,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                data.managerScore.toStringAsFixed(1),
                style: TextStyle(
                  color: scoreColor(data.managerScore),
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        const PressableCard(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              IconBox(
                icon: Icons.show_chart_rounded,
                color: MColors.plum,
                tint: MColors.plumTint,
              ),
              SizedBox(width: 13),
              Expanded(
                child: Text(
                  'Past feedbacks and growth insights will appear here as your manager shares them.',
                  style: TextStyle(
                    color: MColors.inkSoft,
                    fontSize: 14,
                    height: 1.45,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ComingSoonTab extends StatelessWidget {
  const _ComingSoonTab({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Center(
      key: const ValueKey('coming-soon'),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: _ComingSoonBlock(icon: icon, title: title, body: body),
      ),
    );
  }
}

class _BottomTabs extends StatelessWidget {
  const _BottomTabs({required this.state, required this.bloc});

  final ManagerState state;
  final ManagerBloc bloc;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: MColors.line)),
        ),
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
        child: Row(
          children: [
            if (state.canManage)
              _TabButton(
                label: 'Manage',
                icon: Icons.checklist_rounded,
                selected: state.tab == ManagerTab.manage,
                onTap: () =>
                    bloc.add(const ChangeManagerTab(ManagerTab.manage)),
              ),
            _TabButton(
              label: 'Grow',
              icon: Icons.show_chart_rounded,
              selected: state.tab == ManagerTab.grow,
              onTap: () => bloc.add(const ChangeManagerTab(ManagerTab.grow)),
            ),
            _TabButton(
              label: 'Connect',
              icon: Icons.newspaper_rounded,
              selected: state.tab == ManagerTab.connect,
              onTap: () => bloc.add(const ChangeManagerTab(ManagerTab.connect)),
            ),
            _TabButton(
              label: 'Quick Actions',
              icon: Icons.bolt_rounded,
              selected: state.tab == ManagerTab.quick,
              onTap: () => bloc.add(const ChangeManagerTab(ManagerTab.quick)),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected ? MColors.terraTint : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: selected ? MColors.terra : MColors.inkFaint),
              const SizedBox(height: 3),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected ? MColors.terra : MColors.inkFaint,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LeaveCard extends StatelessWidget {
  const _LeaveCard({required this.leave, required this.bloc});

  final LeaveRequest leave;
  final ManagerBloc bloc;

  @override
  Widget build(BuildContext context) {
    final colors = leavePalette(leave.type);
    return PressableCard(
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AvatarBadge(
                initial: leave.initial,
                index: leave.avatarIndex,
                size: 40,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      leave.who,
                      style: const TextStyle(
                        color: MColors.ink,
                        fontWeight: FontWeight.w800,
                        fontSize: 15.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${shortDate(leave.start)}–${shortDate(leave.end)} · ${leave.days} days',
                      style: const TextStyle(
                        color: MColors.inkSoft,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: colors.$2,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  leave.type,
                  style: TextStyle(
                    color: colors.$1,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            leave.reason,
            style: const TextStyle(
              color: MColors.ink,
              fontSize: 14,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Requested ${daysAgo(leave.requestedOn)} ago',
            style: const TextStyle(color: MColors.inkFaint, fontSize: 12),
          ),
          const SizedBox(height: 14),
          if (leave.decision == LeaveDecision.pending)
            Row(
              children: [
                Expanded(
                  child: ActionButton(
                    label: 'Decline',
                    background: Colors.white,
                    foreground: MColors.ink,
                    border: MColors.line,
                    onTap: () =>
                        bloc.add(DecideLeave(leave.id, LeaveDecision.declined)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ActionButton(
                    label: 'Approve',
                    background: MColors.terra,
                    foreground: Colors.white,
                    onTap: () =>
                        bloc.add(DecideLeave(leave.id, LeaveDecision.approved)),
                  ),
                ),
              ],
            )
          else
            Row(
              children: [
                Icon(
                  leave.decision == LeaveDecision.approved
                      ? Icons.check_circle_rounded
                      : Icons.cancel_rounded,
                  color: leave.decision == LeaveDecision.approved
                      ? MColors.sageDeep
                      : MColors.live,
                ),
                const SizedBox(width: 8),
                Text(
                  leave.decision == LeaveDecision.approved
                      ? 'Approved'
                      : 'Declined',
                  style: const TextStyle(
                    color: MColors.inkSoft,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _OvertimeRequestCard extends StatelessWidget {
  const _OvertimeRequestCard({required this.request, required this.onDecide});

  final OvertimeRequest request;
  final ValueChanged<LeaveDecision> onDecide;

  void _decide(LeaveDecision decision) {
    onDecide(decision);
  }

  @override
  Widget build(BuildContext context) {
    return PressableCard(
      onTap: () => _showDetails(context),
      padding: const EdgeInsets.all(15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AvatarBadge(
                initial: request.initial,
                index: request.avatarIndex,
                size: 40,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.who,
                      style: const TextStyle(
                        color: MColors.ink,
                        fontWeight: FontWeight.w800,
                        fontSize: 15.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${request.team} · ${_managerDate(request.workDate)}',
                      style: const TextStyle(
                        color: MColors.inkSoft,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: MColors.goldTint,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  request.duration,
                  style: const TextStyle(
                    color: MColors.gold,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 11),
          Text(
            request.project,
            style: const TextStyle(
              color: MColors.ink,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            _requestedAgo(request.requestedOn),
            style: const TextStyle(color: MColors.inkFaint, fontSize: 12),
          ),
          const SizedBox(height: 14),
          if (request.decision == LeaveDecision.pending)
            Row(
              children: [
                Expanded(
                  child: ActionButton(
                    label: 'Decline',
                    background: Colors.white,
                    foreground: MColors.ink,
                    border: MColors.line,
                    onTap: () => _decide(LeaveDecision.declined),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ActionButton(
                    label: 'Approve',
                    background: MColors.terra,
                    foreground: Colors.white,
                    onTap: () => _decide(LeaveDecision.approved),
                  ),
                ),
              ],
            )
          else
            Row(
              children: [
                Icon(
                  request.decision == LeaveDecision.approved
                      ? Icons.check_circle_rounded
                      : Icons.cancel_rounded,
                  color: request.decision == LeaveDecision.approved
                      ? MColors.sageDeep
                      : MColors.live,
                ),
                const SizedBox(width: 8),
                Text(
                  request.decision == LeaveDecision.approved
                      ? 'Approved'
                      : 'Declined',
                  style: const TextStyle(
                    color: MColors.inkSoft,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  void _showDetails(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: MColors.line,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Overtime request',
                style: TextStyle(
                  color: MColors.ink,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${request.who} · ${request.team}',
                style: const TextStyle(color: MColors.inkSoft, fontSize: 13.5),
              ),
              const SizedBox(height: 20),
              _OvertimeDetailRow(
                label: 'DATE',
                value: _managerDate(request.workDate),
              ),
              _OvertimeDetailRow(label: 'DURATION', value: request.duration),
              _OvertimeDetailRow(label: 'PROJECT', value: request.project),
              const SizedBox(height: 8),
              if (request.decision == LeaveDecision.pending)
                Row(
                  children: [
                    Expanded(
                      child: ActionButton(
                        label: 'Decline',
                        background: Colors.white,
                        foreground: MColors.ink,
                        border: MColors.line,
                        onTap: () {
                          Navigator.pop(sheetContext);
                          _decide(LeaveDecision.declined);
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ActionButton(
                        label: 'Approve',
                        background: MColors.terra,
                        foreground: Colors.white,
                        onTap: () {
                          Navigator.pop(sheetContext);
                          _decide(LeaveDecision.approved);
                        },
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OvertimeDetailRow extends StatelessWidget {
  const _OvertimeDetailRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: MColors.bg,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      children: [
        SizedBox(
          width: 82,
          child: Text(
            label,
            style: const TextStyle(
              color: MColors.inkFaint,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: .7,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: MColors.ink,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    ),
  );
}

class _AwardCard extends StatelessWidget {
  const _AwardCard({
    required this.award,
    required this.team,
    required this.onTap,
  });

  final AwardNomination award;
  final List<TeamMember> team;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = awardPalette(award.key);
    final nominee = award.nomineeId == null
        ? null
        : team.where((item) => item.id == award.nomineeId).firstOrNull;
    return PressableCard(
      onTap: onTap,
      padding: const EdgeInsets.all(13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconBox(
            icon: awardIcon(award.icon),
            color: palette.$1,
            tint: palette.$2,
            size: 40,
          ),
          const Spacer(),
          Text(
            award.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: MColors.ink,
              fontSize: 14.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            nominee?.name ?? award.subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: nominee == null ? MColors.inkSoft : palette.$1,
              fontSize: 12.2,
              height: 1.25,
              fontWeight: nominee == null ? FontWeight.w500 : FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _AwardPicker extends StatelessWidget {
  const _AwardPicker({required this.state, required this.bloc});

  final ManagerState state;
  final ManagerBloc bloc;

  @override
  Widget build(BuildContext context) {
    final data = state.dashboard!;
    final award = data.awards.firstWhere(
      (item) => item.key == state.awardPickerKey,
    );
    return Positioned.fill(
      child: GestureDetector(
        onTap: () => bloc.add(const CloseAwardPicker()),
        child: Container(
          color: MColors.ink.withValues(alpha: .44),
          alignment: Alignment.bottomCenter,
          child: GestureDetector(
            onTap: () {},
            child: SafeArea(
              top: false,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(18, 10, 18, 24),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                          color: MColors.line,
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      award.title,
                      style: const TextStyle(
                        color: MColors.ink,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Choose one teammate for this recognition.',
                      style: TextStyle(color: MColors.inkSoft, fontSize: 13.5),
                    ),
                    const SizedBox(height: 14),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 360),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: data.recognitionCandidates.length,
                        separatorBuilder: (context, index) =>
                            const Divider(height: 1, color: MColors.line),
                        itemBuilder: (context, index) {
                          final member = data.recognitionCandidates[index];
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: AvatarBadge(
                              initial: member.initial,
                              index: member.avatarIndex,
                              size: 38,
                            ),
                            title: Text(
                              member.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                color: MColors.ink,
                              ),
                            ),
                            subtitle: Text(member.team),
                            trailing: const Icon(Icons.chevron_right_rounded),
                            onTap: () =>
                                bloc.add(NominateAward(award.key, member.id)),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ApplyLeaveSheet extends StatefulWidget {
  const _ApplyLeaveSheet({required this.state, required this.bloc});

  final ManagerState state;
  final ManagerBloc bloc;

  @override
  State<_ApplyLeaveSheet> createState() => _ApplyLeaveSheetState();
}

class _ApplyLeaveSheetState extends State<_ApplyLeaveSheet> {
  String _type = 'Casual';
  late DateTime _startDate;
  late DateTime _endDate;
  final TextEditingController _reasonController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, now.day);
    _endDate = _startDate;
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _selectDate({required bool start}) async {
    final selected = await showDatePicker(
      context: context,
      initialDate: start ? _startDate : _endDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (selected == null || !mounted) return;
    setState(() {
      if (start) {
        _startDate = selected;
        if (_endDate.isBefore(selected)) _endDate = selected;
      } else {
        _endDate = selected;
      }
    });
  }

  void _submit() {
    final reason = _reasonController.text.trim();
    if (reason.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a reason for leave')),
      );
      return;
    }
    widget.bloc.add(
      SubmitLeaveApplication(
        type: _type,
        startDate: _startDate,
        endDate: _endDate,
        reason: reason,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: GestureDetector(
        onTap: () => widget.bloc.add(const CloseApplyLeave()),
        child: Container(
          color: MColors.ink.withValues(alpha: .44),
          alignment: Alignment.bottomCenter,
          child: GestureDetector(
            onTap: () {},
            child: SafeArea(
              top: false,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(18, 10, 18, 24),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: widget.state.applyLeaveSent
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const IconBox(
                            icon: Icons.check_rounded,
                            color: Colors.white,
                            tint: MColors.sage,
                            size: 62,
                            iconSize: 28,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Request sent',
                            style: TextStyle(
                              color: MColors.ink,
                              fontSize: 21,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 5),
                          const Text(
                            'Your manager will be notified.',
                            style: TextStyle(color: MColors.inkSoft),
                          ),
                          const SizedBox(height: 18),
                          ActionButton(
                            label: 'Done',
                            background: MColors.terra,
                            foreground: Colors.white,
                            onTap: () =>
                                widget.bloc.add(const CloseApplyLeave()),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Container(
                              width: 38,
                              height: 4,
                              decoration: BoxDecoration(
                                color: MColors.line,
                                borderRadius: BorderRadius.circular(99),
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          const Text(
                            'Apply for leave',
                            style: TextStyle(
                              color: MColors.ink,
                              fontSize: 21,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Wrap(
                            spacing: 8,
                            children: ['Sick', 'Casual', 'Earned'].map((type) {
                              final selected = _type == type;
                              return ChoiceChip(
                                label: Text(type),
                                selected: selected,
                                onSelected: (_) => setState(() => _type = type),
                                selectedColor: MColors.ink,
                                labelStyle: TextStyle(
                                  color: selected
                                      ? Colors.white
                                      : MColors.inkSoft,
                                  fontWeight: FontWeight.w800,
                                ),
                                backgroundColor: Colors.white,
                                side: const BorderSide(color: MColors.line),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            key: ValueKey(
                              'leave-start-${_startDate.toIso8601String()}',
                            ),
                            readOnly: true,
                            initialValue: MaterialLocalizations.of(
                              context,
                            ).formatMediumDate(_startDate),
                            onTap: () => _selectDate(start: true),
                            decoration: _fieldDecoration('Start date'),
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            key: ValueKey(
                              'leave-end-${_endDate.toIso8601String()}',
                            ),
                            readOnly: true,
                            initialValue: MaterialLocalizations.of(
                              context,
                            ).formatMediumDate(_endDate),
                            onTap: () => _selectDate(start: false),
                            decoration: _fieldDecoration('End date'),
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: _reasonController,
                            maxLines: 3,
                            maxLength: 500,
                            decoration: _fieldDecoration('Reason'),
                          ),
                          const SizedBox(height: 16),
                          ActionButton(
                            label: 'Submit request',
                            background: MColors.terra,
                            foreground: Colors.white,
                            onTap: _submit,
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GroupRows extends StatelessWidget {
  const _GroupRows({
    required this.label,
    required this.count,
    required this.color,
    required this.rows,
    required this.today,
    required this.bloc,
  });

  final String label;
  final int count;
  final Color color;
  final List<TeamMember> rows;
  final DateTime today;
  final ManagerBloc bloc;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(6, 18, 6, 8),
          child: Row(
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text(
                label.toUpperCase(),
                style: const TextStyle(
                  color: MColors.inkSoft,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: .6,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$count',
                style: const TextStyle(
                  color: MColors.inkFaint,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        _RowsCard(rows: rows, today: today, bloc: bloc),
      ],
    );
  }
}

class _RowsCard extends StatelessWidget {
  const _RowsCard({
    required this.rows,
    required this.today,
    required this.bloc,
  });

  final List<TeamMember> rows;
  final DateTime today;
  final ManagerBloc bloc;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: MColors.line),
        ),
        child: Column(
          children: rows.indexed.map((entry) {
            return _TeamRow(
              member: entry.$2,
              today: today,
              first: entry.$1 == 0,
              onTap: () => bloc.add(OpenFeedbackRecord(entry.$2.id)),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _TeamRow extends StatelessWidget {
  const _TeamRow({
    required this.member,
    required this.today,
    required this.first,
    required this.onTap,
  });

  final TeamMember member;
  final DateTime today;
  final bool first;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final overdue = member.missedMonths > 0;
    final due = _daysUntil(today, member.next);
    final soon = !overdue && due >= 0 && due <= 4;
    return Material(
      color: overdue ? const Color(0xFFFBF2E8) : Colors.white,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
          decoration: BoxDecoration(
            border: first
                ? null
                : const Border(top: BorderSide(color: Color(0xFFF4ECE0))),
          ),
          child: Row(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFD2C6B4), width: 2),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(width: 12),
              AvatarBadge(
                initial: member.initial,
                index: member.avatarIndex,
                size: 34,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      member.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: MColors.ink,
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 1),
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          color: MColors.inkSoft,
                          fontSize: 12,
                        ),
                        children: [
                          TextSpan(text: member.team),
                          if (overdue)
                            TextSpan(
                              text: ' · Missed ${member.missedMonths}mo',
                              style: const TextStyle(
                                color: MColors.live,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          if (soon)
                            TextSpan(
                              text: due == 0
                                  ? ' · Due today'
                                  : due == 1
                                  ? ' · Due tomorrow'
                                  : ' · Due in ${due}d',
                              style: const TextStyle(
                                color: MColors.gold,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFFC9BDAC)),
            ],
          ),
        ),
      ),
    );
  }
}

class _GivenRows extends StatelessWidget {
  const _GivenRows({required this.rows});

  final List<TeamMember> rows;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: MColors.line),
        ),
        child: Column(
          children: rows.indexed.map((entry) {
            final member = entry.$2;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
              decoration: BoxDecoration(
                border: entry.$1 == 0
                    ? null
                    : const Border(top: BorderSide(color: Color(0xFFF4ECE0))),
              ),
              child: Row(
                children: [
                  const IconBox(
                    icon: Icons.check_rounded,
                    color: Colors.white,
                    tint: MColors.sage,
                    size: 22,
                    iconSize: 13,
                  ),
                  const SizedBox(width: 12),
                  Opacity(
                    opacity: .55,
                    child: AvatarBadge(
                      initial: member.initial,
                      index: member.avatarIndex,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      member.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: MColors.inkFaint,
                        decoration: TextDecoration.lineThrough,
                        decorationColor: Color(0xFFCFC4B5),
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Text(
                    member.score.toStringAsFixed(1),
                    style: TextStyle(
                      color: scoreColor(member.score),
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _ParamCard extends StatefulWidget {
  const _ParamCard({
    required this.param,
    required this.locked,
    required this.onScore,
    required this.onNote,
  });

  final FeedbackParam param;
  final bool locked;
  final ValueChanged<double> onScore;
  final ValueChanged<String> onNote;

  @override
  State<_ParamCard> createState() => _ParamCardState();
}

class _ParamCardState extends State<_ParamCard> {
  bool _help = false;

  @override
  Widget build(BuildContext context) {
    final color = scoreColor(widget.param.score <= 0 ? 1 : widget.param.score);
    return PressableCard(
      padding: const EdgeInsets.all(17),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        widget.param.name,
                        style: const TextStyle(
                          color: MColors.ink,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      borderRadius: BorderRadius.circular(99),
                      onTap: () => setState(() => _help = !_help),
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: _help ? MColors.terra : MColors.terraTint,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.info_outline_rounded,
                          size: 15,
                          color: _help ? Colors.white : MColors.terra,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: widget.param.score <= 0
                          ? '—'
                          : widget.param.score.toStringAsFixed(1),
                      style: TextStyle(
                        color: color,
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const TextSpan(
                      text: '/5',
                      style: TextStyle(
                        color: MColors.inkFaint,
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_help) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: MColors.terraTint,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                paramHelp(widget.param.name),
                style: const TextStyle(
                  color: MColors.inkSoft,
                  fontSize: 13.5,
                  height: 1.5,
                ),
              ),
            ),
          ],
          const SizedBox(height: 14),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: color,
              inactiveTrackColor: MColors.line,
              thumbColor: color,
              overlayColor: color.withValues(alpha: .14),
              trackHeight: 8,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 9),
            ),
            child: Slider(
              min: 1,
              max: 5,
              divisions: 8,
              value: math.max(1, widget.param.score),
              onChanged: widget.locked ? null : widget.onScore,
            ),
          ),
          Text(
            widget.param.score >= 4
                ? 'Exceeds expectation'
                : widget.param.score >= 2.5
                ? 'Meets expectation'
                : widget.param.score > 0
                ? 'Needs work'
                : 'Drag to score',
            style: TextStyle(
              color: widget.param.score > 0 ? color : MColors.inkFaint,
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            key: ValueKey('${widget.param.name}-${widget.param.note}'),
            initialValue: widget.param.note,
            enabled: !widget.locked,
            maxLines: 3,
            onChanged: widget.onNote,
            decoration: _fieldDecoration(
              'Add a note — type or record by voice…',
              suffix: Icons.mic_none_rounded,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeedbackGuide extends StatefulWidget {
  const _FeedbackGuide();

  @override
  State<_FeedbackGuide> createState() => _FeedbackGuideState();
}

class _FeedbackGuideState extends State<_FeedbackGuide> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    return PressableCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _open = !_open),
            child: Padding(
              padding: const EdgeInsets.all(15),
              child: Row(
                children: [
                  const IconBox(
                    icon: Icons.lightbulb_outline_rounded,
                    color: MColors.plum,
                    tint: MColors.plumTint,
                    size: 36,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'What makes good feedback?',
                      style: TextStyle(
                        color: MColors.ink,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Icon(
                    _open
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: MColors.inkFaint,
                  ),
                ],
              ),
            ),
          ),
          if (_open)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: const [
                  _GuideLine(
                    'Be specific',
                    'Point to real moments, not “lately”.',
                  ),
                  _GuideLine(
                    'Balance it',
                    'Name a strength and one thing to grow.',
                  ),
                  _GuideLine('Make it actionable', 'Say what to do next.'),
                  _GuideLine('Focus on behaviour', 'Comment on what they did.'),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _GuideLine extends StatelessWidget {
  const _GuideLine(this.title, this.body);
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.check_circle_outline_rounded,
            color: MColors.sageDeep,
            size: 17,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                  color: MColors.inkSoft,
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 13.5,
                  height: 1.45,
                ),
                children: [
                  TextSpan(
                    text: '$title. ',
                    style: const TextStyle(
                      color: MColors.ink,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  TextSpan(text: body),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfirmSendSheet extends StatelessWidget {
  const _ConfirmSendSheet({required this.member, required this.onSend});

  final TeamMember member;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final first = member.name.split(' ').first;
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                  color: MColors.line,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                const IconBox(
                  icon: Icons.send_rounded,
                  color: MColors.terra,
                  tint: MColors.terraTint,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Send to $first?',
                        style: const TextStyle(
                          color: MColors.ink,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'This locks the feedback — no further edits.',
                        style: TextStyle(
                          color: MColors.inkSoft,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: ActionButton(
                    label: 'Cancel',
                    background: Colors.white,
                    foreground: MColors.ink,
                    border: MColors.line,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ActionButton(
                    label: 'Send now',
                    icon: Icons.send_rounded,
                    background: MColors.terra,
                    foreground: Colors.white,
                    onTap: onSend,
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

class _ComingSoonBlock extends StatelessWidget {
  const _ComingSoonBlock({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconBox(
          icon: icon,
          color: MColors.terra,
          tint: MColors.terraTint,
          size: 76,
        ),
        const SizedBox(height: 18),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: MColors.ink,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          body,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: MColors.inkSoft,
            fontSize: 14,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: MColors.terraTint,
            borderRadius: BorderRadius.circular(99),
          ),
          child: const Text(
            'Coming soon',
            style: TextStyle(
              color: MColors.terra,
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.title, this.sub, this.onBack});

  final String title;
  final String? sub;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 52, 16, 12),
      decoration: const BoxDecoration(
        color: MColors.bg,
        border: Border(bottom: BorderSide(color: MColors.line)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (onBack != null)
                RoundIconButton(
                  icon: Icons.chevron_left_rounded,
                  onTap: onBack!,
                )
              else
                const SizedBox(width: 38),
              const SizedBox(width: 38),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              color: MColors.ink,
              fontSize: 30,
              fontWeight: FontWeight.w800,
              height: 1.08,
              letterSpacing: -0.6,
            ),
          ),
          if (sub != null) ...[
            const SizedBox(height: 5),
            Text(
              sub!,
              style: const TextStyle(color: MColors.inkSoft, fontSize: 14.5),
            ),
          ],
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.value,
    required this.label,
    required this.color,
  });

  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return PressableCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 23,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            label,
            style: const TextStyle(
              color: MColors.inkSoft,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, this.trailing});

  final String title;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: MColors.ink,
                fontSize: 19,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.1,
              ),
            ),
          ),
          if (trailing != null)
            Text(
              trailing!,
              style: const TextStyle(
                color: MColors.inkSoft,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
        ],
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.value, required this.color});

  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(99),
      child: Container(
        height: 8,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        color: const Color(0xFFE7DDCD),
        child: FractionallySizedBox(
          widthFactor: value.clamp(0, 1),
          alignment: Alignment.centerLeft,
          child: Container(color: color),
        ),
      ),
    );
  }
}

class _SearchBox extends StatelessWidget {
  const _SearchBox({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: value,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: 'Find a teammate',
        prefixIcon: const Icon(Icons.search_rounded, color: MColors.inkFaint),
        suffixIcon: value.isEmpty
            ? null
            : IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => onChanged(''),
              ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 11,
          horizontal: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: MColors.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: MColors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: MColors.terra, width: 1.5),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
    this.dot,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;
  final Color? dot;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(99),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
          decoration: BoxDecoration(
            color: selected ? MColors.ink : Colors.white,
            borderRadius: BorderRadius.circular(99),
            border: Border.all(color: selected ? MColors.ink : MColors.line),
          ),
          child: Row(
            children: [
              if (dot != null) ...[
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : MColors.inkSoft,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '$count',
                style: TextStyle(
                  color: selected ? Colors.white70 : MColors.inkFaint,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PressableCard extends StatelessWidget {
  const PressableCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
    this.color = Colors.white,
    this.borderColor = MColors.line,
    this.dashed = false,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final Color color;
  final Color borderColor;
  final bool dashed;

  @override
  Widget build(BuildContext context) {
    final card = AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: dashed ? 1.5 : 1),
        boxShadow: color == Colors.white
            ? [
                BoxShadow(
                  color: const Color(0xFF462D1C).withValues(alpha: .04),
                  blurRadius: 22,
                  offset: const Offset(0, 10),
                ),
              ]
            : null,
      ),
      child: child,
    );

    if (onTap == null) return card;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: card,
      ),
    );
  }
}

class IconBox extends StatelessWidget {
  const IconBox({
    super.key,
    required this.icon,
    required this.color,
    required this.tint,
    this.size = 44,
    this.iconSize = 22,
  });

  final IconData icon;
  final Color color;
  final Color tint;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: tint,
        borderRadius: BorderRadius.circular(size * .3),
      ),
      child: Icon(icon, color: color, size: iconSize),
    );
  }
}

class AvatarBadge extends StatelessWidget {
  const AvatarBadge({
    super.key,
    required this.initial,
    required this.index,
    required this.size,
  });

  final String initial;
  final int index;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = avatarColors[index % avatarColors.length];
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: TextStyle(
          color: Colors.white,
          fontSize: size * .42,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class RoundIconButton extends StatelessWidget {
  const RoundIconButton({super.key, required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(99),
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: MColors.line),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: MColors.ink),
      ),
    );
  }
}

class ActionButton extends StatelessWidget {
  const ActionButton({
    super.key,
    required this.label,
    required this.background,
    required this.foreground,
    this.onTap,
    this.icon,
    this.border,
  });

  final String label;
  final Color background;
  final Color foreground;
  final VoidCallback? onTap;
  final IconData? icon;
  final Color? border;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: border == null
                ? null
                : Border.all(color: border!, width: 1.5),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, color: foreground, size: 18),
                const SizedBox(width: 7),
              ],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: foreground,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
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

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final FeedbackStatus status;

  @override
  Widget build(BuildContext context) {
    final spec = switch (status) {
      FeedbackStatus.pending => (
        'Not started',
        MColors.inkFaint,
        const Color(0xFFEFEAE2),
      ),
      FeedbackStatus.saved => ('Ready to send', MColors.gold, MColors.goldTint),
      FeedbackStatus.sent => ('Sent', MColors.sageDeep, MColors.sageTint),
      FeedbackStatus.missed => (
        'Missed',
        MColors.live,
        const Color(0xFFFBE6E3),
      ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: spec.$3,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        spec.$1,
        style: TextStyle(
          color: spec.$2,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

InputDecoration _fieldDecoration(String hint, {IconData? suffix}) {
  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: MColors.inkFaint),
    suffixIcon: suffix == null
        ? null
        : Icon(suffix, color: MColors.terra, size: 18),
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.all(13),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(13),
      borderSide: const BorderSide(color: MColors.line, width: 1.5),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(13),
      borderSide: const BorderSide(color: MColors.line, width: 1.5),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(13),
      borderSide: const BorderSide(color: MColors.terra, width: 1.5),
    ),
  );
}

int _daysUntil(DateTime today, DateTime date) {
  final a = DateTime(today.year, today.month, today.day);
  final b = DateTime(date.year, date.month, date.day);
  return b.difference(a).inDays;
}

String shortDate(DateTime date) {
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
  return '${months[date.month - 1]} ${date.day}';
}

String daysAgo(DateTime requestedOn) {
  final days = math.max(0, DateTime.now().difference(requestedOn).inDays);
  return days <= 1 ? '$days day' : '$days days';
}

String _requestedAgo(DateTime requestedOn) =>
    'Requested ${daysAgo(requestedOn)} ago';

String _managerDate(DateTime date) {
  const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  return '${date.day} ${_monthName(date.month)} · ${weekdays[date.weekday - 1]}';
}

String _monthName(int month) {
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
  return months[month - 1];
}

Color scoreColor(double score) {
  if (score >= 4.25) return MColors.sageDeep;
  if (score >= 3.5) return MColors.gold;
  if (score >= 2.5) return MColors.terra;
  return MColors.live;
}

(Color, Color) leavePalette(String type) {
  return switch (type) {
    'Sick' => (MColors.live, const Color(0xFFFBE6E3)),
    'Earned' => (MColors.teal, MColors.sageTint),
    _ => (MColors.gold, MColors.goldTint),
  };
}

(Color, Color) awardPalette(String key) {
  return switch (key) {
    'artist' => (MColors.plum, MColors.plumTint),
    'mentor' => (MColors.teal, MColors.sageTint),
    'culture' => (MColors.terra, MColors.terraTint),
    _ => (MColors.gold, MColors.goldTint),
  };
}

IconData awardIcon(String icon) {
  return switch (icon) {
    'palette' => Icons.palette_outlined,
    'school' => Icons.school_outlined,
    'heart' => Icons.favorite_border_rounded,
    _ => Icons.star_border_rounded,
  };
}

String paramHelp(String name) {
  return switch (name) {
    'Ownership Mindset' =>
      'Takes responsibility end-to-end, unblocks themselves, and follows through without being chased.',
    'Communication Clarity' =>
      'Shares context clearly and on time so others can act.',
    'Quality of Work' =>
      'Output is accurate, thorough and reliable, with few rework loops.',
    'Collaboration' =>
      'Works well across functions, gives and receives feedback, and lifts the team.',
    _ => 'How this person performed on this parameter this month.',
  };
}

const List<Color> avatarColors = [
  Color(0xFFBE5A36),
  Color(0xFF4F8C89),
  Color(0xFF8A6AA0),
  Color(0xFFC98A2E),
  Color(0xFF7E8B6E),
  Color(0xFFC0392B),
  Color(0xFF3563C4),
];

class MColors {
  static const bg = Color(0xFFF4EEE5);
  static const ink = Color(0xFF2A2420);
  static const inkSoft = Color(0xFF6E655C);
  static const inkFaint = Color(0xFFA79D92);
  static const line = Color(0xFFF0E8DD);
  static const terra = Color(0xFFBE5A36);
  static const terraDeep = Color(0xFF7C3318);
  static const terraTint = Color(0xFFF6E5DB);
  static const gold = Color(0xFFC98A2E);
  static const goldTint = Color(0xFFF4ECDD);
  static const sage = Color(0xFF7E8B6E);
  static const sageDeep = Color(0xFF4C5840);
  static const sageTint = Color(0xFFDEEBE9);
  static const live = Color(0xFFC0392B);
  static const plum = Color(0xFF8A6AA0);
  static const plumTint = Color(0xFFEEE6F0);
  static const teal = Color(0xFF4F8C89);
}
