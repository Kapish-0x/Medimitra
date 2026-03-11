import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/network/api_client.dart';
import '../../../core/config/app_config.dart';

class DashboardTab extends StatefulWidget {
  const DashboardTab({super.key});
  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  List _appointments = [];
  List _reports = [];
  bool _loadingAppts = true;
  bool _loadingReports = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final api = ApiClient.instance.dio;
    try {
      final res = await api.get('${AppConfig.baseUrl}/appointments',
        queryParameters: {'upcoming': 'true'});
      if (mounted) setState(() { _appointments = res.data['appointments'] ?? []; _loadingAppts = false; });
    } catch (_) { if (mounted) setState(() => _loadingAppts = false); }

    try {
      final res = await api.get('${AppConfig.baseUrl}/reports');
      if (mounted) setState(() { _reports = res.data['reports'] ?? []; _loadingReports = false; });
    } catch (_) { if (mounted) setState(() => _loadingReports = false); }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: RefreshIndicator(
        color: AppTheme.primary,
        onRefresh: _loadData,
        child: CustomScrollView(slivers: [
          SliverToBoxAdapter(child: _Header(user: user)),
          SliverToBoxAdapter(child: const _HealthCard()),
          SliverToBoxAdapter(child: const _QuickActions()),
          SliverToBoxAdapter(child: _UpcomingSection(loading: _loadingAppts, appointments: _appointments)),
          SliverToBoxAdapter(child: _ReportsSection(loading: _loadingReports, reports: _reports)),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ]),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final dynamic user;
  const _Header({this.user});

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning,';
    if (h < 17) return 'Good afternoon,';
    return 'Good evening,';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28), bottomRight: Radius.circular(28)),
      ),
      child: SafeArea(bottom: false, child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_greeting(), style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 15)),
              const SizedBox(height: 2),
              Text('${user?.name ?? 'User'} 👋', style: const TextStyle(
                color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
            ])),
            // Notification
            Container(width: 44, height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Stack(children: [
                const Center(child: Icon(Icons.notifications_outlined, color: Colors.white, size: 24)),
                Positioned(right: 10, top: 10, child: Container(
                  width: 8, height: 8,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6B6B), shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.primary, width: 1.5)),
                )),
              ]),
            ),
            const SizedBox(width: 10),
            Container(width: 44, height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
              child: Center(child: Text(
                user?.initials ?? 'U',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18),
              )),
            ),
          ]),
          const SizedBox(height: 18),
          Container(height: 46,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
            child: Row(children: [
              const SizedBox(width: 14),
              Icon(Icons.search_rounded, color: Colors.white.withOpacity(0.7), size: 20),
              const SizedBox(width: 10),
              Text('Search doctors, medicines...', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14)),
            ]),
          ),
        ]),
      )),
    );
  }
}

class _HealthCard extends StatelessWidget {
  const _HealthCard();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: AppTheme.primary.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 6))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Text('Health Overview', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppTheme.textDark)),
            const Spacer(),
            Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: AppTheme.accentSoft, borderRadius: BorderRadius.circular(20)),
              child: const Text('Good', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w600, fontSize: 12))),
          ]),
          const SizedBox(height: 18),
          Row(children: const [
            _HStat(icon: Icons.favorite_rounded, label: 'Heart Rate', value: '72', unit: 'bpm', color: Color(0xFFE05C5C)),
            _VDivider(),
            _HStat(icon: Icons.water_drop_rounded, label: 'Blood P.', value: '118/76', unit: 'mmHg', color: Color(0xFF6C5CE7)),
            _VDivider(),
            _HStat(icon: Icons.thermostat_rounded, label: 'Temp', value: '98.4', unit: '°F', color: Color(0xFFFFA743)),
          ]),
        ]),
      ),
    );
  }
}

class _HStat extends StatelessWidget {
  final IconData icon; final String label, value, unit; final Color color;
  const _HStat({required this.icon, required this.label, required this.value, required this.unit, required this.color});
  @override
  Widget build(BuildContext context) => Expanded(child: Column(children: [
    Container(width: 36, height: 36, decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
      child: Icon(icon, color: color, size: 18)),
    const SizedBox(height: 8),
    Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppTheme.textDark, letterSpacing: -0.5)),
    Text(unit, style: const TextStyle(fontSize: 10, color: AppTheme.textLight)),
    const SizedBox(height: 2),
    Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, color: AppTheme.textMid)),
  ]));
}

class _VDivider extends StatelessWidget {
  const _VDivider();
  @override
  Widget build(BuildContext context) => Container(width: 1, height: 56, color: AppTheme.divider);
}

class _QuickActions extends StatelessWidget {
  const _QuickActions();
  static const _actions = [
    (icon: Icons.calendar_today_rounded, label: 'Book\nAppt', color: Color(0xFF0A6E6E), bg: Color(0xFFE6F9F5)),
    (icon: Icons.upload_file_rounded, label: 'Upload\nReport', color: Color(0xFF6C5CE7), bg: Color(0xFFF0EEFF)),
    (icon: Icons.local_pharmacy_rounded, label: 'Order\nMeds', color: Color(0xFFFFA743), bg: Color(0xFFFFF6E8)),
    (icon: Icons.emergency_rounded, label: 'Emergency', color: Color(0xFFE05C5C), bg: Color(0xFFFFEEEE)),
  ];
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Quick Actions', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppTheme.textDark)),
      const SizedBox(height: 14),
      Row(children: _actions.asMap().entries.map((e) => Expanded(child: Padding(
        padding: EdgeInsets.only(right: e.key < 3 ? 10 : 0),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.divider)),
          child: Column(children: [
            Container(width: 42, height: 42, decoration: BoxDecoration(color: e.value.bg, borderRadius: BorderRadius.circular(12)),
              child: Icon(e.value.icon, color: e.value.color, size: 22)),
            const SizedBox(height: 8),
            Text(e.value.label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textMid, height: 1.3)),
          ]),
        ),
      ))).toList()),
    ]),
  );
}

class _UpcomingSection extends StatelessWidget {
  final bool loading;
  final List appointments;
  const _UpcomingSection({required this.loading, required this.appointments});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Upcoming Appointments', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppTheme.textDark)),
          Text('See all', style: TextStyle(color: AppTheme.primary, fontSize: 13, fontWeight: FontWeight.w600)),
        ]),
        const SizedBox(height: 14),
        if (loading) Container(height: 100, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
          child: const Center(child: CircularProgressIndicator(color: AppTheme.primary)))
        else if (appointments.isEmpty) Container(padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppTheme.divider)),
          child: const Center(child: Text('No upcoming appointments', style: TextStyle(color: AppTheme.textLight, fontSize: 14))))
        else _ApptCard(appt: appointments.first),
      ]),
    );
  }
}

class _ApptCard extends StatelessWidget {
  final dynamic appt;
  const _ApptCard({required this.appt});
  @override
  Widget build(BuildContext context) {
    final doctor = appt['doctor'];
    final date = appt['date'] != null ? appt['date'].toString().substring(0, 10) : '';
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: const BoxDecoration(gradient: AppTheme.cardGradient, borderRadius: BorderRadius.all(Radius.circular(20))),
      child: Row(children: [
        Container(width: 54, height: 54, decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(14)),
          child: const Icon(Icons.person_outline_rounded, color: Colors.white, size: 30)),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(doctor?['name'] ?? 'Doctor', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 3),
          Text(doctor?['specialization'] ?? '', style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 13)),
          const SizedBox(height: 10),
          Row(children: [
            _Badge(icon: Icons.calendar_today_rounded, text: date),
            const SizedBox(width: 10),
            _Badge(icon: Icons.access_time_rounded, text: appt['timeSlot'] ?? ''),
          ]),
        ])),
      ]),
    );
  }
}

class _Badge extends StatelessWidget {
  final IconData icon; final String text;
  const _Badge({required this.icon, required this.text});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
    child: Row(children: [
      Icon(icon, color: Colors.white, size: 12), const SizedBox(width: 4),
      Text(text, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500)),
    ]),
  );
}

class _ReportsSection extends StatelessWidget {
  final bool loading;
  final List reports;
  const _ReportsSection({required this.loading, required this.reports});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Recent Reports', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: AppTheme.textDark)),
          Text('See all', style: TextStyle(color: AppTheme.primary, fontSize: 13, fontWeight: FontWeight.w600)),
        ]),
        const SizedBox(height: 14),
        if (loading) const Center(child: Padding(padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(color: AppTheme.primary)))
        else if (reports.isEmpty) Container(padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppTheme.divider)),
          child: const Center(child: Text('No reports yet', style: TextStyle(color: AppTheme.textLight))))
        else Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppTheme.divider)),
          child: Column(children: reports.take(3).toList().asMap().entries.map((e) {
            final r = e.value;
            final isReview = r['status'] == 'Review';
            return Column(children: [
              Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), child: Row(children: [
                Container(width: 40, height: 40, decoration: BoxDecoration(color: AppTheme.accentSoft, borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.description_outlined, color: AppTheme.primary, size: 20)),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(r['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppTheme.textDark)),
                  Text(r['type'] ?? '', style: const TextStyle(fontSize: 12, color: AppTheme.textLight)),
                ])),
                Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isReview ? const Color(0xFFFFF0CC) : AppTheme.accentSoft,
                    borderRadius: BorderRadius.circular(20)),
                  child: Text(r['status'] ?? '', style: TextStyle(
                    color: isReview ? AppTheme.warning : AppTheme.primary,
                    fontWeight: FontWeight.w600, fontSize: 11))),
              ])),
              if (e.key < reports.take(3).length - 1) const Divider(height: 1, color: AppTheme.divider, indent: 60),
            ]);
          }).toList()),
        ),
      ]),
    );
  }
}
