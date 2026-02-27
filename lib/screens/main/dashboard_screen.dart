import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/activity.dart';
import '../../models/product_variant.dart';
import '../../providers/auth_provider.dart';
import '../../providers/inventory_provider.dart';
import '../../providers/sync_provider.dart';
import '../../widgets/ad_banner.dart';
import '../settings/cloud_sync_settings_screen.dart';
import '../product/low_stock_screen.dart';
import '../product/product_details_screen.dart';
import '../product/product_list_screen.dart';
import '../settings/notification_settings_screen.dart';
import '../profile/profile_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final inventory = Provider.of<InventoryProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.currentUser;

    final totalProducts = inventory.products.length;
    final lowStockProducts = inventory.lowStockProducts;
    final totalValue = inventory.products
        .fold<double>(0, (sum, p) => sum + (p.price * inventory.effectiveStock(p)));
    final categoryCount = inventory.categories.length;
    final currency = user?.currency ?? 'USD';

    final initials = (user?.name ?? 'U')
        .trim()
        .split(' ')
        .take(2)
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
        .join();

    final cs = Theme.of(context).colorScheme;
    final surface = cs.surface;
    final scaffoldBg = Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: scaffoldBg,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hello, ${user?.name.split(' ').first ?? 'there'} 👋',
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              'Here\'s your inventory today',
              style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.5)),
            ),
          ],
        ),
        actions: [
          if (auth.isPro) _SyncStatusButton(cs: cs),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const NotificationSettingsScreen()),
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            ),
            child: CircleAvatar(
              radius: 18,
              backgroundColor:
                  Theme.of(context).colorScheme.primary,
              child: Text(
                initials,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13),
              ),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Stats row ──────────────────────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          title: 'Products',
                          value: totalProducts.toString(),
                          icon: Icons.inventory_2_outlined,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          title: 'Low Stock',
                          value: lowStockProducts.length.toString(),
                          icon: Icons.warning_amber_outlined,
                          color: lowStockProducts.isNotEmpty
                              ? Colors.red
                              : Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          title: 'Total Value',
                          value: '$currency ${totalValue.toStringAsFixed(0)}',
                          icon: Icons.attach_money,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          title: 'Categories',
                          value: categoryCount.toString(),
                          icon: Icons.category_outlined,
                          color: Colors.purple,
                        ),
                      ),
                    ],
                  ),

                  // ── Low stock alerts ────────────────────────────────────
                  if (lowStockProducts.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _SectionHeader(
                      title: 'Low Stock Alerts',
                      onViewAll: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const LowStockScreen()),
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${lowStockProducts.length} items',
                          style: TextStyle(
                              color: Colors.red[700],
                              fontSize: 12,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: surface,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          ...lowStockProducts
                              .take(3)
                              .map((p) => _LowStockTile(
                                    product: p,
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ProductDetailsScreen(
                                            productId: p.id),
                                      ),
                                    ),
                                  )),
                          if (lowStockProducts.length > 3)
                            InkWell(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        const LowStockScreen()),
                              ),
                              borderRadius: const BorderRadius.vertical(
                                  bottom: Radius.circular(16)),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 12),
                                decoration: BoxDecoration(
                                  color: Colors.red[50],
                                  borderRadius:
                                      const BorderRadius.vertical(
                                          bottom: Radius.circular(16)),
                                ),
                                child: Center(
                                  child: Text(
                                    'View all ${lowStockProducts.length} alerts',
                                    style: TextStyle(
                                        color: Colors.red[700],
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],

                  // ── Recent products ─────────────────────────────────────
                  const SizedBox(height: 24),
                  _SectionHeader(
                    title: 'Recent Products',
                    onViewAll: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const ProductListScreen()),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (inventory.products.isEmpty)
                    const _EmptyState(
                      icon: Icons.inventory_2_outlined,
                      message: 'No products yet',
                    )
                  else
                    Container(
                      decoration: BoxDecoration(
                        color: surface,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: inventory.products.length > 5
                            ? 5
                            : inventory.products.length,
                        separatorBuilder: (_, __) => const Divider(
                            height: 1, indent: 72),
                        itemBuilder: (context, index) {
                          final product = inventory.products[index];
                          final isLow = inventory.isProductLowStock(product);
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 4),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ProductDetailsScreen(
                                    productId: product.id),
                              ),
                            ),
                            leading: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                                image: product.imageUrl != null
                                    ? DecorationImage(
                                        image:
                                            NetworkImage(product.imageUrl!),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                              ),
                              child: product.imageUrl == null
                                  ? Icon(
                                      Icons.inventory_2,
                                      size: 20,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary,
                                    )
                                  : null,
                            ),
                            title: Text(product.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14)),
                            subtitle: Text('SKU: ${product.sku}',
                                style: const TextStyle(fontSize: 12)),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${inventory.effectiveStock(product)} units',
                                  style: TextStyle(
                                    color: isLow
                                        ? Colors.red
                                        : Colors.green[700],
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                if (isLow)
                                  Text(
                                    'Low stock',
                                    style: TextStyle(
                                        color: Colors.red[400],
                                        fontSize: 10),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),

                  // ── Recent activities ───────────────────────────────────
                  const SizedBox(height: 24),
                  _SectionHeader(
                    title: 'Recent Activity',
                    onViewAll: null,
                  ),
                  const SizedBox(height: 8),
                  if (inventory.recentActivities.isEmpty)
                    const _EmptyState(
                      icon: Icons.history,
                      message: 'No activity yet',
                    )
                  else
                    Container(
                      decoration: BoxDecoration(
                        color: surface,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount:
                            inventory.recentActivities.length > 8
                                ? 8
                                : inventory.recentActivities.length,
                        separatorBuilder: (_, __) =>
                            const Divider(height: 1, indent: 60),
                        itemBuilder: (context, index) {
                          final act =
                              inventory.recentActivities[index];
                          return _ActivityTile(activity: act);
                        },
                      ),
                    ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          const AdBanner(),
        ],
      ),
    );
  }
}

// ── Section header ─────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onViewAll;
  final Widget? trailing;

  const _SectionHeader({
    required this.title,
    required this.onViewAll,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Text(
              title,
              style: const TextStyle(
                  fontSize: 17, fontWeight: FontWeight.bold),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 8),
              trailing!,
            ],
          ],
        ),
        if (onViewAll != null)
          TextButton(
            onPressed: onViewAll,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('See All'),
          ),
      ],
    );
  }
}

// ── Stat card ──────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surface;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                fontSize: 12),
          ),
        ],
      ),
    );
  }
}

// ── Low stock tile ──────────────────────────────────────────────────────────

class _LowStockTile extends StatelessWidget {
  final dynamic product;
  final VoidCallback onTap;
  const _LowStockTile({required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final variants = ProductVariant.decodeList(product.variantsJson as String?);
    final hasVariants = variants.isNotEmpty;

    String subtitle;
    bool isOutOfStock;

    if (hasVariants) {
      final lowVariants = variants
          .where((v) => v.stock <= (product.lowStockThreshold as int))
          .toList();
      isOutOfStock = lowVariants.every((v) => v.stock == 0);
      if (isOutOfStock) {
        subtitle = 'Out of stock in: ${lowVariants.map((v) => v.name).join(', ')}';
      } else {
        subtitle = lowVariants
            .map((v) => '${v.name}: ${v.stock} left')
            .join(' · ');
      }
    } else {
      isOutOfStock = (product.stock as int) == 0;
      subtitle = isOutOfStock
          ? 'Out of stock'
          : '${product.stock} left · threshold ${product.lowStockThreshold}';
    }

    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      onTap: onTap,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isOutOfStock
              ? Colors.red.withValues(alpha: 0.1)
              : Colors.orange.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          isOutOfStock
              ? Icons.remove_shopping_cart_outlined
              : Icons.warning_amber_rounded,
          size: 20,
          color: isOutOfStock ? Colors.red : Colors.orange[700],
        ),
      ),
      title: Text(product.name,
          style: const TextStyle(
              fontWeight: FontWeight.w600, fontSize: 14)),
      subtitle: Text(
        subtitle,
        style: TextStyle(
            fontSize: 12,
            color: isOutOfStock ? Colors.red[700] : Colors.orange[700]),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: const Icon(Icons.chevron_right, size: 18),
    );
  }
}

// ── Activity tile ───────────────────────────────────────────────────────────

class _ActivityTile extends StatelessWidget {
  final Activity activity;
  const _ActivityTile({required this.activity});

  @override
  Widget build(BuildContext context) {
    final info = _activityInfo(activity.type);
    final qty = activity.quantityChange;
    final qtyText = qty != null
        ? (qty > 0 ? '+$qty units' : '$qty units')
        : null;

    final diff = DateTime.now().difference(activity.timestamp);
    final timeAgo = diff.inMinutes < 1
        ? 'just now'
        : diff.inHours < 1
            ? '${diff.inMinutes}m ago'
            : diff.inDays < 1
                ? '${diff.inHours}h ago'
                : diff.inDays == 1
                    ? 'yesterday'
                    : '${diff.inDays}d ago';

    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: info.color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(info.icon, size: 18, color: info.color),
      ),
      title: Text(
        activity.productName,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        info.label,
        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (qtyText != null)
            Text(
              qtyText,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: (qty ?? 0) >= 0 ? Colors.green[700] : Colors.red,
              ),
            ),
          Text(
            timeAgo,
            style: TextStyle(fontSize: 10, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  _ActivityDisplayInfo _activityInfo(ActivityType type) {
    switch (type) {
      case ActivityType.productAdded:
        return _ActivityDisplayInfo(
            Icons.add_box_outlined, Colors.blue, 'Product added');
      case ActivityType.productDeleted:
        return _ActivityDisplayInfo(
            Icons.delete_outline, Colors.red, 'Product deleted');
      case ActivityType.restock:
        return _ActivityDisplayInfo(
            Icons.add_shopping_cart, Colors.green, 'Restocked');
      case ActivityType.stockAdjustment:
        return _ActivityDisplayInfo(
            Icons.tune, Colors.blueGrey, 'Stock adjusted');
      case ActivityType.returnToStock:
        return _ActivityDisplayInfo(
            Icons.replay, Colors.teal, 'Return to stock');
      case ActivityType.damagedArticle:
        return _ActivityDisplayInfo(
            Icons.report_outlined, Colors.orange, 'Damaged article');
      case ActivityType.sale:
        return _ActivityDisplayInfo(
            Icons.point_of_sale, Colors.purple, 'Sale');
    }
  }
}

class _ActivityDisplayInfo {
  final IconData icon;
  final Color color;
  final String label;
  const _ActivityDisplayInfo(this.icon, this.color, this.label);
}

// ── Sync status button (Pro only) ────────────────────────────────────────────

class _SyncStatusButton extends StatefulWidget {
  final ColorScheme cs;
  const _SyncStatusButton({required this.cs});

  @override
  State<_SyncStatusButton> createState() => _SyncStatusButtonState();
}

class _SyncStatusButtonState extends State<_SyncStatusButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _spin;

  @override
  void initState() {
    super.initState();
    _spin = AnimationController(
        vsync: this, duration: const Duration(seconds: 1));
  }

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sync = context.watch<SyncProvider>();

    if (sync.isSyncing) {
      _spin.repeat();
    } else {
      _spin.stop();
      _spin.reset();
    }

    final (icon, color) = switch (sync.status) {
      SyncStatus.syncing => (Icons.sync_rounded, Colors.blue),
      SyncStatus.success => (Icons.cloud_done_outlined, Colors.green),
      SyncStatus.error   => (Icons.cloud_off_rounded, Colors.red),
      SyncStatus.idle    => (Icons.cloud_upload_outlined, widget.cs.onSurface.withValues(alpha: 0.6)),
    };

    final pendingCount = sync.pending.total;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          tooltip: 'Cloud Sync',
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => const CloudSyncSettingsScreen()),
          ),
          icon: sync.isSyncing
              ? RotationTransition(
                  turns: _spin,
                  child: Icon(Icons.sync_rounded, color: color),
                )
              : Icon(icon, color: color),
        ),
        if (pendingCount > 0 && !sync.isSyncing)
          Positioned(
            right: 6,
            top: 6,
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: Colors.orange,
                shape: BoxShape.circle,
                border: Border.all(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    width: 1.5),
              ),
              child: Center(
                child: Text(
                  pendingCount > 9 ? '9+' : '$pendingCount',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ── Empty state ─────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surface;
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, size: 36, color: cs.onSurface.withValues(alpha: 0.2)),
          const SizedBox(height: 8),
          Text(message,
              style: TextStyle(
                  color: cs.onSurface.withValues(alpha: 0.4), fontSize: 13)),
        ],
      ),
    );
  }
}
