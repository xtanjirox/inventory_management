import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../profile/profile_screen.dart';
import 'notification_settings_screen.dart';

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
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        children: [
          // ── Pro upgrade banner ───────────────────────────────────────────
          if (!isPro) ...[
            GestureDetector(
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen())),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7C3AED), Color(0xFF4F46E5)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF7C3AED).withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.workspace_premium,
                          color: Colors.white, size: 22),
                    ),
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
                          Text('Unlimited products · Cloud sync · Insights',
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 12)),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded,
                        color: Colors.white70),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],

          // ── Account card ─────────────────────────────────────────────────
          _SectionLabel(label: 'Account'),
          _SettingsCard(children: [
            _SettingsTile(
              leading: CircleAvatar(
                radius: 20,
                backgroundColor: primary,
                child: Text(initials,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14)),
              ),
              title: user?.name ?? 'User',
              subtitle: user?.email ?? '',
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _PlanChip(isPro: isPro),
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_right_rounded,
                      color: Color(0xFFCBD5E1), size: 20),
                ],
              ),
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen())),
            ),
          ]),
          const SizedBox(height: 20),

          // ── Preferences card ─────────────────────────────────────────────
          _SectionLabel(label: 'Preferences'),
          _SettingsCard(children: [
            _SettingsTile(
              iconData: Icons.language_rounded,
              iconColor: const Color(0xFF0EA5E9),
              title: 'Language',
              value: _languageLabel(user?.language ?? 'en'),
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen())),
            ),
            const _SettingsDivider(),
            _SettingsTile(
              iconData: Icons.attach_money_rounded,
              iconColor: Colors.green,
              title: 'Currency',
              value: user?.currency ?? 'USD',
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen())),
            ),
          ]),
          const SizedBox(height: 20),

          // ── Notifications card ───────────────────────────────────────────
          _SectionLabel(label: 'Notifications'),
          _SettingsCard(children: [
            _SettingsTile(
              iconData: Icons.notifications_outlined,
              iconColor: Colors.orange,
              title: 'Notification Settings',
              subtitle: 'Low stock alerts & inventory recap',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const NotificationSettingsScreen()),
              ),
            ),
          ]),
          const SizedBox(height: 20),

          // ── Cloud sync card ──────────────────────────────────────────────
          _SectionLabel(label: 'Cloud Sync'),
          _SettingsCard(children: [
            _SettingsTile(
              iconData: Icons.cloud_outlined,
              iconColor: isPro ? primary : Colors.grey,
              title: 'Sync with Cloud',
              subtitle: isPro
                  ? 'Pro feature — tap to configure'
                  : 'Upgrade to Pro to enable',
              subtitleColor: isPro ? null : Colors.orange[700],
              trailing: isPro
                  ? const Icon(Icons.chevron_right_rounded,
                      color: Color(0xFFCBD5E1), size: 20)
                  : _ProTag(),
              onTap: isPro
                  ? () {}
                  : () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const ProfileScreen())),
            ),
          ]),
          const SizedBox(height: 20),

          // ── About card ───────────────────────────────────────────────────
          _SectionLabel(label: 'About'),
          _SettingsCard(children: [
            _SettingsTile(
              iconData: Icons.info_outline_rounded,
              iconColor: const Color(0xFF64748B),
              title: 'App Version',
              value: '1.0.0 · ${isPro ? "Pro" : "Free"}',
            ),
            const _SettingsDivider(),
            _SettingsTile(
              iconData: Icons.help_outline_rounded,
              iconColor: const Color(0xFF64748B),
              title: 'Help & Support',
              onTap: () {},
            ),
          ]),
          const SizedBox(height: 24),

          // ── Logout ───────────────────────────────────────────────────────
          GestureDetector(
            onTap: () async => await auth.logout(),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.logout_rounded, color: Colors.red[600], size: 20),
                  const SizedBox(width: 8),
                  Text('Log Out',
                      style: TextStyle(
                          color: Colors.red[600],
                          fontWeight: FontWeight.w600,
                          fontSize: 15)),
                ],
              ),
            ),
          ),
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
}

// ── Reusable Settings Widgets ─────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Color(0xFF94A3B8),
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}

class _SettingsDivider extends StatelessWidget {
  const _SettingsDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, indent: 56, color: Color(0xFFF1F5F9));
  }
}

class _SettingsTile extends StatelessWidget {
  final Widget? leading;
  final IconData? iconData;
  final Color? iconColor;
  final String title;
  final String? subtitle;
  final Color? subtitleColor;
  final String? value;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    this.leading,
    this.iconData,
    this.iconColor,
    required this.title,
    this.subtitle,
    this.subtitleColor,
    this.value,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Widget leadingWidget;
    if (leading != null) {
      leadingWidget = leading!;
    } else if (iconData != null) {
      leadingWidget = Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: (iconColor ?? Colors.grey).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(iconData, color: iconColor ?? Colors.grey, size: 18),
      );
    } else {
      leadingWidget = const SizedBox(width: 36);
    }

    Widget? trailingWidget = trailing;
    if (trailingWidget == null) {
      if (value != null) {
        trailingWidget = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(value!,
                style: const TextStyle(
                    fontSize: 13, color: Color(0xFF94A3B8))),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right_rounded,
                color: Color(0xFFCBD5E1), size: 20),
          ],
        );
      } else if (onTap != null) {
        trailingWidget = const Icon(Icons.chevron_right_rounded,
            color: Color(0xFFCBD5E1), size: 20);
      }
    }

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              leadingWidget,
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF0D1B3E))),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(subtitle!,
                          style: TextStyle(
                              fontSize: 12,
                              color: subtitleColor ?? const Color(0xFF94A3B8))),
                    ],
                  ],
                ),
              ),
              if (trailingWidget != null) trailingWidget,
            ],
          ),
        ),
      ),
    );
  }
}

class _ProTag extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
