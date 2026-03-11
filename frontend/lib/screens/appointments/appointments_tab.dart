import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/api_client.dart';
import '../../../core/providers/auth_provider.dart';

class AppointmentsTab extends StatefulWidget {
  const AppointmentsTab({super.key});
  @override
  State<AppointmentsTab> createState() => _AppointmentsTabState();
}

class _AppointmentsTabState extends State<AppointmentsTab>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  List _upcoming = [], _past = [], _cancelled = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    _load();
  }

  @override
  void dispose() { _tab.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final api = ApiClient.instance.dio;
    try {
      final res = await api.get('/appointments');
      final all = List.from(res.data['appointments'] ?? []);
      final now = DateTime.now();
      setState(() {
        _upcoming = all.where((a) {
          try { return DateTime.parse(a['date']).isAfter(now) && a['status'] != 'Cancelled'; } catch(error) { return false; }
        }).toList();
        _past = all.where((a) {
          try { return DateTime.parse(a['date']).isBefore(now) || a['status'] == 'Completed'; } catch(error) { return false; }
        }).toList();
        _cancelled = all.where((a) => a['status'] == 'Cancelled').toList();
        _loading = false;
      });
    } catch (error) { setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: NestedScrollView(
        headerSliverBuilder: (_, __) => [
          SliverAppBar(
            pinned: true, floating: true,
            backgroundColor: Colors.white,
            title: const Text('Appointments'),
            actions: [
              if (user?.isPatient ?? true)
                Padding(padding: const EdgeInsets.only(right: 16),
                  child: GestureDetector(
                    onTap: () => _showBookSheet(context),
                    child: Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(10)),
                      child: const Text('+ Book', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13))),
                  )),
            ],
            bottom: TabBar(
              controller: _tab,
              indicatorColor: AppTheme.primary,
              labelColor: AppTheme.primary,
              unselectedLabelColor: AppTheme.textLight,
              indicatorWeight: 2.5,
              labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              tabs: const [Tab(text: 'Upcoming'), Tab(text: 'Past'), Tab(text: 'Cancelled')],
            ),
          ),
        ],
        body: _loading
            ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
            : TabBarView(controller: _tab, children: [
                _ApptList(items: _upcoming, onRefresh: _load),
                _ApptList(items: _past, onRefresh: _load),
                _ApptList(items: _cancelled, onRefresh: _load),
              ]),
      ),
    );
  }

  void _showBookSheet(BuildContext context) {
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _BookSheet(onBooked: _load),
    );
  }
}

class _ApptList extends StatelessWidget {
  final List items;
  final VoidCallback onRefresh;
  const _ApptList({required this.items, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.event_note_rounded, size: 64, color: AppTheme.divider),
      SizedBox(height: 12),
      Text('No appointments here', style: TextStyle(color: AppTheme.textLight, fontSize: 15)),
    ]));
    }
    return RefreshIndicator(
      color: AppTheme.primary, onRefresh: () async => onRefresh(),
      child: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) => _ApptCard(appt: items[i], onRefresh: onRefresh),
      ),
    );
  }
}

class _ApptCard extends StatelessWidget {
  final dynamic appt;
  final VoidCallback onRefresh;
  const _ApptCard({required this.appt, required this.onRefresh});

  Color get _statusColor {
    switch (appt['status']) {
      case 'Confirmed': return AppTheme.success;
      case 'Pending': return AppTheme.warning;
      case 'Completed': return AppTheme.textLight;
      default: return AppTheme.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    final doctor = appt['doctor'];
    final patient = appt['patient'];
    final user = context.read<AuthProvider>().user;
    final dateStr = appt['date'] != null ? appt['date'].toString().substring(0, 10) : '';
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.divider)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(width: 48, height: 48, decoration: BoxDecoration(color: AppTheme.accentSoft, borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.person_outline_rounded, color: AppTheme.primary, size: 26)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(user?.isDoctor == true ? (patient?['name'] ?? 'Patient') : (doctor?['name'] ?? 'Doctor'),
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppTheme.textDark)),
            Text(doctor?['specialization'] ?? (user?.isDoctor == true ? 'Patient' : ''),
              style: const TextStyle(color: AppTheme.textLight, fontSize: 13)),
          ])),
          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: _statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
            child: Text(appt['status'] ?? '',
              style: TextStyle(color: _statusColor, fontSize: 12, fontWeight: FontWeight.w600))),
        ]),
        const SizedBox(height: 12),
        const Divider(color: AppTheme.divider, height: 1),
        const SizedBox(height: 10),
        Row(children: [
          const Icon(Icons.calendar_today_rounded, size: 13, color: AppTheme.textLight),
          const SizedBox(width: 4), Text(dateStr, style: const TextStyle(fontSize: 12, color: AppTheme.textMid)),
          const SizedBox(width: 14),
          const Icon(Icons.access_time_rounded, size: 13, color: AppTheme.textLight),
          const SizedBox(width: 4), Text(appt['timeSlot'] ?? '', style: const TextStyle(fontSize: 12, color: AppTheme.textMid)),
          const SizedBox(width: 14),
          Icon(appt['type'] == 'Online' ? Icons.videocam_rounded : Icons.local_hospital_rounded,
            size: 13, color: AppTheme.textLight),
          const SizedBox(width: 4), Text(appt['type'] ?? '', style: const TextStyle(fontSize: 12, color: AppTheme.textMid)),
        ]),
        if (appt['status'] == 'Confirmed' || appt['status'] == 'Pending') ...[
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: OutlinedButton(
              onPressed: () async {
                await ApiClient.instance.dio.patch('/appointments/${appt['_id']}/status',
                  data: {'status': 'Cancelled'});
                onRefresh();
              },
              style: OutlinedButton.styleFrom(side: const BorderSide(color: AppTheme.divider),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 10)),
              child: const Text('Cancel', style: TextStyle(color: AppTheme.textMid, fontWeight: FontWeight.w600)),
            )),
          ]),
        ],
      ]),
    );
  }
}

class _BookSheet extends StatefulWidget {
  final VoidCallback onBooked;
  const _BookSheet({required this.onBooked});
  @override
  State<_BookSheet> createState() => _BookSheetState();
}

class _BookSheetState extends State<_BookSheet> {
  List _doctors = [];
  String? _selectedDoctor;
  String _selectedSpecialty = 'All';
  List<String> _specialties = ['All'];
  int _dateIdx = 0;
  int _timeIdx = 0;
  String _type = 'In-Person';
  bool _loading = false;
  bool _loadingDoctors = true;

  final _dates = List.generate(7, (i) {
    final d = DateTime.now().add(Duration(days: i));
    return '${_wd(d.weekday)}\n${d.day}';
  });
  static String _wd(int w) => ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'][w-1];

  final _times = ['9:00 AM','10:30 AM','12:00 PM','2:00 PM','4:30 PM','6:00 PM'];

  @override
  void initState() {
    super.initState();
    _loadDoctors();
  }

  Future<void> _loadDoctors() async {
    try {
      final res = await ApiClient.instance.dio.get('/doctors');
      final docs = List.from(res.data['doctors'] ?? []);
      final specs = <String>{'All'};
      for (final d in docs) { if (d['specialization'] != null) specs.add(d['specialization']); }
      setState(() { _doctors = docs; _specialties = specs.toList(); _loadingDoctors = false; });
    } catch (_) { setState(() => _loadingDoctors = false); }
  }

  List get _filtered => _selectedSpecialty == 'All' ? _doctors
      : _doctors.where((d) => d['specialization'] == _selectedSpecialty).toList();

  Future<void> _book() async {
    if (_selectedDoctor == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a doctor')));
      return;
    }
    setState(() => _loading = true);
    final date = DateTime.now().add(Duration(days: _dateIdx));
    try {
      await ApiClient.instance.dio.post('/appointments', data: {
        'doctorId': _selectedDoctor,
        'date': date.toIso8601String(),
        'timeSlot': _times[_timeIdx],
        'type': _type,
      });
      if (mounted) {
        Navigator.pop(context);
        widget.onBooked();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Appointment booked!'), backgroundColor: AppTheme.primary));
      }
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Failed to book. Try again.'), backgroundColor: AppTheme.error));
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false, initialChildSize: 0.9, minChildSize: 0.5, maxChildSize: 0.95,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        child: SingleChildScrollView(controller: ctrl, padding: const EdgeInsets.all(24), child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppTheme.divider, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 20),
          const Text('Book Appointment', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppTheme.textDark)),
          const SizedBox(height: 20),

          // Specialty filter
          SizedBox(height: 36, child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _specialties.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final sel = _selectedSpecialty == _specialties[i];
              return GestureDetector(
                onTap: () => setState(() { _selectedSpecialty = _specialties[i]; _selectedDoctor = null; }),
                child: AnimatedContainer(duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: sel ? AppTheme.primary : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: sel ? AppTheme.primary : AppTheme.divider)),
                  child: Center(child: Text(_specialties[i],
                    style: TextStyle(color: sel ? Colors.white : AppTheme.textMid, fontWeight: FontWeight.w600, fontSize: 13))),
                ),
              );
            },
          )),
          const SizedBox(height: 16),

          // Doctor list
          if (_loadingDoctors) const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator(color: AppTheme.primary)))
          else if (_filtered.isEmpty) const Padding(padding: EdgeInsets.all(16), child: Text('No doctors found', style: TextStyle(color: AppTheme.textLight)))
          else ..._filtered.map((doc) {
            final sel = _selectedDoctor == doc['_id'];
            return GestureDetector(
              onTap: () => setState(() => _selectedDoctor = doc['_id']),
              child: AnimatedContainer(duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: sel ? AppTheme.accentSoft : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: sel ? AppTheme.primary : AppTheme.divider, width: sel ? 1.5 : 1)),
                child: Row(children: [
                  Container(width: 44, height: 44, decoration: BoxDecoration(color: AppTheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.person_outline_rounded, color: AppTheme.primary)),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(doc['name'], style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppTheme.textDark)),
                    Text(doc['specialization'] ?? '', style: const TextStyle(fontSize: 13, color: AppTheme.textLight)),
                  ])),
                  if (sel) const Icon(Icons.check_circle_rounded, color: AppTheme.primary),
                ]),
              ),
            );
          }).toList(),

          const SizedBox(height: 16),
          // Type
          Row(children: ['In-Person', 'Online'].map((t) {
            final sel = _type == t;
            return Expanded(child: GestureDetector(
              onTap: () => setState(() => _type = t),
              child: AnimatedContainer(duration: const Duration(milliseconds: 200),
                margin: EdgeInsets.only(right: t == 'In-Person' ? 8 : 0),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: sel ? AppTheme.primary : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: sel ? AppTheme.primary : AppTheme.divider)),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(t == 'Online' ? Icons.videocam_rounded : Icons.local_hospital_rounded, size: 16, color: sel ? Colors.white : AppTheme.textMid),
                  const SizedBox(width: 6),
                  Text(t, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: sel ? Colors.white : AppTheme.textMid)),
                ]),
              ),
            ));
          }).toList()),
          const SizedBox(height: 16),

          // Date
          const Text('Select Date', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textDark)),
          const SizedBox(height: 10),
          Row(children: List.generate(5, (i) {
            final sel = _dateIdx == i;
            return Expanded(child: GestureDetector(
              onTap: () => setState(() => _dateIdx = i),
              child: AnimatedContainer(duration: const Duration(milliseconds: 200),
                margin: EdgeInsets.only(right: i < 4 ? 8 : 0),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: sel ? AppTheme.primary : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: sel ? AppTheme.primary : AppTheme.divider)),
                child: Text(_dates[i], textAlign: TextAlign.center,
                  style: TextStyle(color: sel ? Colors.white : AppTheme.textMid, fontWeight: FontWeight.w600, fontSize: 12, height: 1.4)),
              ),
            ));
          })),
          const SizedBox(height: 16),

          // Time
          const Text('Select Time', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textDark)),
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 8, children: List.generate(_times.length, (i) {
            final sel = _timeIdx == i;
            return GestureDetector(
              onTap: () => setState(() => _timeIdx = i),
              child: AnimatedContainer(duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: sel ? AppTheme.primary : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: sel ? AppTheme.primary : AppTheme.divider)),
                child: Text(_times[i], style: TextStyle(color: sel ? Colors.white : AppTheme.textMid, fontWeight: FontWeight.w600, fontSize: 13)),
              ),
            );
          })),
          const SizedBox(height: 28),

          SizedBox(width: double.infinity, height: 54, child: ElevatedButton(
            onPressed: _loading ? null : _book,
            child: _loading ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text('Confirm Booking'),
          )),
          const SizedBox(height: 16),
        ]),
      )),
    );
  }
}
