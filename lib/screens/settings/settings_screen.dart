import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../profile/profile_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.currentUser;
    final isPro = auth.isPro;
    final primary = Theme.of(context).colorScheme.primary;

    final initials = (user?.name ?? 'U')
        .trim()
        .split(' ')
        .take(2)
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
        .join();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 8),

          // ── Plan banner ──────────────────────────────────────────────────
          if (!isPro)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: InkWell(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                ),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF7C3AED), Color(0xFF4F46E5)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.workspace_premium,
                          color: Colors.white, size: 28),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Upgrade to Pro',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15)),
                            Text('Unlimited products + cloud sync',
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 12)),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios,
                          color: Colors.white70, size: 16),
                    ],
                  ),
                ),
              ),
            ),

          // ── Account ──────────────────────────────────────────────────────
          _buildSectionHeader('Account'),
          ListTile(
            leading: CircleAvatar(
              backgroundColor: primary,
              child: Text(
                initials,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(user?.name ?? 'User'),
            subtitle: Text(user?.email ?? ''),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _PlanChip(isPro: isPro),
                const Icon(Icons.chevron_right),
              ],
            ),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            ),
          ),
          const Divider(),

          // ── Preferences ───────────────────────────────────────────────────
          _buildSectionHeader('Preferences'),
          ListTile(
            leading: const Icon(Icons.language),
            title: const Text('Language'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _languageLabel(user?.language ?? 'en'),
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.attach_money),
            title: const Text('Currency'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  user?.currency ?? 'USD',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const Icon(Icons.chevron_right),
              ],
            ),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            ),
          ),
          const Divider(),

          // ── Cloud Sync ────────────────────────────────────────────────────
          _buildSectionHeader('Cloud Sync'),
          ListTile(
            leading: Icon(
              Icons.cloud_outlined,
              color: isPro ? primary : Colors.grey,
            ),
            title: const Text('Sync with Cloud'),
            subtitle: Text(
              isPro
                  ? 'Pro feature — tap to configure'
                  : 'Upgrade to Pro to enable',
              style: TextStyle(
                  color: isPro ? Colors.grey[600] : Colors.orange[700],
                  fontSize: 12),
            ),
            trailing: isPro
                ? const Icon(Icons.chevron_right)
                : Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange[200]!),
                    ),
                    child: Text('Pro',
                        style: TextStyle(
                            color: Colors.orange[700],
                            fontSize: 11,
                            fontWeight: FontWeight.bold)),
                  ),
            onTap: isPro
                ? () {}
                : () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const ProfileScreen()),
                    ),
          ),
          const Divider(),

          // ── About ─────────────────────────────────────────────────────────
          _buildSectionHeader('About'),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('App Version'),
            trailing: Text(
              '1.0.0 · ${isPro ? "Pro" : "Normal"}',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: const Text('Help & Support'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),

          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: OutlinedButton.icon(
              onPressed: () async {
                await auth.logout();
              },
              icon: const Icon(Icons.logout, color: Colors.red),
              label: const Text('Log Out'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  String _languageLabel(String code) {
    const map = {
      'en': 'English',
      'fr': 'Français',
      'es': 'Español',
      'ar': 'العربية',
      'de': 'Deutsch',
      'pt': 'Português',
    };
    return map[code] ?? code;
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
        ),
      ),
    );
  }
}

class _PlanChip extends StatelessWidget {
  final bool isPro;
  const _PlanChip({required this.isPro});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isPro ? const Color(0xFF7C3AED) : Colors.grey[200],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        isPro ? 'Pro' : 'Normal',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: isPro ? Colors.white : Colors.grey[600],
        ),
      ),
    );
  }
}
