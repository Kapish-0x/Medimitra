import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/api_client.dart';
import '../../../core/providers/auth_provider.dart';

class ReportsTab extends StatefulWidget {
  const ReportsTab({super.key});
  @override
  State<ReportsTab> createState() => _ReportsTabState();
}

class _ReportsTabState extends State<ReportsTab> {
  List _reports = [];
  List _filtered = [];
  bool _loading = true;
  String _search = '';

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await ApiClient.instance.dio.get('/reports');
      final all = List.from(res.data['reports'] ?? []);
      if (mounted) setState(() { _reports = all; _filtered = all; _loading = false; });
    } catch (_) { if (mounted) setState(() => _loading = false); }
  }

  void _filter(String q) {
    setState(() {
      _search = q;
      _filtered = _reports.where((r) =>
        (r['title'] ?? '').toLowerCase().contains(q.toLowerCase()) ||
        (r['type'] ?? '').toLowerCase().contains(q.toLowerCase())
      ).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final normal = _filtered.where((r) => r['status'] == 'Normal').length;
    final review = _filtered.where((r) => r['status'] == 'Review').length;

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: const Text('Medical Reports'),
        backgroundColor: Colors.white,
        actions: [
          if (user?.isDoctor == true)
            Padding(padding: const EdgeInsets.only(right: 16),
              child: GestureDetector(
                onTap: () => _showUploadSheet(context),
                child: Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(10)),
                  child: const Text('+ Upload', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13))),
              )),
        ],
      ),
      body: RefreshIndicator(
        color: AppTheme.primary, onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
            : Column(children: [
                Padding(padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: Container(height: 46,
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.divider)),
                    child: Row(children: [
                      const SizedBox(width: 14),
                      const Icon(Icons.search_rounded, color: AppTheme.textLight, size: 20),
                      const SizedBox(width: 10),
                      Expanded(child: TextField(
                        onChanged: _filter,
                        style: const TextStyle(fontSize: 14, color: AppTheme.textDark),
                        decoration: const InputDecoration(
                          hintText: 'Search reports...',
                          border: InputBorder.none,
                          fillColor: Colors.transparent,
                          filled: false,
                          contentPadding: EdgeInsets.zero,
                        ),
                      )),
                    ]),
                  )),
                const SizedBox(height: 14),
                Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Row(children: [
                  _SumCard(count: '${_filtered.length}', label: 'Total', color: AppTheme.primary),
                  const SizedBox(width: 10),
                  _SumCard(count: '$normal', label: 'Normal', color: AppTheme.success),
                  const SizedBox(width: 10),
                  _SumCard(count: '$review', label: 'Review', color: AppTheme.warning),
                ])),
                const SizedBox(height: 14),
                Expanded(child: _reports.isEmpty
                    ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        const Icon(Icons.folder_open_rounded, size: 64, color: AppTheme.divider),
                        const SizedBox(height: 12),
                        Text(user?.isDoctor == true ? 'No reports uploaded yet' : 'No reports available',
                          style: const TextStyle(color: AppTheme.textLight, fontSize: 15)),
                      ]))
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: _filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) => _ReportCard(report: _filtered[i]),
                      )),
              ]),
      ),
    );
  }

  void _showUploadSheet(BuildContext ctx) {
    showModalBottomSheet(context: ctx, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _UploadSheet(onUploaded: _load));
  }
}

class _SumCard extends StatelessWidget {
  final String count, label; final Color color;
  const _SumCard({required this.count, required this.label, required this.color});
  @override
  Widget build(BuildContext context) => Expanded(child: Container(
    padding: const EdgeInsets.symmetric(vertical: 12),
    decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(12)),
    child: Column(children: [
      Text(count, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: color)),
      Text(label, style: TextStyle(fontSize: 12, color: color.withOpacity(0.8), fontWeight: FontWeight.w500)),
    ]),
  ));
}

class _ReportCard extends StatelessWidget {
  final dynamic report;
  const _ReportCard({required this.report});

  Color get _typeColor {
    switch (report['type']) {
      case 'Imaging': return const Color(0xFF6C5CE7);
      case 'Cardiology': return const Color(0xFFE05C5C);
      default: return AppTheme.primary;
    }
  }
  IconData get _typeIcon {
    switch (report['type']) {
      case 'Imaging': return Icons.image_outlined;
      case 'Cardiology': return Icons.monitor_heart_outlined;
      default: return Icons.science_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isReview = report['status'] == 'Review';
    final patient = report['patient'];
    final uploadedBy = report['uploadedBy'];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.divider)),
      child: Row(children: [
        Container(width: 48, height: 48, decoration: BoxDecoration(color: _typeColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
          child: Icon(_typeIcon, color: _typeColor, size: 24)),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(report['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppTheme.textDark)),
          const SizedBox(height: 2),
          Text('${uploadedBy?['name'] ?? ''} · ${report['type'] ?? ''}',
            style: const TextStyle(fontSize: 12, color: AppTheme.textLight)),
          if (patient != null) ...[
            const SizedBox(height: 2),
            Text('Patient: ${patient['name']}', style: const TextStyle(fontSize: 11, color: AppTheme.textLight)),
          ],
        ])),
        Column(children: [
          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isReview ? const Color(0xFFFFF0CC) : AppTheme.accentSoft,
              borderRadius: BorderRadius.circular(8)),
            child: Text(report['status'] ?? '',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                color: isReview ? AppTheme.warning : AppTheme.primary))),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () async {
              try {
                await ApiClient.instance.dio.get('/reports/${report['_id']}/download');
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Downloading...')));
              } catch (_) {}
            },
            child: const Icon(Icons.download_rounded, color: AppTheme.textLight, size: 20),
          ),
        ]),
      ]),
    );
  }
}

class _UploadSheet extends StatefulWidget {
  final VoidCallback onUploaded;
  const _UploadSheet({required this.onUploaded});
  @override
  State<_UploadSheet> createState() => _UploadSheetState();
}

class _UploadSheetState extends State<_UploadSheet> {
  final _titleCtrl = TextEditingController();
  final _patientCtrl = TextEditingController();
  String _type = 'Lab Report';
  String _status = 'Normal';
  bool _loading = false;
  List _patients = [];

  final _types = ['Lab Report', 'Imaging', 'Cardiology', 'Prescription', 'Discharge Summary', 'Other'];
  final _statuses = ['Normal', 'Review', 'Critical', 'Pending'];

  @override
  void initState() { super.initState(); _loadPatients(); }

  Future<void> _loadPatients() async {
    // For demo - in prod you'd have a patient search endpoint
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false, initialChildSize: 0.75,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(controller: ctrl, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppTheme.divider, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 20),
          const Text('Upload Report', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppTheme.textDark)),
          const SizedBox(height: 24),

          _lbl('Report Title'),
          const SizedBox(height: 8),
          TextField(controller: _titleCtrl, decoration: const InputDecoration(hintText: 'e.g. Blood Test Report')),
          const SizedBox(height: 16),

          _lbl('Patient Email'),
          const SizedBox(height: 8),
          TextField(controller: _patientCtrl, decoration: const InputDecoration(hintText: 'patient@email.com')),
          const SizedBox(height: 16),

          _lbl('Report Type'),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: _types.map((t) {
            final sel = _type == t;
            return GestureDetector(onTap: () => setState(() => _type = t),
              child: AnimatedContainer(duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(color: sel ? AppTheme.primary : Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: sel ? AppTheme.primary : AppTheme.divider)),
                child: Text(t, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: sel ? Colors.white : AppTheme.textMid))));
          }).toList()),
          const SizedBox(height: 28),

          Container(width: double.infinity, height: 120,
            decoration: BoxDecoration(color: AppTheme.accentSoft, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppTheme.primary.withOpacity(0.3), style: BorderStyle.solid)),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.cloud_upload_outlined, color: AppTheme.primary, size: 36),
              const SizedBox(height: 8),
              const Text('Tap to select PDF or Image', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w600)),
              Text('Max 10MB · PDF, JPG, PNG', style: TextStyle(color: AppTheme.primary.withOpacity(0.6), fontSize: 12)),
            ])),
          const SizedBox(height: 28),

          SizedBox(width: double.infinity, height: 54, child: ElevatedButton(
            onPressed: _loading ? null : () { Navigator.pop(context); widget.onUploaded(); },
            child: _loading ? const CircularProgressIndicator(color: Colors.white) : const Text('Upload Report'),
          )),
        ])),
      ),
    );
  }

  Widget _lbl(String t) => Text(t, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textDark));
}
