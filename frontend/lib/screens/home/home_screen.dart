import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import 'dashboard_tab.dart';
import '../appointments/appointments_tab.dart';
import '../reports/reports_tab.dart';
import '../medicines/medicines_tab.dart';
import '../profile/profile_tab.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _idx = 0;

  final _tabs = const [
    DashboardTab(),
    AppointmentsTab(),
    ReportsTab(),
    MedicinesTab(),
    ProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _idx, children: _tabs),
      bottomNavigationBar: _BottomNav(current: _idx, onTap: (i) => setState(() => _idx = i)),
    );
  }
}

class _BottomNav extends StatelessWidget {
  final int current;
  final ValueChanged<int> onTap;
  const _BottomNav({required this.current, required this.onTap});

  static const _items = [
    (icon: Icons.home_rounded, label: 'Home'),
    (icon: Icons.calendar_month_rounded, label: 'Appointments'),
    (icon: Icons.folder_copy_rounded, label: 'Reports'),
    (icon: Icons.local_pharmacy_rounded, label: 'Medicines'),
    (icon: Icons.person_rounded, label: 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 20, offset: const Offset(0, -4))],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: List.generate(_items.length, (i) => Expanded(
              child: GestureDetector(
                onTap: () => onTap(i),
                behavior: HitTestBehavior.opaque,
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: i == current ? AppTheme.accentSoft : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(_items[i].icon, size: 24,
                      color: i == current ? AppTheme.primary : AppTheme.textLight),
                  ),
                  const SizedBox(height: 2),
                  Text(_items[i].label, style: TextStyle(
                    fontSize: 10,
                    fontWeight: i == current ? FontWeight.w700 : FontWeight.w400,
                    color: i == current ? AppTheme.primary : AppTheme.textLight,
                  )),
                ]),
              ),
            )),
          ),
        ),
      ),
    );
  }
}
