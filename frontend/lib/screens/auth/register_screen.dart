import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/auth_provider.dart';
import '../home/home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _specCtrl = TextEditingController();
  final _licCtrl = TextEditingController();
  bool _obscure = true;
  String _role = 'patient';

  @override
  void dispose() {
    _nameCtrl.dispose(); _emailCtrl.dispose();
    _passCtrl.dispose(); _specCtrl.dispose(); _licCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    context.read<AuthProvider>().clearError();
    final ok = await context.read<AuthProvider>().register(
      name: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      password: _passCtrl.text,
      role: _role,
      specialization: _role == 'doctor' ? _specCtrl.text.trim() : null,
      licenseNumber: _role == 'doctor' ? _licCtrl.text.trim() : null,
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
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(width: 42, height: 42,
                  decoration: BoxDecoration(color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.divider)),
                  child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppTheme.textDark),
                ),
              ),
              const SizedBox(height: 28),
              const Text('Create\nAccount ✨', style: TextStyle(
                fontSize: 34, fontWeight: FontWeight.w800,
                color: AppTheme.textDark, height: 1.15, letterSpacing: -1,
              )),
              const SizedBox(height: 10),
              const Text('Join Medimitra to manage your health effortlessly',
                style: TextStyle(fontSize: 15, color: AppTheme.textMid, height: 1.4)),
              const SizedBox(height: 36),

              // Error
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
                    Expanded(child: Text(auth.error!, style: const TextStyle(color: AppTheme.error, fontSize: 13))),
                  ]),
                );
              }),

              // Role selector
              Row(children: ['patient', 'doctor'].map((role) {
                final sel = _role == role;
                return Expanded(child: GestureDetector(
                  onTap: () => setState(() => _role = role),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    margin: EdgeInsets.only(right: role == 'patient' ? 8 : 0, left: role == 'doctor' ? 8 : 0),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: sel ? AppTheme.primary : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: sel ? AppTheme.primary : AppTheme.divider, width: 1.5),
                    ),
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(role == 'patient' ? Icons.person_outline_rounded : Icons.medical_information_outlined,
                        size: 20, color: sel ? Colors.white : AppTheme.textMid),
                      const SizedBox(width: 6),
                      Text(role == 'patient' ? 'Patient' : 'Doctor',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15,
                          color: sel ? Colors.white : AppTheme.textMid)),
                    ]),
                  ),
                ));
              }).toList()),
              const SizedBox(height: 28),

              _label('Full Name'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(hintText: 'Your full name',
                  prefixIcon: Icon(Icons.person_outline_rounded, color: AppTheme.textLight)),
                validator: (v) => v!.length >= 2 ? null : 'Enter your name',
              ),
              const SizedBox(height: 20),

              _label('Email'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(hintText: 'you@example.com',
                  prefixIcon: Icon(Icons.mail_outline_rounded, color: AppTheme.textLight)),
                validator: (v) => v!.contains('@') ? null : 'Enter a valid email',
              ),
              const SizedBox(height: 20),

              _label('Password'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _passCtrl,
                obscureText: _obscure,
                decoration: InputDecoration(
                  hintText: 'Min. 6 characters',
                  prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppTheme.textLight),
                  suffixIcon: GestureDetector(
                    onTap: () => setState(() => _obscure = !_obscure),
                    child: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: AppTheme.textLight),
                  ),
                ),
                validator: (v) => v!.length >= 6 ? null : 'Min 6 characters',
              ),

              if (_role == 'doctor') ...[
                const SizedBox(height: 20),
                _label('Specialization'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _specCtrl,
                  decoration: const InputDecoration(hintText: 'e.g. Cardiologist',
                    prefixIcon: Icon(Icons.local_hospital_outlined, color: AppTheme.textLight)),
                  validator: (v) => _role == 'doctor' && v!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 20),
                _label('License Number'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _licCtrl,
                  decoration: const InputDecoration(hintText: 'Medical license number',
                    prefixIcon: Icon(Icons.badge_outlined, color: AppTheme.textLight)),
                  validator: (v) => _role == 'doctor' && v!.isEmpty ? 'Required' : null,
                ),
              ],
              const SizedBox(height: 36),

              Consumer<AuthProvider>(builder: (_, auth, __) => SizedBox(
                width: double.infinity, height: 56,
                child: ElevatedButton(
                  onPressed: auth.isLoading ? null : _register,
                  child: auth.isLoading
                    ? const SizedBox(width: 22, height: 22,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                    : const Text('Create Account'),
                ),
              )),
              const SizedBox(height: 28),

              Center(child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: RichText(text: const TextSpan(
                  text: 'Already have an account? ',
                  style: TextStyle(color: AppTheme.textMid, fontSize: 15),
                  children: [TextSpan(text: 'Sign In',
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
