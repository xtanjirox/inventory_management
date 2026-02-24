import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:flutter/services.dart';

import '../../models/models.dart';
import '../../providers/auth_provider.dart';
import '../../providers/inventory_provider.dart';
import '../../utils/plan_limits.dart';
import '../../widgets/app_dialogs.dart';
import '../payment/plan_selection_screen.dart';

class AddProductScreen extends StatefulWidget {
  final Product? productToEdit; // If null, we are adding a new product

  const AddProductScreen({super.key, this.productToEdit});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _skuController;
  late TextEditingController _priceController;
  late TextEditingController _stockController;
  late TextEditingController _lowStockController;
  
  String? _selectedCategoryId;
  String? _selectedWarehouseId;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.productToEdit?.name ?? '');
    _descriptionController = TextEditingController(text: widget.productToEdit?.description ?? '');
    _skuController = TextEditingController(text: widget.productToEdit?.sku ?? '');
    _priceController = TextEditingController(text: widget.productToEdit?.price.toString() ?? '');
    _stockController = TextEditingController(text: widget.productToEdit?.stock.toString() ?? '');
    _lowStockController = TextEditingController(text: widget.productToEdit?.lowStockThreshold.toString() ?? '10');
    
    _selectedCategoryId = widget.productToEdit?.categoryId;
    _selectedWarehouseId = widget.productToEdit?.warehouseId;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _skuController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _lowStockController.dispose();
    super.dispose();
  }

  Future<void> _scanBarcode() async {
    String barcodeScanRes;
    try {
      barcodeScanRes = await FlutterBarcodeScanner.scanBarcode(
          '#1152D4', 'Cancel', true, ScanMode.BARCODE);
    } on PlatformException {
      barcodeScanRes = 'Failed to get platform version.';
    }

    if (!mounted) return;

    if (barcodeScanRes != '-1' && barcodeScanRes != 'Unknown') {
      setState(() {
        _skuController.text = barcodeScanRes;
      });
    }
  }

  void _showAddCategoryDialog(BuildContext context, InventoryProvider inventory) {
    AppDialogs.input(
      context: context,
      icon: Icons.category_outlined,
      iconColor: const Color(0xFF1152D4),
      title: 'New Category',
      message: 'Give your category a clear, descriptive name.',
      fieldLabel: 'Category Name',
      confirmLabel: 'Create',
      onConfirm: (name) async {
        await inventory.addCategory(name);
        final newCat = inventory.categories.last;
        if (mounted) {
          setState(() => _selectedCategoryId = newCat.id);
        }
      },
    );
  }

  void _showPlanLimitDialog() {
    AppDialogs.showUpgrade(
      context: context,
      title: 'Product Limit Reached',
      subtitle: 'You have reached the ${PlanLimits.normalMaxProducts}-product limit on the Free plan.',
      features: kProFeatures,
      confirmLabel: 'Upgrade to Pro',
      onConfirm: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PlanSelectionScreen()),
      ),
    );
  }

  Future<void> _saveProduct(InventoryProvider inventory) async {
    if (_formKey.currentState!.validate()) {
      if (_selectedCategoryId == null || _selectedWarehouseId == null) {
        AppDialogs.snack(context, 'Please select a category and a warehouse', error: true);
        return;
      }

      final isEdit = widget.productToEdit != null &&
          widget.productToEdit!.id.isNotEmpty;

      // Plan limit check — only for new products
      if (!isEdit) {
        final auth = Provider.of<AuthProvider>(context, listen: false);
        if (!PlanLimits.canAddProduct(auth.plan, inventory.products.length)) {
          _showPlanLimitDialog();
          return;
        }
      }

      final product = Product(
        id: isEdit ? widget.productToEdit!.id : null,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        categoryId: _selectedCategoryId!,
        warehouseId: _selectedWarehouseId!,
        sku: _skuController.text.trim(),
        price: double.tryParse(_priceController.text) ?? 0.0,
        stock: int.tryParse(_stockController.text) ?? 0,
        lowStockThreshold: int.tryParse(_lowStockController.text) ?? 10,
        imageUrl: widget.productToEdit?.imageUrl,
      );

      if (isEdit) {
        await inventory.updateProduct(product);
        if (mounted) AppDialogs.snack(context, 'Product updated successfully', success: true);
      } else {
        await inventory.addProduct(product);
        if (mounted) AppDialogs.snack(context, 'Product added successfully', success: true);
      }

      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final inventory = Provider.of<InventoryProvider>(context);

    // Ensure selected category exists in list (or set to first)
    if (_selectedCategoryId != null && !inventory.categories.any((c) => c.id == _selectedCategoryId)) {
      _selectedCategoryId = inventory.categories.isNotEmpty ? inventory.categories.first.id : null;
    } else if (_selectedCategoryId == null && inventory.categories.isNotEmpty) {
      _selectedCategoryId = inventory.categories.first.id;
    }

    // Ensure selected warehouse exists in list (or set to first)
    if (_selectedWarehouseId != null && !inventory.warehouses.any((w) => w.id == _selectedWarehouseId)) {
      _selectedWarehouseId = inventory.warehouses.isNotEmpty ? inventory.warehouses.first.id : null;
    } else if (_selectedWarehouseId == null && inventory.warehouses.isNotEmpty) {
      _selectedWarehouseId = inventory.warehouses.first.id;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.productToEdit == null ? 'Add New Product' : 'Edit Product',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: _scanBarcode,
            tooltip: 'Scan Barcode',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Stack(
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.grey[300]!,
                          style: BorderStyle.solid,
                        ),
                        image: widget.productToEdit?.imageUrl != null
                            ? DecorationImage(
                                image: NetworkImage(widget.productToEdit!.imageUrl!),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: widget.productToEdit?.imageUrl == null
                          ? const Icon(
                              Icons.add_a_photo_outlined,
                              size: 40,
                              color: Colors.grey,
                            )
                          : null,
                    ),
                    Positioned(
                      right: -10,
                      bottom: -10,
                      child: IconButton(
                        onPressed: () {},
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.edit,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Basic Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Product Name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a product name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedCategoryId,
                      decoration: InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: inventory.categories.map((Category category) {
                        return DropdownMenuItem(
                          value: category.id,
                          child: Text(category.name),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _selectedCategoryId = newValue;
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => _showAddCategoryDialog(context, inventory),
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.add,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedWarehouseId,
                decoration: InputDecoration(
                  labelText: 'Warehouse',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: inventory.warehouses.map((Warehouse warehouse) {
                  return DropdownMenuItem(
                    value: warehouse.id,
                    child: Text(warehouse.name),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedWarehouseId = newValue;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Inventory Details',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _skuController,
                      decoration: InputDecoration(
                        labelText: 'SKU / Barcode',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter SKU/Barcode';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _scanBarcode,
                    icon: Icon(
                      Icons.qr_code_scanner,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _priceController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Price',
                        prefixText: '${Provider.of<AuthProvider>(context, listen: false).currentUser?.currency ?? 'USD'} ',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Required';
                        if (double.tryParse(value) == null) return 'Invalid';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _stockController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Stock Quantity',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Required';
                        if (int.tryParse(value) == null) return 'Invalid';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _lowStockController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Low Stock Alert Threshold',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Required';
                  if (int.tryParse(value) == null) return 'Invalid';
                  return null;
                },
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async => _saveProduct(inventory),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    widget.productToEdit == null ? 'Save Product' : 'Update Product',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
