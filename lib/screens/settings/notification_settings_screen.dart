import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/inventory_provider.dart';
import '../../services/notification_service.dart';
import '../profile/profile_screen.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  bool _lowStockEnabled = true;
  String _lowStockFreq = 'daily'; // 'daily', 'weekly', 'custom'
  int _lowStockCustomHours = 12;

  bool _recapEnabled = false;
  String _recapFreq = 'daily'; // 'daily', 'weekly', 'custom'
  int _recapCustomDays = 1;
  TimeOfDay _recapTime = const TimeOfDay(hour: 9, minute: 0);

  bool _permissionGranted = false;

  @override
  void initState() {
    super.initState();
    _requestPermission();
  }

  Future<void> _requestPermission() async {
    final granted = await NotificationService.instance.requestPermission();
    if (mounted) setState(() => _permissionGranted = granted);
  }

  Future<void> _applySettings(BuildContext context) async {
    final inventory = Provider.of<InventoryProvider>(context, listen: false);
    final ns = NotificationService.instance;

    // Low stock notifications
    if (_lowStockEnabled) {
      final hours = _lowStockFreq == 'daily'
          ? 24
          : _lowStockFreq == 'weekly'
              ? 168
              : _lowStockCustomHours;
      await ns.scheduleLowStockCheck(
        lowStockCount: inventory.lowStockProducts.length,
        totalProducts: inventory.products.length,
        interval: Duration(hours: hours),
      );
    } else {
      await ns.cancelLowStockNotification();
    }

    // Recap notifications (Pro only)
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.currentUser;
    final currency = user?.currency ?? 'USD';
    final totalValue = inventory.products
        .fold<double>(0, (sum, p) => sum + p.price * p.stock);

    if (_recapEnabled && auth.isPro) {
      final customDays = _recapCustomDays;
      
      await ns.scheduleRecap(
        totalProducts: inventory.products.length,
        totalValue: totalValue,
        lowStockCount: inventory.lowStockProducts.length,
        time: _recapTime,
        currency: currency,
        daily: _recapFreq == 'daily',
        customIntervalHours: _recapFreq == 'custom' ? customDays * 24 : null,
      );
    } else {
      await ns.cancelRecapNotification();
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notification settings saved')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final isPro = auth.isPro;
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications',
            style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          TextButton(
            onPressed: () => _applySettings(context),
            child: const Text('Save'),
          ),
        ],
      ),
      body: ListView(
        children: [
          if (!_permissionGranted)
            _PermissionBanner(onGrant: _requestPermission),

          // ── Low Stock Notifications ────────────────────────────────────────
          _sectionHeader('Low Stock Alerts'),
          SwitchListTile(
            title: const Text('Low stock notifications'),
            subtitle: const Text('Get alerted when products run low'),
            secondary: const Icon(Icons.warning_amber_outlined),
            value: _lowStockEnabled,
            onChanged: (v) => setState(() => _lowStockEnabled = v),
          ),
          if (_lowStockEnabled) ...[
            _subHeader('Check frequency'),
            RadioListTile<String>(
              title: const Text('Every day'),
              value: 'daily',
              groupValue: _lowStockFreq,
              onChanged: (v) => setState(() => _lowStockFreq = v!),
            ),
            RadioListTile<String>(
              title: const Text('Every week'),
              value: 'weekly',
              groupValue: _lowStockFreq,
              onChanged: (v) => setState(() => _lowStockFreq = v!),
            ),
            RadioListTile<String>(
              title: Row(
                children: [
                  const Text('Custom interval'),
                  const SizedBox(width: 8),
                  if (!isPro) _proBadge(),
                ],
              ),
              value: 'custom',
              groupValue: _lowStockFreq,
              onChanged: isPro
                  ? (v) => setState(() => _lowStockFreq = v!)
                  : null,
            ),
            if (_lowStockFreq == 'custom' && isPro)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                child: Row(
                  children: [
                    const Text('Every '),
                    SizedBox(
                      width: 60,
                      child: TextFormField(
                        initialValue: _lowStockCustomHours.toString(),
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          isDense: true,
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 8, vertical: 8),
                        ),
                        onChanged: (v) => setState(() =>
                            _lowStockCustomHours =
                                int.tryParse(v) ?? 12),
                      ),
                    ),
                    const Text(' hours'),
                  ],
                ),
              ),
          ],

          const Divider(),

          // ── Inventory Recap ────────────────────────────────────────────────
          _sectionHeader(Row(children: [
            const Text('Inventory Recap'),
            const SizedBox(width: 8),
            if (!isPro) _proBadge(),
          ])),
          if (!isPro)
            _ProLockedCard(
              description: 'Get a daily recap of your inventory status — '
                  'total value, low stock count, and more.',
              onUpgrade: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              ),
            )
          else ...[
            SwitchListTile(
              title: const Text('Enable recap notifications'),
              subtitle: const Text(
                  'Brief daily summary of your inventory status'),
              secondary: const Icon(Icons.summarize_outlined),
              value: _recapEnabled,
              onChanged: (v) => setState(() => _recapEnabled = v),
            ),
            if (_recapEnabled) ...[
              ListTile(
                leading: const Icon(Icons.access_time),
                title: const Text('Notification time'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_recapTime.format(context),
                        style: TextStyle(color: primary)),
                    const Icon(Icons.chevron_right),
                  ],
                ),
                onTap: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: _recapTime,
                  );
                  if (picked != null) {
                    setState(() => _recapTime = picked);
                  }
                },
              ),
              _subHeader('Frequency'),
              RadioListTile<String>(
                title: const Text('Daily'),
                value: 'daily',
                groupValue: _recapFreq,
                onChanged: (v) => setState(() => _recapFreq = v!),
              ),
              RadioListTile<String>(
                title: const Text('Weekly'),
                value: 'weekly',
                groupValue: _recapFreq,
                onChanged: (v) => setState(() => _recapFreq = v!),
              ),
              RadioListTile<String>(
                title: const Text('Custom'),
                value: 'custom',
                groupValue: _recapFreq,
                onChanged: (v) => setState(() => _recapFreq = v!),
              ),
              if (_recapFreq == 'custom')
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                  child: Row(
                    children: [
                      const Text('Every '),
                      SizedBox(
                        width: 60,
                        child: TextFormField(
                          initialValue: _recapCustomDays.toString(),
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            isDense: true,
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 8, vertical: 8),
                          ),
                          onChanged: (v) => setState(() =>
                              _recapCustomDays =
                                  int.tryParse(v) ?? 1),
                        ),
                      ),
                      const Text(' days'),
                    ],
                  ),
                ),
            ],
          ],
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _sectionHeader(dynamic title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: DefaultTextStyle(
        style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
            letterSpacing: 0.8),
        child: title is Widget
            ? title
            : Text((title as String).toUpperCase()),
      ),
    );
  }

  Widget _subHeader(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 16, 0),
      child: Text(text,
          style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF374151))),
    );
  }

  Widget _proBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF7C3AED),
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Text('PRO',
          style: TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold)),
    );
  }
}

class _PermissionBanner extends StatelessWidget {
  final VoidCallback onGrant;
  const _PermissionBanner({required this.onGrant});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.notifications_off_outlined, color: Colors.orange[700]),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Enable notifications to receive alerts',
              style: TextStyle(color: Colors.orange[800], fontSize: 13),
            ),
          ),
          TextButton(
            onPressed: onGrant,
            child: const Text('Enable'),
          ),
        ],
      ),
    );
  }
}

class _ProLockedCard extends StatelessWidget {
  final String description;
  final VoidCallback onUpgrade;

  const _ProLockedCard({
    required this.description,
    required this.onUpgrade,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF7C3AED), Color(0xFF4F46E5)],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.lock_outline, color: Colors.white, size: 28),
            const SizedBox(height: 10),
            const Text('Pro Feature',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(description,
                style:
                    const TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onUpgrade,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF7C3AED),
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Upgrade to Pro',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
