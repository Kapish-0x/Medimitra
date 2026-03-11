import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/auth_provider.dart';
import '../home/home_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthProvider>().clearError();
    final ok = await context.read<AuthProvider>().login(
      _emailCtrl.text.trim(),
      _passCtrl.text,
    );
    if (ok && mounted) {
      Navigator.pushAndRemoveUntil(context,
        MaterialPageRoute(builder: (_) => const HomeScreen()), (_) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Form(
            key: _formKey,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const SizedBox(height: 40),
              // Logo
              Container(width: 52, height: 52,
                decoration: BoxDecoration(
                  gradient: AppTheme.cardGradient,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.medical_services_rounded, color: Colors.white, size: 28),
              ),
              const SizedBox(height: 28),
              const Text('Welcome\nback 👋', style: TextStyle(
                fontSize: 34, fontWeight: FontWeight.w800,
                color: AppTheme.textDark, height: 1.15, letterSpacing: -1,
              )),
              const SizedBox(height: 10),
              const Text('Sign in to continue managing your health',
                style: TextStyle(fontSize: 15, color: AppTheme.textMid, height: 1.4)),
              const SizedBox(height: 44),

              // Error banner
              Consumer<AuthProvider>(builder: (_, auth, __) {
                if (auth.error == null) return const SizedBox.shrink();
                return Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.error.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.error.withOpacity(0.3)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.error_outline_rounded, color: AppTheme.error, size: 18),
                    const SizedBox(width: 10),
                    Expanded(child: Text(auth.error!,
                      style: const TextStyle(color: AppTheme.error, fontSize: 13))),
                  ]),
                );
              }),

              _label('Email'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  hintText: 'you@example.com',
                  prefixIcon: Icon(Icons.mail_outline_rounded, color: AppTheme.textLight),
                ),
                validator: (v) => v!.contains('@') ? null : 'Enter a valid email',
              ),
              const SizedBox(height: 20),

              _label('Password'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _passCtrl,
                obscureText: _obscure,
                decoration: InputDecoration(
                  hintText: '••••••••',
                  prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppTheme.textLight),
                  suffixIcon: GestureDetector(
                    onTap: () => setState(() => _obscure = !_obscure),
                    child: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: AppTheme.textLight),
                  ),
                ),
                validator: (v) => v!.length >= 6 ? null : 'Min 6 characters',
              ),
              const SizedBox(height: 36),

              // Login Button
              Consumer<AuthProvider>(builder: (_, auth, __) => SizedBox(
                width: double.infinity, height: 56,
                child: ElevatedButton(
                  onPressed: auth.isLoading ? null : _login,
                  child: auth.isLoading
                    ? const SizedBox(width: 22, height: 22,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                    : const Text('Sign In'),
                ),
              )),
              const SizedBox(height: 28),

              Row(children: [
                const Expanded(child: Divider(color: AppTheme.divider)),
                Padding(padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Text('or', style: TextStyle(color: AppTheme.textLight))),
                const Expanded(child: Divider(color: AppTheme.divider)),
              ]),
              const SizedBox(height: 28),

              SizedBox(
                width: double.infinity, height: 56,
                child: OutlinedButton.icon(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppTheme.divider, width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  icon: const Icon(Icons.g_mobiledata_rounded, size: 28, color: AppTheme.textDark),
                  label: const Text('Continue with Google',
                    style: TextStyle(color: AppTheme.textDark, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 36),

              Center(child: GestureDetector(
                onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const RegisterScreen())),
                child: RichText(text: const TextSpan(
                  text: "Don't have an account? ",
                  style: TextStyle(color: AppTheme.textMid, fontSize: 15),
                  children: [TextSpan(text: 'Sign Up',
                    style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w700))],
                )),
              )),
              const SizedBox(height: 32),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _label(String t) => Text(t,
    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textMid));
}
