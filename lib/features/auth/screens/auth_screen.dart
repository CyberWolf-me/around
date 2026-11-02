import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
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

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _usernameCtrl.dispose();
    _fullNameCtrl.dispose();
    _neighborhoodCtrl.dispose();
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
    }

    if (!SupabaseService.isInitialized) {
      setState(() => _errorMessage = 'Backend connection is offline. Please rebuild the app with valid Supabase cloud configuration.');
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

        // If session was not automatically established, perform explicit sign in
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

      // Hydrate live profile & feed from Supabase
      await ref.read(currentProfileProvider.notifier).syncRemoteProfile();
      await ref.read(postsRepositoryProvider.notifier).syncRemoteFeed();

      HapticService.heavy();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isSignUp ? 'Account created! Welcome to Around, $email' : 'Signed in as $email'),
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
          padding: const EdgeInsets.all(18),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.paper,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.ink, width: 2),
              boxShadow: const [AppColors.shadow],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Around · Tashkent',
                  style: GoogleFonts.spaceMono(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.orange),
                ),
                const SizedBox(height: 6),
                Text(
                  _isSignUp ? 'Join your trusted circle.' : 'Welcome back.',
                  style: GoogleFonts.bricolageGrotesque(fontSize: 24, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 16),
                if (_errorMessage != null)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.blush,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.danger, width: 1.5),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: AppColors.danger, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                if (_isSignUp) ...[
                  TextField(
                    controller: _fullNameCtrl,
                    decoration: const InputDecoration(labelText: 'Full Name *', hintText: 'e.g. Kamila Rahimova'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _usernameCtrl,
                    decoration: const InputDecoration(labelText: 'Username (@handle) *', hintText: 'e.g. kamilar'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _neighborhoodCtrl,
                    decoration: const InputDecoration(labelText: 'Tashkent District', hintText: 'e.g. Mirabad, Yakkasaray'),
                  ),
                  const SizedBox(height: 10),
                ],
                TextField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email Address *', hintText: 'you@example.com'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _passwordCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Password (min 8 chars) *'),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.orange,
                      foregroundColor: AppColors.ink,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: AppColors.ink, width: 2),
                      ),
                    ),
                    child: Text(
                      _isLoading ? 'Authenticating...' : (_isSignUp ? 'Create Account' : 'Sign In'),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: TextButton(
                    onPressed: () => setState(() {
                      _isSignUp = !_isSignUp;
                      _errorMessage = null;
                    }),
                    child: Text(
                      _isSignUp ? 'Already have an account? Sign In' : 'Need an account? Create one',
                      style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.bold, fontSize: 12.5),
                    ),
                  ),
                ),
                const Divider(height: 28, color: Color(0x3015130F)),
                Center(
                  child: OutlinedButton.icon(
                    onPressed: _continueAsGuest,
                    icon: const Icon(Icons.explore_outlined, size: 16, color: AppColors.ink),
                    label: const Text(
                      'Continue as Guest (Read-Only)',
                      style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.ink, width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
