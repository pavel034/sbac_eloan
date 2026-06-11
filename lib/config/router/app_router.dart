// ignore_for_file: deprecated_member_use
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/loan_models.dart';
import '../../providers/auth_provider.dart';
import '../../providers/loan_provider.dart';
import '../../utils/all.dart';
import '../../widgets/custom_widgets.dart';

// ---------------------------------------------------------------------------
// Route paths
// ---------------------------------------------------------------------------

class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String otpVerification = '/login/otp-verification';
  static const String onboarding = '/onboarding';
  static const String home = '/home';
  static const String myLoans = '/my-loans';
  static const String profile = '/profile';
  static const String ekyc = '/ekyc';
  static const String loanApplication = '/loan-application';
  static const String loanDetails = '/loan-details';
  static const String loanAuthorization = '/loan-authorization';
}

// ---------------------------------------------------------------------------
// Router provider
// ---------------------------------------------------------------------------

final goRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateNotifierProvider);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    redirect: (context, state) {
      final loc = state.matchedLocation;
      final isAuthRoute =
          loc == AppRoutes.login || loc == AppRoutes.otpVerification;

      return authState.maybeWhen(
        data: (user) {
          if (user != null) {
            // Authenticated: leave protected routes alone, redirect away from auth/splash
            if (isAuthRoute || loc == AppRoutes.splash) return AppRoutes.home;
          } else {
            // Unauthenticated: redirect to login from anywhere except auth routes
            if (!isAuthRoute) return AppRoutes.login;
          }
          return null;
        },
        loading: () => loc == AppRoutes.splash ? null : AppRoutes.splash,
        error: (_, __) => AppRoutes.login,
        orElse: () => null,
      );
    },
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Page not found',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => context.go(AppRoutes.home),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    ),
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (_, __) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (_, __) => const LoginScreen(),
        routes: [
          GoRoute(
            path: 'otp-verification',
            builder: (_, state) => OTPVerificationScreen(
              phoneNumber: state.extra as String? ?? '',
            ),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (_, __) => const OnboardingScreen(),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (_, __) => const HomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.myLoans,
        builder: (_, __) => const MyLoansScreen(),
      ),
      GoRoute(
        path: AppRoutes.profile,
        builder: (_, __) => const ProfileScreen(),
      ),
      GoRoute(
        path: AppRoutes.ekyc,
        builder: (_, __) => const EKYCScreen(),
      ),
      GoRoute(
        path: AppRoutes.loanApplication,
        builder: (_, __) => const LoanApplicationScreen(),
      ),
      GoRoute(
        path: '${AppRoutes.loanDetails}/:loanId',
        builder: (_, state) => LoanDetailsScreen(
          loanId: state.pathParameters['loanId']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.loanAuthorization,
        builder: (_, __) => const LoanAuthorizationScreen(),
        routes: [
          GoRoute(
            path: ':loanId',
            builder: (_, state) => LoanAuthorizationDetailScreen(
              loanId: state.pathParameters['loanId']!,
            ),
          ),
        ],
      ),
    ],
  );
});

// ===========================================================================
// SPLASH SCREEN
// ===========================================================================

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E40AF),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(Icons.trending_up,
                  size: 56, color: Colors.white),
            ),
            const SizedBox(height: 24),
            const Text('SBAC E-Loan',
                style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
            const SizedBox(height: 8),
            Text('Digital Micro-Lending',
                style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.8))),
            const SizedBox(height: 48),
            const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(Colors.white)),
          ],
        ),
      ),
    );
  }
}

// ===========================================================================
// LOGIN SCREEN
// ===========================================================================

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  bool _agreeToTerms = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _sendOTP() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_agreeToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please agree to Terms & Conditions')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final phone =
          Formatters.formatPhoneNumber(_phoneController.text.trim());
      await ref.read(authStateNotifierProvider.notifier).sendOTP(phone);
      if (mounted) {
        context.push(AppRoutes.otpVerification, extra: phone);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 32),
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E40AF),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(Icons.trending_up,
                      size: 40, color: Colors.white),
                ),
                const SizedBox(height: 32),
                Text('Welcome Back',
                    style: Theme.of(context).textTheme.displaySmall),
                const SizedBox(height: 8),
                Text('Sign in with your phone number',
                    style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 40),
                CustomTextField(
                  label: 'Phone Number',
                  hint: '+8801712345678',
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  prefixIcon: Icons.phone_outlined,
                  validator: Validators.validatePhoneNumber,
                ),
                const SizedBox(height: 16),
                CheckboxListTile(
                  value: _agreeToTerms,
                  onChanged: (v) =>
                      setState(() => _agreeToTerms = v ?? false),
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: RichText(
                    text: TextSpan(
                      style: Theme.of(context).textTheme.bodySmall,
                      children: const [
                        TextSpan(text: 'I agree to '),
                        TextSpan(
                          text: 'Terms & Conditions',
                          style: TextStyle(
                              color: Color(0xFF1E40AF),
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                CustomButton(
                  label: 'Send OTP',
                  isLoading: _isLoading,
                  onPressed: _sendOTP,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ===========================================================================
// OTP VERIFICATION SCREEN
// ===========================================================================

class OTPVerificationScreen extends ConsumerStatefulWidget {
  final String phoneNumber;

  const OTPVerificationScreen({super.key, required this.phoneNumber});

  @override
  ConsumerState<OTPVerificationScreen> createState() =>
      _OTPVerificationScreenState();
}

class _OTPVerificationScreenState
    extends ConsumerState<OTPVerificationScreen> {
  final _otpController = TextEditingController();
  int _secondsRemaining = 60;
  bool _canResend = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    if (!mounted) return;
    if (_secondsRemaining > 0) {
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          setState(() => _secondsRemaining--);
          _startTimer();
        }
      });
    } else {
      setState(() => _canResend = true);
    }
  }

  Future<void> _verifyOTP() async {
    final otp = _otpController.text.trim();
    if (Validators.validateOTP(otp) != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid 6-digit OTP')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await ref.read(authStateNotifierProvider.notifier).verifyOTP(
            phoneNumber: widget.phoneNumber,
            otp: otp,
          );
      if (mounted) context.go(AppRoutes.home);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Verification failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verify OTP')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              Text('Enter Verification Code',
                  style: Theme.of(context).textTheme.displaySmall),
              const SizedBox(height: 8),
              Text('We sent a 6-digit code to ${widget.phoneNumber}',
                  style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 40),
              TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .displaySmall
                    ?.copyWith(letterSpacing: 8),
                decoration: const InputDecoration(
                  counterText: '',
                  hintText: '------',
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: _canResend
                      ? () {
                          setState(() {
                            _secondsRemaining = 60;
                            _canResend = false;
                          });
                          _startTimer();
                        }
                      : null,
                  child: Text(
                    _canResend
                        ? 'Resend Code'
                        : 'Resend in ${_secondsRemaining}s',
                  ),
                ),
              ),
              const Spacer(),
              CustomButton(
                label: 'Verify',
                isLoading: _isLoading,
                onPressed: _verifyOTP,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

// ===========================================================================
// ONBOARDING SCREEN
// ===========================================================================

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late final PageController _controller;
  int _page = 0;

  final _pages = const [
    _OnboardingData(
        title: 'Fast Loans',
        desc: 'Get instant approval for loans up to BDT 1,00,000',
        icon: Icons.flash_on_rounded),
    _OnboardingData(
        title: 'Digital KYC',
        desc: 'Complete verification in less than 5 minutes',
        icon: Icons.verified_user_rounded),
    _OnboardingData(
        title: 'Flexible Repayment',
        desc: 'Choose 3 to 12 month repayment terms',
        icon: Icons.calendar_month_rounded),
  ];

  @override
  void initState() {
    super.initState();
    _controller = PageController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: () => context.go(AppRoutes.home),
                child: const Text('Skip'),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (_, i) => _OnboardingPage(data: _pages[i]),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pages.length,
                (i) => Container(
                  width: i == _page ? 20 : 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: i == _page
                        ? const Color(0xFF1E40AF)
                        : const Color(0xFFE5E7EB),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  if (_page > 0) ...[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _controller.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        ),
                        child: const Text('Back'),
                      ),
                    ),
                    const SizedBox(width: 16),
                  ],
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        if (_page == _pages.length - 1) {
                          context.go(AppRoutes.home);
                        } else {
                          _controller.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        }
                      },
                      child: Text(
                          _page == _pages.length - 1 ? 'Get Started' : 'Next'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingData {
  final String title;
  final String desc;
  final IconData icon;

  const _OnboardingData(
      {required this.title, required this.desc, required this.icon});
}

class _OnboardingPage extends StatelessWidget {
  final _OnboardingData data;

  const _OnboardingPage({required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: const Color(0xFF1E40AF).withOpacity(0.1),
              borderRadius: BorderRadius.circular(32),
            ),
            child: Icon(data.icon, size: 60, color: const Color(0xFF1E40AF)),
          ),
          const SizedBox(height: 32),
          Text(data.title,
              style: Theme.of(context).textTheme.displaySmall,
              textAlign: TextAlign.center),
          const SizedBox(height: 16),
          Text(data.desc,
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

// ===========================================================================
// HOME SCREEN  (Enhanced Dashboard)
// ===========================================================================

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final summaryAsync = ref.watch(loanSummaryProvider);
    final loansAsync = ref.watch(userLoansProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('SBAC E-Loan'),
        actions: [
          userAsync.when(
            data: (user) => user?.isAdmin == true
                ? IconButton(
                    icon: const Icon(Icons.admin_panel_settings_outlined),
                    tooltip: 'Loan Authorization',
                    onPressed: () =>
                        context.push(AppRoutes.loanAuthorization),
                  )
                : const SizedBox.shrink(),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () => context.push(AppRoutes.profile),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(currentUserProvider);
            ref.invalidate(loanSummaryProvider);
            ref.invalidate(userLoansProvider);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome Banner
                userAsync.when(
                  data: (user) => _WelcomeBanner(user: user),
                  loading: () => const _BannerSkeleton(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
                const SizedBox(height: 16),

                // Loan Stats
                summaryAsync.when(
                  data: (s) =>
                      s != null ? _StatsRow(summary: s) : const SizedBox.shrink(),
                  loading: () => const _StatsSkeleton(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
                const SizedBox(height: 20),

                // Active Loan Card
                loansAsync.when(
                  data: (loans) {
                    final active = loans.where((l) =>
                        l.status == LoanApplicationStatus.repaying ||
                        l.status == LoanApplicationStatus.disbursed).toList();
                    if (active.isEmpty) return const SizedBox.shrink();
                    return Column(children: [
                      _ActiveLoanCard(loan: active.first),
                      const SizedBox(height: 20),
                    ]);
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),

                // Quick Actions
                Text('Quick Actions',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.3,
                  children: [
                    _ActionCard(
                      icon: Icons.add_circle_outline,
                      label: 'Apply for Loan',
                      color: const Color(0xFF1E40AF),
                      onTap: () => context.push(AppRoutes.loanApplication),
                    ),
                    _ActionCard(
                      icon: Icons.list_alt_rounded,
                      label: 'My Loans',
                      color: const Color(0xFF0EA5E9),
                      onTap: () => context.push(AppRoutes.myLoans),
                    ),
                    _ActionCard(
                      icon: Icons.verified_user_outlined,
                      label: 'KYC Verification',
                      color: const Color(0xFF10B981),
                      onTap: () => context.push(AppRoutes.ekyc),
                    ),
                    _ActionCard(
                      icon: Icons.payment_rounded,
                      label: 'Payments',
                      color: const Color(0xFFF59E0B),
                      onTap: () => context.push(AppRoutes.myLoans),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Recent Applications
                loansAsync.when(
                  data: (loans) {
                    if (loans.isEmpty) return const SizedBox.shrink();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Recent Applications',
                                style: Theme.of(context).textTheme.titleLarge),
                            TextButton(
                              onPressed: () => context.push(AppRoutes.myLoans),
                              child: const Text('See All'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ...loans.take(3).map((l) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: _LoanCard(loan: l),
                            )),
                      ],
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WelcomeBanner extends StatelessWidget {
  final AuthUser? user;
  const _WelcomeBanner({this.user});

  @override
  Widget build(BuildContext context) {
    final kycColor = user?.kycStatus == 'verified'
        ? const Color(0xFF10B981)
        : const Color(0xFFF59E0B);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E40AF), Color(0xFF0EA5E9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white.withOpacity(0.2),
            child: Text(
              (user?.fullName?.isNotEmpty == true
                      ? user!.fullName![0]
                      : user?.phone.isNotEmpty == true
                          ? user!.phone[0]
                          : 'U')
                  .toUpperCase(),
              style: const TextStyle(
                  fontSize: 22,
                  color: Colors.white,
                  fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hello, ${user?.fullName?.split(' ').first ?? 'there'}!',
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
                const SizedBox(height: 2),
                Text(
                  user?.phone ?? '',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.8), fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: kycColor.withOpacity(0.25),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: kycColor.withOpacity(0.5)),
            ),
            child: Text(
              'KYC: ${(user?.kycStatus ?? 'Pending').toTitleCase}',
              style: TextStyle(
                  color: kycColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _BannerSkeleton extends StatelessWidget {
  const _BannerSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 88,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final LoanSummary summary;
  const _StatsRow({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatChip(
            label: 'Total',
            value: '${summary.totalApplications}',
            color: const Color(0xFF1E40AF)),
        const SizedBox(width: 10),
        _StatChip(
            label: 'Active',
            value: '${summary.activeLoans}',
            color: const Color(0xFF10B981)),
        const SizedBox(width: 10),
        _StatChip(
            label: 'Pending',
            value: '${summary.pendingApplications}',
            color: const Color(0xFFF59E0B)),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatChip(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          border: Border.all(color: color.withOpacity(0.25)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: color)),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(
                    fontSize: 11,
                    color: color.withOpacity(0.8),
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

class _StatsSkeleton extends StatelessWidget {
  const _StatsSkeleton();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(
          3,
          (i) => Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: i < 2 ? 10 : 0),
                  child: Container(
                    height: 68,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              )),
    );
  }
}

class _ActiveLoanCard extends StatelessWidget {
  final LoanApplication loan;
  const _ActiveLoanCard({required this.loan});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () =>
          context.push('${AppRoutes.loanDetails}/${loan.loanId}'),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0F172A), Color(0xFF1E3A5F)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Active Loan',
                    style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w500)),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: const Color(0xFF10B981).withOpacity(0.4)),
                  ),
                  child: Text(
                    loan.status.displayName,
                    style: const TextStyle(
                        color: Color(0xFF10B981),
                        fontSize: 11,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              (loan.approvedAmount ?? loan.requestedAmount).asCurrency,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.schedule_rounded,
                    color: Colors.white54, size: 14),
                const SizedBox(width: 4),
                Text(
                  '${loan.loanTenureMonths} months  •  ${loan.loanPurpose}',
                  style: const TextStyle(
                      color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          border: Border.all(color: color.withOpacity(0.2)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(label,
                style: TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 13, color: color),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String desc;

  const _InfoCard(
      {required this.icon, required this.title, required this.desc});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF1E40AF).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: const Color(0xFF1E40AF), size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 2),
                  Text(desc,
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ===========================================================================
// MY LOANS SCREEN
// ===========================================================================

class MyLoansScreen extends ConsumerWidget {
  const MyLoansScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loansAsync = ref.watch(userLoansProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My Loans')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.loanApplication),
        icon: const Icon(Icons.add),
        label: const Text('New Loan'),
      ),
      body: loansAsync.when(
        data: (loans) {
          if (loans.isEmpty) {
            return EmptyState(
              icon: Icons.account_balance_wallet_outlined,
              title: 'No Loans Yet',
              subtitle: 'Apply for your first loan today',
              action: FilledButton(
                onPressed: () => context.push(AppRoutes.loanApplication),
                child: const Text('Apply Now'),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () => ref.refresh(userLoansProvider.future),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: loans.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) => _LoanCard(loan: loans[i]),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorState(
          message: 'Failed to load loans: $e',
          onRetry: () => ref.refresh(userLoansProvider.future),
        ),
      ),
    );
  }
}

class _LoanCard extends StatelessWidget {
  final LoanApplication loan;

  const _LoanCard({required this.loan});

  @override
  Widget build(BuildContext context) {
    final statusColor = loan.status.statusColor;
    return Card(
      child: InkWell(
        onTap: () => context.push('${AppRoutes.loanDetails}/${loan.loanId}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    loan.requestedAmount.asCurrency,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      loan.status.displayName,
                      style: TextStyle(
                          color: statusColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${loan.loanTenureMonths} months • ${loan.loanPurpose}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 4),
              Text(
                'Applied: ${loan.createdAt.formattedDate}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ===========================================================================
// PROFILE SCREEN
// ===========================================================================

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: userAsync.when(
        data: (user) {
          if (user == null) {
            return const Center(child: Text('User not found'));
          }
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Avatar
              Center(
                child: CircleAvatar(
                  radius: 48,
                  backgroundColor: const Color(0xFF1E40AF),
                  child: Text(
                    (user.fullName?.isNotEmpty == true
                            ? user.fullName![0]
                            : user.phone.isNotEmpty
                                ? user.phone[0]
                                : 'U')
                        .toUpperCase(),
                    style: const TextStyle(
                        fontSize: 32,
                        color: Colors.white,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  user.fullName ?? 'SBAC User',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              const SizedBox(height: 4),
              Center(
                child: Text(user.phone,
                    style: Theme.of(context).textTheme.bodyMedium),
              ),
              const SizedBox(height: 8),
              Center(
                child: Chip(
                  label: Text(
                    'KYC: ${user.kycStatus.toTitleCase}',
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                  backgroundColor: user.kycStatus == 'verified'
                      ? const Color(0xFF10B981)
                      : const Color(0xFFF59E0B),
                ),
              ),
              const SizedBox(height: 24),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.list_alt_rounded),
                      title: const Text('My Loans'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push(AppRoutes.myLoans),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.verified_user_outlined),
                      title: const Text('KYC Verification'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push(AppRoutes.ekyc),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Logout'),
                      content:
                          const Text('Are you sure you want to logout?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: FilledButton.styleFrom(
                              backgroundColor: Colors.red),
                          child: const Text('Logout'),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true && context.mounted) {
                    await ref
                        .read(authStateNotifierProvider.notifier)
                        .logout();
                  }
                },
                icon: const Icon(Icons.logout, color: Colors.red),
                label: const Text('Logout',
                    style: TextStyle(color: Colors.red)),
                style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red)),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorState(message: 'Error: $e'),
      ),
    );
  }
}

// ===========================================================================
// eKYC SCREEN
// ===========================================================================

class EKYCScreen extends ConsumerStatefulWidget {
  const EKYCScreen({super.key});

  @override
  ConsumerState<EKYCScreen> createState() => _EKYCScreenState();
}

class _EKYCScreenState extends ConsumerState<EKYCScreen> {
  int _step = 0;
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _nidCtrl = TextEditingController();
  final _dobCtrl = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _nidCtrl.dispose();
    _dobCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitKYC() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _step = 3; // success step
    });
    await ref.read(authStateNotifierProvider.notifier).updateProfile(
          fullName: _nameCtrl.text.trim(),
          kycStatus: 'in_progress',
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('KYC Verification')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: _step == 3 ? _buildSuccess() : _buildSteps(),
        ),
      ),
    );
  }

  Widget _buildSuccess() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle_rounded,
                size: 64, color: Color(0xFF10B981)),
          ),
          const SizedBox(height: 24),
          Text('KYC Submitted!',
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(
            'Your documents are under review. We\'ll notify you within 24 hours.',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          FilledButton(
            onPressed: () => context.go(AppRoutes.home),
            child: const Text('Back to Home'),
          ),
        ],
      ),
    );
  }

  Widget _buildSteps() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Step indicator
        Row(
          children: List.generate(3, (i) {
            final done = i < _step;
            final active = i == _step;
            return Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: done || active
                            ? const Color(0xFF1E40AF)
                            : const Color(0xFFE5E7EB),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  if (i < 2) const SizedBox(width: 4),
                ],
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        Text(
          'Step ${_step + 1} of 3',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 24),
        Expanded(
          child: Form(
            key: _formKey,
            child: _step == 0
                ? _buildPersonalInfo()
                : _step == 1
                    ? _buildNIDInfo()
                    : _buildReview(),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            if (_step > 0) ...[
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() => _step--),
                  child: const Text('Back'),
                ),
              ),
              const SizedBox(width: 16),
            ],
            Expanded(
              child: CustomButton(
                label: _step == 2 ? 'Submit KYC' : 'Continue',
                isLoading: _isLoading,
                onPressed: () {
                  if (_step == 2) {
                    _submitKYC();
                  } else if (_formKey.currentState!.validate()) {
                    setState(() => _step++);
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPersonalInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Personal Information',
            style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 6),
        Text('Enter your details as on your NID',
            style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 24),
        CustomTextField(
          label: 'Full Name (as on NID)',
          hint: 'Your full name',
          controller: _nameCtrl,
          prefixIcon: Icons.person_outline,
          validator: Validators.validateName,
        ),
        const SizedBox(height: 16),
        CustomTextField(
          label: 'Date of Birth',
          hint: 'DD/MM/YYYY',
          controller: _dobCtrl,
          prefixIcon: Icons.calendar_today_outlined,
          readOnly: true,
          validator: (v) =>
              v == null || v.isEmpty ? 'Date of birth is required' : null,
          onChanged: (_) {},
        ),
        const SizedBox(height: 4),
        TextButton(
          onPressed: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: DateTime(1990),
              firstDate: DateTime(1940),
              lastDate: DateTime.now().subtract(const Duration(days: 6570)),
            );
            if (picked != null) {
              _dobCtrl.text = Formatters.formatDate(picked);
            }
          },
          child: const Text('Select Date of Birth'),
        ),
      ],
    );
  }

  Widget _buildNIDInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('National ID',
            style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 6),
        Text('Enter your NID number',
            style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 24),
        CustomTextField(
          label: 'NID Number',
          hint: '10, 13, or 17 digit NID number',
          controller: _nidCtrl,
          keyboardType: TextInputType.number,
          prefixIcon: Icons.credit_card_outlined,
          validator: Validators.validateNID,
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1E40AF).withOpacity(0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: const Color(0xFF1E40AF).withOpacity(0.2)),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline,
                  color: Color(0xFF1E40AF), size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Your NID will be verified with Bangladesh Election Commission records.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Review & Submit',
            style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 6),
        Text('Please confirm your information',
            style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 24),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                InfoRow(label: 'Full Name', value: _nameCtrl.text),
                const Divider(),
                InfoRow(
                    label: 'Date of Birth',
                    value: _dobCtrl.text.isEmpty
                        ? 'Not provided'
                        : _dobCtrl.text),
                const Divider(),
                InfoRow(label: 'NID Number', value: _nidCtrl.text),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.amber.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.amber.withOpacity(0.4)),
          ),
          child: Row(
            children: [
              const Icon(Icons.warning_amber_rounded,
                  color: Colors.amber, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'By submitting, you consent to NID verification.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ===========================================================================
// LOAN APPLICATION SCREEN
// ===========================================================================

class LoanApplicationScreen extends ConsumerStatefulWidget {
  const LoanApplicationScreen({super.key});

  @override
  ConsumerState<LoanApplicationScreen> createState() =>
      _LoanApplicationScreenState();
}

class _LoanApplicationScreenState
    extends ConsumerState<LoanApplicationScreen> {
  int _step = 0;
  final _formKey = GlobalKey<FormState>();
  final _incomeCtrl = TextEditingController();
  final _debtsCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  bool _isLoading = false;

  static const _purposes = [
    'Business',
    'Education',
    'Medical',
    'Home Improvement',
    'Emergency',
    'Other',
  ];

  static const _employmentTypes = [
    'Salaried',
    'Self-Employed',
    'Business Owner',
    'Farmer',
    'Other',
  ];

  @override
  void dispose() {
    _incomeCtrl.dispose();
    _debtsCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final user = ref.read(currentUserProvider).value;
    if (user == null) return;

    setState(() => _isLoading = true);
    try {
      final form = ref.read(loanFormProvider);
      await ref.read(loanServiceProvider).submitLoanApplication(
            userId: user.uid,
            productId: 'default',
            requestedAmount: form.amount,
            loanTenureMonths: form.tenureMonths,
            loanPurpose: form.loanPurpose ?? '',
            employmentType: form.employmentType ?? '',
            monthlyIncome: form.monthlyIncome,
            existingDebts: form.existingDebts,
            existingLoans: form.existingLoans,
            documents: form.documents,
            applicantNotes: form.applicantNotes,
            consentGiven: form.consentGiven,
          );
      if (mounted) {
        ref.read(loanFormProvider.notifier).reset();
        setState(() => _step = 3);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Submission failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  double _emi(double amount, int months) {
    const rate = 12.0 / 100 / 12;
    final factor = math.pow(1 + rate, months).toDouble();
    return amount * rate * factor / (factor - 1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Apply for Loan')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: _step == 3 ? _buildSuccess() : _buildForm(),
        ),
      ),
    );
  }

  Widget _buildSuccess() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle_rounded,
                size: 64, color: Color(0xFF10B981)),
          ),
          const SizedBox(height: 24),
          Text('Application Submitted!',
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(
            'Your loan application is under review. You\'ll be notified shortly.',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          FilledButton(
            onPressed: () => context.go(AppRoutes.home),
            child: const Text('Back to Home'),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => context.push(AppRoutes.myLoans),
            child: const Text('View My Loans'),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Progress
        Row(
          children: List.generate(3, (i) {
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: i <= _step
                        ? const Color(0xFF1E40AF)
                        : const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        Text(
          ['Step 1: Loan Details', 'Step 2: Your Info',
              'Step 3: Review'][_step],
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 20),
        Expanded(
          child: Form(
            key: _formKey,
            child: _step == 0
                ? _buildStep1()
                : _step == 1
                    ? _buildStep2()
                    : _buildStep3(),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            if (_step > 0) ...[
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() => _step--),
                  child: const Text('Back'),
                ),
              ),
              const SizedBox(width: 16),
            ],
            Expanded(
              child: CustomButton(
                label: _step == 2 ? 'Submit Application' : 'Continue',
                isLoading: _isLoading,
                onPressed: () {
                  if (_step == 2) {
                    final form = ref.read(loanFormProvider);
                    if (!form.consentGiven) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content:
                                Text('Please agree to the terms')),
                      );
                      return;
                    }
                    _submit();
                  } else if (_formKey.currentState!.validate()) {
                    setState(() => _step++);
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStep1() {
    final form = ref.watch(loanFormProvider);
    final notifier = ref.read(loanFormProvider.notifier);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Loan Amount',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(form.amount.asCurrency,
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium
                  ?.copyWith(color: const Color(0xFF1E40AF))),
          Slider(
            value: form.amount,
            min: 10000,
            max: 100000,
            divisions: 18,
            label: form.amount.asCurrency,
            onChanged: notifier.setAmount,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('BDT 10,000',
                  style: Theme.of(context).textTheme.bodySmall),
              Text('BDT 1,00,000',
                  style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
          const SizedBox(height: 24),
          Text('Loan Tenure',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [3, 6, 9, 12].map((m) {
              final selected = form.tenureMonths == m;
              return ChoiceChip(
                label: Text('$m months'),
                selected: selected,
                onSelected: (_) => notifier.setTenure(m),
                selectedColor:
                    const Color(0xFF1E40AF).withOpacity(0.15),
                labelStyle: TextStyle(
                  color: selected ? const Color(0xFF1E40AF) : null,
                  fontWeight: selected ? FontWeight.w600 : null,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  InfoRow(
                    label: 'Estimated EMI',
                    value: _emi(form.amount, form.tenureMonths).asCurrency,
                    valueColor: const Color(0xFF1E40AF),
                  ),
                  const Divider(),
                  const InfoRow(
                    label: 'Interest Rate',
                    value: '12% per annum',
                  ),
                  const Divider(),
                  InfoRow(
                    label: 'Total Repayment',
                    value: (_emi(form.amount, form.tenureMonths) *
                            form.tenureMonths)
                        .asCurrency,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep2() {
    final form = ref.watch(loanFormProvider);
    final notifier = ref.read(loanFormProvider.notifier);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Loan Purpose',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: form.loanPurpose,
            hint: const Text('Select purpose'),
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.category_outlined),
            ),
            items: _purposes
                .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                .toList(),
            onChanged: (v) => v != null ? notifier.setLoanPurpose(v) : null,
            validator: (v) =>
                v == null ? 'Please select a loan purpose' : null,
          ),
          const SizedBox(height: 16),
          Text('Employment Type',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: form.employmentType,
            hint: const Text('Select employment type'),
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.work_outline),
            ),
            items: _employmentTypes
                .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                .toList(),
            onChanged: (v) =>
                v != null ? notifier.setEmploymentType(v) : null,
            validator: (v) =>
                v == null ? 'Please select employment type' : null,
          ),
          const SizedBox(height: 16),
          CustomTextField(
            label: 'Monthly Income (BDT)',
            hint: 'e.g. 25000',
            controller: _incomeCtrl,
            keyboardType: TextInputType.number,
            prefixIcon: Icons.account_balance_wallet_outlined,
            validator: Validators.validateIncome,
            onChanged: (v) {
              final parsed = double.tryParse(v.replaceAll(',', ''));
              if (parsed != null) notifier.setMonthlyIncome(parsed);
            },
          ),
          const SizedBox(height: 16),
          CustomTextField(
            label: 'Existing Monthly Debts (BDT)',
            hint: 'Enter 0 if none',
            controller: _debtsCtrl,
            keyboardType: TextInputType.number,
            prefixIcon: Icons.money_off_outlined,
            validator: (v) =>
                v == null || v.isEmpty ? 'Please enter 0 if none' : null,
            onChanged: (v) {
              final parsed = double.tryParse(v.replaceAll(',', '')) ?? 0;
              notifier.setExistingDebts(parsed);
            },
          ),
          const SizedBox(height: 16),
          CustomTextField(
            label: 'Additional Notes (optional)',
            hint: 'Any additional information...',
            controller: _notesCtrl,
            maxLines: 3,
            onChanged: notifier.setNotes,
          ),
        ],
      ),
    );
  }

  Widget _buildStep3() {
    final form = ref.watch(loanFormProvider);
    final notifier = ref.read(loanFormProvider.notifier);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Review Application',
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Loan Details',
                      style: Theme.of(context).textTheme.titleMedium),
                  const Divider(),
                  InfoRow(
                      label: 'Amount', value: form.amount.asCurrency),
                  InfoRow(
                      label: 'Tenure',
                      value: '${form.tenureMonths} months'),
                  InfoRow(
                      label: 'Purpose',
                      value: form.loanPurpose ?? '-'),
                  InfoRow(
                      label: 'Employment',
                      value: form.employmentType ?? '-'),
                  InfoRow(
                      label: 'Monthly Income',
                      value: form.monthlyIncome.asCurrency),
                  InfoRow(
                      label: 'Estimated EMI',
                      value: _emi(form.amount, form.tenureMonths)
                          .asCurrency,
                      valueColor: const Color(0xFF1E40AF)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          CheckboxListTile(
            value: form.consentGiven,
            onChanged: (v) => notifier.setConsent(v ?? false),
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            title: RichText(
              text: TextSpan(
                style: Theme.of(context).textTheme.bodySmall,
                children: const [
                  TextSpan(text: 'I confirm all information is accurate and agree to the '),
                  TextSpan(
                    text: 'Terms & Conditions',
                    style: TextStyle(
                        color: Color(0xFF1E40AF),
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// LOAN DETAILS SCREEN
// ===========================================================================

class LoanDetailsScreen extends ConsumerWidget {
  final String loanId;

  const LoanDetailsScreen({super.key, required this.loanId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loanAsync = ref.watch(loanDetailsProvider(loanId));
    final scheduleAsync = ref.watch(repaymentScheduleProvider(loanId));

    return Scaffold(
      appBar: AppBar(title: const Text('Loan Details')),
      body: loanAsync.when(
        data: (loan) {
          if (loan == null) {
            return const Center(child: Text('Loan not found'));
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Status banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      loan.status.statusColor,
                      loan.status.statusColor.withOpacity(0.7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loan.requestedAmount.asCurrency,
                      style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      loan.status.displayName,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Loan details card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Loan Information',
                          style: Theme.of(context).textTheme.titleMedium),
                      const Divider(),
                      InfoRow(
                          label: 'Tenure',
                          value: '${loan.loanTenureMonths} months'),
                      InfoRow(label: 'Purpose', value: loan.loanPurpose),
                      InfoRow(
                          label: 'Employment',
                          value: loan.employmentType),
                      InfoRow(
                          label: 'Monthly Income',
                          value: loan.monthlyIncome.asCurrency),
                      InfoRow(
                          label: 'Applied On',
                          value: loan.createdAt.formattedDate),
                      if (loan.approvedAmount != null)
                        InfoRow(
                          label: 'Approved Amount',
                          value: loan.approvedAmount!.asCurrency,
                          valueColor: const Color(0xFF10B981),
                        ),
                      if (loan.rejectionReason != null)
                        InfoRow(
                          label: 'Rejection Reason',
                          value: loan.rejectionReason!,
                          valueColor: Colors.red,
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Repayment schedule
              scheduleAsync.when(
                data: (schedule) {
                  if (schedule == null) {
                    if (loan.status == LoanApplicationStatus.approved ||
                        loan.status == LoanApplicationStatus.disbursed ||
                        loan.status == LoanApplicationStatus.repaying) {
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              const Icon(Icons.schedule_rounded,
                                  size: 48, color: Colors.grey),
                              const SizedBox(height: 8),
                              Text('Repayment schedule will be available after disbursement.',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium,
                                  textAlign: TextAlign.center),
                            ],
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Repayment Schedule',
                          style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 12),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              InfoRow(
                                label: 'Monthly EMI',
                                value: schedule.emiAmount.asCurrency,
                                valueColor: const Color(0xFF1E40AF),
                              ),
                              const Divider(),
                              InfoRow(
                                  label: 'Total Interest',
                                  value: schedule.totalInterest.asCurrency),
                              InfoRow(
                                  label: 'Total Repayment',
                                  value: schedule.totalRepayment.asCurrency),
                              InfoRow(
                                  label: 'EMIs Paid',
                                  value:
                                      '${schedule.emisPaid} / ${schedule.emiCount}'),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...schedule.emiSchedule.take(6).map(
                            (emi) => _EmiTile(emi: emi),
                          ),
                      if (schedule.emiSchedule.length > 6)
                        Padding(
                          padding:
                              const EdgeInsets.symmetric(vertical: 8),
                          child: Center(
                            child: Text(
                              '+${schedule.emiSchedule.length - 6} more EMIs',
                              style:
                                  Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        ),
                    ],
                  );
                },
                loading: () => const Center(
                    child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(),
                )),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorState(message: 'Error: $e'),
      ),
    );
  }
}

class _EmiTile extends StatelessWidget {
  final EMI emi;

  const _EmiTile({required this.emi});

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    IconData statusIcon;
    switch (emi.status) {
      case 'paid':
        statusColor = const Color(0xFF10B981);
        statusIcon = Icons.check_circle_rounded;
        break;
      case 'overdue':
        statusColor = Colors.red;
        statusIcon = Icons.warning_rounded;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.radio_button_unchecked;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(statusIcon, color: statusColor, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('EMI #${emi.emiNumber}',
                      style: Theme.of(context).textTheme.titleSmall),
                  Text(emi.dueDate.formattedDate,
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            Text(
              emi.totalAmount.asCurrency,
              style: TextStyle(fontWeight: FontWeight.w600, color: statusColor),
            ),
          ],
        ),
      ),
    );
  }
}

// ===========================================================================
// LOAN AUTHORIZATION SCREEN  (Admin)
// ===========================================================================

class LoanAuthorizationScreen extends ConsumerStatefulWidget {
  const LoanAuthorizationScreen({super.key});

  @override
  ConsumerState<LoanAuthorizationScreen> createState() =>
      _LoanAuthorizationScreenState();
}

class _LoanAuthorizationScreenState
    extends ConsumerState<LoanAuthorizationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Loan Authorization'),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'Pending Review'),
            Tab(text: 'All Applications'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _ApplicationList(
            provider: pendingApplicationsProvider,
            emptyTitle: 'No Pending Applications',
            emptySubtitle: 'All applications have been reviewed',
          ),
          _ApplicationList(
            provider: allApplicationsProvider,
            emptyTitle: 'No Applications Yet',
            emptySubtitle: 'Applications will appear here once submitted',
          ),
        ],
      ),
    );
  }
}

class _ApplicationList extends ConsumerWidget {
  final ProviderBase<AsyncValue<List<LoanApplication>>> provider;
  final String emptyTitle;
  final String emptySubtitle;

  const _ApplicationList({
    required this.provider,
    required this.emptyTitle,
    required this.emptySubtitle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(provider);
    return async.when(
      data: (loans) {
        if (loans.isEmpty) {
          return EmptyState(
            icon: Icons.inbox_outlined,
            title: emptyTitle,
            subtitle: emptySubtitle,
          );
        }
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(provider),
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: loans.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (_, i) => _AppCard(loan: loans[i]),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => ErrorState(
        message: 'Failed to load: $e',
        onRetry: () => ref.invalidate(provider),
      ),
    );
  }
}

class _AppCard extends StatelessWidget {
  final LoanApplication loan;
  const _AppCard({required this.loan});

  @override
  Widget build(BuildContext context) {
    final statusColor = loan.status.statusColor;
    return Card(
      child: InkWell(
        onTap: () => context
            .push('${AppRoutes.loanAuthorization}/${loan.loanId}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(loan.requestedAmount.asCurrency,
                      style: Theme.of(context).textTheme.titleLarge),
                  _StatusBadge(status: loan.status),
                ],
              ),
              const SizedBox(height: 8),
              Row(children: [
                const Icon(Icons.work_outline, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text('${loan.employmentType}  •  ${loan.loanPurpose}',
                    style: Theme.of(context).textTheme.bodySmall),
              ]),
              const SizedBox(height: 4),
              Row(children: [
                const Icon(Icons.account_balance_wallet_outlined,
                    size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                    'Income: ${loan.monthlyIncome.asCurrency}  •  ${loan.loanTenureMonths} months',
                    style: Theme.of(context).textTheme.bodySmall),
              ]),
              const SizedBox(height: 4),
              Row(children: [
                const Icon(Icons.calendar_today_outlined,
                    size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text('Applied: ${loan.createdAt.formattedDate}',
                    style: Theme.of(context).textTheme.bodySmall),
              ]),
              if (loan.status == LoanApplicationStatus.submitted ||
                  loan.status == LoanApplicationStatus.underReview) ...[
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 8),
                Text(
                  'Tap to review →',
                  style: TextStyle(
                      fontSize: 12,
                      color: statusColor,
                      fontWeight: FontWeight.w500),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final LoanApplicationStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = status.statusColor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.displayName,
        style: TextStyle(
            color: color, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}

// ===========================================================================
// LOAN AUTHORIZATION DETAIL  (Admin — approve / reject)
// ===========================================================================

class LoanAuthorizationDetailScreen extends ConsumerWidget {
  final String loanId;
  const LoanAuthorizationDetailScreen({super.key, required this.loanId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loanAsync = ref.watch(loanDetailsProvider(loanId));

    return Scaffold(
      appBar: AppBar(title: const Text('Application Review')),
      body: loanAsync.when(
        data: (loan) {
          if (loan == null) {
            return const Center(child: Text('Application not found'));
          }
          final canAct = loan.status == LoanApplicationStatus.submitted ||
              loan.status == LoanApplicationStatus.underReview;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Status banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      loan.status.statusColor,
                      loan.status.statusColor.withOpacity(0.7)
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(loan.requestedAmount.asCurrency,
                        style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                    const SizedBox(height: 4),
                    Text(loan.status.displayName,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 13)),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Applicant details
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Applicant Details',
                          style: Theme.of(context).textTheme.titleMedium),
                      const Divider(),
                      InfoRow(label: 'Loan Purpose', value: loan.loanPurpose),
                      InfoRow(
                          label: 'Employment', value: loan.employmentType),
                      InfoRow(
                          label: 'Monthly Income',
                          value: loan.monthlyIncome.asCurrency),
                      InfoRow(
                          label: 'Existing Debts',
                          value: loan.existingDebts.asCurrency),
                      InfoRow(
                          label: 'Existing Loans',
                          value: '${loan.existingLoans}'),
                      InfoRow(
                          label: 'Tenure Requested',
                          value: '${loan.loanTenureMonths} months'),
                      InfoRow(
                          label: 'Applied On',
                          value: loan.createdAt.formattedDate),
                      if (loan.applicantNotes?.isNotEmpty == true)
                        InfoRow(
                            label: 'Notes',
                            value: loan.applicantNotes!),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              if (loan.status == LoanApplicationStatus.approved ||
                  loan.status == LoanApplicationStatus.rejected) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Decision',
                            style:
                                Theme.of(context).textTheme.titleMedium),
                        const Divider(),
                        if (loan.approvedAmount != null)
                          InfoRow(
                              label: 'Approved Amount',
                              value: loan.approvedAmount!.asCurrency,
                              valueColor: const Color(0xFF10B981)),
                        if (loan.rejectionReason != null)
                          InfoRow(
                              label: 'Rejection Reason',
                              value: loan.rejectionReason!,
                              valueColor: Colors.red),
                        if (loan.decidedAt != null)
                          InfoRow(
                              label: 'Decided On',
                              value: loan.decidedAt!.formattedDate),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Action buttons
              if (canAct) ...[
                Row(children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          padding:
                              const EdgeInsets.symmetric(vertical: 14)),
                      onPressed: () =>
                          _showRejectDialog(context, ref, loan),
                      icon: const Icon(Icons.cancel_outlined),
                      label: const Text('Reject'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          padding:
                              const EdgeInsets.symmetric(vertical: 14)),
                      onPressed: () =>
                          _showApproveDialog(context, ref, loan),
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('Approve'),
                    ),
                  ),
                ]),
                const SizedBox(height: 8),
                if (loan.status == LoanApplicationStatus.submitted)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await ref
                            .read(loanServiceProvider)
                            .markUnderReview(loanId);
                        ref.invalidate(loanDetailsProvider(loanId));
                        ref.invalidate(pendingApplicationsProvider);
                      },
                      icon: const Icon(Icons.visibility_outlined),
                      label: const Text('Mark as Under Review'),
                    ),
                  ),
              ],
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorState(message: 'Error: $e'),
      ),
    );
  }

  Future<void> _showApproveDialog(
    BuildContext context,
    WidgetRef ref,
    LoanApplication loan,
  ) async {
    final amountCtrl = TextEditingController(
        text: loan.requestedAmount.toStringAsFixed(0));
    final notesCtrl = TextEditingController();
    int tenure = loan.loanTenureMonths;
    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Approve Application'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: amountCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Approved Amount (BDT)',
                    prefixIcon: Icon(Icons.attach_money),
                  ),
                  validator: (v) {
                    final n = double.tryParse(v ?? '');
                    if (n == null || n <= 0) return 'Enter valid amount';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  value: tenure,
                  decoration: const InputDecoration(
                      labelText: 'Approved Tenure'),
                  items: [3, 6, 9, 12]
                      .map((m) => DropdownMenuItem(
                          value: m, child: Text('$m months')))
                      .toList(),
                  onChanged: (v) => setState(() => tenure = v ?? tenure),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: notesCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Internal Notes (optional)',
                    prefixIcon: Icon(Icons.note_outlined),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981)),
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(ctx, true);
                }
              },
              child: const Text('Approve'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await ref.read(loanServiceProvider).approveLoan(
              loan.loanId,
              approvedAmount:
                  double.parse(amountCtrl.text.replaceAll(',', '')),
              approvedTenureMonths: tenure,
              internalNotes: notesCtrl.text,
            );
        ref.invalidate(loanDetailsProvider(loan.loanId));
        ref.invalidate(pendingApplicationsProvider);
        ref.invalidate(allApplicationsProvider);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Application approved successfully')),
          );
          context.pop();
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }

  Future<void> _showRejectDialog(
    BuildContext context,
    WidgetRef ref,
    LoanApplication loan,
  ) async {
    final reasonCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject Application'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: reasonCtrl,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Rejection Reason',
              hintText: 'Explain why this application is being rejected...',
            ),
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'Reason is required' : null,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style:
                FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(ctx, true);
              }
            },
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await ref.read(loanServiceProvider).rejectLoan(
              loan.loanId,
              rejectionReason: reasonCtrl.text.trim(),
            );
        ref.invalidate(loanDetailsProvider(loan.loanId));
        ref.invalidate(pendingApplicationsProvider);
        ref.invalidate(allApplicationsProvider);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Application rejected')),
          );
          context.pop();
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }
}
