import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/beta_access_service.dart';
import '../../../core/widgets/bouncing_widget.dart';
import '../../../data/repositories/posts_repository.dart';
import '../../../data/repositories/profiles_repository.dart';
import '../../../data/services/haptic_service.dart';
import '../../../data/services/storage_service.dart';
import '../../../data/services/supabase_service.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  bool _isSignUp = false;
  bool _isLoading = false;
  String? _errorMessage;

  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController();
  final TextEditingController _usernameCtrl = TextEditingController();
  final TextEditingController _fullNameCtrl = TextEditingController();
  final TextEditingController _neighborhoodCtrl = TextEditingController(text: 'Mirabad');
  final TextEditingController _betaCodeCtrl = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _usernameCtrl.dispose();
    _fullNameCtrl.dispose();
    _neighborhoodCtrl.dispose();
    _betaCodeCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;

    if (!email.contains('@') || !email.contains('.')) {
      setState(() => _errorMessage = 'Please enter a valid email address.');
      return;
    }
    if (password.length < 8) {
      setState(() => _errorMessage = 'Password must be at least 8 characters.');
      return;
    }

    if (_isSignUp) {
      final username = _usernameCtrl.text.trim();
      final fullName = _fullNameCtrl.text.trim();
      if (username.length < 2 || !RegExp(r'^[a-zA-Z0-9_.-]+$').hasMatch(username)) {
        setState(() => _errorMessage = 'Username must be 2–32 characters (letters, numbers, _ . -).');
        return;
      }
      if (fullName.isEmpty) {
        setState(() => _errorMessage = 'Please enter your full name.');
        return;
      }
      if (!BetaAccessService.hasAccess()) {
        final code = _betaCodeCtrl.text.trim();
        final betaResult = await BetaAccessService.activateWithCode(code);
        if (!betaResult.isValid) {
          setState(() => _errorMessage = betaResult.error ?? 'Invalid beta invite code.');
          return;
        }
      }
    }

    if (!SupabaseService.isInitialized) {
      setState(() => _errorMessage = 'Backend connection is offline. Please rebuild the app with valid Supabase configuration.');
      return;
    }

    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    try {
      if (_isSignUp) {
        final authRes = await SupabaseService.signUpWithEmail(
          email: email,
          password: password,
          username: _usernameCtrl.text.trim(),
          fullName: _fullNameCtrl.text.trim(),
          neighborhood: _neighborhoodCtrl.text.trim(),
        );

        if (authRes == null || authRes.user == null) {
          throw 'Failed to create user account. Please check your credentials.';
        }

        if (authRes.session == null) {
          await SupabaseService.signInWithEmail(email, password);
        }
      } else {
        final authRes = await SupabaseService.signInWithEmail(email, password);
        if (authRes == null || authRes.user == null) {
          throw 'Invalid email or password. Please verify your credentials.';
        }
      }

      await StorageService.setAuthUserEmail(email);
      await StorageService.setGuestMode(false);

      await ref.read(currentProfileProvider.notifier).syncRemoteProfile();
      await ref.read(postsRepositoryProvider.notifier).syncRemoteFeed();

      HapticService.heavy();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isSignUp ? 'Welcome to Around, $email' : 'Signed in as $email'),
            backgroundColor: AppColors.ink,
          ),
        );
        context.go('/feed');
      }
    } catch (e) {
      String readableError = e.toString().replaceFirst('Exception: ', '');
      if (readableError.contains('Invalid login credentials')) {
        readableError = 'Invalid email or password. Please try again.';
      } else if (readableError.contains('User already registered')) {
        readableError = 'An account with this email already exists. Please Sign In.';
      } else if (readableError.toLowerCase().contains('email not confirmed')) {
        readableError = 'Please verify your email address before signing in. Check your inbox for the confirmation link.';
      }
      setState(() => _errorMessage = readableError);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _continueAsGuest() async {
    HapticService.light();
    await StorageService.setGuestMode(true);
    if (mounted) {
      context.go('/feed');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back',
          constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/onboarding');
            }
          },
        ),
        title: Text(
          _isSignUp ? 'Create Account' : 'Sign In',
          style: GoogleFonts.bricolageGrotesque(fontWeight: FontWeight.w800, fontSize: 18),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.cardSurface,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.borderSubtle, width: 1),
              boxShadow: const [AppColors.shadowCard],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AROUND · TASHKENT',
                  style: GoogleFonts.spaceMono(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1, color: AppColors.orange),
                ),
                const SizedBox(height: 6),
                Text(
                  _isSignUp ? 'Join your trusted circle.' : 'Welcome back.',
                  style: GoogleFonts.bricolageGrotesque(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.ink),
                ),
                const SizedBox(height: 18),
                if (_errorMessage != null)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.blush,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.danger.withValues(alpha: 0.4), width: 1),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_outline, color: AppColors.danger, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: AppColors.danger, fontSize: 12, fontWeight: FontWeight.w600, height: 1.3),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (_isSignUp) ...[
                  if (BetaAccessService.hasAccess())
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: AppColors.orangeSubtle,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.orange.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.verified, size: 16, color: AppColors.orange),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'VIP Cohort: ${BetaAccessService.getActiveCohort() ?? 'Founding Member'}',
                              style: GoogleFonts.instrumentSans(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.ink),
                            ),
                          ),
                        ],
                      ),
                    )
                  else ...[
                    TextField(
                      controller: _betaCodeCtrl,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(
                        labelText: 'Beta Invite Code (e.g. TASH50) *',
                        hintText: '6-character VIP code or friend link',
                        prefixIcon: Icon(Icons.vpn_key_outlined, size: 18),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  TextField(
                    controller: _fullNameCtrl,
                    decoration: const InputDecoration(labelText: 'Full Name *', hintText: 'e.g. Kamila Rahimova'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _usernameCtrl,
                    decoration: const InputDecoration(labelText: 'Username (@handle) *', hintText: 'e.g. kamilar'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _neighborhoodCtrl,
                    decoration: const InputDecoration(labelText: 'Tashkent District', hintText: 'e.g. Mirabad, Yakkasaray'),
                  ),
                  const SizedBox(height: 12),
                ],
                TextField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email Address *', hintText: 'you@example.com'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _passwordCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Password (min 8 chars) *'),
                ),
                const SizedBox(height: 22),
                BouncingWidget(
                  onTap: _isLoading ? null : _submit,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.orange,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: const [AppColors.shadowTactile],
                    ),
                    alignment: Alignment.center,
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Text(
                            _isSignUp ? 'Create Account' : 'Sign In',
                            style: GoogleFonts.instrumentSans(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: BouncingWidget(
                    onTap: () => setState(() {
                      _isSignUp = !_isSignUp;
                      _errorMessage = null;
                    }),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                      child: Text(
                        _isSignUp ? 'Already have an account? Sign In' : 'Need an account? Create one',
                        style: GoogleFonts.instrumentSans(
                          color: AppColors.ink,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Divider(height: 1, color: AppColors.borderHairline),
                ),
                Center(
                  child: BouncingWidget(
                    onTap: _continueAsGuest,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.paper2,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.borderSubtle, width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.explore_outlined, size: 16, color: AppColors.ink2),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'Continue as Guest (Read-Only)',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.instrumentSans(
                                color: AppColors.ink,
                                fontWeight: FontWeight.w600,
                                fontSize: 12.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
