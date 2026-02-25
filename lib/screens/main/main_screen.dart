import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/inventory_provider.dart';
import '../../widgets/ad_banner_widget.dart';
import 'dashboard_screen.dart';
import '../product/product_list_screen.dart';
import '../scanner/scanner_screen.dart';
import '../stats/stats_screen.dart';
import '../settings/settings_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const ProductListScreen(),
    const ScannerScreen(),
    const StatsScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final inventory = Provider.of<InventoryProvider>(context);
    final primary = Theme.of(context).colorScheme.primary;

    if (inventory.isLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: primary),
              const SizedBox(height: 16),
              Text('Loading inventory…',
                  style: TextStyle(color: Colors.grey[500], fontSize: 14)),
            ],
          ),
        ),
      );
    }

    if (inventory.error != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.error_outline_rounded,
                      size: 48, color: Colors.red[400]),
                ),
                const SizedBox(height: 20),
                const Text('Something went wrong',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 8),
                Text(inventory.error!,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: inventory.refresh,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Try Again'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AdBannerWidget(),
          _AppNavBar(
            currentIndex: _currentIndex,
            onTap: (i) => setState(() => _currentIndex = i),
          ),
        ],
      ),
    );
  }
}

class _AppNavBar extends StatelessWidget {
  final int currentIndex;
  final void Function(int) onTap;

  const _AppNavBar({required this.currentIndex, required this.onTap});

  static const _items = [
    _NavItem(Icons.grid_view_rounded, Icons.grid_view_rounded, 'Home'),
    _NavItem(Icons.inventory_2_outlined, Icons.inventory_2, 'Products'),
    _NavItem(Icons.qr_code_scanner_rounded, Icons.qr_code_scanner_rounded, 'Scan'),
    _NavItem(Icons.bar_chart_outlined, Icons.bar_chart_rounded, 'Stats'),
    _NavItem(Icons.settings_outlined, Icons.settings_rounded, 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    final surface = Theme.of(context).colorScheme.surface;
    return Container(
      decoration: BoxDecoration(
        color: surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 64,
          child: Row(
            children: List.generate(_items.length, (i) {
              final item = _items[i];
              final selected = i == currentIndex;
              final isScan = i == 2;

              if (isScan) {
                return Expanded(
                  child: GestureDetector(
                    onTap: () => onTap(i),
                    child: Center(
                      child: Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: selected ? primary : const Color(0xFF0D1B3E),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: (selected ? primary : const Color(0xFF0D1B3E))
                                  .withValues(alpha: 0.35),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          selected ? item.activeIcon : item.icon,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                );
              }

              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onTap(i),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: selected
                              ? primary.withValues(alpha: 0.1)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          selected ? item.activeIcon : item.icon,
                          color: selected ? primary : Colors.grey[400],
                          size: 22,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.label,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.normal,
                          color:
                              selected ? primary : Colors.grey[400],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavItem(this.icon, this.activeIcon, this.label);
}
