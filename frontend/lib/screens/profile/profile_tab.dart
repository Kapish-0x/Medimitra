import '../../../core/network/api_client.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/auth_provider.dart';
import '../auth/login_screen.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final hp = user?.healthProfile;

    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: SingleChildScrollView(child: Column(children: [
        // Header gradient
        Container(width: double.infinity,
          decoration: const BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.only(bottomLeft: Radius.circular(28), bottomRight: Radius.circular(28))),
          child: SafeArea(bottom: false, child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
            child: Column(children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('Profile', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
                GestureDetector(
                  onTap: () => _showEditSheet(context, user),
                  child: Container(padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.edit_outlined, color: Colors.white, size: 20))),
              ]),
              const SizedBox(height: 24),
              Container(width: 80, height: 80,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25), shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withOpacity(0.5), width: 2)),
                child: Center(child: Text(user?.initials ?? 'U',
                  style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w800)))),
              const SizedBox(height: 14),
              Text(user?.name ?? '', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(user?.email ?? '', style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 14)),
              const SizedBox(height: 16),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                _Tag(text: user?.role == 'doctor' ? 'Doctor' : 'Patient'),
                const SizedBox(width: 8),
                if (hp?['bloodGroup'] != null && (hp!['bloodGroup'] as String).isNotEmpty)
                  _Tag(text: 'Blood: ${hp['bloodGroup']}'),
                if (user?.isDoctor == true && user?.specialization != null) ...[
                  const SizedBox(width: 8),
                  _Tag(text: user!.specialization!),
                ],
              ]),
            ]),
          )),
        ),
        const SizedBox(height: 24),

        // Health info cards (patients)
        if (user?.isPatient == true) Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Row(children: [
          _InfoCard(icon: Icons.height_rounded, label: 'Height', value: hp?['height'] != null ? '${hp!['height']} cm' : '--', color: const Color(0xFF6C5CE7)),
          const SizedBox(width: 12),
          _InfoCard(icon: Icons.monitor_weight_rounded, label: 'Weight', value: hp?['weight'] != null ? '${hp!['weight']} kg' : '--', color: const Color(0xFF0A6E6E)),
          const SizedBox(width: 12),
          _InfoCard(icon: Icons.water_drop_rounded, label: 'Blood', value: hp?['bloodGroup'] ?? '--', color: const Color(0xFFE05C5C)),
        ])),
        const SizedBox(height: 24),

        // Doctor verified badge
        if (user?.isDoctor == true) Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: user?.isVerifiedDoctor == true ? AppTheme.accentSoft : const Color(0xFFFFF6E8),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: user?.isVerifiedDoctor == true ? AppTheme.primary : AppTheme.warning)),
          child: Row(children: [
            Icon(user?.isVerifiedDoctor == true ? Icons.verified_rounded : Icons.pending_rounded,
              color: user?.isVerifiedDoctor == true ? AppTheme.primary : AppTheme.warning, size: 24),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(user?.isVerifiedDoctor == true ? 'Verified Doctor' : 'Verification Pending',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: user?.isVerifiedDoctor == true ? AppTheme.primary : AppTheme.warning)),
              Text(user?.isVerifiedDoctor == true ? 'Your license has been verified' : 'Admin will verify your license soon',
                style: const TextStyle(fontSize: 12, color: AppTheme.textMid)),
            ])),
          ]),
        )),
        if (user?.isDoctor == true) const SizedBox(height: 16),

        // Menu
        Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _SectionLabel('My Health'),
          const SizedBox(height: 10),
          _MenuGroup(items: [
            (Icons.favorite_rounded, 'Health Profile', const Color(0xFFE05C5C)),
            (Icons.medical_information_rounded, 'Medical History', const Color(0xFF6C5CE7)),
            (Icons.vaccines_rounded, 'Vaccinations', const Color(0xFF13A89E)),
            (Icons.emergency_rounded, 'Emergency Contacts', const Color(0xFFFFA743)),
          ]),
          const SizedBox(height: 20),
          _SectionLabel('Orders & Reports'),
          const SizedBox(height: 10),
          _MenuGroup(items: [
            (Icons.shopping_bag_rounded, 'My Orders', const Color(0xFF0A6E6E)),
            (Icons.folder_copy_rounded, 'My Reports', const Color(0xFF6C5CE7)),
          ]),
          const SizedBox(height: 20),
          _SectionLabel('Account'),
          const SizedBox(height: 10),
          _MenuGroup(items: [
            (Icons.notifications_rounded, 'Notifications', const Color(0xFF0A6E6E)),
            (Icons.lock_rounded, 'Change Password', const Color(0xFF6C5CE7)),
            (Icons.help_rounded, 'Help & Support', const Color(0xFFFFA743)),
          ]),
          const SizedBox(height: 20),

          // Logout
          GestureDetector(
            onTap: () async {
              await context.read<AuthProvider>().logout();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
              }
            },
            child: Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(color: const Color(0xFFFFEEEE), borderRadius: BorderRadius.circular(16)),
              child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.logout_rounded, color: AppTheme.error, size: 20),
                SizedBox(width: 10),
                Text('Log Out', style: TextStyle(color: AppTheme.error, fontWeight: FontWeight.w700, fontSize: 15)),
              ])),
          ),
          const SizedBox(height: 32),
        ])),
      ])),
    );
  }

  void _showEditSheet(BuildContext context, dynamic user) {
    showModalBottomSheet(context: context, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _EditSheet(user: user));
  }
}

class _Tag extends StatelessWidget {
  final String text;
  const _Tag({required this.text});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
    decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
    child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)));
}

class _InfoCard extends StatelessWidget {
  final IconData icon; final String label, value; final Color color;
  const _InfoCard({required this.icon, required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) => Expanded(child: Container(
    padding: const EdgeInsets.symmetric(vertical: 16),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppTheme.divider)),
    child: Column(children: [
      Container(width: 38, height: 38, decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: color, size: 20)),
      const SizedBox(height: 8),
      Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppTheme.textDark)),
      Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textLight)),
    ]),
  ));
}

class _SectionLabel extends StatelessWidget {
  final String t;
  const _SectionLabel(this.t);
  @override
  Widget build(BuildContext context) => Text(t, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textMid, letterSpacing: 0.3));
}

class _MenuGroup extends StatelessWidget {
  final List<(IconData, String, Color)> items;
  const _MenuGroup({required this.items});
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.divider)),
    child: Column(children: items.asMap().entries.map((e) => Column(children: [
      GestureDetector(onTap: () {}, child: Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14), child: Row(children: [
        Container(width: 36, height: 36, decoration: BoxDecoration(color: e.value.$3.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(e.value.$1, color: e.value.$3, size: 18)),
        const SizedBox(width: 14),
        Expanded(child: Text(e.value.$2, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15, color: AppTheme.textDark))),
        const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppTheme.textLight),
      ]))),
      if (e.key < items.length - 1) const Divider(height: 1, color: AppTheme.divider, indent: 66),
    ])).toList()),
  );
}

class _EditSheet extends StatefulWidget {
  final dynamic user;
  const _EditSheet({this.user});
  @override
  State<_EditSheet> createState() => _EditSheetState();
}

class _EditSheetState extends State<_EditSheet> {
  late TextEditingController _nameCtrl;
  late TextEditingController _phoneCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.user?.name ?? '');
    _phoneCtrl = TextEditingController(text: widget.user?.phone ?? '');
  }

  @override
  void dispose() { _nameCtrl.dispose(); _phoneCtrl.dispose(); super.dispose(); }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {

      await ApiClient.instance.dio.put('/users/profile', data: {
        'name': _nameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
      });
      if (mounted) { Navigator.pop(context); }
    } catch (_) {} finally { if (mounted) setState(() => _saving = false); }
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
    child: Container(decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      padding: const EdgeInsets.all(24),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppTheme.divider, borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: 20),
        const Text('Edit Profile', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.textDark)),
        const SizedBox(height: 20),
        TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.person_outline_rounded, color: AppTheme.textLight))),
        const SizedBox(height: 16),
        TextField(controller: _phoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Phone', prefixIcon: Icon(Icons.phone_outlined, color: AppTheme.textLight))),
        const SizedBox(height: 24),
        SizedBox(width: double.infinity, height: 52, child: ElevatedButton(
          onPressed: _saving ? null : _save,
          child: _saving ? const CircularProgressIndicator(color: Colors.white) : const Text('Save Changes'),
        )),
        const SizedBox(height: 8),
      ])),
  );
}
