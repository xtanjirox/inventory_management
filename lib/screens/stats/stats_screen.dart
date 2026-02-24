import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';

import '../../providers/inventory_provider.dart';
import '../../providers/auth_provider.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  String _selectedPeriod = 'This Week';
  final List<String> _periods = ['Today', 'This Week', 'This Month', 'This Year'];

  @override
  Widget build(BuildContext context) {
    final inventory = Provider.of<InventoryProvider>(context);
    final user = Provider.of<AuthProvider>(context).currentUser;
    final currency = user?.currency ?? 'USD';
    final primary = Theme.of(context).colorScheme.primary;
    final totalValue = inventory.products.fold<double>(0, (sum, p) => sum + (p.price * p.stock));
    final totalItems = inventory.products.fold<int>(0, (sum, p) => sum + p.stock);

    final lowStockCount = inventory.lowStockProducts.length;
    final sortedProducts = List.of(inventory.products)
      ..sort((a, b) => (b.price * b.stock).compareTo(a.price * a.stock));
    final top5 = sortedProducts.take(5).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download_outlined),
            onPressed: () {},
            tooltip: 'Export',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Period selector ───────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Overview',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold,
                        color: Color(0xFF0D1B3E))),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: const Border.fromBorderSide(
                        BorderSide(color: Color(0xFFE2E8F0))),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedPeriod,
                      isDense: true,
                      icon: Icon(Icons.keyboard_arrow_down_rounded,
                          color: primary, size: 18),
                      style: TextStyle(
                          color: primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13),
                      items: _periods
                          .map((v) => DropdownMenuItem(
                              value: v, child: Text(v)))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => _selectedPeriod = v);
                      },
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── KPI cards row ─────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: _KpiCard(
                    icon: Icons.attach_money_rounded,
                    iconColor: Colors.green,
                    title: 'Total Value',
                    value: '$currency ${totalValue.toStringAsFixed(0)}',
                    trend: '+15%',
                    isPositive: true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _KpiCard(
                    icon: Icons.inventory_2_outlined,
                    iconColor: primary,
                    title: 'Total Items',
                    value: totalItems.toString(),
                    trend: '+8%',
                    isPositive: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _KpiCard(
                    icon: Icons.warning_amber_rounded,
                    iconColor: Colors.orange,
                    title: 'Low Stock',
                    value: lowStockCount.toString(),
                    trend: lowStockCount > 0 ? 'Needs attention' : 'All good',
                    isPositive: lowStockCount == 0,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _KpiCard(
                    icon: Icons.category_outlined,
                    iconColor: const Color(0xFF7C3AED),
                    title: 'Categories',
                    value: inventory.categories.length.toString(),
                    trend: 'Active',
                    isPositive: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ── Chart ─────────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2))
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Stock Value Trend',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0D1B3E))),
                  const SizedBox(height: 4),
                  Text('Weekly overview',
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey[500])),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 180,
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: 100,
                        barTouchData: BarTouchData(enabled: false),
                        titlesData: FlTitlesData(
                          show: true,
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                const days = [
                                  'Mon', 'Tue', 'Wed', 'Thu',
                                  'Fri', 'Sat', 'Sun'
                                ];
                                return Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Text(
                                    days[value.toInt() % days.length],
                                    style: const TextStyle(
                                        color: Color(0xFF94A3B8),
                                        fontSize: 11),
                                  ),
                                );
                              },
                            ),
                          ),
                          leftTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                        ),
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          horizontalInterval: 25,
                          getDrawingHorizontalLine: (_) => FlLine(
                            color: const Color(0xFFF1F5F9),
                            strokeWidth: 1,
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        barGroups: [
                          _buildBarGroup(0, 45),
                          _buildBarGroup(1, 60),
                          _buildBarGroup(2, 85),
                          _buildBarGroup(3, 50),
                          _buildBarGroup(4, 70),
                          _buildBarGroup(5, 95),
                          _buildBarGroup(6, 65),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Top products ──────────────────────────────────────────────
            const Text('Top Products by Value',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0D1B3E))),
            const SizedBox(height: 12),
            if (inventory.products.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text('No products yet',
                      style: TextStyle(color: Colors.grey[500])),
                ),
              )
            else
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2))
                  ],
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: top5.length,
                  separatorBuilder: (_, __) => const Divider(
                      height: 1, indent: 68, color: Color(0xFFF1F5F9)),
                  itemBuilder: (context, index) {
                    final product = top5[index];
                    final value = product.price * product.stock;
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      leading: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: product.imageUrl == null
                            ? Icon(Icons.inventory_2_outlined,
                                color: primary.withValues(alpha: 0.6),
                                size: 20)
                            : ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.network(product.imageUrl!,
                                    fit: BoxFit.cover),
                              ),
                      ),
                      title: Text(product.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 14)),
                      subtitle: Text('${product.stock} units',
                          style: TextStyle(
                              color: Colors.grey[500], fontSize: 12)),
                      trailing: Text(
                        '$currency ${value.toStringAsFixed(2)}',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: primary),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  BarChartGroupData _buildBarGroup(int x, double y) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          width: 18,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(6),
            topRight: Radius.circular(6),
          ),
        ),
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String value;
  final String trend;
  final bool isPositive;

  const _KpiCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
    required this.trend,
    required this.isPositive,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(height: 12),
          Text(value,
              style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0D1B3E))),
          const SizedBox(height: 2),
          Text(title,
              style:
                  TextStyle(fontSize: 12, color: Colors.grey[500])),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(
                isPositive
                    ? Icons.trending_up_rounded
                    : Icons.trending_down_rounded,
                size: 12,
                color: isPositive ? Colors.green[600] : Colors.orange[700],
              ),
              const SizedBox(width: 3),
              Text(
                trend,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isPositive ? Colors.green[600] : Colors.orange[700],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
