import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../routes/app_routes.dart';
import '../bloc/auth_bloc.dart';
import '../data/auth_session_store.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  late final AnimationController _floatController;
  late final AnimationController _blinkController;
  late final TextEditingController _emailController;
  late final List<TextEditingController> _otpControllers;
  late final List<FocusNode> _otpFocusNodes;
  late final AuthBloc _bloc;
  bool _didFocusOtp = false;

  @override
  void initState() {
    super.initState();
    _bloc = AuthBloc();
    _emailController = TextEditingController();
    _emailController.addListener(_handleEmailChanged);
    _otpControllers = List.generate(6, (_) => TextEditingController());
    _otpFocusNodes = List.generate(6, (_) => FocusNode());
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3600),
    )..repeat();
    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat();
  }

  @override
  void dispose() {
    _bloc.dispose();
    _floatController.dispose();
    _blinkController.dispose();
    _emailController
      ..removeListener(_handleEmailChanged)
      ..dispose();
    for (final controller in _otpControllers) {
      controller.dispose();
    }
    for (final focusNode in _otpFocusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  void _handleEmailChanged() {
    _bloc.add(AuthEmailChanged(_emailController.text));
  }

  void _handleOtpChanged() {
    _bloc.add(
      AuthOtpChanged(
        _otpControllers.map((controller) => controller.text).join(),
      ),
    );
  }

  void _sendCode() {
    _bloc.add(const RequestAuthOtp());
  }

  void _verifyCode() {
    _bloc.add(const VerifyAuthOtp());
  }

  void _editEmail() {
    _didFocusOtp = false;
    for (final controller in _otpControllers) {
      controller.clear();
    }
    _bloc.add(const EditAuthEmail());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _CxColors.paper,
      body: SafeArea(
        child: StreamBuilder<AuthState>(
          stream: _bloc.stream,
          initialData: _bloc.state,
          builder: (context, snapshot) {
            final state = snapshot.data ?? _bloc.state;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              if (state.error != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.error!),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: _CxColors.ink,
                  ),
                );
                _bloc.add(const ClearAuthError());
              }
              if (state.step == AuthStep.code && !_didFocusOtp) {
                _didFocusOtp = true;
                _otpFocusNodes.first.requestFocus();
              }
            });

            return AnimatedSwitcher(
              duration: const Duration(milliseconds: 420),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) {
                final curved = CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                );
                return FadeTransition(
                  opacity: curved,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.04, 0),
                      end: Offset.zero,
                    ).animate(curved),
                    child: child,
                  ),
                );
              },
              child: switch (state.step) {
                AuthStep.email => _EmailStep(
                  key: const ValueKey('email'),
                  floatController: _floatController,
                  emailController: _emailController,
                  isEmailValid: state.isEmailValid,
                  isLoading: state.isLoading,
                  onSendCode: _sendCode,
                ),
                AuthStep.code => _CodeStep(
                  key: const ValueKey('code'),
                  blinkController: _blinkController,
                  email: state.email,
                  otpControllers: _otpControllers,
                  otpFocusNodes: _otpFocusNodes,
                  isOtpComplete: state.isOtpComplete,
                  isLoading: state.isLoading,
                  onOtpChanged: _handleOtpChanged,
                  onBack: _editEmail,
                  onVerify: _verifyCode,
                ),
                AuthStep.success => _SuccessStep(
                  key: const ValueKey('success'),
                  floatController: _floatController,
                  name: state.session?.user.name ?? 'there',
                  company: state.session?.user.company ?? 'Sowaka',
                  onEnter: () async {
                    final session = state.session;
                    if (session == null) return;
                    await AuthSessionStore().save(session);
                    if (!context.mounted) return;
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      AppRoutes.home,
                      (_) => false,
                      arguments: session,
                    );
                  },
                ),
              },
            );
          },
        ),
      ),
    );
  }
}

class _EmailStep extends StatelessWidget {
  const _EmailStep({
    super.key,
    required this.floatController,
    required this.emailController,
    required this.isEmailValid,
    required this.isLoading,
    required this.onSendCode,
  });

  final AnimationController floatController;
  final TextEditingController emailController;
  final bool isEmailValid;
  final bool isLoading;
  final VoidCallback onSendCode;

  @override
  Widget build(BuildContext context) {
    return _PhoneCanvas(
      horizontalPadding: 26,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _BrandRow(),
          const SizedBox(height: 42),
          _PeopleCluster(controller: floatController),
          const SizedBox(height: 30),
          const Text(
            'Sign in to\nConnect',
            style: TextStyle(
              color: _CxColors.ink,
              fontSize: 31,
              height: 1.08,
              letterSpacing: -0.9,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            "Enter your work email and we'll send a 6-digit code. No passwords - we'll find your company for you.",
            style: TextStyle(
              color: _CxColors.muted,
              fontSize: 14,
              height: 1.55,
              fontWeight: FontWeight.w400,
            ),
          ),
          const Spacer(),
          const Text(
            'WORK EMAIL',
            style: TextStyle(
              color: _CxColors.softText,
              fontSize: 11,
              height: 1,
              letterSpacing: 1.32,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 9),
          _EmailField(controller: emailController, isValid: isEmailValid),
          const SizedBox(height: 14),
          _PrimaryButton(
            label: isLoading ? 'Sending code...' : 'Send me a code',
            isLoading: isLoading,
            onPressed: isEmailValid && !isLoading ? onSendCode : null,
          ),
        ],
      ),
    );
  }
}

class _CodeStep extends StatelessWidget {
  const _CodeStep({
    super.key,
    required this.blinkController,
    required this.email,
    required this.otpControllers,
    required this.otpFocusNodes,
    required this.isOtpComplete,
    required this.isLoading,
    required this.onOtpChanged,
    required this.onBack,
    required this.onVerify,
  });

  final AnimationController blinkController;
  final String email;
  final List<TextEditingController> otpControllers;
  final List<FocusNode> otpFocusNodes;
  final bool isOtpComplete;
  final bool isLoading;
  final VoidCallback onOtpChanged;
  final VoidCallback onBack;
  final VoidCallback onVerify;

  @override
  Widget build(BuildContext context) {
    return _PhoneCanvas(
      horizontalPadding: 26,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _RoundIconButton(
                icon: Icons.chevron_left_rounded,
                onPressed: onBack,
              ),
              const Text(
                'STEP 2 OF 2',
                style: TextStyle(
                  color: _CxColors.softText,
                  fontSize: 11,
                  letterSpacing: 1.32,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 36),
          const Text(
            'Enter your code',
            style: TextStyle(
              color: _CxColors.ink,
              fontSize: 28,
              height: 1.1,
              letterSpacing: -0.84,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 11),
          Wrap(
            spacing: 4,
            runSpacing: 2,
            children: [
              const Text(
                'We sent a 6-digit code to',
                style: TextStyle(
                  color: _CxColors.muted,
                  fontSize: 14,
                  height: 1.6,
                ),
              ),
              Text(
                email.isEmpty ? 'your work email' : email,
                style: const TextStyle(
                  color: _CxColors.ink,
                  fontSize: 14,
                  height: 1.6,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Text(
                '·',
                style: TextStyle(color: _CxColors.muted, fontSize: 14),
              ),
              GestureDetector(
                onTap: onBack,
                child: const Text(
                  'Edit',
                  style: TextStyle(
                    color: _CxColors.rust,
                    fontSize: 14,
                    height: 1.6,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),
          _OtpRow(
            blinkController: blinkController,
            controllers: otpControllers,
            focusNodes: otpFocusNodes,
            onChanged: onOtpChanged,
          ),
          const SizedBox(height: 24),
          const Row(
            children: [
              Icon(Icons.refresh_rounded, size: 15, color: _CxColors.softText),
              SizedBox(width: 7),
              Text(
                'Resend code in ',
                style: TextStyle(color: _CxColors.softText, fontSize: 13),
              ),
              Text(
                '0:24',
                style: TextStyle(
                  color: _CxColors.muted,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const Spacer(),
          _PrimaryButton(
            label: isLoading ? 'Verifying...' : 'Verify & continue',
            isLoading: isLoading,
            onPressed: isOtpComplete && !isLoading ? onVerify : null,
          ),
          const SizedBox(height: 18),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.mark_email_read_outlined,
                size: 14,
                color: _CxColors.softText,
              ),
              SizedBox(width: 7),
              Text(
                "Can't find it? Check your spam folder.",
                style: TextStyle(color: _CxColors.softText, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SuccessStep extends StatelessWidget {
  const _SuccessStep({
    super.key,
    required this.floatController,
    required this.name,
    required this.company,
    required this.onEnter,
  });

  final AnimationController floatController;
  final String name;
  final String company;
  final VoidCallback onEnter;

  @override
  Widget build(BuildContext context) {
    return _PhoneCanvas(
      horizontalPadding: 28,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Spacer(),
          _SuccessMark(controller: floatController),
          const SizedBox(height: 14),
          Text(
            "You're in, ${name.split(' ').first}",
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _CxColors.ink,
              fontSize: 28,
              letterSpacing: -0.84,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          _CompanyPill(company: company),
          const SizedBox(height: 14),
          const SizedBox(
            width: 250,
            child: Text(
              '248 teammates are already moving together. Welcome to the crew.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _CxColors.muted,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 20),
          const _AvatarStack(),
          const Spacer(),
          _PrimaryButton(label: 'Enter Connect', onPressed: onEnter),
        ],
      ),
    );
  }
}

class _PhoneCanvas extends StatelessWidget {
  const _PhoneCanvas({required this.child, required this.horizontalPadding});

  final Widget child;
  final double horizontalPadding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        20,
        horizontalPadding,
        30,
      ),
      child: child,
    );
  }
}

class _BrandRow extends StatelessWidget {
  const _BrandRow();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        _BrandLogo(size: 34, fontSize: 18),
        SizedBox(width: 10),
        Text(
          'Sowaka',
          style: TextStyle(
            color: _CxColors.ink,
            fontSize: 15.5,
            letterSpacing: -0.15,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _BrandLogo extends StatelessWidget {
  const _BrandLogo({required this.size, required this.fontSize});

  final double size;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _CxColors.rust,
        boxShadow: [
          BoxShadow(
            color: _CxColors.rust.withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Text(
          'S',
          style: TextStyle(
            color: Colors.white,
            fontSize: fontSize,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _PeopleCluster extends StatelessWidget {
  const _PeopleCluster({required this.controller});

  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final dy = -6 * (0.5 + 0.5 * math.sin(controller.value * math.pi * 2));
        return Padding(
          padding: const EdgeInsets.only(left: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const _Person(
                color: _CxColors.gold,
                head: 26,
                bodyWidth: 34,
                bodyHeight: 22,
              ),
              const _OverlapPerson(
                color: _CxColors.olive,
                head: 30,
                bodyWidth: 40,
                bodyHeight: 26,
              ),
              Transform.translate(
                offset: Offset(0, dy),
                child: const _OverlapPerson(
                  color: _CxColors.rust,
                  head: 36,
                  bodyWidth: 48,
                  bodyHeight: 31,
                ),
              ),
              const _OverlapPerson(
                color: _CxColors.purple,
                head: 30,
                bodyWidth: 40,
                bodyHeight: 26,
              ),
              const _OverlapPerson(
                color: _CxColors.teal,
                head: 26,
                bodyWidth: 34,
                bodyHeight: 22,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _OverlapPerson extends StatelessWidget {
  const _OverlapPerson({
    required this.color,
    required this.head,
    required this.bodyWidth,
    required this.bodyHeight,
  });

  final Color color;
  final double head;
  final double bodyWidth;
  final double bodyHeight;

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: const Offset(-8, 0),
      child: _Person(
        color: color,
        head: head,
        bodyWidth: bodyWidth,
        bodyHeight: bodyHeight,
      ),
    );
  }
}

class _Person extends StatelessWidget {
  const _Person({
    required this.color,
    required this.head,
    required this.bodyWidth,
    required this.bodyHeight,
  });

  final Color color;
  final double head;
  final double bodyWidth;
  final double bodyHeight;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: head,
          height: head,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF28180C).withValues(alpha: 0.18),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
        ),
        Transform.translate(
          offset: Offset(0, -head * 0.14),
          child: Container(
            width: bodyWidth,
            height: bodyHeight,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(bodyWidth / 2),
                bottom: const Radius.circular(8),
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF28180C).withValues(alpha: 0.14),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _EmailField extends StatelessWidget {
  const _EmailField({required this.controller, required this.isValid});

  final TextEditingController controller;
  final bool isValid;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isValid ? _CxColors.olive : _CxColors.line,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF462D1C).withValues(alpha: 0.04),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 16),
          const Icon(
            Icons.mail_outline_rounded,
            size: 20,
            color: _CxColors.rust,
          ),
          const SizedBox(width: 11),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              autocorrect: false,
              enableSuggestions: false,
              style: const TextStyle(
                color: _CxColors.ink,
                fontSize: 15.5,
                fontWeight: FontWeight.w600,
              ),
              decoration: const InputDecoration(
                hintText: 'name@company.com',
                hintStyle: TextStyle(
                  color: _CxColors.softText,
                  fontSize: 15.5,
                  fontWeight: FontWeight.w600,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          AnimatedOpacity(
            duration: const Duration(milliseconds: 160),
            opacity: isValid ? 1 : 0,
            child: const Icon(
              Icons.check_circle_rounded,
              size: 19,
              color: _CxColors.olive,
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: onPressed == null
              ? _CxColors.rust.withValues(alpha: 0.45)
              : _CxColors.rust,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            if (onPressed != null)
              BoxShadow(
                color: _CxColors.rust.withValues(alpha: 0.34),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLoading) ...[
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 10),
            ],
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (!isLoading) ...[
              const SizedBox(width: 9),
              const Icon(
                Icons.arrow_forward_rounded,
                color: Colors.white,
                size: 19,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: _CxColors.line),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF462D1C).withValues(alpha: 0.05),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Icon(icon, color: _CxColors.ink, size: 20),
      ),
    );
  }
}

class _OtpRow extends StatelessWidget {
  const _OtpRow({
    required this.blinkController,
    required this.controllers,
    required this.focusNodes,
    required this.onChanged,
  });

  final AnimationController blinkController;
  final List<TextEditingController> controllers;
  final List<FocusNode> focusNodes;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(6, (index) {
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(left: index == 0 ? 0 : 9),
            child: _OtpBox(
              controller: controllers[index],
              focusNode: focusNodes[index],
              blinkController: blinkController,
              onChanged: (value) {
                if (value.isNotEmpty && index < focusNodes.length - 1) {
                  focusNodes[index + 1].requestFocus();
                }
                if (value.isEmpty && index > 0) {
                  focusNodes[index - 1].requestFocus();
                }
                onChanged();
              },
            ),
          ),
        );
      }),
    );
  }
}

class _OtpBox extends StatefulWidget {
  const _OtpBox({
    required this.controller,
    required this.focusNode,
    required this.blinkController,
    required this.onChanged,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final AnimationController blinkController;
  final ValueChanged<String> onChanged;

  @override
  State<_OtpBox> createState() => _OtpBoxState();
}

class _OtpBoxState extends State<_OtpBox> {
  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_handleFocusChanged);
    widget.controller.addListener(_handleTextChanged);
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_handleFocusChanged);
    widget.controller.removeListener(_handleTextChanged);
    super.dispose();
  }

  void _handleFocusChanged() {
    setState(() {});
  }

  void _handleTextChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isActive = widget.focusNode.hasFocus;

    return Container(
      height: 62,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isActive ? _CxColors.rust : _CxColors.line,
          width: isActive ? 2 : 1.5,
        ),
        boxShadow: [
          if (isActive)
            BoxShadow(
              color: _CxColors.rust.withValues(alpha: 0.12),
              spreadRadius: 4,
            )
          else
            BoxShadow(
              color: const Color(0xFF462D1C).withValues(alpha: 0.04),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          TextField(
            controller: widget.controller,
            focusNode: widget.focusNode,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.next,
            maxLength: 1,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: const TextStyle(
              color: _CxColors.ink,
              fontSize: 27,
              fontWeight: FontWeight.w700,
            ),
            decoration: const InputDecoration(
              counterText: '',
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
            onChanged: widget.onChanged,
          ),
          if (isActive && widget.controller.text.isEmpty)
            IgnorePointer(
              child: AnimatedBuilder(
                animation: widget.blinkController,
                builder: (context, child) {
                  return Opacity(
                    opacity: widget.blinkController.value < 0.5 ? 1 : 0,
                    child: child,
                  );
                },
                child: Container(
                  width: 2,
                  height: 26,
                  decoration: BoxDecoration(
                    color: _CxColors.rust,
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SuccessMark extends StatelessWidget {
  const _SuccessMark({required this.controller});

  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 170,
      height: 120,
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, child) {
          double float(double phase, double amount) {
            return -amount *
                (0.5 +
                    0.5 * math.sin((controller.value + phase) * math.pi * 2));
          }

          return Stack(
            children: [
              Positioned(
                left: 20,
                top: 10 + float(0, 6),
                child: Transform.rotate(
                  angle: 0.35,
                  child: const _Confetti(
                    color: _CxColors.gold,
                    square: true,
                    size: 11,
                  ),
                ),
              ),
              Positioned(
                right: 24,
                top: 6 + float(0.2, 6),
                child: const _Confetti(color: _CxColors.olive, size: 9),
              ),
              Positioned(
                right: 14,
                bottom: 26 - float(0.45, 6),
                child: Transform.rotate(
                  angle: -0.26,
                  child: const _Confetti(
                    color: _CxColors.purple,
                    square: true,
                    size: 12,
                  ),
                ),
              ),
              Positioned(
                left: 16,
                bottom: 20 - float(0.65, 6),
                child: const _Confetti(color: _CxColors.teal, size: 9),
              ),
              Center(
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _CxColors.rust,
                    boxShadow: [
                      BoxShadow(
                        color: _CxColors.rust.withValues(alpha: 0.42),
                        blurRadius: 36,
                        offset: const Offset(0, 18),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 48,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Confetti extends StatelessWidget {
  const _Confetti({
    required this.color,
    required this.size,
    this.square = false,
  });

  final Color color;
  final double size;
  final bool square;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: square ? BoxShape.rectangle : BoxShape.circle,
        borderRadius: square ? BorderRadius.circular(3) : null,
      ),
    );
  }
}

class _CompanyPill extends StatelessWidget {
  const _CompanyPill({required this.company});

  final String company;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFE9EBE0),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.apartment_rounded,
            size: 15,
            color: Color(0xFF4C5840),
          ),
          const SizedBox(width: 7),
          Text(
            company,
            style: const TextStyle(
              color: Color(0xFF4C5840),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _AvatarStack extends StatelessWidget {
  const _AvatarStack();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      width: 106,
      child: Stack(
        children: const [
          Positioned(
            left: 0,
            child: _Avatar(label: 'R', color: _CxColors.rust),
          ),
          Positioned(
            left: 24,
            child: _Avatar(label: 'M', color: _CxColors.olive),
          ),
          Positioned(
            left: 48,
            child: _Avatar(label: 'K', color: _CxColors.purple),
          ),
          Positioned(
            left: 72,
            child: _Avatar(label: '+245', color: _CxColors.line, dark: true),
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.label, required this.color, this.dark = false});

  final String label;
  final Color color;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        border: Border.all(color: _CxColors.paper, width: 2.5),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: dark ? _CxColors.muted : Colors.white,
          fontSize: dark ? 12 : 14,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _CxColors {
  static const paper = Color(0xFFF6F2EC);
  static const ink = Color(0xFF2A2420);
  static const muted = Color(0xFF6E655C);
  static const softText = Color(0xFFA79D92);
  static const line = Color(0xFFEAE3D9);
  static const rust = Color(0xFFBE5A36);
  static const gold = Color(0xFFC98A2E);
  static const olive = Color(0xFF7E8B6E);
  static const purple = Color(0xFF8A6AA0);
  static const teal = Color(0xFF4F8C89);
}
