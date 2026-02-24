import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/user_profile.dart';
import '../../providers/auth_provider.dart';
import '../../utils/plan_limits.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();
  bool _isEditing = false;

  static const List<Map<String, String>> _currencies = [
    {'code': 'USD', 'label': 'USD (\$)'},
    {'code': 'EUR', 'label': 'EUR (€)'},
    {'code': 'GBP', 'label': 'GBP (£)'},
    {'code': 'JPY', 'label': 'JPY (¥)'},
    {'code': 'CAD', 'label': 'CAD (CA\$)'},
    {'code': 'AUD', 'label': 'AUD (A\$)'},
    {'code': 'CHF', 'label': 'CHF (Fr)'},
    {'code': 'MAD', 'label': 'MAD (د.م.)'},
  ];

  static const List<Map<String, String>> _languages = [
    {'code': 'en', 'label': 'English'},
    {'code': 'fr', 'label': 'Français'},
    {'code': 'es', 'label': 'Español'},
    {'code': 'ar', 'label': 'العربية'},
    {'code': 'de', 'label': 'Deutsch'},
    {'code': 'pt', 'label': 'Português'},
  ];

  @override
  void initState() {
    super.initState();
    final user = Provider.of<AuthProvider>(context, listen: false).currentUser;
    _nameController.text = user?.name ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveName(AuthProvider auth) async {
    final error = await auth.updateProfile(name: _nameController.text.trim());
    if (!mounted) return;
    setState(() => _isEditing = false);
    if (error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error), backgroundColor: Colors.red));
    }
  }

  void _showUpgradeDialog(BuildContext context, AuthProvider auth) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Upgrade to Pro'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Unlock all features with the Pro plan:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            _featureRow(Icons.inventory_2, 'Unlimited products'),
            _featureRow(Icons.cloud_sync, 'Cloud synchronization'),
            _featureRow(Icons.bar_chart, 'Advanced analytics'),
            _featureRow(Icons.download, 'CSV & PDF export'),
            _featureRow(Icons.support_agent, 'Priority support'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              await auth.upgradeToPro();
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('🎉 You are now on the Pro plan!'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C3AED),
              foregroundColor: Colors.white,
            ),
            child: const Text('Upgrade Now'),
          ),
        ],
      ),
    );
  }

  Widget _featureRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF7C3AED)),
          const SizedBox(width: 10),
          Text(text),
        ],
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context, AuthProvider auth) {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Change Password'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: currentCtrl,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Current Password'),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: newCtrl,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'New Password'),
                validator: (v) =>
                    (v == null || v.length < 6) ? 'Min 6 characters' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: confirmCtrl,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Confirm Password'),
                validator: (v) =>
                    v != newCtrl.text ? 'Passwords do not match' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              final error = await auth.changePassword(
                currentPassword: currentCtrl.text,
                newPassword: newCtrl.text,
              );
              if (context.mounted) {
                Navigator.pop(context);
                if (error != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(error), backgroundColor: Colors.red),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Password changed successfully')),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.currentUser;
    if (user == null) return const SizedBox.shrink();

    final isPro = user.plan == AppPlan.pro;
    final primary = Theme.of(context).colorScheme.primary;
    final initials = user.name
        .trim()
        .split(' ')
        .take(2)
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
        .join();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          if (_isEditing)
            TextButton(
              onPressed: () => _saveName(auth),
              child: const Text('Save'),
            )
          else
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => setState(() => _isEditing = true),
            ),
        ],
      ),
      body: ListView(
        children: [
          // ── Avatar & name ──────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(vertical: 32),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [primary.withOpacity(0.08), primary.withOpacity(0.02)],
              ),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 44,
                  backgroundColor: primary,
                  child: Text(
                    initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                if (_isEditing)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: TextField(
                      controller: _nameController,
                      textAlign: TextAlign.center,
                      autofocus: true,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                      ),
                    ),
                  )
                else
                  Text(
                    user.name,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                const SizedBox(height: 4),
                Text(
                  user.email,
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
                const SizedBox(height: 12),
                _PlanBadge(isPro: isPro),
              ],
            ),
          ),

          // ── Plan card ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: _PlanCard(
              user: user,
              isPro: isPro,
              onUpgrade: () => _showUpgradeDialog(context, auth),
            ),
          ),

          // ── Preferences ───────────────────────────────────────────────────
          _sectionHeader('Preferences'),
          ListTile(
            leading: const Icon(Icons.language),
            title: const Text('Language'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _languages
                          .firstWhere(
                            (l) => l['code'] == user.language,
                            orElse: () => _languages.first,
                          )['label'] ??
                      'English',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
            onTap: () => _showPickerDialog(
              context: context,
              title: 'Language',
              items: _languages,
              selected: user.language,
              onSelected: (code) => auth.updateProfile(language: code),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.attach_money),
            title: const Text('Currency'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _currencies
                          .firstWhere(
                            (c) => c['code'] == user.currency,
                            orElse: () => _currencies.first,
                          )['label'] ??
                      'USD',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
            onTap: () => _showPickerDialog(
              context: context,
              title: 'Currency',
              items: _currencies,
              selected: user.currency,
              onSelected: (code) => auth.updateProfile(currency: code),
            ),
          ),

          // ── Security ──────────────────────────────────────────────────────
          _sectionHeader('Security'),
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: const Text('Change Password'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showChangePasswordDialog(context, auth),
          ),

          // ── Logout ────────────────────────────────────────────────────────
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: OutlinedButton.icon(
              onPressed: () async {
                await auth.logout();
                if (context.mounted) {
                  Navigator.of(context)
                      .popUntil((route) => route.isFirst);
                }
              },
              icon: const Icon(Icons.logout, color: Colors.red),
              label: const Text('Log Out'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
            fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
      ),
    );
  }

  void _showPickerDialog({
    required BuildContext context,
    required String title,
    required List<Map<String, String>> items,
    required String selected,
    required void Function(String code) onSelected,
  }) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(title,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          ...items.map((item) => ListTile(
                title: Text(item['label']!),
                trailing: item['code'] == selected
                    ? Icon(Icons.check,
                        color: Theme.of(context).colorScheme.primary)
                    : null,
                onTap: () {
                  onSelected(item['code']!);
                  Navigator.pop(context);
                },
              )),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _PlanBadge extends StatelessWidget {
  final bool isPro;
  const _PlanBadge({required this.isPro});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      decoration: BoxDecoration(
        color: isPro ? const Color(0xFF7C3AED) : Colors.grey[200],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPro ? Icons.workspace_premium : Icons.person_outline,
            size: 14,
            color: isPro ? Colors.white : Colors.grey[600],
          ),
          const SizedBox(width: 4),
          Text(
            isPro ? 'Pro Plan' : 'Normal Plan',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isPro ? Colors.white : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final UserProfile user;
  final bool isPro;
  final VoidCallback onUpgrade;

  const _PlanCard({
    required this.user,
    required this.isPro,
    required this.onUpgrade,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: isPro
            ? const LinearGradient(
                colors: [Color(0xFF7C3AED), Color(0xFF4F46E5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: isPro ? null : Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isPro ? '⚡ Pro Plan' : '🔒 Normal Plan',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isPro ? Colors.white : const Color(0xFF1F2937),
                ),
              ),
              if (!isPro)
                ElevatedButton(
                  onPressed: onUpgrade,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C3AED),
                    foregroundColor: Colors.white,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                  child: const Text('Upgrade',
                      style: TextStyle(fontSize: 13)),
                ),
            ],
          ),
          const SizedBox(height: 16),
          _limitRow(
            icon: Icons.inventory_2_outlined,
            label: PlanLimits.getProductLimitText(user.plan),
            isPro: isPro,
          ),
          const SizedBox(height: 8),
          _limitRow(
            icon: Icons.cloud_outlined,
            label: PlanLimits.getCloudSyncText(user.plan),
            isPro: isPro,
          ),
          const SizedBox(height: 8),
          _limitRow(
            icon: Icons.bar_chart_outlined,
            label: isPro ? 'Full analytics' : 'Basic stats only',
            isPro: isPro,
          ),
        ],
      ),
    );
  }

  Widget _limitRow({
    required IconData icon,
    required String label,
    required bool isPro,
  }) {
    final color = isPro ? Colors.white70 : Colors.grey[600]!;
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(color: color, fontSize: 13)),
      ],
    );
  }
}
