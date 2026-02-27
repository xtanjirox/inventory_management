import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/sync_provider.dart';
import '../../providers/auth_provider.dart';
import '../profile/profile_screen.dart';

class CloudSyncSettingsScreen extends StatefulWidget {
  const CloudSyncSettingsScreen({super.key});

  @override
  State<CloudSyncSettingsScreen> createState() =>
      _CloudSyncSettingsScreenState();
}

class _CloudSyncSettingsScreenState extends State<CloudSyncSettingsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _spinController;

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SyncProvider>().refreshPendingCounts();
    });
  }

  @override
  void dispose() {
    _spinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sync = context.watch<SyncProvider>();
    final isPro = context.watch<AuthProvider>().isPro;
    final cs = Theme.of(context).colorScheme;

    if (sync.isSyncing) {
      _spinController.repeat();
    } else {
      _spinController.stop();
      _spinController.reset();
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Cloud Sync')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
        children: [
          if (!isPro) _ProUpgradeBanner(cs: cs),
          if (!isPro) const SizedBox(height: 20),

          // ── Status card ─────────────────────────────────────────────────
          _SyncStatusCard(sync: sync, spinController: _spinController, cs: cs),
          const SizedBox(height: 20),

          // ── Pending items ───────────────────────────────────────────────
          _SectionLabel(label: 'Pending to upload'),
          _PendingCard(sync: sync, cs: cs),
          const SizedBox(height: 20),

          // ── Auto sync toggle ────────────────────────────────────────────
          _SectionLabel(label: 'Options'),
          _OptionsCard(sync: sync, isPro: isPro, cs: cs),
          const SizedBox(height: 32),

          // ── Sync now button ─────────────────────────────────────────────
          SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: (isPro && !sync.isSyncing)
                  ? () => context.read<SyncProvider>().syncAll()
                  : null,
              icon: sync.isSyncing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child:
                          CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.cloud_upload_outlined),
              label: Text(sync.isSyncing ? 'Syncing…' : 'Sync Now'),
              style: ElevatedButton.styleFrom(
                backgroundColor: cs.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
            ),
          ),
          if (sync.status == SyncStatus.error && sync.lastError != null) ...[
            const SizedBox(height: 12),
            _ErrorBanner(message: sync.lastError!),
          ],
        ],
      ),
    );
  }
}

// ── Status card ─────────────────────────────────────────────────────────────

class _SyncStatusCard extends StatelessWidget {
  final SyncProvider sync;
  final AnimationController spinController;
  final ColorScheme cs;

  const _SyncStatusCard(
      {required this.sync,
      required this.spinController,
      required this.cs});

  @override
  Widget build(BuildContext context) {
    final (icon, label, color) = switch (sync.status) {
      SyncStatus.syncing => (Icons.sync_rounded, 'Syncing…', Colors.blue),
      SyncStatus.success => (
          Icons.cloud_done_rounded,
          'Up to date',
          Colors.green
        ),
      SyncStatus.error => (Icons.cloud_off_rounded, 'Sync failed', Colors.red),
      SyncStatus.idle => (
          Icons.cloud_outlined,
          sync.lastSyncedAt != null ? 'Last synced' : 'Not synced yet',
          cs.primary
        ),
    };

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.15), color.withValues(alpha: 0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: sync.status == SyncStatus.syncing
                ? RotationTransition(
                    turns: spinController,
                    child: Icon(Icons.sync_rounded, color: color, size: 24),
                  )
                : Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: color)),
                const SizedBox(height: 4),
                if (sync.lastSyncedAt != null)
                  Text(
                    _formatDateTime(sync.lastSyncedAt!),
                    style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurface.withValues(alpha: 0.5)),
                  )
                else
                  Text(
                    'Tap "Sync Now" to upload your data',
                    style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurface.withValues(alpha: 0.5)),
                  ),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${sync.pending.total} pending',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: color),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

// ── Pending card ─────────────────────────────────────────────────────────────

class _PendingCard extends StatelessWidget {
  final SyncProvider sync;
  final ColorScheme cs;
  const _PendingCard({required this.sync, required this.cs});

  @override
  Widget build(BuildContext context) {
    final rows = [
      (Icons.category_outlined, Colors.purple, 'Categories', sync.pending.categories),
      (Icons.warehouse_outlined, Colors.teal, 'Warehouses', sync.pending.warehouses),
      (Icons.inventory_2_outlined, Colors.blue, 'Products', sync.pending.products),
      (Icons.history_rounded, Colors.orange, 'Activities', sync.pending.activities),
    ];

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          for (int i = 0; i < rows.length; i++) ...[
            if (i > 0)
              Divider(
                  height: 1,
                  indent: 56,
                  color: cs.onSurface.withValues(alpha: 0.08)),
            _PendingRow(
              icon: rows[i].$1,
              color: rows[i].$2,
              label: rows[i].$3,
              count: rows[i].$4,
              cs: cs,
            ),
          ],
        ],
      ),
    );
  }
}

class _PendingRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final int count;
  final ColorScheme cs;
  const _PendingRow(
      {required this.icon,
      required this.color,
      required this.label,
      required this.count,
      required this.cs});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label,
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w500)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: count > 0
                  ? Colors.orange.withValues(alpha: 0.12)
                  : Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              count > 0 ? '$count pending' : 'Synced',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: count > 0 ? Colors.orange[700] : Colors.green[700],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Options card ─────────────────────────────────────────────────────────────

class _OptionsCard extends StatelessWidget {
  final SyncProvider sync;
  final bool isPro;
  final ColorScheme cs;
  const _OptionsCard(
      {required this.sync, required this.isPro, required this.cs});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child:
                  Icon(Icons.autorenew_rounded, color: cs.primary, size: 18),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Auto-Sync',
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w500)),
                  SizedBox(height: 2),
                  Text('Sync automatically after changes',
                      style:
                          TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
                ],
              ),
            ),
            Switch.adaptive(
              value: sync.autoSync,
              activeColor: cs.primary,
              onChanged: isPro
                  ? (v) => context.read<SyncProvider>().setAutoSync(v)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Pro upgrade banner ───────────────────────────────────────────────────────

class _ProUpgradeBanner extends StatelessWidget {
  final ColorScheme cs;
  const _ProUpgradeBanner({required this.cs});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
          context, MaterialPageRoute(builder: (_) => const ProfileScreen())),
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
                  Text('Pro feature',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15)),
                  Text('Upgrade to Pro to enable cloud sync',
                      style:
                          TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.white70),
          ],
        ),
      ),
    );
  }
}

// ── Error banner ─────────────────────────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: Colors.red[600], size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: Colors.red[700], fontSize: 13),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Section label ────────────────────────────────────────────────────────────

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
