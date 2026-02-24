import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:provider/provider.dart';

import '../../providers/inventory_provider.dart';
import '../../widgets/app_dialogs.dart';
import '../product/product_details_screen.dart';
import '../product/add_product_screen.dart';
import '../../models/models.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  String _scanBarcode = 'Unknown';

  Future<void> scanBarcodeNormal(BuildContext context, InventoryProvider inventory) async {
    String barcodeScanRes;
    try {
      barcodeScanRes = await FlutterBarcodeScanner.scanBarcode(
          '#1152D4', 'Cancel', true, ScanMode.BARCODE);
    } on PlatformException {
      barcodeScanRes = 'Failed to get platform version.';
    }

    if (!mounted) return;

    setState(() {
      _scanBarcode = barcodeScanRes;
    });

    if (barcodeScanRes != '-1' && barcodeScanRes != 'Unknown') {
      final product = inventory.getProductById(barcodeScanRes);
      
      if (product != null) {
        // Product found, go to details
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductDetailsScreen(productId: product.id),
            ),
          );
        }
      } else {
        // Product not found, offer to add
        if (mounted) {
          _showUnknownBarcodeDialog(context, barcodeScanRes);
        }
      }
    }
  }

  void _showUnknownBarcodeDialog(BuildContext context, String barcode) {
    AppDialogs.show(
      context: context,
      icon: Icons.qr_code_2_outlined,
      iconColor: const Color(0xFF1152D4),
      title: 'Product Not Found',
      message: 'No product matches barcode\n"$barcode"\n\nWould you like to add it to your inventory?',
      confirmLabel: 'Add Product',
      onConfirm: () {
        final dummyProduct = Product(
          id: '',
          name: '',
          description: '',
          categoryId: '',
          warehouseId: '',
          sku: barcode,
          price: 0,
          stock: 0,
          lowStockThreshold: 10,
        );
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AddProductScreen(productToEdit: dummyProduct),
          ),
        );
      },
      cancelLabel: 'Dismiss',
    );
  }

  @override
  Widget build(BuildContext context) {
    final inventory = Provider.of<InventoryProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Scanner',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.qr_code_scanner,
                  size: 100,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Scan a Barcode',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Point your camera at a barcode to quickly find or add a product to your inventory.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => scanBarcodeNormal(context, inventory),
                  icon: const Icon(Icons.camera_alt_outlined),
                  label: const Text('Start Scanning'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              if (_scanBarcode != 'Unknown' && _scanBarcode != '-1')
                Text(
                  'Last scanned: $_scanBarcode',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
