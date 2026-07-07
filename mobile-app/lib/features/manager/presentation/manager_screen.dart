import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../../../routes/app_routes.dart';
import '../../auth/data/auth_models.dart';
import '../../auth/data/auth_session_store.dart';
import '../../profile/presentation/profile_screen.dart';
import '../bloc/manager_bloc.dart';
import '../data/manager_models.dart';
import 'quick_actions_screen.dart';

const int _maxLeaveApplyDays = 30;

class ManagerScreen extends StatefulWidget {
  const ManagerScreen({super.key, required this.session});

  final AuthSession session;

  @override
  State<ManagerScreen> createState() => _ManagerScreenState();
}

class _ManagerScreenState extends State<ManagerScreen> {
  late final ManagerBloc _bloc;
  late final QuickActionsController _quickActionsController;
  bool _profileOpen = false;

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
    return _profileOpen ||
        state.awardPickerKey != null ||
        state.applyLeaveOpen ||
        state.view != ManagerView.home ||
        (state.tab == ManagerTab.quick && _quickActionsController.canGoBack) ||
        state.tab != _defaultTab;
  }

  void _handleBack(ManagerState state) {
    if (_profileOpen) {
      setState(() => _profileOpen = false);
    } else if (state.awardPickerKey != null) {
      _bloc.add(const CloseAwardPicker());
    } else if (state.applyLeaveOpen) {
      _bloc.add(const CloseApplyLeave());
    } else if (state.view == ManagerView.feedbackRecord) {
      _bloc.add(const CloseFeedbackRecord());
    } else if (state.view == ManagerView.feedbackList) {
      _bloc.add(const CloseFeedbackList());
    } else if (state.view == ManagerView.leaveRequests) {
      _bloc.add(const CloseLeaveRequests());
    } else if (state.view == ManagerView.overtimeRequests) {
      _bloc.add(const CloseOvertimeRequests());
    } else if (state.tab == ManagerTab.quick &&
        _quickActionsController.canGoBack) {
      _quickActionsController.handleBack();
    } else if (state.tab != _defaultTab) {
      _bloc.add(ChangeManagerTab(_defaultTab));
    }
  }

  void _openProfile() => setState(() => _profileOpen = true);

  void _closeProfile() => setState(() => _profileOpen = false);

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
            body: _profileOpen
                ? ProfileScreen(
                    session: widget.session,
                    dashboard: state.dashboard!,
                    onBack: _closeProfile,
                    onLogout: _logout,
                  )
                : Stack(
                    children: [
                      Column(
                        children: [
                          Expanded(
                            child: MediaQuery.removePadding(
                              context: context,
                              removeBottom: true,
                              child: _TabContent(
                                state: state,
                                bloc: _bloc,
                                quickActionsController: _quickActionsController,
                                onOpenProfile: _openProfile,
                              ),
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
    required this.onOpenProfile,
  });

  final ManagerState state;
  final ManagerBloc bloc;
  final QuickActionsController quickActionsController;
  final VoidCallback onOpenProfile;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      child: switch (state.tab) {
        ManagerTab.manage => _ManageContent(
          state: state,
          bloc: bloc,
          onOpenProfile: onOpenProfile,
        ),
        ManagerTab.grow => _GrowTab(state: state, onOpenProfile: onOpenProfile),
        ManagerTab.connect => _ComingSoonTab(
          key: ValueKey('connect'),
          icon: Icons.newspaper_rounded,
          title: 'Connect',
          body: 'Company feed, shout-outs and updates — coming soon.',
          profileAction: _ProfileAvatarAction(
            key: const ValueKey('connect-profile-avatar'),
            initial: state.dashboard!.managerInitial,
            onTap: onOpenProfile,
          ),
        ),
        ManagerTab.quick => QuickActionsScreen(
          key: const ValueKey('quick-actions'),
          bloc: bloc,
          dashboard: state.dashboard!,
          controller: quickActionsController,
          profileAction: _ProfileAvatarAction(
            key: const ValueKey('quick-profile-avatar'),
            initial: state.dashboard!.managerInitial,
            onTap: onOpenProfile,
          ),
        ),
      },
    );
  }
}

class _ManageContent extends StatelessWidget {
  const _ManageContent({
    required this.state,
    required this.bloc,
    required this.onOpenProfile,
  });

  final ManagerState state;
  final ManagerBloc bloc;
  final VoidCallback onOpenProfile;

  @override
  Widget build(BuildContext context) {
    return switch (state.view) {
      ManagerView.home => _ManagerHome(
        state: state,
        bloc: bloc,
        onOpenProfile: onOpenProfile,
      ),
      ManagerView.feedbackList => _FeedbackList(state: state, bloc: bloc),
      ManagerView.feedbackRecord => _RecordFeedback(state: state, bloc: bloc),
      ManagerView.leaveRequests => _RequestList(
        state: state,
        bloc: bloc,
        type: _RequestType.leave,
      ),
      ManagerView.overtimeRequests => _RequestList(
        state: state,
        bloc: bloc,
        type: _RequestType.overtime,
      ),
    };
  }
}

class _ManagerHome extends StatelessWidget {
  const _ManagerHome({
    required this.state,
    required this.bloc,
    required this.onOpenProfile,
  });

  final ManagerState state;
  final ManagerBloc bloc;
  final VoidCallback onOpenProfile;

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
    final pendingLeaveList = data.leaves
        .where((leave) => leave.decision == LeaveDecision.pending)
        .toList();
    final pendingLeaves = pendingLeaveList.length;
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
              Semantics(
                button: true,
                label: 'Open profile',
                child: InkWell(
                  key: const ValueKey('manager-profile-avatar'),
                  borderRadius: BorderRadius.circular(99),
                  onTap: onOpenProfile,
                  child: AvatarBadge(
                    initial: data.managerInitial,
                    index: 1,
                    size: 42,
                  ),
                ),
              ),
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
          trailing: open == 0 ? 'All given' : '$open pending',
          onTap: () => bloc.add(const OpenFeedbackList()),
        ),
        const SizedBox(height: 10),
        _ProgressBar(
          value: data.team.isEmpty ? 0 : given / data.team.length,
          color: MColors.terra,
        ),
        const SizedBox(height: 14),
        _AvatarActionCluster(
          people: data.team
              .take(10)
              .map(
                (member) => _ActionAvatar(
                  initial: _nameInitials(member.name),
                  index: member.avatarIndex,
                  completed: member.status == FeedbackStatus.sent,
                ),
              ),
          onTap: () => bloc.add(const OpenFeedbackList()),
        ),
        const SizedBox(height: 28),
        _SectionTitle(
          title: 'Leave requests',
          trailing: pendingLeaves == 0 ? 'All clear' : '$pendingLeaves pending',
          onTap: () => bloc.add(const OpenLeaveRequests()),
        ),
        const SizedBox(height: 12),
        _AvatarActionCluster(
          people: pendingLeaveList.map(
            (leave) => _ActionAvatar(
              initial: _nameInitials(leave.who),
              index: leave.avatarIndex,
            ),
          ),
          emptyText: 'All requests reviewed',
          onTap: () => bloc.add(const OpenLeaveRequests()),
        ),
        const SizedBox(height: 28),
        _SectionTitle(
          title: 'Overtime requests',
          trailing: pendingOvertime.isEmpty
              ? 'All clear'
              : '${pendingOvertime.length} pending',
          onTap: () => bloc.add(const OpenOvertimeRequests()),
        ),
        const SizedBox(height: 12),
        _AvatarActionCluster(
          people: pendingOvertime.map(
            (request) => _ActionAvatar(
              initial: _nameInitials(request.who),
              index: request.avatarIndex,
            ),
          ),
          emptyText: 'All requests reviewed',
          onTap: () => bloc.add(const OpenOvertimeRequests()),
        ),
        const SizedBox(height: 28),
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
              onNominate: () =>
                  bloc.add(OpenAwardPicker(data.awards[index].key)),
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
        .where((item) => item.status != FeedbackStatus.sent)
        .toList();
    final completed = data.team
        .where((item) => item.status == FeedbackStatus.sent)
        .toList();
    int urgency(TeamMember member) {
      if (member.missedMonths > 0 || member.status == FeedbackStatus.missed) {
        return 0;
      }
      final days = _daysUntil(data.today, member.next);
      return days >= 0 && days <= 4 ? 1 : 2;
    }

    int sortByUrgency(TeamMember a, TeamMember b) {
      final byGroup = urgency(a).compareTo(urgency(b));
      return byGroup != 0 ? byGroup : a.next.compareTo(b.next);
    }

    final pending = open..sort(sortByUrgency);
    final done = completed..sort((a, b) => b.next.compareTo(a.next));
    final query = state.searchQuery.trim().toLowerCase();
    final visible =
        data.team.where((item) {
          final matches =
              query.isEmpty ||
              item.name.toLowerCase().contains(query) ||
              item.team.toLowerCase().contains(query);
          if (!matches) return false;
          return switch (state.feedbackFilter) {
            FeedbackFilter.all => true,
            FeedbackFilter.pending => item.status != FeedbackStatus.sent,
            FeedbackFilter.done => item.status == FeedbackStatus.sent,
          };
        }).toList()..sort((a, b) {
          if (a.status == FeedbackStatus.sent &&
              b.status != FeedbackStatus.sent) {
            return 1;
          }
          if (a.status != FeedbackStatus.sent &&
              b.status == FeedbackStatus.sent) {
            return -1;
          }
          return a.status == FeedbackStatus.sent
              ? b.next.compareTo(a.next)
              : sortByUrgency(a, b);
        });
    final grouped = state.feedbackFilter == FeedbackFilter.all && query.isEmpty;
    final progress = data.team.isEmpty
        ? 0.0
        : completed.length / data.team.length;

    return Column(
      key: const ValueKey('feedback-list'),
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(20, 54, 20, 10),
          child: Column(
            children: [
              Row(
                children: [
                  RoundIconButton(
                    icon: Icons.chevron_left_rounded,
                    onTap: () => bloc.add(const CloseFeedbackList()),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_monthName(data.today.month)} · for you to action',
                          style: const TextStyle(
                            color: MColors.inkSoft,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Monthly Check-ins',
                          style: TextStyle(
                            color: MColors.ink,
                            fontSize: 27,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AvatarBadge(initial: data.managerInitial, index: 1, size: 42),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _FeedbackStat(
                      value: open.length,
                      label: 'feedback to give',
                      color: MColors.terra,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _FeedbackStat(
                      value: done.length,
                      label: 'done',
                      color: MColors.sageDeep,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 36),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Feedback',
                      style: TextStyle(
                        color: MColors.ink,
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      '${completed.length} of ${data.team.length} given',
                      style: const TextStyle(
                        color: MColors.inkSoft,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  color: MColors.terra,
                  backgroundColor: MColors.line,
                ),
              ),
              const SizedBox(height: 14),
              _FeedbackSearchField(
                query: state.searchQuery,
                onChanged: (value) => bloc.add(ChangeFeedbackSearch(value)),
                onClear: () => bloc.add(const ChangeFeedbackSearch('')),
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _FeedbackFilterChip(
                      label: 'All',
                      count: data.team.length,
                      selected: state.feedbackFilter == FeedbackFilter.all,
                      onTap: () => bloc.add(
                        const ChangeFeedbackFilter(FeedbackFilter.all),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _FeedbackFilterChip(
                      label: 'Pending',
                      count: pending.length,
                      dot: MColors.gold,
                      selected: state.feedbackFilter == FeedbackFilter.pending,
                      onTap: () => bloc.add(
                        const ChangeFeedbackFilter(FeedbackFilter.pending),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _FeedbackFilterChip(
                      label: 'Done',
                      count: done.length,
                      dot: MColors.sageDeep,
                      selected: state.feedbackFilter == FeedbackFilter.done,
                      onTap: () => bloc.add(
                        const ChangeFeedbackFilter(FeedbackFilter.done),
                      ),
                    ),
                  ],
                ),
              ),
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
              else if (grouped) ...[
                if (pending.isNotEmpty) ...[
                  const _FeedbackGroupHeader(
                    label: 'Pending',
                    color: MColors.gold,
                  ),
                  _FeedbackRows(
                    members: pending,
                    today: data.today,
                    bloc: bloc,
                  ),
                ],
                if (done.isNotEmpty) ...[
                  const _FeedbackGroupHeader(
                    label: 'Done',
                    color: MColors.sageDeep,
                  ),
                  _GivenFeedbackRows(members: done, bloc: bloc),
                ],
              ] else if (state.feedbackFilter == FeedbackFilter.done)
                _GivenFeedbackRows(members: visible, bloc: bloc)
              else if (state.feedbackFilter == FeedbackFilter.all) ...[
                if (visible.any((item) => item.status != FeedbackStatus.sent))
                  _FeedbackRows(
                    members: visible
                        .where((item) => item.status != FeedbackStatus.sent)
                        .toList(),
                    today: data.today,
                    bloc: bloc,
                  ),
                if (visible.any(
                  (item) => item.status == FeedbackStatus.sent,
                )) ...[
                  const SizedBox(height: 10),
                  _GivenFeedbackRows(
                    members: visible
                        .where((item) => item.status == FeedbackStatus.sent)
                        .toList(),
                    bloc: bloc,
                  ),
                ],
              ] else
                _FeedbackRows(members: visible, today: data.today, bloc: bloc),
            ],
          ),
        ),
      ],
    );
  }
}

class _FeedbackStat extends StatelessWidget {
  const _FeedbackStat({
    required this.value,
    required this.label,
    required this.color,
  });
  final int value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(15),
      border: Border.all(color: const Color(0xFFF0E8DD)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$value',
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

class _FeedbackSearchField extends StatefulWidget {
  const _FeedbackSearchField({
    required this.query,
    required this.onChanged,
    required this.onClear,
  });

  final String query;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  State<_FeedbackSearchField> createState() => _FeedbackSearchFieldState();
}

class _FeedbackSearchFieldState extends State<_FeedbackSearchField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.query);
  }

  @override
  void didUpdateWidget(covariant _FeedbackSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.query != _controller.text) {
      _controller.value = TextEditingValue(
        text: widget.query,
        selection: TextSelection.collapsed(offset: widget.query.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: _controller,
    onChanged: widget.onChanged,
    decoration: InputDecoration(
      hintText: 'Find a teammate',
      prefixIcon: const Icon(Icons.search_rounded, size: 20),
      suffixIcon: widget.query.isEmpty
          ? null
          : IconButton(
              onPressed: widget.onClear,
              icon: const Icon(Icons.close_rounded, size: 18),
            ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 12),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: MColors.line),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: MColors.terra),
      ),
    ),
  );
}

class _FeedbackFilterChip extends StatelessWidget {
  const _FeedbackFilterChip({
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
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(99),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
      decoration: BoxDecoration(
        color: selected ? MColors.ink : Colors.white,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: selected ? MColors.ink : MColors.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
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
  );
}

class _FeedbackGroupHeader extends StatelessWidget {
  const _FeedbackGroupHeader({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Padding(
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
      ],
    ),
  );
}

class _FeedbackRows extends StatelessWidget {
  const _FeedbackRows({
    required this.members,
    required this.today,
    required this.bloc,
  });
  final List<TeamMember> members;
  final DateTime today;
  final ManagerBloc bloc;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFF0E8DD)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0D462D1C),
          blurRadius: 26,
          offset: Offset(0, 12),
        ),
      ],
    ),
    clipBehavior: Clip.antiAlias,
    child: Column(
      children: members.indexed.map((entry) {
        final member = entry.$2;
        final overdue =
            member.missedMonths > 0 || member.status == FeedbackStatus.missed;
        final days = _daysUntil(today, member.next);
        final due = overdue
            ? 'Missed ${member.missedMonths == 0 ? 1 : member.missedMonths}mo'
            : days == 0
            ? 'Due today'
            : days == 1
            ? 'Due tomorrow'
            : days > 1 && days <= 4
            ? 'Due in ${days}d'
            : null;
        return InkWell(
          onTap: () => bloc.add(OpenFeedbackRecord(member.id)),
          child: Container(
            color: overdue ? const Color(0xFFFBF2E8) : Colors.transparent,
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
            decoration: entry.$1 == 0
                ? null
                : const BoxDecoration(
                    border: Border(top: BorderSide(color: Color(0xFFF4ECE0))),
                  ),
            child: Row(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: const Color(0xFFD2C6B4),
                      width: 2,
                    ),
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
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(text: member.team),
                            if (due != null)
                              TextSpan(
                                text: ' · $due',
                                style: TextStyle(
                                  color: overdue ? MColors.live : MColors.gold,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                          ],
                        ),
                        style: const TextStyle(
                          color: MColors.inkSoft,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 19,
                  color: Color(0xFFC9BDAC),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    ),
  );
}

class _GivenFeedbackRows extends StatelessWidget {
  const _GivenFeedbackRows({required this.members, required this.bloc});
  final List<TeamMember> members;
  final ManagerBloc bloc;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFF0E8DD)),
    ),
    clipBehavior: Clip.antiAlias,
    child: Column(
      children: members.indexed.map((entry) {
        final member = entry.$2;
        return InkWell(
          onTap: () => bloc.add(OpenFeedbackRecord(member.id)),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
            decoration: entry.$1 == 0
                ? null
                : const BoxDecoration(
                    border: Border(top: BorderSide(color: Color(0xFFF4ECE0))),
                  ),
            child: Row(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: MColors.sageDeep,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    size: 13,
                    color: Colors.white,
                  ),
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
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      decoration: TextDecoration.lineThrough,
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
          ),
        );
      }).toList(),
    ),
  );
}

// Kept for the legacy report-card layout used by older manager builds.
// ignore: unused_element
class _FeedbackAnchorBanner extends StatelessWidget {
  const _FeedbackAnchorBanner({required this.month, required this.sessions});

  final String month;
  final int sessions;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: MColors.terraTint,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const IconBox(
            icon: Icons.edit_calendar_rounded,
            color: MColors.terra,
            tint: Colors.white,
            size: 44,
            iconSize: 23,
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$month cycle · $sessions sessions allocated',
                  style: const TextStyle(
                    color: MColors.terraDeep,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                const Text(
                  'Anchor: 5th · Auto-closes 35 days after if unsent',
                  style: TextStyle(
                    color: MColors.terraDeep,
                    fontSize: 13,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ignore: unused_element
class _FeedbackSectionHead extends StatelessWidget {
  const _FeedbackSectionHead({
    required this.label,
    required this.count,
    required this.color,
  });

  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: .9,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
            padding: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Text(
              '$count',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ignore: unused_element
class _FeedbackReportCard extends StatelessWidget {
  const _FeedbackReportCard({
    required this.member,
    required this.today,
    required this.showDue,
    required this.onTap,
  });

  final TeamMember member;
  final DateTime today;
  final bool showDue;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final done = member.params.where((item) => item.score > 0).length;
    final total = member.params.length;
    final started = member.status != FeedbackStatus.pending || done > 0;
    final note = member.params
        .map((item) => item.note.trim())
        .firstWhere((item) => item.isNotEmpty, orElse: () => '');
    final (status, statusColor) = switch (member.status) {
      FeedbackStatus.pending => ('Not started', MColors.inkFaint),
      FeedbackStatus.saved => ('Ready to send', MColors.gold),
      FeedbackStatus.sent => ('Sent', MColors.sageDeep),
      FeedbackStatus.missed => ('Missed', MColors.live),
    };

    return PressableCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          AvatarBadge(
            initial: member.initial,
            index: member.avatarIndex,
            size: 54,
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        member.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: MColors.ink,
                          fontSize: 17.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -.2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (showDue)
                      _FeedbackDueChip(today: today, date: member.next)
                    else
                      Text(
                        shortDate(member.next),
                        style: const TextStyle(
                          color: MColors.inkFaint,
                          fontSize: 12.5,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 9),
                Row(
                  children: [
                    if (showDue)
                      _FeedbackProgressMeter(done: done, total: total)
                    else
                      _FeedbackScoreRing(score: member.score),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        status,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                Text(
                  started
                      ? (note.isEmpty ? 'Scores recorded — add notes.' : note)
                      : 'Tap to start this month’s feedback',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: started ? MColors.inkSoft : MColors.inkFaint,
                    fontSize: 13.5,
                    height: 1.42,
                    fontStyle: started ? FontStyle.normal : FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          const Icon(
            Icons.chevron_right_rounded,
            size: 24,
            color: MColors.inkFaint,
          ),
        ],
      ),
    );
  }
}

class _FeedbackDueChip extends StatelessWidget {
  const _FeedbackDueChip({required this.today, required this.date});

  final DateTime today;
  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final days = _daysUntil(today, date);
    final urgent = days <= 7;
    final soon = days > 7 && days <= 14;
    final color = urgent
        ? MColors.live
        : soon
        ? MColors.gold
        : MColors.inkSoft;
    final tint = urgent
        ? const Color(0xFFFBE6E3)
        : soon
        ? MColors.goldTint
        : const Color(0xFFEFEAE2);
    final label = days < 0
        ? 'Closed'
        : days == 0
        ? 'Due today'
        : 'Due in ${days}d';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: tint,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.schedule_rounded, size: 12, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeedbackProgressMeter extends StatelessWidget {
  const _FeedbackProgressMeter({required this.done, required this.total});

  final int done;
  final int total;

  @override
  Widget build(BuildContext context) {
    final complete = total > 0 && done == total;
    final color = complete
        ? MColors.sageDeep
        : done == 0
        ? MColors.inkFaint
        : MColors.gold;
    final progress = total == 0 ? 0.0 : done / total;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 72,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              minHeight: 7,
              value: progress,
              color: color,
              backgroundColor: MColors.line,
            ),
          ),
        ),
        const SizedBox(width: 7),
        Text(
          '$done/$total scored',
          style: TextStyle(
            color: color,
            fontSize: 12.5,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _FeedbackScoreRing extends StatelessWidget {
  const _FeedbackScoreRing({required this.score});

  final double score;

  @override
  Widget build(BuildContext context) {
    final color = scoreColor(score <= 0 ? 1 : score);
    return SizedBox(
      width: 44,
      height: 44,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 38,
            height: 38,
            child: CircularProgressIndicator(
              value: (score / 5).clamp(0.0, 1.0),
              strokeWidth: 4,
              color: color,
              backgroundColor: MColors.line,
              strokeCap: StrokeCap.round,
            ),
          ),
          Text(
            score.toStringAsFixed(1),
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
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

class _RecordFeedback extends StatefulWidget {
  const _RecordFeedback({required this.state, required this.bloc});

  final ManagerState state;
  final ManagerBloc bloc;

  @override
  State<_RecordFeedback> createState() => _RecordFeedbackState();
}

class _RecordFeedbackState extends State<_RecordFeedback> {
  late final PageController _pageController;
  final stt.SpeechToText _speech = stt.SpeechToText();
  int _tab = 0;
  int _page = 0;
  bool _speechInitialized = false;
  String? _listeningField;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: .88);
  }

  @override
  void dispose() {
    _speech.cancel();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _toggleSpeech({
    required String field,
    required String currentText,
    required ValueChanged<String> onText,
  }) async {
    if (_speech.isListening && _listeningField == field) {
      await _speech.stop();
      if (mounted) setState(() => _listeningField = null);
      return;
    }
    if (_speech.isListening) await _speech.cancel();

    final available = _speechInitialized
        ? true
        : await _speech.initialize(
            onStatus: (status) {
              if ((status == 'done' || status == 'notListening') && mounted) {
                setState(() => _listeningField = null);
              }
            },
            onError: (error) {
              if (!mounted) return;
              setState(() => _listeningField = null);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Voice input unavailable: ${error.errorMsg}'),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: MColors.ink,
                ),
              );
            },
          );
    _speechInitialized = available;
    if (!available) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Speech recognition is unavailable or microphone access was denied.',
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: MColors.ink,
        ),
      );
      return;
    }

    final prefix = currentText.trim();
    if (mounted) setState(() => _listeningField = field);
    await _speech.listen(
      onResult: (result) {
        final words = result.recognizedWords.trim();
        if (words.isEmpty) return;
        onText(prefix.isEmpty ? words : '$prefix $words');
        if (result.finalResult && mounted) {
          setState(() => _listeningField = null);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final bloc = widget.bloc;
    final member = state.selectedMember;
    if (member == null) return const SizedBox.shrink();

    final locked =
        member.status == FeedbackStatus.sent ||
        member.status == FeedbackStatus.missed;
    final complete =
        state.recordParams.isNotEmpty &&
        state.recordParams.every((item) => item.score > 0);
    final scored = state.recordParams.where((item) => item.score > 0).toList();
    final overall = scored.isEmpty
        ? 0.0
        : scored.fold<double>(0, (sum, item) => sum + item.score) /
              state.recordParams.length;
    final overallColor = scoreColor(overall <= 0 ? 1 : overall);
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;

    return ColoredBox(
      key: const ValueKey('record-feedback'),
      color: MColors.bg,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                children: [
                  Row(
                    children: [
                      RoundIconButton(
                        icon: Icons.chevron_left_rounded,
                        onTap: () => bloc.add(const CloseFeedbackRecord()),
                      ),
                      const SizedBox(width: 12),
                      AvatarBadge(
                        initial: member.initial,
                        index: member.avatarIndex,
                        size: 42,
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
                                fontSize: 21,
                                height: 1.1,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -.3,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${member.team} · 1-on-1',
                              style: const TextStyle(
                                color: MColors.inkSoft,
                                fontSize: 13.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _FeedbackModeSwitch(
                    selected: _tab,
                    onChanged: (value) => setState(() => _tab = value),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _tab == 0
                  ? Column(
                      children: [
                        if (keyboardOpen)
                          const SizedBox(height: 10)
                        else ...[
                          const SizedBox(height: 17),
                          const Text(
                            'OVERALL SCORE',
                            style: TextStyle(
                              color: MColors.inkFaint,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.35,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: 88,
                            height: 88,
                            decoration: BoxDecoration(
                              color: overall == 0
                                  ? const Color(0xFFD9CDBC)
                                  : overallColor,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  overall == 0
                                      ? '—'
                                      : overall.toStringAsFixed(1),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 34,
                                    height: .95,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const Text(
                                  'out of 5',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        Expanded(
                          child: state.recordParams.isEmpty
                              ? const Center(
                                  child: Text(
                                    'No feedback parameters configured.',
                                    style: TextStyle(color: MColors.inkSoft),
                                  ),
                                )
                              : PageView.builder(
                                  controller: _pageController,
                                  itemCount: state.recordParams.length,
                                  onPageChanged: (value) =>
                                      setState(() => _page = value),
                                  itemBuilder: (context, index) => Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 5,
                                      vertical: 3,
                                    ),
                                    child: _ParamCard(
                                      param: state.recordParams[index],
                                      locked: locked,
                                      listening:
                                          _listeningField == 'param-$index',
                                      onScore: (value) => bloc.add(
                                        UpdateFeedbackScore(index, value),
                                      ),
                                      onNote: (value) => bloc.add(
                                        UpdateFeedbackNote(index, value),
                                      ),
                                      onVoice: () => _toggleSpeech(
                                        field: 'param-$index',
                                        currentText:
                                            state.recordParams[index].note,
                                        onText: (value) => bloc.add(
                                          UpdateFeedbackNote(index, value),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                        ),
                        if (state.recordParams.length > 1)
                          Padding(
                            padding: const EdgeInsets.only(top: 8, bottom: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(
                                state.recordParams.length,
                                (index) => AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  width: index == _page ? 18 : 6,
                                  height: 6,
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: index == _page
                                        ? MColors.terra
                                        : const Color(0xFFD9CDBC),
                                    borderRadius: BorderRadius.circular(99),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        if (!locked && !keyboardOpen)
                          SafeArea(
                            top: false,
                            bottom: false,
                            child: Container(
                              padding: const EdgeInsets.fromLTRB(
                                16,
                                10,
                                16,
                                14,
                              ),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                border: Border(
                                  top: BorderSide(color: MColors.line),
                                ),
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
                                      onTap: () =>
                                          bloc.add(const SaveFeedback()),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    flex: 2,
                                    child: ActionButton(
                                      label:
                                          'Send to ${member.name.split(' ').first}',
                                      icon: Icons.send_rounded,
                                      background: complete
                                          ? MColors.terra
                                          : MColors.line,
                                      foreground: complete
                                          ? Colors.white
                                          : MColors.inkFaint,
                                      onTap: complete
                                          ? () => _confirmSend(
                                              context,
                                              bloc,
                                              member,
                                            )
                                          : null,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    )
                  : _PastFeedbackTab(member: member),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmSend(BuildContext context, ManagerBloc bloc, TeamMember member) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _ConfirmSendSheet(
        member: member,
        onSend: () {
          Navigator.of(context).pop();
          bloc.add(const SendFeedback());
        },
      ),
    );
  }
}

class _FeedbackModeSwitch extends StatelessWidget {
  const _FeedbackModeSwitch({required this.selected, required this.onChanged});

  final int selected;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(
      color: const Color(0xFFEAE0D2),
      borderRadius: BorderRadius.circular(13),
    ),
    child: Row(
      children: List.generate(2, (index) {
        final active = selected == index;
        return Expanded(
          child: InkWell(
            onTap: () => onChanged(index),
            borderRadius: BorderRadius.circular(11),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: const EdgeInsets.symmetric(vertical: 9),
              decoration: BoxDecoration(
                color: active ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(11),
                boxShadow: active
                    ? const [
                        BoxShadow(
                          color: Color(0x1F462D1C),
                          blurRadius: 3,
                          offset: Offset(0, 1),
                        ),
                      ]
                    : null,
              ),
              child: Text(
                index == 0 ? 'Give feedback' : 'Past feedback',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: active ? MColors.ink : MColors.inkSoft,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        );
      }),
    ),
  );
}

class _PastFeedbackTab extends StatelessWidget {
  const _PastFeedbackTab({required this.member});

  final TeamMember member;

  @override
  Widget build(BuildContext context) {
    final scored = member.params.where((item) => item.score > 0).toList();
    final overall = scored.isEmpty
        ? member.score
        : scored.fold<double>(0, (sum, item) => sum + item.score) /
              scored.length;
    final color = scoreColor(overall <= 0 ? 1 : overall);
    final hasFeedback =
        member.status == FeedbackStatus.sent || scored.isNotEmpty;

    if (!hasFeedback) {
      return const SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20, 16, 20, 30),
        child: _EmptyPastFeedback(),
      );
    }
    final record = GrowthRecord(
      period:
          '${member.next.year}-${member.next.month.toString().padLeft(2, '0')}',
      overallScore: overall,
      parameters: member.params,
      sentAt: member.next,
      managerName: 'Manager',
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
      children: [
        const Text(
          'Trend',
          style: TextStyle(
            color: MColors.ink,
            fontSize: 18,
            letterSpacing: -0.1,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        _GrowthChart(records: [record], values: [overall], color: color),
        const SizedBox(height: 22),
        const _GrowthSectionLabel('MONTH BY MONTH'),
        const SizedBox(height: 12),
        SizedBox(
          height: 205,
          child: _GrowthMonthCard(record: record, parameter: null),
        ),
        const SizedBox(height: 22),
        const Text(
          'Full history is retained ✦',
          textAlign: TextAlign.center,
          style: TextStyle(color: MColors.inkFaint, fontSize: 12),
        ),
      ],
    );
  }
}

// Retained temporarily while older deep links are migrated to the tabbed flow.
// ignore: unused_element
class _LegacyRecordFeedback extends StatelessWidget {
  const _LegacyRecordFeedback({required this.state, required this.bloc});

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
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => _PastFeedbackScreen(member: member),
                      ),
                    ),
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
                        listening: false,
                        onScore: (value) =>
                            bloc.add(UpdateFeedbackScore(entry.$1, value)),
                        onNote: (value) =>
                            bloc.add(UpdateFeedbackNote(entry.$1, value)),
                        onVoice: () {},
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
              bottom: false,
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

class _PastFeedbackScreen extends StatelessWidget {
  const _PastFeedbackScreen({required this.member});

  final TeamMember member;

  @override
  Widget build(BuildContext context) {
    final scored = member.params.where((item) => item.score > 0).toList();
    final overall = scored.isEmpty
        ? member.score
        : scored.fold<double>(0, (sum, item) => sum + item.score) /
              scored.length;
    final color = scoreColor(overall <= 0 ? 1 : overall);
    final hasFeedback =
        member.status == FeedbackStatus.sent || scored.isNotEmpty;

    return Scaffold(
      backgroundColor: MColors.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                children: [
                  Row(
                    children: [
                      RoundIconButton(
                        icon: Icons.chevron_left_rounded,
                        onTap: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(width: 12),
                      AvatarBadge(
                        initial: member.initial,
                        index: member.avatarIndex,
                        size: 42,
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
                                fontSize: 21,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -.3,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${member.team} · 1-on-1',
                              style: const TextStyle(
                                color: MColors.inkSoft,
                                fontSize: 13.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAE0D2),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => Navigator.of(context).pop(),
                            borderRadius: BorderRadius.circular(11),
                            child: const Padding(
                              padding: EdgeInsets.symmetric(vertical: 9),
                              child: Text(
                                'Give feedback',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: MColors.inkSoft,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 9),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(11),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x1F462D1C),
                                  blurRadius: 3,
                                  offset: Offset(0, 1),
                                ),
                              ],
                            ),
                            child: const Text(
                              'Past feedback',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: MColors.ink,
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
                children: [
                  if (!hasFeedback)
                    const _EmptyPastFeedback()
                  else ...[
                    Container(
                      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: MColors.line),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Text(
                                'TREND',
                                style: TextStyle(
                                  color: MColors.inkFaint,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              SizedBox(width: 8),
                              Text(
                                'overall, month by month',
                                style: TextStyle(
                                  color: MColors.inkSoft,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                overall.toStringAsFixed(1),
                                style: TextStyle(
                                  color: color,
                                  fontSize: 42,
                                  height: .9,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const Padding(
                                padding: EdgeInsets.only(bottom: 2),
                                child: Text(
                                  '/5',
                                  style: TextStyle(
                                    color: MColors.inkFaint,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 11,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFDEEBE9),
                                  borderRadius: BorderRadius.circular(99),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(
                                      Icons.trending_up_rounded,
                                      size: 16,
                                      color: MColors.teal,
                                    ),
                                    SizedBox(width: 5),
                                    Text(
                                      'Latest',
                                      style: TextStyle(
                                        color: MColors.teal,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(99),
                            child: LinearProgressIndicator(
                              value: (overall / 5).clamp(0.0, 1.0),
                              minHeight: 8,
                              color: color,
                              backgroundColor: MColors.line,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    _PastFeedbackMonthCard(
                      member: member,
                      overall: overall,
                      color: color,
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Full history is retained ✦',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: MColors.inkFaint, fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyPastFeedback extends StatelessWidget {
  const _EmptyPastFeedback();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 96),
    child: Column(
      children: [
        const Icon(Icons.show_chart_rounded, size: 42, color: MColors.inkFaint),
        const SizedBox(height: 14),
        const Text(
          'No past feedback yet',
          style: TextStyle(
            color: MColors.ink,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Sent feedback will build this journey over time.',
          textAlign: TextAlign.center,
          style: TextStyle(color: MColors.inkSoft, fontSize: 13.5),
        ),
      ],
    ),
  );
}

class _PastFeedbackMonthCard extends StatelessWidget {
  const _PastFeedbackMonthCard({
    required this.member,
    required this.overall,
    required this.color,
  });

  final TeamMember member;
  final double overall;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: MColors.line),
    ),
    padding: const EdgeInsets.all(15),
    child: Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_monthName(member.next.month)} ${member.next.year}',
                    style: const TextStyle(
                      color: MColors.ink,
                      fontSize: 15.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    overall >= 4
                        ? 'Exceeds expectation'
                        : overall >= 2.5
                        ? 'Meets expectation'
                        : 'Needs work',
                    style: TextStyle(
                      color: color,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              overall.toStringAsFixed(1),
              style: TextStyle(
                color: color,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const Text(
              '/5',
              style: TextStyle(
                color: MColors.inkFaint,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        if (member.params.isNotEmpty) ...[
          const Divider(height: 24, color: MColors.line),
          ...member.params
              .where((item) => item.score > 0)
              .map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.name,
                          style: const TextStyle(
                            color: MColors.inkSoft,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Text(
                        item.score.toStringAsFixed(1),
                        style: TextStyle(
                          color: scoreColor(item.score),
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
        ],
      ],
    ),
  );
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

class _GrowTab extends StatefulWidget {
  const _GrowTab({required this.state, required this.onOpenProfile});

  final ManagerState state;
  final VoidCallback onOpenProfile;

  @override
  State<_GrowTab> createState() => _GrowTabState();
}

class _GrowTabState extends State<_GrowTab> {
  String? _selectedParameter;

  @override
  Widget build(BuildContext context) {
    final data = widget.state.dashboard!;
    final history = data.growthHistory;
    final parameterNames = history.isEmpty
        ? const <String>[]
        : history.last.parameters.map((item) => item.name).toList();
    final selected = parameterNames.contains(_selectedParameter)
        ? _selectedParameter
        : null;
    final selectedIndex = selected == null
        ? -1
        : parameterNames.indexOf(selected);
    final trendColor = _growthParameterColor(selectedIndex);
    final values = history.map((record) {
      if (selected == null) return record.overallScore;
      return record.parameters
              .where((item) => item.name == selected)
              .map((item) => item.score)
              .firstOrNull ??
          0;
    }).toList();

    return Column(
      key: const ValueKey('grow'),
      children: [
        Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: MColors.line)),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: _ProfileAvatarAction(
                      key: const ValueKey('grow-profile-avatar'),
                      initial: data.managerInitial,
                      onTap: widget.onOpenProfile,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Grow',
                    style: TextStyle(
                      color: MColors.ink,
                      fontSize: 30,
                      height: 1.08,
                      letterSpacing: -0.9,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'Your performance & trajectory, from 1-on-1s',
                    style: TextStyle(color: MColors.inkSoft, fontSize: 14.5),
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              if (history.isEmpty)
                const _GrowthEmptyState()
              else ...[
                const Text(
                  'Trend',
                  style: TextStyle(
                    color: MColors.ink,
                    fontSize: 18,
                    letterSpacing: -0.1,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _GrowthChip(
                        label: 'Overall',
                        color: MColors.terra,
                        selected: selected == null,
                        onTap: () => setState(() => _selectedParameter = null),
                      ),
                      ...parameterNames.indexed.map(
                        (entry) => Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: _GrowthChip(
                            label: entry.$2,
                            color: _growthParameterColor(entry.$1),
                            selected: selected == entry.$2,
                            onTap: () =>
                                setState(() => _selectedParameter = entry.$2),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                _GrowthChart(
                  records: history,
                  values: values,
                  color: trendColor,
                ),
                if (selected != null) ...[
                  const SizedBox(height: 22),
                  const _GrowthSectionLabel('MONTH BY MONTH'),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 205,
                    child: ListView.separated(
                      clipBehavior: Clip.none,
                      scrollDirection: Axis.horizontal,
                      itemCount: history.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        final record = history.reversed.elementAt(index);
                        final parameter = record.parameters
                            .where((item) => item.name == selected)
                            .firstOrNull;
                        return SizedBox(
                          width: 270,
                          child: _GrowthMonthCard(
                            record: record,
                            parameter: parameter,
                          ),
                        );
                      },
                    ),
                  ),
                ],
                const SizedBox(height: 22),
                const Center(
                  child: Text(
                    'Full history is retained ✦',
                    style: TextStyle(color: MColors.inkFaint, fontSize: 12),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

Color _growthParameterColor(int index) {
  if (index < 0) return MColors.terra;
  return switch (index % 3) {
    1 => MColors.teal,
    2 => MColors.plum,
    _ => MColors.terra,
  };
}

class _GrowthEmptyState extends StatelessWidget {
  const _GrowthEmptyState();

  @override
  Widget build(BuildContext context) => const PressableCard(
    padding: EdgeInsets.all(20),
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
            'Your trend and month-by-month feedback will appear after your manager shares the first review.',
            style: TextStyle(
              color: MColors.inkSoft,
              fontSize: 14,
              height: 1.45,
            ),
          ),
        ),
      ],
    ),
  );
}

class _GrowthChip extends StatelessWidget {
  const _GrowthChip({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    borderRadius: BorderRadius.circular(99),
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 9),
      decoration: BoxDecoration(
        color: selected ? color : const Color(0xFFF1EBE1),
        border: Border.all(
          color: selected ? Colors.transparent : const Color(0x1A462D1C),
        ),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: selected ? Colors.white : MColors.inkSoft,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
  );
}

class _GrowthChart extends StatelessWidget {
  const _GrowthChart({
    required this.records,
    required this.values,
    required this.color,
  });

  final List<GrowthRecord> records;
  final List<double> values;
  final Color color;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      SizedBox(
        height: 158,
        width: double.infinity,
        child: CustomPaint(painter: _GrowthChartPainter(values, color)),
      ),
      const SizedBox(height: 6),
      Padding(
        padding: const EdgeInsets.only(left: 28, right: 26),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: records
              .map(
                (record) => Text(
                  _periodLabel(record.period),
                  style: const TextStyle(
                    color: MColors.inkFaint,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
              .toList(),
        ),
      ),
    ],
  );
}

class _GrowthChartPainter extends CustomPainter {
  const _GrowthChartPainter(this.values, this.color);

  final List<double> values;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    var minValue = values.reduce(math.min);
    var maxValue = values.reduce(math.max);
    var min = ((minValue - .5) * 2).floor() / 2;
    var max = ((maxValue + .5) * 2).ceil() / 2;
    if (max - min < 2) {
      final middle = (min + max) / 2;
      min = middle - 1;
      max = middle + 1;
    }
    if (min < 0) {
      max -= min;
      min = 0;
    }
    if (max > 5) {
      min -= max - 5;
      max = 5;
    }
    min = math.max(0, min);
    final range = max - min == 0 ? 1.0 : max - min;
    const left = 28.0;
    const right = 26.0;
    const top = 18.0;
    const bottom = 8.0;
    final plotWidth = size.width - left - right;
    final plotHeight = size.height - top - bottom;
    double yFor(double value) => top + (1 - (value - min) / range) * plotHeight;

    for (var index = 0; index < 5; index++) {
      final guide = min + range * index / 4;
      final y = yFor(guide);
      final grid = Paint()
        ..color = MColors.line
        ..strokeWidth = 1;
      if (index == 0) {
        canvas.drawLine(Offset(left, y), Offset(size.width - right, y), grid);
      } else {
        const dash = 4.0;
        for (var x = left; x < size.width - right; x += dash * 2) {
          canvas.drawLine(
            Offset(x, y),
            Offset(math.min(x + dash, size.width - right), y),
            grid,
          );
        }
      }
      final label = TextPainter(
        text: TextSpan(
          text: guide.toStringAsFixed(1),
          style: const TextStyle(
            color: MColors.inkFaint,
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      label.paint(canvas, Offset(0, y - label.height / 2));
    }
    final line = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final fill = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [color.withValues(alpha: .18), Colors.transparent],
      ).createShader(Offset.zero & size);
    final points = values.indexed.map((entry) {
      final x = values.length == 1
          ? left + plotWidth / 2
          : left + entry.$1 * plotWidth / (values.length - 1);
      final y = yFor(entry.$2.clamp(0, 5));
      return Offset(x, y);
    }).toList();
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }
    final area = Path.from(path)
      ..lineTo(points.last.dx, top + plotHeight)
      ..lineTo(points.first.dx, top + plotHeight)
      ..close();
    canvas
      ..drawPath(area, fill)
      ..drawPath(path, line);
    for (final entry in points.indexed) {
      final isLast = entry.$1 == points.length - 1;
      canvas.drawCircle(
        entry.$2,
        isLast ? 5.5 : 4,
        Paint()..color = isLast ? color : Colors.white,
      );
      canvas.drawCircle(
        entry.$2,
        isLast ? 4.25 : 3,
        Paint()
          ..color = color
          ..style = isLast ? PaintingStyle.fill : PaintingStyle.stroke
          ..strokeWidth = 2.5,
      );
    }

    final valueLabel = TextPainter(
      text: TextSpan(
        text: values.last.toStringAsFixed(1),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final last = points.last;
    final pillWidth = valueLabel.width + 16;
    const pillHeight = 23.0;
    final pillLeft = (last.dx - pillWidth / 2).clamp(
      left,
      size.width - right - pillWidth,
    );
    final pillTop = math.max(0.0, last.dy - 31);
    final pill = RRect.fromRectAndRadius(
      Rect.fromLTWH(pillLeft, pillTop, pillWidth, pillHeight),
      const Radius.circular(99),
    );
    canvas.drawRRect(pill, Paint()..color = color);
    valueLabel.paint(
      canvas,
      Offset(
        pillLeft + (pillWidth - valueLabel.width) / 2,
        pillTop + (pillHeight - valueLabel.height) / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(_GrowthChartPainter oldDelegate) =>
      oldDelegate.values != values || oldDelegate.color != color;
}

class _GrowthSectionLabel extends StatelessWidget {
  const _GrowthSectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Text(
    label,
    style: const TextStyle(
      color: MColors.inkFaint,
      fontSize: 11,
      fontWeight: FontWeight.w800,
      letterSpacing: 1.1,
    ),
  );
}

class _GrowthMonthCard extends StatelessWidget {
  const _GrowthMonthCard({required this.record, required this.parameter});

  final GrowthRecord record;
  final FeedbackParam? parameter;

  @override
  Widget build(BuildContext context) {
    final score = parameter?.score ?? record.overallScore;
    final notes = record.parameters
        .where((item) => item.note.trim().isNotEmpty)
        .map((item) => '${item.name}: ${item.note.trim()}')
        .join('\n\n');
    final note = parameter?.note.trim().isNotEmpty == true
        ? parameter!.note
        : notes.isNotEmpty
        ? notes
        : 'No feedback was recorded in this cycle.';
    return PressableCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _periodTitle(record.period),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: MColors.inkSoft,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                score.toStringAsFixed(1),
                style: TextStyle(
                  color: scoreColor(score),
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Text(
                '/5',
                style: TextStyle(
                  color: MColors.inkFaint,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1, color: MColors.line),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Text(
                note,
                style: const TextStyle(
                  color: MColors.inkSoft,
                  fontSize: 13.5,
                  height: 1.65,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ComingSoonTab extends StatelessWidget {
  const _ComingSoonTab({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    required this.profileAction,
  });

  final IconData icon;
  final String title;
  final String body;
  final Widget profileAction;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('coming-soon'),
      children: [
        SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Row(children: [const Spacer(), profileAction]),
          ),
        ),
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: _ComingSoonBlock(icon: icon, title: title, body: body),
            ),
          ),
        ),
      ],
    );
  }
}

class _ProfileAvatarAction extends StatelessWidget {
  const _ProfileAvatarAction({
    super.key,
    required this.initial,
    required this.onTap,
  });

  final String initial;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Open profile',
      child: InkWell(
        borderRadius: BorderRadius.circular(99),
        onTap: onTap,
        child: AvatarBadge(initial: initial, index: 1, size: 42),
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

class _ActionAvatar {
  const _ActionAvatar({
    required this.initial,
    required this.index,
    this.completed = false,
  });

  final String initial;
  final int index;
  final bool completed;
}

class _AvatarActionCluster extends StatelessWidget {
  const _AvatarActionCluster({
    required this.people,
    required this.onTap,
    this.emptyText = 'All caught up',
  });

  final Iterable<_ActionAvatar> people;
  final VoidCallback onTap;
  final String emptyText;

  @override
  Widget build(BuildContext context) {
    final items = people.toList();
    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
        child: Text(
          emptyText,
          style: const TextStyle(
            color: MColors.inkFaint,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }
    return Semantics(
      button: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: items.map((person) {
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Opacity(
                    opacity: person.completed ? .5 : 1,
                    child: AvatarBadge(
                      initial: person.initial,
                      index: person.index,
                      size: 46,
                    ),
                  ),
                  if (person.completed)
                    const Positioned(
                      right: -2,
                      bottom: -2,
                      child: CircleAvatar(
                        radius: 10,
                        backgroundColor: Colors.white,
                        child: CircleAvatar(
                          radius: 8,
                          backgroundColor: MColors.sage,
                          child: Icon(
                            Icons.check_rounded,
                            size: 11,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

enum _RequestType { leave, overtime }

class _RequestList extends StatefulWidget {
  const _RequestList({
    required this.state,
    required this.bloc,
    required this.type,
  });

  final ManagerState state;
  final ManagerBloc bloc;
  final _RequestType type;

  @override
  State<_RequestList> createState() => _RequestListState();
}

class _RequestListState extends State<_RequestList> {
  bool _reviewed = false;

  @override
  Widget build(BuildContext context) {
    final isLeave = widget.type == _RequestType.leave;
    final isOvertime = widget.type == _RequestType.overtime;
    final pendingCount = switch (widget.type) {
      _RequestType.leave =>
        widget.state.dashboard!.leaves
            .where((item) => item.decision == LeaveDecision.pending)
            .length,
      _RequestType.overtime =>
        widget.state.dashboard!.overtime
            .where((item) => item.decision == LeaveDecision.pending)
            .length,
    };
    final close = switch (widget.type) {
      _RequestType.leave => const CloseLeaveRequests(),
      _RequestType.overtime => const CloseOvertimeRequests(),
    };
    final title = switch (widget.type) {
      _RequestType.leave => 'Leave requests',
      _RequestType.overtime => 'Overtime requests',
    };

    return Column(
      key: ValueKey('${widget.type.name}-requests'),
      children: [
        _TopBar(
          title: title,
          sub: 'Review requests from your team',
          onBack: () => widget.bloc.add(close),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
          child: Row(
            children: [
              Expanded(
                child: _RequestFilterButton(
                  label: pendingCount == 0
                      ? 'Pending'
                      : 'Pending · $pendingCount',
                  selected: !_reviewed,
                  onTap: () => setState(() => _reviewed = false),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _RequestFilterButton(
                  label: 'Reviewed',
                  selected: _reviewed,
                  onTap: () => setState(() => _reviewed = true),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Builder(
            builder: (context) {
              if (isLeave) {
                final items = widget.state.dashboard!.leaves
                    .where(
                      (item) => _reviewed
                          ? item.decision != LeaveDecision.pending
                          : item.decision == LeaveDecision.pending,
                    )
                    .toList();
                return _RequestListBody(
                  empty: items.isEmpty,
                  reviewed: _reviewed,
                  children: items
                      .map((item) => _LeaveCard(leave: item, bloc: widget.bloc))
                      .toList(),
                );
              }
              if (isOvertime) {
                final items = widget.state.dashboard!.overtime
                    .where(
                      (item) => _reviewed
                          ? item.decision != LeaveDecision.pending
                          : item.decision == LeaveDecision.pending,
                    )
                    .toList();
                return _RequestListBody(
                  empty: items.isEmpty,
                  reviewed: _reviewed,
                  children: items
                      .map(
                        (item) => _OvertimeRequestCard(
                          request: item,
                          bloc: widget.bloc,
                        ),
                      )
                      .toList(),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ),
      ],
    );
  }
}

class _RequestFilterButton extends StatelessWidget {
  const _RequestFilterButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    borderRadius: BorderRadius.circular(12),
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(vertical: 11),
      decoration: BoxDecoration(
        color: selected ? MColors.terra : Colors.white,
        border: Border.all(color: selected ? MColors.terra : MColors.line),
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: TextStyle(
          color: selected ? Colors.white : MColors.inkSoft,
          fontSize: 13.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    ),
  );
}

class _RequestListBody extends StatelessWidget {
  const _RequestListBody({
    required this.empty,
    required this.reviewed,
    required this.children,
  });

  final bool empty;
  final bool reviewed;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    if (empty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                reviewed ? Icons.history_rounded : Icons.task_alt_rounded,
                size: 42,
                color: MColors.sageDeep,
              ),
              const SizedBox(height: 12),
              Text(
                reviewed
                    ? 'No reviewed requests yet.'
                    : 'No requests waiting on you.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: MColors.inkSoft,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 32),
      itemCount: children.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (_, index) => children[index],
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
      onTap: () => _openDetails(context),
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(15, 15, 15, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    AvatarBadge(
                      initial: leave.initial,
                      index: leave.avatarIndex,
                      size: 42,
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            leave.who,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: MColors.ink,
                              fontWeight: FontWeight.w800,
                              fontSize: 15.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${leave.team} · ${_appliedTimestamp(leave.requestedOn)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: MColors.inkFaint,
                              fontSize: 12.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (leave.decision != LeaveDecision.pending) ...[
                      const SizedBox(width: 8),
                      _LeaveStatusPill(decision: leave.decision),
                    ],
                  ],
                ),
                const SizedBox(height: 13),
                _LeaveDatePanel(leave: leave, colors: colors),
                const SizedBox(height: 10),
                _LeaveTypeChip(type: leave.type),
                const SizedBox(height: 11),
                Text(
                  leave.reason,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: MColors.inkSoft,
                    fontSize: 13.5,
                    height: 1.55,
                  ),
                ),
                if (leave.decision == LeaveDecision.declined &&
                    leave.managerNote.isNotEmpty) ...[
                  const SizedBox(height: 11),
                  _ReviewedDeclineNote(note: leave.managerNote),
                ],
              ],
            ),
          ),
          if (leave.decision == LeaveDecision.pending)
            Padding(
              padding: const EdgeInsets.fromLTRB(15, 0, 15, 15),
              child: Row(
                children: [
                  Expanded(
                    child: ActionButton(
                      label: 'Decline',
                      icon: Icons.close_rounded,
                      background: Colors.white,
                      foreground: MColors.inkSoft,
                      border: MColors.line,
                      onTap: () =>
                          _confirmDecision(context, LeaveDecision.declined),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ActionButton(
                      label: 'Approve',
                      icon: Icons.check_rounded,
                      background: MColors.sageDeep,
                      foreground: Colors.white,
                      onTap: () =>
                          _confirmDecision(context, LeaveDecision.approved),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _openDetails(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _LeaveRequestDetailPage(leave: leave, bloc: bloc),
      ),
    );
  }

  Future<void> _confirmDecision(
    BuildContext context,
    LeaveDecision decision,
  ) async {
    final result = await _showLeaveDecisionSheet(context, leave, decision);
    if (result != null && context.mounted) {
      bloc.add(
        DecideLeave(leave.id, decision, managerNote: result.managerNote),
      );
    }
  }
}

class _LeaveDatePanel extends StatelessWidget {
  const _LeaveDatePanel({required this.leave, required this.colors});

  final LeaveRequest leave;
  final (Color, Color) colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
      decoration: BoxDecoration(
        color: colors.$2,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.calendar_month_rounded, size: 18, color: colors.$1),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _leaveDateRange(leave),
              style: TextStyle(
                color: colors.$1,
                fontSize: 14.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Text(
            '${leave.days} ${leave.days == 1 ? 'day' : 'days'}',
            style: TextStyle(
              color: colors.$1.withValues(alpha: .85),
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _LeaveTypeChip extends StatelessWidget {
  const _LeaveTypeChip({required this.type, this.large = false});

  final String type;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final colors = leavePalette(type);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: large ? 12 : 9,
        vertical: large ? 6 : 4,
      ),
      decoration: BoxDecoration(
        color: colors.$2,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        type,
        style: TextStyle(
          color: colors.$1,
          fontSize: large ? 13 : 11.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _LeaveStatusPill extends StatelessWidget {
  const _LeaveStatusPill({required this.decision});

  final LeaveDecision decision;

  @override
  Widget build(BuildContext context) {
    final approved = decision == LeaveDecision.approved;
    final color = approved ? MColors.sageDeep : MColors.terraDeep;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: approved ? MColors.sageTint : MColors.terraTint,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (approved) ...[
            Icon(Icons.check_rounded, size: 13, color: color),
            const SizedBox(width: 5),
          ],
          Text(
            approved ? 'Approved' : 'Declined',
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

class _LeaveRequestDetailPage extends StatelessWidget {
  const _LeaveRequestDetailPage({required this.leave, required this.bloc});

  final LeaveRequest leave;
  final ManagerBloc bloc;

  @override
  Widget build(BuildContext context) {
    final colors = leavePalette(leave.type);
    return Scaffold(
      backgroundColor: MColors.bg,
      body: Column(
        children: [
          _TopBar(
            title: 'Leave request',
            sub: '${leave.who} · ${leave.team}',
            onBack: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
              children: [
                PressableCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          AvatarBadge(
                            initial: leave.initial,
                            index: leave.avatarIndex,
                            size: 50,
                          ),
                          const SizedBox(width: 13),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  leave.who,
                                  style: const TextStyle(
                                    color: MColors.ink,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _appliedTimestamp(leave.requestedOn),
                                  style: const TextStyle(
                                    color: MColors.inkFaint,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          leave.decision == LeaveDecision.pending
                              ? _LeaveTypeChip(type: leave.type, large: true)
                              : _LeaveStatusPill(decision: leave.decision),
                        ],
                      ),
                      const SizedBox(height: 16),
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: _LeaveInfoTile(
                                label: 'DATES',
                                value: _leaveDateRange(leave),
                                background: colors.$2,
                                foreground: colors.$1,
                              ),
                            ),
                            const SizedBox(width: 12),
                            _LeaveInfoTile(
                              label: 'DURATION',
                              value:
                                  '${leave.days} ${leave.days == 1 ? 'day' : 'days'}',
                              background: const Color(0xFFF8F4EE),
                              foreground: MColors.ink,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                const _LeaveSectionLabel('REASON'),
                const SizedBox(height: 7),
                PressableCard(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    leave.reason,
                    style: const TextStyle(
                      color: MColors.ink,
                      fontSize: 14.5,
                      height: 1.65,
                    ),
                  ),
                ),
                if (leave.decision == LeaveDecision.declined &&
                    leave.managerNote.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  const _LeaveSectionLabel('DECLINE NOTE'),
                  const SizedBox(height: 7),
                  PressableCard(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      leave.managerNote,
                      style: const TextStyle(
                        color: MColors.ink,
                        fontSize: 14.5,
                        height: 1.65,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                const _LeaveSectionLabel('REQUEST DETAILS'),
                const SizedBox(height: 7),
                PressableCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 5,
                  ),
                  child: Column(
                    children: [
                      _LeaveDetailRow(
                        icon: Icons.event_available_rounded,
                        label: 'Leave type',
                        value: leave.type,
                      ),
                      const Divider(height: 1, color: MColors.line),
                      _LeaveDetailRow(
                        icon: Icons.schedule_rounded,
                        label: 'Requested',
                        value: _requestTimestamp(leave.requestedOn),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (leave.decision == LeaveDecision.pending)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: MColors.line)),
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    Expanded(
                      flex: 10,
                      child: ActionButton(
                        label: 'Decline',
                        icon: Icons.close_rounded,
                        background: Colors.white,
                        foreground: MColors.inkSoft,
                        border: MColors.line,
                        onTap: () => _decide(context, LeaveDecision.declined),
                      ),
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      flex: 14,
                      child: ActionButton(
                        label: 'Approve',
                        icon: Icons.check_rounded,
                        background: MColors.sageDeep,
                        foreground: Colors.white,
                        onTap: () => _decide(context, LeaveDecision.approved),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _decide(BuildContext context, LeaveDecision decision) async {
    final result = await _showLeaveDecisionSheet(context, leave, decision);
    if (result == null || !context.mounted) return;
    bloc.add(DecideLeave(leave.id, decision, managerNote: result.managerNote));
  }
}

class _LeaveInfoTile extends StatelessWidget {
  const _LeaveInfoTile({
    required this.label,
    required this.value,
    required this.background,
    required this.foreground,
  });

  final String label;
  final String value;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: foreground.withValues(alpha: .75),
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: .7,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: TextStyle(
              color: foreground,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewedDeclineNote extends StatelessWidget {
  const _ReviewedDeclineNote({required this.note});

  final String note;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: MColors.terraTint,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Decline note',
          style: TextStyle(
            color: MColors.terraDeep,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          note,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: MColors.inkSoft,
            fontSize: 13,
            height: 1.45,
          ),
        ),
      ],
    ),
  );
}

class _LeaveSectionLabel extends StatelessWidget {
  const _LeaveSectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 4),
    child: Text(
      label,
      style: const TextStyle(
        color: MColors.inkFaint,
        fontSize: 11.5,
        fontWeight: FontWeight.w800,
        letterSpacing: 1,
      ),
    ),
  );
}

class _LeaveDetailRow extends StatelessWidget {
  const _LeaveDetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 13),
    child: Row(
      children: [
        Icon(icon, size: 19, color: MColors.inkFaint),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: MColors.inkSoft, fontSize: 13.5),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: MColors.ink,
            fontSize: 13.5,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
  );
}

class _DecisionSheetResult {
  const _DecisionSheetResult(this.managerNote);

  final String managerNote;
}

Future<_DecisionSheetResult?> _showLeaveDecisionSheet(
  BuildContext context,
  LeaveRequest leave,
  LeaveDecision decision,
) async {
  final approve = decision == LeaveDecision.approved;
  final accent = approve ? MColors.sageDeep : MColors.terra;
  final noteController = TextEditingController();
  try {
    return await showModalBottomSheet<_DecisionSheetResult>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
          ),
          child: Container(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 20),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                  Text(
                    approve ? 'Approve leave' : 'Decline leave',
                    style: const TextStyle(
                      color: MColors.ink,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          leave.who,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: MColors.inkSoft,
                            fontSize: 13.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _LeaveTypeChip(type: leave.type),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 13,
                      vertical: 11,
                    ),
                    decoration: BoxDecoration(
                      color: MColors.bg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_month_rounded,
                          size: 18,
                          color: MColors.inkFaint,
                        ),
                        const SizedBox(width: 9),
                        Expanded(
                          child: Text(
                            _leaveDateRange(leave),
                            style: const TextStyle(
                              color: MColors.ink,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        Text(
                          '${leave.days}d',
                          style: const TextStyle(
                            color: MColors.inkSoft,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  _LeaveDetailRow(
                    icon: Icons.schedule_rounded,
                    label: 'Applied',
                    value: _requestTimestamp(leave.requestedOn),
                  ),
                  const SizedBox(height: 18),
                  if (!approve) ...[
                    const Text(
                      'Reason for declining',
                      style: TextStyle(
                        color: MColors.ink,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: noteController,
                      autofocus: true,
                      maxLength: 500,
                      maxLines: 3,
                      onChanged: (_) => setSheetState(() {}),
                      decoration: _fieldDecoration(
                        'Explain why this leave request is being declined…',
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  Row(
                    children: [
                      Expanded(
                        flex: 10,
                        child: ActionButton(
                          label: 'Cancel',
                          background: Colors.white,
                          foreground: MColors.inkSoft,
                          border: MColors.line,
                          onTap: () => Navigator.pop(sheetContext),
                        ),
                      ),
                      const SizedBox(width: 11),
                      Expanded(
                        flex: 15,
                        child: ActionButton(
                          label: approve
                              ? 'Confirm approve'
                              : 'Confirm decline',
                          icon: approve ? Icons.check_rounded : null,
                          background:
                              !approve && noteController.text.trim().isEmpty
                              ? MColors.line
                              : accent,
                          foreground:
                              !approve && noteController.text.trim().isEmpty
                              ? MColors.inkFaint
                              : Colors.white,
                          onTap: !approve && noteController.text.trim().isEmpty
                              ? null
                              : () => Navigator.pop(
                                  sheetContext,
                                  _DecisionSheetResult(
                                    noteController.text.trim(),
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  } finally {
    noteController.dispose();
  }
}

String _leaveDateRange(LeaveRequest leave) {
  final start = '${leave.start.day} ${_monthName(leave.start.month)}';
  if (leave.start.year == leave.end.year &&
      leave.start.month == leave.end.month &&
      leave.start.day == leave.end.day) {
    return start;
  }
  return '$start – ${leave.end.day} ${_monthName(leave.end.month)}';
}

String _appliedTimestamp(DateTime value) {
  return 'applied ${daysAgo(value)} ago · ${_requestTimestamp(value)}';
}

String _requestTimestamp(DateTime value) {
  final local = value.toLocal();
  final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
  final minute = local.minute.toString().padLeft(2, '0');
  final suffix = local.hour >= 12 ? 'PM' : 'AM';
  return '${local.day} ${_monthName(local.month)} ${local.year}, $hour:$minute $suffix';
}

class _OvertimeRequestCard extends StatelessWidget {
  const _OvertimeRequestCard({required this.request, required this.bloc});

  final OvertimeRequest request;
  final ManagerBloc bloc;

  @override
  Widget build(BuildContext context) {
    return PressableCard(
      onTap: () => _openDetails(context),
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(15, 15, 15, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    AvatarBadge(
                      initial: request.initial,
                      index: request.avatarIndex,
                      size: 42,
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            request.who,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: MColors.ink,
                              fontWeight: FontWeight.w800,
                              fontSize: 15.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${request.team} · applied ${daysAgo(request.requestedOn)} ago',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: MColors.inkFaint,
                              fontSize: 12.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    request.decision == LeaveDecision.pending
                        ? _RequestChip(
                            label: request.duration,
                            foreground: MColors.gold,
                            background: MColors.goldTint,
                          )
                        : _LeaveStatusPill(decision: request.decision),
                  ],
                ),
                const SizedBox(height: 13),
                _RequestHighlightPanel(
                  icon: Icons.schedule_rounded,
                  value: _managerDate(request.workDate),
                  trailing: request.hours > 0
                      ? '${request.hours.toStringAsFixed(request.hours == request.hours.roundToDouble() ? 0 : 1)} hrs'
                      : request.duration,
                  foreground: MColors.gold,
                  background: MColors.goldTint,
                ),
                const SizedBox(height: 11),
                Text(
                  request.note.isEmpty ? request.project : request.note,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: MColors.inkSoft,
                    fontSize: 13.5,
                    height: 1.55,
                  ),
                ),
              ],
            ),
          ),
          if (request.decision == LeaveDecision.pending)
            Padding(
              padding: const EdgeInsets.fromLTRB(15, 0, 15, 15),
              child: Row(
                children: [
                  Expanded(
                    child: ActionButton(
                      label: 'Decline',
                      icon: Icons.close_rounded,
                      background: Colors.white,
                      foreground: MColors.inkSoft,
                      border: MColors.line,
                      onTap: () =>
                          _confirmDecision(context, LeaveDecision.declined),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ActionButton(
                      label: 'Approve',
                      icon: Icons.check_rounded,
                      background: MColors.sageDeep,
                      foreground: Colors.white,
                      onTap: () =>
                          _confirmDecision(context, LeaveDecision.approved),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _openDetails(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            _OvertimeRequestDetailPage(request: request, bloc: bloc),
      ),
    );
  }

  Future<void> _confirmDecision(
    BuildContext context,
    LeaveDecision decision,
  ) async {
    final result = await _showRequestDecisionSheet(
      context,
      approve: decision == LeaveDecision.approved,
      requestName: 'overtime',
      person: request.who,
      chipLabel: request.duration,
      chipForeground: MColors.gold,
      chipBackground: MColors.goldTint,
      icon: Icons.schedule_rounded,
      value: _managerDate(request.workDate),
      trailing: request.hours > 0 ? '${request.hours} hrs' : request.duration,
    );
    if (result != null && context.mounted) {
      bloc.add(
        DecideOvertime(request.id, decision, managerNote: result.managerNote),
      );
    }
  }
}

class _RequestChip extends StatelessWidget {
  const _RequestChip({
    required this.label,
    required this.foreground,
    required this.background,
    this.large = false,
  });

  final String label;
  final Color foreground;
  final Color background;
  final bool large;

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.symmetric(
      horizontal: large ? 12 : 9,
      vertical: large ? 6 : 4,
    ),
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(99),
    ),
    child: Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: foreground,
        fontSize: large ? 13 : 11.5,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}

class _RequestHighlightPanel extends StatelessWidget {
  const _RequestHighlightPanel({
    required this.icon,
    required this.value,
    required this.trailing,
    required this.foreground,
    required this.background,
  });

  final IconData icon;
  final String value;
  final String trailing;
  final Color foreground;
  final Color background;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        Icon(icon, size: 18, color: foreground),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: foreground,
              fontSize: 14.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Text(
          trailing,
          style: TextStyle(
            color: foreground.withValues(alpha: .85),
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

class _OvertimeRequestDetailPage extends StatelessWidget {
  const _OvertimeRequestDetailPage({required this.request, required this.bloc});

  final OvertimeRequest request;
  final ManagerBloc bloc;

  @override
  Widget build(BuildContext context) => _ManagerRequestDetailPage(
    title: 'Overtime request',
    person: request.who,
    team: request.team,
    initial: request.initial,
    avatarIndex: request.avatarIndex,
    requestedOn: request.requestedOn,
    chip: request.decision == LeaveDecision.pending
        ? _RequestChip(
            label: request.duration,
            foreground: MColors.gold,
            background: MColors.goldTint,
            large: true,
          )
        : _LeaveStatusPill(decision: request.decision),
    primaryLabel: 'WORK DATE',
    primaryValue: _managerDate(request.workDate),
    primaryForeground: MColors.gold,
    primaryBackground: MColors.goldTint,
    secondaryLabel: 'DURATION',
    secondaryValue: request.hours > 0
        ? '${request.hours.toStringAsFixed(request.hours == request.hours.roundToDouble() ? 0 : 1)} hours'
        : request.duration,
    noteLabel: request.note.isEmpty ? null : 'NOTE',
    note: request.note.isEmpty ? null : request.note,
    details: [
      (Icons.work_outline_rounded, 'Project', request.project),
      (
        Icons.schedule_rounded,
        'Requested',
        '${daysAgo(request.requestedOn)} ago',
      ),
    ],
    pending: request.decision == LeaveDecision.pending,
    onDecline: () => _decide(context, LeaveDecision.declined),
    onApprove: () => _decide(context, LeaveDecision.approved),
  );

  Future<void> _decide(BuildContext context, LeaveDecision decision) async {
    final result = await _showRequestDecisionSheet(
      context,
      approve: decision == LeaveDecision.approved,
      requestName: 'overtime',
      person: request.who,
      chipLabel: request.duration,
      chipForeground: MColors.gold,
      chipBackground: MColors.goldTint,
      icon: Icons.schedule_rounded,
      value: _managerDate(request.workDate),
      trailing: request.hours > 0 ? '${request.hours} hrs' : request.duration,
    );
    if (result == null || !context.mounted) return;
    bloc.add(
      DecideOvertime(request.id, decision, managerNote: result.managerNote),
    );
    Navigator.of(context).pop();
  }
}

class _ManagerRequestDetailPage extends StatelessWidget {
  const _ManagerRequestDetailPage({
    required this.title,
    required this.person,
    required this.team,
    required this.initial,
    required this.avatarIndex,
    required this.requestedOn,
    required this.chip,
    required this.primaryLabel,
    required this.primaryValue,
    required this.primaryForeground,
    required this.primaryBackground,
    required this.secondaryLabel,
    required this.secondaryValue,
    required this.details,
    required this.pending,
    required this.onDecline,
    required this.onApprove,
    this.noteLabel,
    this.note,
  });

  final String title;
  final String person;
  final String team;
  final String initial;
  final int avatarIndex;
  final DateTime requestedOn;
  final Widget chip;
  final String primaryLabel;
  final String primaryValue;
  final Color primaryForeground;
  final Color primaryBackground;
  final String secondaryLabel;
  final String secondaryValue;
  final List<(IconData, String, String)> details;
  final bool pending;
  final VoidCallback onDecline;
  final VoidCallback onApprove;
  final String? noteLabel;
  final String? note;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: MColors.bg,
    body: Column(
      children: [
        _TopBar(
          title: title,
          sub: '$person · $team',
          onBack: () => Navigator.of(context).pop(),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
            children: [
              PressableCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        AvatarBadge(
                          initial: initial,
                          index: avatarIndex,
                          size: 50,
                        ),
                        const SizedBox(width: 13),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                person,
                                style: const TextStyle(
                                  color: MColors.ink,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Applied ${daysAgo(requestedOn)} ago',
                                style: const TextStyle(
                                  color: MColors.inkFaint,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(child: chip),
                      ],
                    ),
                    const SizedBox(height: 16),
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: _LeaveInfoTile(
                              label: primaryLabel,
                              value: primaryValue,
                              background: primaryBackground,
                              foreground: primaryForeground,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _LeaveInfoTile(
                              label: secondaryLabel,
                              value: secondaryValue,
                              background: const Color(0xFFF8F4EE),
                              foreground: MColors.ink,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (note != null) ...[
                const SizedBox(height: 18),
                _LeaveSectionLabel(noteLabel!),
                const SizedBox(height: 7),
                PressableCard(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    note!,
                    style: const TextStyle(
                      color: MColors.ink,
                      fontSize: 14.5,
                      height: 1.65,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 18),
              const _LeaveSectionLabel('REQUEST DETAILS'),
              const SizedBox(height: 7),
              PressableCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 5,
                ),
                child: Column(
                  children: [
                    for (var index = 0; index < details.length; index++) ...[
                      _LeaveDetailRow(
                        icon: details[index].$1,
                        label: details[index].$2,
                        value: details[index].$3,
                      ),
                      if (index != details.length - 1)
                        const Divider(height: 1, color: MColors.line),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        if (pending)
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: MColors.line)),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    flex: 10,
                    child: ActionButton(
                      label: 'Decline',
                      icon: Icons.close_rounded,
                      background: Colors.white,
                      foreground: MColors.inkSoft,
                      border: MColors.line,
                      onTap: onDecline,
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    flex: 14,
                    child: ActionButton(
                      label: 'Approve',
                      icon: Icons.check_rounded,
                      background: MColors.sageDeep,
                      foreground: Colors.white,
                      onTap: onApprove,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    ),
  );
}

Future<_DecisionSheetResult?> _showRequestDecisionSheet(
  BuildContext context, {
  required bool approve,
  required String requestName,
  required String person,
  required String chipLabel,
  required Color chipForeground,
  required Color chipBackground,
  required IconData icon,
  required String value,
  required String trailing,
}) async {
  final accent = approve ? MColors.sageDeep : MColors.live;
  final noteController = TextEditingController();
  try {
    return await showModalBottomSheet<_DecisionSheetResult>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
          ),
          child: Container(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 20),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                  Text(
                    '${approve ? 'Approve' : 'Decline'} $requestName',
                    style: const TextStyle(
                      color: MColors.ink,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          person,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: MColors.inkSoft,
                            fontSize: 13.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _RequestChip(
                        label: chipLabel,
                        foreground: chipForeground,
                        background: chipBackground,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 13,
                      vertical: 11,
                    ),
                    decoration: BoxDecoration(
                      color: MColors.bg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(icon, size: 18, color: MColors.inkFaint),
                        const SizedBox(width: 9),
                        Expanded(
                          child: Text(
                            value,
                            style: const TextStyle(
                              color: MColors.ink,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        Text(
                          trailing,
                          style: const TextStyle(
                            color: MColors.inkSoft,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  if (!approve) ...[
                    const Text(
                      'Reason for declining',
                      style: TextStyle(
                        color: MColors.ink,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: noteController,
                      autofocus: true,
                      maxLength: 500,
                      maxLines: 3,
                      onChanged: (_) => setSheetState(() {}),
                      decoration: _fieldDecoration(
                        'Explain why this overtime request is being declined…',
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  Row(
                    children: [
                      Expanded(
                        flex: 10,
                        child: ActionButton(
                          label: 'Cancel',
                          background: Colors.white,
                          foreground: MColors.inkSoft,
                          border: MColors.line,
                          onTap: () => Navigator.pop(sheetContext),
                        ),
                      ),
                      const SizedBox(width: 11),
                      Expanded(
                        flex: 15,
                        child: ActionButton(
                          label: approve
                              ? 'Confirm approve'
                              : 'Confirm decline',
                          icon: approve
                              ? Icons.check_rounded
                              : Icons.close_rounded,
                          background:
                              !approve && noteController.text.trim().isEmpty
                              ? MColors.line
                              : accent,
                          foreground:
                              !approve && noteController.text.trim().isEmpty
                              ? MColors.inkFaint
                              : Colors.white,
                          onTap: !approve && noteController.text.trim().isEmpty
                              ? null
                              : () => Navigator.pop(
                                  sheetContext,
                                  _DecisionSheetResult(
                                    noteController.text.trim(),
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  } finally {
    noteController.dispose();
  }
}

class _AwardCard extends StatelessWidget {
  const _AwardCard({
    required this.award,
    required this.team,
    required this.onNominate,
  });

  final AwardNomination award;
  final List<TeamMember> team;
  final VoidCallback onNominate;

  @override
  Widget build(BuildContext context) {
    final palette = awardPalette(award.key);
    final nominee = award.nomineeId == null
        ? null
        : team.where((item) => item.id == award.nomineeId).firstOrNull;
    return PressableCard(
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
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: nominee == null ? MColors.inkSoft : palette.$1,
              fontSize: 12.2,
              height: 1.25,
              fontWeight: nominee == null ? FontWeight.w500 : FontWeight.w800,
            ),
          ),
          const SizedBox(height: 9),
          Semantics(
            button: true,
            label: 'Nominate someone for ${award.title}',
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: onNominate,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    '+ Nominate',
                    style: TextStyle(
                      color: palette.$1,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
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
  int _step = 0;
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
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selected = await showDatePicker(
      context: context,
      initialDate: start ? _startDate : _endDate,
      firstDate: today.subtract(const Duration(days: 365)),
      lastDate: today.add(const Duration(days: 365)),
      selectableDayPredicate: (day) {
        final date = DateTime(day.year, day.month, day.day);
        if (!_canSelectLeaveDay(date)) return false;
        if (!start && date.isBefore(_startDate)) return false;
        if (!start &&
            date.difference(_startDate).inDays >= _maxLeaveApplyDays) {
          return false;
        }
        return true;
      },
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

  bool _canSelectLeaveDay(DateTime day) {
    return day.weekday != DateTime.saturday &&
        day.weekday != DateTime.sunday &&
        !_isCompanyHoliday(day);
  }

  bool _isCompanyHoliday(DateTime day) {
    final holidays =
        widget.state.dashboard?.holidays ?? const <CompanyHoliday>[];
    return holidays.any(
      (holiday) =>
          holiday.date.year == day.year &&
          holiday.date.month == day.month &&
          holiday.date.day == day.day,
    );
  }

  bool _rangeHasBlockedDay() {
    for (
      var day = _startDate;
      !day.isAfter(_endDate);
      day = day.add(const Duration(days: 1))
    ) {
      if (!_canSelectLeaveDay(day)) return true;
    }
    return false;
  }

  void _continueFromDates() {
    if (_endDate.isBefore(_startDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End date cannot be before start date')),
      );
      return;
    }
    if (_endDate.difference(_startDate).inDays + 1 > _maxLeaveApplyDays) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Leave cannot exceed 30 days')),
      );
      return;
    }
    if (_rangeHasBlockedDay()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Leave cannot include weekends or holidays'),
        ),
      );
      return;
    }
    setState(() => _step = 1);
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
                          if (_step == 0) ...[
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
                            const Text(
                              'Weekends and company holidays are unavailable.',
                              style: TextStyle(
                                color: MColors.inkFaint,
                                fontSize: 12.5,
                              ),
                            ),
                          ] else ...[
                            Wrap(
                              spacing: 8,
                              children: ['Sick', 'Casual', 'Earned'].map((
                                type,
                              ) {
                                final selected = _type == type;
                                return ChoiceChip(
                                  label: Text(type),
                                  selected: selected,
                                  onSelected: (_) =>
                                      setState(() => _type = type),
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
                              controller: _reasonController,
                              maxLines: 3,
                              maxLength: 500,
                              decoration: _fieldDecoration('Reason'),
                            ),
                          ],
                          const SizedBox(height: 16),
                          ActionButton(
                            label: _step == 0
                                ? 'Apply leave'
                                : 'Submit request',
                            background: MColors.terra,
                            foreground: Colors.white,
                            onTap: _step == 0 ? _continueFromDates : _submit,
                          ),
                          if (_step == 1)
                            TextButton(
                              onPressed: () => setState(() => _step = 0),
                              child: const Text('Back'),
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

class _ParamCard extends StatefulWidget {
  const _ParamCard({
    required this.param,
    required this.locked,
    required this.listening,
    required this.onScore,
    required this.onNote,
    required this.onVoice,
  });

  final FeedbackParam param;
  final bool locked;
  final bool listening;
  final ValueChanged<double> onScore;
  final ValueChanged<String> onNote;
  final VoidCallback onVoice;

  @override
  State<_ParamCard> createState() => _ParamCardState();
}

class _ParamCardState extends State<_ParamCard> {
  bool _help = false;
  final GlobalKey _noteKey = GlobalKey();
  late final TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController(text: widget.param.note);
  }

  @override
  void didUpdateWidget(covariant _ParamCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.param.name != oldWidget.param.name ||
        widget.param.note != _noteController.text) {
      _noteController.value = TextEditingValue(
        text: widget.param.note,
        selection: TextSelection.collapsed(offset: widget.param.note.length),
      );
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _ensureNoteVisible() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final noteContext = _noteKey.currentContext;
      if (noteContext == null) return;
      Scrollable.ensureVisible(
        noteContext,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        alignment: 0.72,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final color = scoreColor(widget.param.score <= 0 ? 1 : widget.param.score);
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: EdgeInsets.only(bottom: keyboardOpen ? 96 : 0),
      child: PressableCard(
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
              key: _noteKey,
              controller: _noteController,
              enabled: !widget.locked,
              maxLines: 3,
              scrollPadding: const EdgeInsets.only(bottom: 140),
              onTap: _ensureNoteVisible,
              onChanged: widget.onNote,
              decoration: _fieldDecoration(
                'Add a note — type or record by voice…',
                suffix: widget.listening
                    ? Icons.mic_rounded
                    : Icons.mic_none_rounded,
                suffixActive: widget.listening,
                onSuffixTap: widget.locked ? null : widget.onVoice,
              ),
            ),
          ],
        ),
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
  const _SectionTitle({required this.title, this.trailing, this.onTap});

  final String title;
  final String? trailing;
  final VoidCallback? onTap;

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
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  trailing!,
                  style: TextStyle(
                    color: onTap == null ? MColors.inkSoft : MColors.terra,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
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

InputDecoration _fieldDecoration(
  String hint, {
  IconData? suffix,
  VoidCallback? onSuffixTap,
  bool suffixActive = false,
}) {
  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: MColors.inkFaint),
    suffixIcon: suffix == null
        ? null
        : IconButton(
            tooltip: suffixActive ? 'Stop listening' : 'Dictate feedback',
            onPressed: onSuffixTap,
            icon: Icon(
              suffix,
              color: suffixActive ? MColors.live : MColors.terra,
              size: 19,
            ),
          ),
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

String _nameInitials(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.isEmpty || parts.first.isEmpty) return '?';
  final first = parts.first[0];
  final last = parts.length > 1 && parts.last.isNotEmpty ? parts.last[0] : '';
  return '$first$last'.toUpperCase();
}

String _periodLabel(String period) {
  final date = DateTime.tryParse('$period-01');
  return date == null ? period : _monthName(date.month).substring(0, 3);
}

String _periodTitle(String period) {
  final date = DateTime.tryParse('$period-01');
  return date == null ? period : '${_monthName(date.month)} ${date.year}';
}

String daysAgo(DateTime requestedOn) {
  final days = math.max(0, DateTime.now().difference(requestedOn).inDays);
  return days <= 1 ? '$days day' : '$days days';
}

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
    'Personal' => (MColors.plum, MColors.plumTint),
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
