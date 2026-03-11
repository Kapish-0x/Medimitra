import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import 'auth/login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _ctrl = PageController();
  int _page = 0;

  final _pages = const [
    _OBData(icon: Icons.shield_rounded, color: Color(0xFF13A89E), bg: Color(0xFFE6F9F5),
        title: 'Secure Health\nRecords', sub: 'All your medical reports encrypted and accessible only by you and your doctors.'),
    _OBData(icon: Icons.calendar_today_rounded, color: Color(0xFF0A6E6E), bg: Color(0xFFEAF4FF),
        title: 'Book Appointments\nInstantly', sub: 'Find doctors, schedule visits, get reminders — from one place.'),
    _OBData(icon: Icons.local_pharmacy_rounded, color: Color(0xFF6C5CE7), bg: Color(0xFFF0EEFF),
        title: 'Order Medicines\nWith Ease', sub: 'Browse, cart, and order medicines with full order history and tracking.'),
  ];

  void _go() {
    if (_page < _pages.length - 1) {
      _ctrl.nextPage(duration: const Duration(milliseconds: 380), curve: Curves.easeInOut);
    } else {
      Navigator.pushReplacement(context,
        MaterialPageRoute(builder: (_) => const LoginScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(children: [
          Align(alignment: Alignment.topRight,
            child: Padding(padding: const EdgeInsets.all(20),
              child: GestureDetector(
                onTap: () => Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (_) => const LoginScreen())),
                child: const Text('Skip', style: TextStyle(color: AppTheme.textMid, fontWeight: FontWeight.w600)),
              ),
            ),
          ),
          Expanded(
            child: PageView.builder(
              controller: _ctrl,
              onPageChanged: (i) => setState(() => _page = i),
              itemCount: _pages.length,
              itemBuilder: (_, i) => _PageView(data: _pages[i]),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(32, 0, 32, 44),
            child: Column(children: [
              Row(mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_pages.length, (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: i == _page ? 28 : 8, height: 8,
                  decoration: BoxDecoration(
                    color: i == _page ? AppTheme.primary : AppTheme.divider,
                    borderRadius: BorderRadius.circular(4),
                  ),
                )),
              ),
              const SizedBox(height: 32),
              SizedBox(width: double.infinity, child: ElevatedButton(
                onPressed: _go,
                child: Text(_page == _pages.length - 1 ? 'Get Started' : 'Continue'),
              )),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _OBData {
  final IconData icon;
  final Color color, bg;
  final String title, sub;
  const _OBData({required this.icon, required this.color, required this.bg, required this.title, required this.sub});
}

class _PageView extends StatelessWidget {
  final _OBData data;
  const _PageView({required this.data});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 32),
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(width: 200, height: 200, decoration: BoxDecoration(color: data.bg, shape: BoxShape.circle),
        child: Icon(data.icon, size: 90, color: data.color)),
      const SizedBox(height: 52),
      Text(data.title, textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800,
          color: AppTheme.textDark, height: 1.15, letterSpacing: -0.8)),
      const SizedBox(height: 18),
      Text(data.sub, textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 16, color: AppTheme.textMid, height: 1.6)),
    ]),
  );
}
