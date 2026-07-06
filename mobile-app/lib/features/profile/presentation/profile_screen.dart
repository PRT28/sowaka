import 'package:flutter/material.dart';

import '../../auth/data/auth_models.dart';
import '../../manager/data/manager_models.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({
    super.key,
    required this.session,
    required this.dashboard,
    required this.onBack,
    required this.onLogout,
  });

  final AuthSession session;
  final ManagerDashboard dashboard;
  final VoidCallback onBack;
  final Future<void> Function() onLogout;

  @override
  Widget build(BuildContext context) {
    final user = session.user;
    final role = _titleCase(user.role);
    final designation =
        _nonEmpty(user.designation) ??
        (user.role.toLowerCase() == 'manager'
            ? 'People Manager'
            : 'Team Member');
    final department = _nonEmpty(user.department) ?? dashboard.managerTeam;
    final reportsTo = _nonEmpty(user.managerName) ?? dashboard.approverName;

    return ColoredBox(
      color: _ProfileColors.background,
      child: SingleChildScrollView(
        key: const ValueKey('profile-screen'),
        child: Column(
          children: [
            _ProfileBanner(
              name: user.name,
              designation: designation,
              company: user.company,
              initials: _initials(user.name),
              profilePhotoUrl: user.profilePhotoUrl,
              managerScore: user.role.toLowerCase() == 'manager'
                  ? dashboard.managerScore
                  : null,
              onBack: onBack,
            ),
            Transform.translate(
              offset: const Offset(0, -18),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 22),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 620),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _InfoCard(
                          children: [
                            _ProfileRow(
                              icon: Icons.work_outline_rounded,
                              label: 'Role',
                              value: role,
                            ),
                            _ProfileRow(
                              icon: Icons.badge_outlined,
                              label: 'Designation',
                              value: designation,
                            ),
                            _ProfileRow(
                              icon: Icons.alternate_email_rounded,
                              label: 'Email',
                              value: user.email,
                            ),
                            _ProfileRow(
                              icon: Icons.apartment_rounded,
                              label: 'Company',
                              value: user.company,
                            ),
                            _ProfileRow(
                              icon: Icons.location_on_outlined,
                              label: 'Location',
                              value: user.location ?? '',
                            ),
                            _ProfileRow(
                              icon: Icons.schedule_rounded,
                              label: 'Employment type',
                              value: _titleCase(user.employmentType ?? ''),
                              isLast: true,
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        const _SectionLabel('EMPLOYMENT'),
                        const SizedBox(height: 8),
                        _InfoCard(
                          children: [
                            _ProfileRow(
                              icon: Icons.groups_outlined,
                              label: 'Department / team',
                              value: department,
                            ),
                            _ProfileRow(
                              icon: Icons.account_tree_outlined,
                              label: 'Reports to',
                              value: reportsTo,
                            ),
                            _ProfileRow(
                              icon: Icons.event_available_outlined,
                              label: 'Joined',
                              value: _formatDate(user.joiningDate),
                            ),
                            _ProfileRow(
                              icon: Icons.cake_outlined,
                              label: 'Date of birth',
                              value: _formatDate(user.birthday),
                              isLast: true,
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        const _SectionLabel('TEAM'),
                        const SizedBox(height: 8),
                        _TeamCard(
                          team: department,
                          reportsTo: reportsTo,
                          memberCount: dashboard.team.length,
                          isManager: user.role.toLowerCase() == 'manager',
                          description: user.teamDescription,
                        ),
                        if (user.recognition != null) ...[
                          const SizedBox(height: 18),
                          const _SectionLabel('RECOGNITION'),
                          const SizedBox(height: 8),
                          _RecognitionCard(recognition: user.recognition!),
                        ],
                        const SizedBox(height: 18),
                        _LogoutButton(onPressed: onLogout),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileBanner extends StatelessWidget {
  const _ProfileBanner({
    required this.name,
    required this.designation,
    required this.company,
    required this.initials,
    required this.profilePhotoUrl,
    required this.managerScore,
    required this.onBack,
  });

  final String name;
  final String designation;
  final String company;
  final String initials;
  final String? profilePhotoUrl;
  final double? managerScore;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_ProfileColors.terraTint, _ProfileColors.goldTint],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Positioned(
              left: 18,
              top: 8,
              child: Material(
                color: Colors.white.withValues(alpha: .72),
                shape: const CircleBorder(),
                child: IconButton(
                  key: const ValueKey('profile-back'),
                  tooltip: 'Back',
                  onPressed: onBack,
                  icon: const Icon(Icons.chevron_left_rounded),
                  color: _ProfileColors.inkSoft,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 18, 24, 40),
              child: Center(
                child: Column(
                  children: [
                    Container(
                      width: 92,
                      height: 92,
                      decoration: BoxDecoration(
                        color: _ProfileColors.sage,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x24462D1C),
                            blurRadius: 18,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: _ProfileAvatar(
                        initials: initials,
                        profilePhotoUrl: profilePhotoUrl,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      name,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: _ProfileColors.ink,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -.35,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      designation,
                      style: const TextStyle(
                        color: _ProfileColors.inkSoft,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (managerScore != null) ...[
                      const SizedBox(height: 11),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(99),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x22C98A2E),
                              blurRadius: 12,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              size: 15,
                              color: _ProfileColors.gold,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              'Manager score · ${managerScore!.toStringAsFixed(1)}',
                              style: const TextStyle(
                                color: _ProfileColors.gold,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 11,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: .65),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.apartment_rounded,
                            size: 14,
                            color: _ProfileColors.inkSoft,
                          ),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              company,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: _ProfileColors.inkSoft,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
      decoration: _cardDecoration,
      child: Column(children: children),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.initials, required this.profilePhotoUrl});

  final String initials;
  final String? profilePhotoUrl;

  @override
  Widget build(BuildContext context) {
    final url = _nonEmpty(profilePhotoUrl);
    final fallback = Center(
      child: Text(
        initials,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 31,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
    if (url == null) return fallback;

    return Image.network(
      url,
      width: 92,
      height: 92,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => fallback,
      loadingBuilder: (context, child, progress) =>
          progress == null ? child : fallback,
    );
  }
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({
    required this.icon,
    required this.label,
    required this.value,
    this.isLast = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 12),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(bottom: BorderSide(color: _ProfileColors.line)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: _ProfileColors.terraTint,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: _ProfileColors.terra),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label.toUpperCase(), style: _ProfileText.label),
                const SizedBox(height: 2),
                Text(
                  value.isEmpty ? 'Not available' : value,
                  style: _ProfileText.value,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Text(label, style: _ProfileText.section),
    );
  }
}

class _TeamCard extends StatelessWidget {
  const _TeamCard({
    required this.team,
    required this.reportsTo,
    required this.memberCount,
    required this.isManager,
    required this.description,
  });

  final String team;
  final String reportsTo;
  final int memberCount;
  final bool isManager;
  final String? description;

  @override
  Widget build(BuildContext context) {
    final summary =
        _nonEmpty(description) ??
        (isManager
            ? 'You support $memberCount team ${memberCount == 1 ? 'member' : 'members'} across feedback, leave, recognition and growth.'
            : 'Your team space brings feedback, leave, recognition and growth into one place.');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: _ProfileColors.sageTint,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.groups_rounded,
                  size: 22,
                  color: _ProfileColors.sageDeep,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      team.isEmpty ? 'Your team' : team,
                      style: const TextStyle(
                        color: _ProfileColors.ink,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      reportsTo.isEmpty
                          ? '$memberCount team members'
                          : 'Reports to $reportsTo',
                      style: const TextStyle(
                        color: _ProfileColors.inkSoft,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: _ProfileColors.line),
          const SizedBox(height: 12),
          Text(
            summary,
            style: const TextStyle(
              color: _ProfileColors.inkSoft,
              fontSize: 13,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecognitionCard extends StatelessWidget {
  const _RecognitionCard({required this.recognition});

  final UserRecognition recognition;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _ProfileColors.goldTint,
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.workspace_premium_rounded,
              color: _ProfileColors.gold,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  recognition.label.isEmpty ? 'Recognition' : recognition.label,
                  style: const TextStyle(
                    color: _ProfileColors.ink,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (recognition.period.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    recognition.period,
                    style: const TextStyle(
                      color: _ProfileColors.inkSoft,
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  const _LogoutButton({required this.onPressed});

  final Future<void> Function() onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: _ProfileColors.line, width: 1.5),
      ),
      child: InkWell(
        key: const ValueKey('profile-logout'),
        borderRadius: BorderRadius.circular(14),
        onTap: onPressed,
        child: const Padding(
          padding: EdgeInsets.symmetric(vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.logout_rounded, size: 19, color: _ProfileColors.terra),
              SizedBox(width: 8),
              Text(
                'Log out',
                style: TextStyle(
                  color: _ProfileColors.terra,
                  fontSize: 14.5,
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

String _initials(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty);
  final initials = parts.take(2).map((part) => part[0].toUpperCase()).join();
  return initials.isEmpty ? '?' : initials;
}

String _titleCase(String value) {
  final words = value.trim().split(RegExp(r'[_\s-]+'));
  return words
      .where((word) => word.isNotEmpty)
      .map(
        (word) => '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}',
      )
      .join(' ');
}

String? _nonEmpty(String? value) {
  final normalized = value?.trim();
  return normalized == null || normalized.isEmpty ? null : normalized;
}

String _formatDate(String? value) {
  final parsed = DateTime.tryParse(value ?? '');
  if (parsed == null) return '';
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
  return '${parsed.day.toString().padLeft(2, '0')} ${months[parsed.month - 1]} ${parsed.year}';
}

const _cardDecoration = BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.all(Radius.circular(16)),
  border: Border.fromBorderSide(BorderSide(color: _ProfileColors.line)),
  boxShadow: [
    BoxShadow(color: Color(0x0A462D1C), blurRadius: 22, offset: Offset(0, 10)),
  ],
);

class _ProfileText {
  static const label = TextStyle(
    color: _ProfileColors.inkFaint,
    fontSize: 11,
    fontWeight: FontWeight.w700,
    letterSpacing: .55,
  );

  static const value = TextStyle(
    color: _ProfileColors.ink,
    fontSize: 14.5,
    fontWeight: FontWeight.w700,
  );

  static const section = TextStyle(
    color: _ProfileColors.inkFaint,
    fontSize: 11,
    fontWeight: FontWeight.w800,
    letterSpacing: 1.1,
  );
}

class _ProfileColors {
  static const background = Color(0xFFF4EEE5);
  static const ink = Color(0xFF2A2420);
  static const inkSoft = Color(0xFF6E655C);
  static const inkFaint = Color(0xFFA79D92);
  static const line = Color(0xFFF0E8DD);
  static const terra = Color(0xFFBE5A36);
  static const terraTint = Color(0xFFF6E5DB);
  static const gold = Color(0xFFC98A2E);
  static const goldTint = Color(0xFFF4ECDD);
  static const sage = Color(0xFF7E8B6E);
  static const sageDeep = Color(0xFF4C5840);
  static const sageTint = Color(0xFFDEEBE9);
}
