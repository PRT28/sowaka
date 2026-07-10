part of '../../manager/presentation/manager_screen.dart';

class _ParamCard extends StatefulWidget {
  const _ParamCard({
    super.key,
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
  final FocusNode _noteFocusNode = FocusNode();
  late final TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController(text: widget.param.note);
    _noteFocusNode.addListener(_commitNoteOnBlur);
  }

  @override
  void didUpdateWidget(covariant _ParamCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_noteFocusNode.hasFocus && widget.param.note != _noteController.text) {
      _noteController.value = TextEditingValue(
        text: widget.param.note,
        selection: TextSelection.collapsed(offset: widget.param.note.length),
      );
    }
  }

  @override
  void dispose() {
    _commitNote();
    _noteFocusNode.removeListener(_commitNoteOnBlur);
    _noteFocusNode.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _commitNoteOnBlur() {
    if (!_noteFocusNode.hasFocus) _commitNote();
  }

  void _commitNote() {
    final text = _noteController.text;
    if (text != widget.param.note) widget.onNote(text);
  }

  @override
  Widget build(BuildContext context) {
    final color = scoreColor(widget.param.score <= 0 ? 1 : widget.param.score);
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 16),
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
              controller: _noteController,
              focusNode: _noteFocusNode,
              enabled: !widget.locked,
              maxLines: 3,
              scrollPadding: const EdgeInsets.only(bottom: 24),
              onChanged: (_) {},
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
