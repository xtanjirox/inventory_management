import 'package:flutter/material.dart';

/// Centralized branded dialog & snackbar system.
/// All dialogs share the same visual identity: a top icon badge,
/// generous spacing, and brand-consistent buttons.
abstract class AppDialogs {
  // ── Colours ──────────────────────────────────────────────────────────────
  static const Color _primary = Color(0xFF1152D4);

  // ─────────────────────────────────────────────────────────────────────────
  // Generic info / action dialog
  // ─────────────────────────────────────────────────────────────────────────

  static Future<void> show({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String message,
    String confirmLabel = 'OK',
    VoidCallback? onConfirm,
    String? cancelLabel,
    VoidCallback? onCancel,
    bool destructive = false,
  }) {
    return showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (_) => _AppDialog(
        icon: icon,
        iconColor: iconColor,
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        onConfirm: onConfirm,
        cancelLabel: cancelLabel,
        onCancel: onCancel,
        destructive: destructive,
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Delete / destructive confirmation
  // ─────────────────────────────────────────────────────────────────────────

  static Future<void> confirmDelete({
    required BuildContext context,
    required String title,
    required String message,
    required VoidCallback onConfirm,
    String confirmLabel = 'Delete',
  }) {
    return show(
      context: context,
      icon: Icons.delete_outline_rounded,
      iconColor: Colors.red,
      title: title,
      message: message,
      confirmLabel: confirmLabel,
      onConfirm: onConfirm,
      cancelLabel: 'Cancel',
      destructive: true,
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Single text-input dialog
  // ─────────────────────────────────────────────────────────────────────────

  static Future<void> input({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    String? message,
    required String fieldLabel,
    String? initialValue,
    TextInputType keyboardType = TextInputType.text,
    required String confirmLabel,
    required void Function(String value) onConfirm,
    String cancelLabel = 'Cancel',
  }) {
    final ctrl = TextEditingController(text: initialValue);
    return showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (_) => _InputDialog(
        icon: icon,
        iconColor: iconColor,
        title: title,
        message: message,
        fieldLabel: fieldLabel,
        controller: ctrl,
        keyboardType: keyboardType,
        confirmLabel: confirmLabel,
        onConfirm: onConfirm,
        cancelLabel: cancelLabel,
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Pro upgrade dialog
  // ─────────────────────────────────────────────────────────────────────────

  static Future<void> showUpgrade({
    required BuildContext context,
    required String title,
    required String subtitle,
    required List<_FeatureItem> features,
    required String confirmLabel,
    required VoidCallback onConfirm,
  }) {
    return showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (_) => _UpgradeDialog(
        title: title,
        subtitle: subtitle,
        features: features,
        confirmLabel: confirmLabel,
        onConfirm: onConfirm,
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Change password dialog
  // ─────────────────────────────────────────────────────────────────────────

  static Future<void> changePassword({
    required BuildContext context,
    required Future<String?> Function({
      required String currentPassword,
      required String newPassword,
    }) onSave,
    required void Function(String? error) onResult,
  }) {
    return showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (_) => _ChangePasswordDialog(
        onSave: onSave,
        onResult: onResult,
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Branded SnackBar
  // ─────────────────────────────────────────────────────────────────────────

  static void snack(
    BuildContext context,
    String message, {
    bool error = false,
    bool success = false,
    IconData? icon,
  }) {
    final Color bg = error
        ? Colors.red[700]!
        : success
            ? Colors.green[700]!
            : _primary;
    final IconData ic = icon ??
        (error
            ? Icons.error_outline_rounded
            : success
                ? Icons.check_circle_outline_rounded
                : Icons.info_outline_rounded);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        backgroundColor: bg,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        content: Row(
          children: [
            Icon(ic, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
                child: Text(message,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500))),
          ],
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

// ── Feature item helper ─────────────────────────────────────────────────────

class _FeatureItem {
  final IconData icon;
  final String text;
  const _FeatureItem(this.icon, this.text);
}

List<_FeatureItem> kProFeatures = const [
  _FeatureItem(Icons.inventory_2_outlined, 'Unlimited products'),
  _FeatureItem(Icons.cloud_sync_outlined, 'Cloud synchronization'),
  _FeatureItem(Icons.bar_chart_outlined, 'Advanced analytics'),
  _FeatureItem(Icons.download_outlined, 'CSV & PDF export'),
  _FeatureItem(Icons.notifications_outlined, 'Inventory recap notifications'),
  _FeatureItem(Icons.support_agent_outlined, 'Priority support'),
];

// ── Shared header widget ─────────────────────────────────────────────────────

class _DialogIconBadge extends StatelessWidget {
  final IconData icon;
  final Color color;
  const _DialogIconBadge({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        shape: BoxShape.circle,
        border: Border.all(
          color: color.withValues(alpha: 0.25),
          width: 1.5,
        ),
      ),
      child: Icon(icon, color: color, size: 30),
    );
  }
}

// ── _AppDialog ───────────────────────────────────────────────────────────────

class _AppDialog extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String message;
  final String confirmLabel;
  final VoidCallback? onConfirm;
  final String? cancelLabel;
  final VoidCallback? onCancel;
  final bool destructive;

  const _AppDialog({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.message,
    required this.confirmLabel,
    this.onConfirm,
    this.cancelLabel,
    this.onCancel,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final confirmColor =
        destructive ? Colors.red[600]! : const Color(0xFF1152D4);

    return Dialog(
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 0,
      backgroundColor: Colors.white,
      insetPadding:
          const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _DialogIconBadge(icon: icon, color: iconColor),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0D1B3E)),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  height: 1.5),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  onConfirm?.call();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: confirmColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: Text(confirmLabel,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 15)),
              ),
            ),
            if (cancelLabel != null) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  onCancel?.call();
                },
                child: Text(
                  cancelLabel!,
                  style: TextStyle(
                      color: Colors.grey[600], fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── _InputDialog ─────────────────────────────────────────────────────────────

class _InputDialog extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? message;
  final String fieldLabel;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final String confirmLabel;
  final void Function(String) onConfirm;
  final String cancelLabel;

  const _InputDialog({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.message,
    required this.fieldLabel,
    required this.controller,
    required this.keyboardType,
    required this.confirmLabel,
    required this.onConfirm,
    required this.cancelLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 0,
      backgroundColor: Colors.white,
      insetPadding:
          const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _DialogIconBadge(icon: icon, color: iconColor),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0D1B3E)),
            ),
            if (message != null) ...[
              const SizedBox(height: 8),
              Text(
                message!,
                textAlign: TextAlign.center,
                style:
                    TextStyle(fontSize: 13, color: Colors.grey[600], height: 1.4),
              ),
            ],
            const SizedBox(height: 20),
            TextField(
              controller: controller,
              keyboardType: keyboardType,
              autofocus: true,
              decoration: InputDecoration(
                labelText: fieldLabel,
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide:
                      const BorderSide(color: Color(0xFF1152D4), width: 2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (controller.text.trim().isEmpty) return;
                  Navigator.pop(context);
                  onConfirm(controller.text.trim());
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1152D4),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: Text(confirmLabel,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 15)),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                cancelLabel,
                style: TextStyle(
                    color: Colors.grey[600], fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── _UpgradeDialog ───────────────────────────────────────────────────────────

class _UpgradeDialog extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<_FeatureItem> features;
  final String confirmLabel;
  final VoidCallback onConfirm;

  const _UpgradeDialog({
    required this.title,
    required this.subtitle,
    required this.features,
    required this.confirmLabel,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 0,
      backgroundColor: Colors.white,
      insetPadding:
          const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Gradient header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF7C3AED), Color(0xFF4F46E5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.workspace_premium,
                      color: Colors.white, size: 28),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.85)),
                ),
              ],
            ),
          ),
          // Features list
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
            child: Column(
              children: [
                ...features.map((f) => _ProFeatureRow(f)),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      onConfirm();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7C3AED),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: Text(confirmLabel,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 15)),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Maybe later',
                    style: TextStyle(
                        color: Colors.grey[600], fontWeight: FontWeight.w500),
                  ),
                ),
                const SizedBox(height: 4),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProFeatureRow extends StatelessWidget {
  final _FeatureItem item;
  const _ProFeatureRow(this.item);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFF7C3AED).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(item.icon,
                size: 16, color: const Color(0xFF7C3AED)),
          ),
          const SizedBox(width: 12),
          Text(
            item.text,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF0D1B3E)),
          ),
        ],
      ),
    );
  }
}

// ── _ChangePasswordDialog ─────────────────────────────────────────────────────

class _ChangePasswordDialog extends StatefulWidget {
  final Future<String?> Function({
    required String currentPassword,
    required String newPassword,
  }) onSave;
  final void Function(String? error) onResult;

  const _ChangePasswordDialog(
      {required this.onSave, required this.onResult});

  @override
  State<_ChangePasswordDialog> createState() =>
      _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _loading = false;
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 0,
      backgroundColor: Colors.white,
      insetPadding:
          const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _DialogIconBadge(
                  icon: Icons.lock_outline_rounded,
                  color: const Color(0xFF1152D4)),
              const SizedBox(height: 16),
              const Text(
                'Change Password',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0D1B3E)),
              ),
              const SizedBox(height: 4),
              Text('Keep your account secure',
                  style:
                      TextStyle(fontSize: 13, color: Colors.grey[600])),
              const SizedBox(height: 20),
              _PasswordField(
                controller: _currentCtrl,
                label: 'Current Password',
                obscure: _obscureCurrent,
                onToggle: () =>
                    setState(() => _obscureCurrent = !_obscureCurrent),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              _PasswordField(
                controller: _newCtrl,
                label: 'New Password',
                obscure: _obscureNew,
                onToggle: () =>
                    setState(() => _obscureNew = !_obscureNew),
                validator: (v) =>
                    (v == null || v.length < 6) ? 'Min 6 characters' : null,
              ),
              const SizedBox(height: 12),
              _PasswordField(
                controller: _confirmCtrl,
                label: 'Confirm New Password',
                obscure: _obscureConfirm,
                onToggle: () =>
                    setState(() => _obscureConfirm = !_obscureConfirm),
                validator: (v) =>
                    v != _newCtrl.text ? 'Passwords do not match' : null,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading
                      ? null
                      : () async {
                          if (!_formKey.currentState!.validate()) return;
                          setState(() => _loading = true);
                          final error = await widget.onSave(
                            currentPassword: _currentCtrl.text,
                            newPassword: _newCtrl.text,
                          );
                          if (mounted) {
                            Navigator.pop(context);
                            widget.onResult(error);
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1152D4),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Update Password',
                          style: TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 15)),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel',
                    style: TextStyle(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PasswordField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool obscure;
  final VoidCallback onToggle;
  final String? Function(String?) validator;

  const _PasswordField({
    required this.controller,
    required this.label,
    required this.obscure,
    required this.onToggle,
    required this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: Color(0xFF1152D4), width: 2),
        ),
        suffixIcon: IconButton(
          icon: Icon(obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              size: 20, color: Colors.grey[500]),
          onPressed: onToggle,
        ),
      ),
    );
  }
}
