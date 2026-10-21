import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../theme/app_theme.dart';
import '../widgets/brand_logo.dart';
import '../widgets/primary_button.dart';
import 'store_shell.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override State<AuthScreen> createState() => _AuthScreenState();
}
class _AuthScreenState extends State<AuthScreen> {
  bool isSignUp = false, obscure = true;
  bool isSubmitting = false;
  final name = TextEditingController(), email = TextEditingController(), password = TextEditingController();
  @override void dispose() { name.dispose(); email.dispose(); password.dispose(); super.dispose(); }
  void enterStore() => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const StoreShell()));

  Future<void> _submit() async {
    if (!SupabaseConfig.isConfigured) {
      enterStore();
      return;
    }
    if (isSignUp && name.text.trim().isEmpty) {
      _message('Enter your full name.');
      return;
    }
    if (email.text.trim().isEmpty || password.text.isEmpty) {
      _message('Enter your email and password.');
      return;
    }

    setState(() => isSubmitting = true);
    try {
      final auth = Supabase.instance.client.auth;
      if (isSignUp) {
        final response = await auth.signUp(
          email: email.text.trim(),
          password: password.text,
          data: {'full_name': name.text.trim()},
        );
        if (response.session == null) {
          _message('Check your email to confirm your account, then log in.');
          return;
        }
      } else {
        await auth.signInWithPassword(
          email: email.text.trim(),
          password: password.text,
        );
      }

      if (mounted) enterStore();
    } on AuthException catch (error) {
      _message(error.message);
    } catch (_) {
      _message('Could not connect to Supabase Auth.');
    } finally {
      if (mounted) setState(() => isSubmitting = false);
    }
  }

  Future<void> _resetPassword() async {
    if (!SupabaseConfig.isConfigured) {
      _message('Supabase Auth is not configured.');
      return;
    }
    if (email.text.trim().isEmpty) {
      _message('Enter your email address first.');
      return;
    }
    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(
        email.text.trim(),
      );
      _message('Password reset instructions sent.');
    } on AuthException catch (error) {
      _message(error.message);
    } catch (_) {
      _message('Could not send password reset instructions.');
    }
  }
  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(child: Center(child: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 22),
      child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 430), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Center(child: BrandLogo(size: 65)),
        const SizedBox(height: 8),
        const Text('Create More With the Right Tools', textAlign: TextAlign.center, style: TextStyle(color: AppColors.muted, fontSize: 13)),
        const SizedBox(height: 32),
        if (isSignUp) ...[TextField(controller: name, textCapitalization: TextCapitalization.words, decoration: const InputDecoration(labelText: 'Full name', prefixIcon: Icon(Icons.person_outline))), const SizedBox(height: 12)],
        TextField(controller: email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email address', prefixIcon: Icon(Icons.email_outlined))),
        const SizedBox(height: 12),
        TextField(controller: password, obscureText: obscure, decoration: InputDecoration(labelText: 'Password', prefixIcon: const Icon(Icons.lock_outline), suffixIcon: IconButton(onPressed: () => setState(() => obscure = !obscure), icon: Icon(obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined)))),
        if (!isSignUp) Align(alignment: Alignment.centerRight, child: TextButton(onPressed: _resetPassword, child: const Text('Forgot password?'))),
        const SizedBox(height: 8),
        PrimaryButton(label: isSubmitting ? 'Please wait...' : isSignUp ? 'Sign Up' : 'Log In', onPressed: isSubmitting ? null : _submit),
        const SizedBox(height: 14),
        const Row(children: [Expanded(child: Divider()), Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Text('or', style: TextStyle(color: AppColors.muted))), Expanded(child: Divider())]),
        const SizedBox(height: 12),
        OutlinedButton.icon(onPressed: enterStore, icon: const Icon(Icons.g_mobiledata, size: 28), label: const Text('Continue with Google'), style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48), foregroundColor: AppColors.ink, side: const BorderSide(color: AppColors.line))),
          OutlinedButton.icon(onPressed: SupabaseConfig.isConfigured ? () => _message('Google sign-in is not configured in Supabase yet.') : enterStore, icon: const Icon(Icons.g_mobiledata, size: 28), label: const Text('Continue with Google'), style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48), foregroundColor: AppColors.ink, side: const BorderSide(color: AppColors.line))),
        const SizedBox(height: 10),
        OutlinedButton.icon(onPressed: enterStore, icon: const Icon(Icons.facebook, color: Color(0xFF1877F2)), label: const Text('Continue with Facebook'), style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48), foregroundColor: AppColors.ink, side: const BorderSide(color: AppColors.line))),
          OutlinedButton.icon(onPressed: SupabaseConfig.isConfigured ? () => _message('Facebook sign-in is not configured in Supabase yet.') : enterStore, icon: const Icon(Icons.facebook, color: Color(0xFF1877F2)), label: const Text('Continue with Facebook'), style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48), foregroundColor: AppColors.ink, side: const BorderSide(color: AppColors.line))),
        const SizedBox(height: 18),
        Center(child: TextButton(onPressed: () => setState(() => isSignUp = !isSignUp), child: Text(isSignUp ? 'Already have an account? Log In' : 'Already have an account? Log In  ·  Sign Up', style: const TextStyle(color: AppColors.ink)))),
        const SizedBox(height: 8),
        const Text('By continuing, you agree to our Terms and Privacy Policy.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.muted, fontSize: 10)),
      ])),
    ))),
  );
  void _message(String message) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
