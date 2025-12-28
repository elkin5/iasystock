import 'package:flutter/material.dart';

import '../../config/get_it_config.dart';
import '../../models/menu/product_model.dart';
import '../../models/menu/warehouse_model.dart';
import '../../models/product_stock/product_stock_model.dart';
import '../../services/product_stock/product_stock_service.dart';
import '../menu/secure_network_image.dart';

class ProductStockEntryResult {
  final ProductModel product;
  final int quantity;
  final double entryPrice;
  final double salePrice;
  final int warehouseId;
  final DateTime entryDate;

  const ProductStockEntryResult({
    required this.product,
    required this.quantity,
    required this.entryPrice,
    required this.salePrice,
    required this.warehouseId,
    required this.entryDate,
  });
}

class ProductStockEntryModal extends StatefulWidget {
  final List<WarehouseModel> warehouses;
  final ProductStockEntry? initialEntry;

  const ProductStockEntryModal({
    super.key,
    required this.warehouses,
    this.initialEntry,
  });

  @override
  State<ProductStockEntryModal> createState() => _ProductStockEntryModalState();
}

class _ProductStockEntryModalState extends State<ProductStockEntryModal> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _quantityController;
  late final TextEditingController _entryPriceController;
  late final TextEditingController _salePriceController;

  ProductModel? _selectedProduct;
  int? _selectedWarehouseId;
  DateTime _entryDate = DateTime.now();
  String _salePriceHelperText = 'Sugerido: +30% sobre el precio de entrada';

  @override
  void initState() {
    super.initState();
    final entry = widget.initialEntry;

    _quantityController = TextEditingController(
      text: entry?.stock.quantity.toString() ?? '',
    );
    _entryPriceController = TextEditingController(
      text: entry?.stock.entryPrice.toString() ?? '',
    );
    _salePriceController = TextEditingController(
      text: entry?.stock.salePrice.toString() ?? '',
    );

    _selectedProduct = entry?.product;
    _selectedWarehouseId = entry?.stock.warehouseId;
    _entryDate = entry?.stock.entryDate ?? DateTime.now();

    _entryPriceController.addListener(_updateSuggestedSalePrice);
    _salePriceController.addListener(_updateHelperFromSalePrice);
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _entryPriceController.dispose();
    _salePriceController.dispose();
    super.dispose();
  }

  void _updateSuggestedSalePrice() {
    final entryText = _entryPriceController.text;
    final entryValue = double.tryParse(entryText);
    if (entryValue != null) {
      final suggested = entryValue * 1.3;
      // Actualizar el campo de texto con el precio sugerido
      _salePriceController.text = suggested.toStringAsFixed(2);
      setState(() {
        _salePriceHelperText = '30% margen';
      });
    } else {
      _salePriceController.text = '';
      setState(() {
        _salePriceHelperText = '';
      });
    }
  }

  void _updateHelperFromSalePrice() {
    final entryValue = double.tryParse(_entryPriceController.text);
    final saleValue = double.tryParse(_salePriceController.text);

    if (entryValue != null && saleValue != null && entryValue > 0) {
      final margin = ((saleValue - entryValue) / entryValue) * 100;
      setState(() {
        _salePriceHelperText = '${margin.toStringAsFixed(1)}% margen';
      });
    }
  }

  void _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _entryDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _entryDate = picked);
    }
  }

  bool _hasTwoDecimalsOrLess(String value) {
    final parts = value.split('.');
    return parts.length < 2 || parts.last.length <= 2;
  }

  void _submit() {
    if (_formKey.currentState?.validate() != true) return;

    if (_selectedProduct == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona un producto'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedWarehouseId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona un almacén'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final result = ProductStockEntryResult(
      product: _selectedProduct!,
      quantity: int.parse(_quantityController.text),
      entryPrice: double.parse(_entryPriceController.text),
      salePrice: double.parse(_salePriceController.text),
      warehouseId: _selectedWarehouseId!,
      entryDate: _entryDate,
    );

    Navigator.of(context).pop(result);
  }

  Future<void> _selectProduct() async {
    final productStockService = getIt<ProductStockService>();

    final product = await showDialog<ProductModel>(
      context: context,
      builder: (context) => _ProductSearchDialog(
        productStockService: productStockService,
      ),
    );

    if (product != null) {
      setState(() => _selectedProduct = product);
    }
  }

  InputDecoration _inputDecoration(String label, {String? helperText}) {
    final theme = Theme.of(context);
    return InputDecoration(
      labelText: label,
      helperText: helperText,
      filled: true,
      fillColor: Colors.grey.shade100,
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: theme.primaryColor),
      ),
      labelStyle: const TextStyle(fontWeight: FontWeight.w500),
      helperStyle: TextStyle(color: Colors.grey[600]),
    );
  }

  Widget _buildProductSelector() {
    if (_selectedProduct != null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            if (_selectedProduct!.imageUrl != null &&
                _selectedProduct!.imageUrl!.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: SecureNetworkImage(
                  imageUrl: _selectedProduct!.imageUrl,
                  productId: _selectedProduct!.id,
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                ),
              )
            else
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.inventory_2, color: Colors.grey),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _selectedProduct!.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  if (_selectedProduct!.description != null)
                    Text(
                      _selectedProduct!.description!,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit, size: 20),
              onPressed: _selectProduct,
              tooltip: 'Cambiar producto',
              color: Theme.of(context).primaryColor,
            ),
          ],
        ),
      );
    }

    return OutlinedButton.icon(
      onPressed: _selectProduct,
      icon: const Icon(Icons.search),
      label: const Text('Buscar producto'),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
        minimumSize: const Size.fromHeight(56),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initialEntry != null;
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Icon(
                        isEditing
                            ? Icons.edit_note_rounded
                            : Icons.add_box_rounded,
                        color: theme.primaryColor,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        isEditing
                            ? 'Editar registro de stock'
                            : 'Nuevo registro de stock',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Selector de producto
                  _buildProductSelector(),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _quantityController,
                    decoration: _inputDecoration('Cantidad *'),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Campo requerido';
                      }
                      final parsed = int.tryParse(value);
                      if (parsed == null || parsed <= 0) {
                        return 'Ingresa una cantidad válida';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _entryPriceController,
                    decoration: _inputDecoration('Precio de entrada *'),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Campo requerido';
                      }
                      final parsed = double.tryParse(value);
                      if (parsed == null || parsed <= 0) {
                        return 'Ingresa un valor válido';
                      }
                      if (!_hasTwoDecimalsOrLess(value)) {
                        return 'Máximo dos decimales';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _salePriceController,
                    decoration: _inputDecoration(
                      'Precio de venta *',
                      helperText: _salePriceHelperText,
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Campo requerido';
                      }
                      final parsed = double.tryParse(value);
                      if (parsed == null || parsed <= 0) {
                        return 'Ingresa un valor válido';
                      }
                      if (!_hasTwoDecimalsOrLess(value)) {
                        return 'Máximo dos decimales';
                      }
                      final entryValue =
                          double.tryParse(_entryPriceController.text);
                      if (entryValue != null && parsed <= entryValue) {
                        return 'Debe ser mayor al precio de entrada';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    value: _selectedWarehouseId,
                    decoration: _inputDecoration('Almacén *'),
                    items: widget.warehouses
                        .map(
                          (warehouse) => DropdownMenuItem(
                            value: warehouse.id,
                            child: Text(warehouse.name),
                          ),
                        )
                        .toList(),
                    onChanged: (value) =>
                        setState(() => _selectedWarehouseId = value),
                    validator: (value) =>
                        value == null ? 'Selecciona un almacén' : null,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Fecha de entrada: '
                          '${_entryDate.day.toString().padLeft(2, '0')}/'
                          '${_entryDate.month.toString().padLeft(2, '0')}/'
                          '${_entryDate.year}',
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _selectDate,
                        icon: Icon(
                          Icons.calendar_today_rounded,
                          color: theme.primaryColor,
                        ),
                        label: Text(
                          'Cambiar',
                          style: TextStyle(color: theme.primaryColor),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 18,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: BorderSide(color: theme.primaryColor),
                          foregroundColor: theme.primaryColor,
                        ),
                        child: const Text('Cancelar'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: _submit,
                        icon: Icon(isEditing ? Icons.check : Icons.save),
                        label: Text(isEditing ? 'Actualizar' : 'Registrar'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 18,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Diálogo para buscar y seleccionar producto
class _ProductSearchDialog extends StatefulWidget {
  final ProductStockService productStockService;

  const _ProductSearchDialog({required this.productStockService});

  @override
  State<_ProductSearchDialog> createState() => _ProductSearchDialogState();
}

class _ProductSearchDialogState extends State<_ProductSearchDialog> {
  final TextEditingController _searchController = TextEditingController();
  List<ProductModel> _products = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    try {
      final products = await widget.productStockService.getProducts(size: 50);
      setState(() {
        _products = products;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _searchProducts(String query) async {
    if (query.isEmpty) {
      await _loadProducts();
      return;
    }

    setState(() => _isLoading = true);
    try {
      final products = await widget.productStockService.getProducts(
        searchQuery: query,
        size: 50,
      );
      setState(() {
        _products = products;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.search, color: Theme.of(context).primaryColor),
                      const SizedBox(width: 12),
                      const Text(
                        'Buscar producto',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Escribe para buscar...',
                      prefixIcon: Icon(Icons.search,
                          color: Theme.of(context).primaryColor),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            BorderSide(color: Theme.of(context).primaryColor),
                      ),
                    ),
                    onChanged: (value) {
                      Future.delayed(const Duration(milliseconds: 500), () {
                        if (_searchController.text == value) {
                          _searchProducts(value);
                        }
                      });
                    },
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _products.isEmpty
                      ? const Center(child: Text('No se encontraron productos'))
                      : ListView.builder(
                          itemCount: _products.length,
                          itemBuilder: (context, index) {
                            final product = _products[index];
                            return ListTile(
                              leading: product.imageUrl != null &&
                                      product.imageUrl!.isNotEmpty
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(6),
                                      child: SecureNetworkImage(
                                        imageUrl: product.imageUrl,
                                        productId: product.id,
                                        width: 48,
                                        height: 48,
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade200,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Icon(Icons.inventory_2,
                                          color: Colors.grey),
                                    ),
                              title: Text(product.name),
                              subtitle: product.description != null
                                  ? Text(
                                      product.description!,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    )
                                  : null,
                              onTap: () => Navigator.of(context).pop(product),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
