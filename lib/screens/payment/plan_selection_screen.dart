import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/user_profile.dart';
import '../../providers/auth_provider.dart';
import '../main/main_screen.dart';

class PlanSelectionScreen extends StatefulWidget {
  const PlanSelectionScreen({super.key});

  @override
  State<PlanSelectionScreen> createState() => _PlanSelectionScreenState();
}

class _PlanSelectionScreenState extends State<PlanSelectionScreen> {
  AppPlan _selected = AppPlan.normal;
  bool _isProcessing = false;

  Future<void> _continue() async {
    setState(() => _isProcessing = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);

    if (_selected == AppPlan.pro) {
      final confirmed = await _showPaymentSheet();
      if (!confirmed) {
        setState(() => _isProcessing = false);
        return;
      }
      await auth.upgradeToPro();
    }

    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const MainScreen()),
      (route) => false,
    );
  }

  Future<bool> _showPaymentSheet() async {
    return await showModalBottomSheet<bool>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => const _PaymentSheet(),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    const Icon(Icons.workspace_premium,
                        size: 56, color: Color(0xFF7C3AED)),
                    const SizedBox(height: 16),
                    const Text(
                      'Choose your plan',
                      style: TextStyle(
                          fontSize: 26, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Start free or unlock everything with Pro',
                      style: TextStyle(color: Colors.grey[600], fontSize: 15),
                    ),
                    const SizedBox(height: 32),

                    // Free plan card
                    _PlanCard(
                      plan: AppPlan.normal,
                      selected: _selected == AppPlan.normal,
                      onTap: () => setState(() => _selected = AppPlan.normal),
                      title: 'Free',
                      price: '\$0',
                      period: 'forever',
                      color: Colors.grey[700]!,
                      features: const [
                        _Feature('Up to 50 products', true),
                        _Feature('Basic inventory management', true),
                        _Feature('Barcode scanning', true),
                        _Feature('Includes ads', false),
                        _Feature('Cloud sync', false),
                        _Feature('Inventory recap notifications', false),
                        _Feature('Advanced analytics', false),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Pro plan card
                    _PlanCard(
                      plan: AppPlan.pro,
                      selected: _selected == AppPlan.pro,
                      onTap: () => setState(() => _selected = AppPlan.pro),
                      title: 'Pro',
                      price: '\$9.99',
                      period: 'per month',
                      color: const Color(0xFF7C3AED),
                      badge: 'RECOMMENDED',
                      features: const [
                        _Feature('Unlimited products', true),
                        _Feature('Full inventory management', true),
                        _Feature('Barcode scanning', true),
                        _Feature('No ads', true),
                        _Feature('Cloud sync', true),
                        _Feature('Recap notifications', true),
                        _Feature('Advanced analytics', true),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _isProcessing ? null : _continue,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _selected == AppPlan.pro
                            ? const Color(0xFF7C3AED)
                            : Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: _isProcessing
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : Text(
                              _selected == AppPlan.pro
                                  ? 'Get Pro — \$9.99/mo'
                                  : 'Continue for Free',
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                    ),
                  ),
                  if (_selected == AppPlan.pro)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(
                        'Cancel anytime · Secure payment',
                        style:
                            TextStyle(color: Colors.grey[500], fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Feature {
  final String label;
  final bool included;
  const _Feature(this.label, this.included);
}

class _PlanCard extends StatelessWidget {
  final AppPlan plan;
  final bool selected;
  final VoidCallback onTap;
  final String title;
  final String price;
  final String period;
  final Color color;
  final String? badge;
  final List<_Feature> features;

  const _PlanCard({
    required this.plan,
    required this.selected,
    required this.onTap,
    required this.title,
    required this.price,
    required this.period,
    required this.color,
    this.badge,
    required this.features,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? color : Colors.grey[200]!,
            width: selected ? 2.5 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.15),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  )
                ]
              : [],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: color),
                    ),
                    if (badge != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          badge!,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ],
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      price,
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: color),
                    ),
                    const SizedBox(width: 4),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Text(
                        period,
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey[500]),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...features.map((f) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Icon(
                        f.included ? Icons.check_circle : Icons.cancel_outlined,
                        size: 18,
                        color: f.included ? color : Colors.grey[400],
                      ),
                      const SizedBox(width: 10),
                      Text(
                        f.label,
                        style: TextStyle(
                          fontSize: 14,
                          color: f.included
                              ? const Color(0xFF1F2937)
                              : Colors.grey[400],
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

// Mock payment bottom sheet
class _PaymentSheet extends StatefulWidget {
  const _PaymentSheet();

  @override
  State<_PaymentSheet> createState() => _PaymentSheetState();
}

class _PaymentSheetState extends State<_PaymentSheet> {
  final _cardController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  final _nameController = TextEditingController();
  bool _processing = false;

  @override
  void dispose() {
    _cardController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pay() async {
    setState(() => _processing = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Payment Details',
                style:
                    TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('\$9.99/month · Cancel anytime',
                style: TextStyle(color: Colors.grey[600], fontSize: 13)),
            const SizedBox(height: 24),
            TextField(
              controller: _nameController,
              decoration: _inputDec('Cardholder Name', Icons.person_outline),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _cardController,
              keyboardType: TextInputType.number,
              decoration: _inputDec('Card Number', Icons.credit_card),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _expiryController,
                    decoration: _inputDec('MM/YY', Icons.date_range),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _cvvController,
                    keyboardType: TextInputType.number,
                    decoration: _inputDec('CVV', Icons.lock_outline),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _processing ? null : _pay,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C3AED),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: _processing
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Pay \$9.99',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock, size: 14, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text('Secured with 256-bit SSL encryption',
                    style:
                        TextStyle(fontSize: 11, color: Colors.grey[500])),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDec(String label, IconData icon) => InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      );
}
