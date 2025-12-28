import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../cubits/menu/person_cubit.dart';
import '../../../cubits/menu/product_cubit.dart';
import '../../../cubits/menu/sale_cubit.dart';
import '../../../cubits/menu/sale_item_cubit.dart';
import '../../../cubits/menu/stock_cubit.dart';
import '../../../models/menu/product_model.dart';
import '../../../models/menu/sale_item_model.dart';
import '../../../widgets/notification_helper.dart';
import '../../../widgets/product_dropdown_widget.dart';
import '../../../widgets/menu/secure_network_image.dart';

class SaleItemFormScreen extends StatefulWidget {
  final SaleItemModel? saleItem;

  const SaleItemFormScreen({super.key, this.saleItem});

  @override
  State<SaleItemFormScreen> createState() => _SaleItemFormScreenState();
}

class _SaleItemFormScreenState extends State<SaleItemFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _quantityController;
  late TextEditingController _unitPriceController;
  late TextEditingController _totalPriceController;
  bool _saving = false;

  int? _selectedSaleId;
  int? _selectedProductId;

  @override
  void initState() {
    super.initState();
    final item = widget.saleItem;

    _selectedSaleId = item?.saleId;
    _selectedProductId = item?.productId;
    _quantityController =
        TextEditingController(text: item?.quantity.toString() ?? '1');
    _unitPriceController =
        TextEditingController(text: item?.unitPrice.toString() ?? '');
    _totalPriceController =
        TextEditingController(text: item?.totalPrice.toString() ?? '');

    // Agregar listeners para calcular automáticamente el total
    _quantityController.addListener(_calculateTotal);
    _unitPriceController.addListener(_calculateTotal);

    context.read<SaleCubit>().findByState('Pendiente');
    context.read<ProductCubit>().loadProducts(refresh: true);
    context.read<PersonCubit>().loadPersons();
  }

  void _calculateTotal() {
    final quantityText = _quantityController.text;
    final unitPriceText = _unitPriceController.text;

    if (quantityText.isNotEmpty && unitPriceText.isNotEmpty) {
      final quantity = int.tryParse(quantityText);
      final unitPrice = double.tryParse(unitPriceText);

      if (quantity != null && unitPrice != null) {
        final total = quantity * unitPrice;
        _totalPriceController.text = total.toStringAsFixed(2);
      }
    }
  }

  Future<void> _saveForm() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedSaleId == null || _selectedProductId == null) {
        NotificationHelper.showError(
            context, 'Debe seleccionar venta y producto');
        return;
      }

      setState(() => _saving = true);

      final quantity = int.parse(_quantityController.text);
      final unitPrice = double.parse(_unitPriceController.text);
      final calculatedTotal = quantity * unitPrice;

      final item = SaleItemModel(
        id: widget.saleItem?.id ?? 0,
        saleId: _selectedSaleId!,
        productId: _selectedProductId!,
        quantity: quantity,
        unitPrice: unitPrice,
        totalPrice: calculatedTotal, // Calculado automáticamente
      );

      try {
        if (widget.saleItem == null) {
          await context.read<SaleItemCubit>().createSaleItem(item);
          NotificationHelper.showSuccess(
              context, 'Ítem de venta creado correctamente');
        } else {
          await context.read<SaleItemCubit>().updateSaleItem(item.id!, item);
          NotificationHelper.showSuccess(
              context, 'Ítem de venta actualizado correctamente');
        }
        if (mounted) Navigator.pop(context);
      } on DioException catch (e) {
        final message =
            e.response?.data['message'] ?? 'Error guardando el ítem de venta';
        NotificationHelper.showError(context, message);
        if (mounted) setState(() => _saving = false);
      } catch (e) {
        NotificationHelper.showError(
            context, 'Error inesperado: ${e.toString()}');
        if (mounted) setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.saleItem != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
            isEditing ? 'Editar Ítem de Venta' : 'Registrar Ítem de Venta'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: BlocBuilder<SaleCubit, SaleState>(
          builder: (context, saleState) {
            if (saleState is SaleLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (saleState is SaleLoaded) {
              final sales = saleState.sales;
              return BlocBuilder<ProductCubit, ProductState>(
                builder: (context, productState) {
                  if (productState is ProductLoading) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (productState is ProductLoaded) {
                    final products = productState.products;
                    return BlocBuilder<PersonCubit, PersonState>(
                      builder: (context, personState) {
                        if (personState is PersonLoading) {
                          return const Center(
                              child: CircularProgressIndicator());
                        } else if (personState is PersonLoaded) {
                          final persons = personState.persons;

                          return Form(
                            key: _formKey,
                            child: ListView(
                              children: [
                                DropdownButtonFormField<int>(
                                  value: _selectedSaleId,
                                  isExpanded: true,
                                  decoration: const InputDecoration(
                                      labelText: 'Venta *'),
                                  items: sales.map((sale) {
                                    final clientName =
                                        _getClientName(sale.personId, persons);
                                    return DropdownMenuItem(
                                      value: sale.id,
                                      child: Text(
                                          'Venta #${sale.id} - ${sale.saleDate != null ? DateFormat('yyyy-MM-dd HH:mm:ss').format(sale.saleDate!) : 'Sin fecha'} - $clientName'),
                                    );
                                  }).toList(),
                                  onChanged: _saving
                                      ? null
                                      : (val) =>
                                          setState(() => _selectedSaleId = val),
                                  validator: (val) => val == null
                                      ? 'Seleccione una venta'
                                      : null,
                                ),
                                const SizedBox(height: 8),
                                ProductDropdownWidget(
                                  selectedProductId: _selectedProductId,
                                  onChanged: _saving
                                      ? null
                                      : (val) async {
                                          setState(
                                              () => _selectedProductId = val);
                                          if (val != null) {
                                            await _loadProductSalePrice();
                                          }
                                        },
                                  enabled: !_saving,
                                  isRequired: true,
                                ),
                                const SizedBox(height: 8),
                                // Imagen del producto seleccionado
                                if (_selectedProductId != null)
                                  _buildSelectedProductImage(products),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _quantityController,
                                  decoration: const InputDecoration(
                                      labelText: 'Cantidad *'),
                                  keyboardType: TextInputType.number,
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Campo requerido';
                                    }
                                    final parsed = int.tryParse(value);
                                    if (parsed == null) {
                                      return 'Debe ser un número entero';
                                    }
                                    if (parsed < 0)
                                      return 'No puede ser negativo';
                                    return null;
                                  },
                                  enabled: !_saving,
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _unitPriceController,
                                  decoration: const InputDecoration(
                                      labelText: 'Precio unitario *'),
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                          decimal: true),
                                  readOnly:
                                      true, // Solo lectura - se carga automáticamente
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _totalPriceController,
                                  decoration: const InputDecoration(
                                      labelText: 'Precio total *'),
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                          decimal: true),
                                  readOnly:
                                      true, // Solo lectura - se calcula automáticamente
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    icon: _saving
                                        ? const SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white),
                                          )
                                        : const Icon(Icons.save),
                                    onPressed: _saving ? null : _saveForm,
                                    label: Text(
                                        _saving ? 'Guardando...' : 'Guardar'),
                                  ),
                                ),
                              ],
                            ),
                          );
                        } else {
                          return const Center(
                              child: Text('Error cargando clientes'));
                        }
                      },
                    );
                  } else {
                    return const Center(
                        child: Text('Error cargando productos'));
                  }
                },
              );
            } else {
              return const Center(child: Text('Error cargando ventas'));
            }
          },
        ),
      ),
    );
  }

  // Widget para mostrar la imagen del producto seleccionado
  Widget _buildSelectedProductImage(List<ProductModel> products) {
    final selectedProduct = _getSelectedProduct(products);
    if (selectedProduct == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey.shade50,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Producto Seleccionado:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              // Imagen del producto
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 80,
                  height: 80,
                  child: (selectedProduct.imageUrl != null &&
                          selectedProduct.imageUrl!.isNotEmpty)
                      ? SecureNetworkImage(
                          imageUrl: selectedProduct.imageUrl,
                          productId: selectedProduct.id,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          placeholder: Container(
                            color: Colors.grey[200],
                            child: const Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                          ),
                          errorWidget: Container(
                            color: Colors.grey[100],
                            child: Icon(
                              Icons.image_not_supported_outlined,
                              size: 32,
                              color: Colors.grey[400],
                            ),
                          ),
                        )
                      : Container(
                          color: Colors.grey[100],
                          child: Icon(
                            Icons.inventory_2_outlined,
                            size: 32,
                            color: Colors.grey[400],
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              // Información del producto
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      selectedProduct.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (selectedProduct.stockQuantity != null)
                      Text(
                        'Stock disponible: ${selectedProduct.stockQuantity}',
                        style: TextStyle(
                          color: selectedProduct.stockQuantity! <=
                                  (selectedProduct.stockMinimum ?? 0)
                              ? Colors.red
                              : Colors.green,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    if (selectedProduct.description != null &&
                        selectedProduct.description!.isNotEmpty)
                      Text(
                        selectedProduct.description!,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Función helper para obtener el nombre del cliente
  String _getClientName(int? personId, List<dynamic> persons) {
    if (personId == null) return 'Sin cliente';

    try {
      final person = persons.firstWhere((p) => p.id == personId);
      return person.name ?? 'Sin nombre';
    } catch (e) {
      return 'Cliente no encontrado';
    }
  }

  // Función helper para obtener el producto seleccionado
  ProductModel? _getSelectedProduct(List<ProductModel> products) {
    if (_selectedProductId == null) return null;

    try {
      return products.firstWhere((p) => p.id == _selectedProductId);
    } catch (e) {
      return null;
    }
  }

  // Función para obtener el precio de venta del producto desde su stock
  Future<void> _loadProductSalePrice() async {
    if (_selectedProductId == null) return;

    try {
      final stockCubit = context.read<StockCubit>();
      final stocks =
          await stockCubit.stockService.findByProductId(_selectedProductId!);

      if (stocks.isNotEmpty) {
        // Obtener el stock más reciente (por fecha de entrada)
        stocks.sort((a, b) => (b.entryDate ?? DateTime.now())
            .compareTo(a.entryDate ?? DateTime.now()));
        final latestStock = stocks.first;

        setState(() {
          _unitPriceController.text = latestStock.salePrice.toStringAsFixed(2);
        });

        // Recalcular el total con el nuevo precio
        _calculateTotal();
      }
    } catch (e) {
      // Si no se puede obtener el precio, mantener el valor actual
      debugPrint('Error obteniendo precio de venta: $e');
    }
  }
}
