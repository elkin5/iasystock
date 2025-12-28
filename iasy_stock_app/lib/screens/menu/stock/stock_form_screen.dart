import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../cubits/menu/person_cubit.dart';
import '../../../cubits/menu/product_cubit.dart';
import '../../../cubits/menu/stock_cubit.dart';
import '../../../cubits/menu/warehouse_cubit.dart';
import '../../../models/menu/stock_model.dart';
import '../../../models/menu/user_model.dart';
import '../../../services/menu/user_service.dart';
import '../../../widgets/notification_helper.dart';
import '../../../widgets/product_dropdown_widget.dart';
import '../../../widgets/current_user_field.dart';
import '../../../config/get_it_config.dart';

class StockFormScreen extends StatefulWidget {
  final StockModel? stock;

  const StockFormScreen({super.key, this.stock});

  @override
  State<StockFormScreen> createState() => _StockFormScreenState();
}

class _StockFormScreenState extends State<StockFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _quantityController;
  late TextEditingController _entryPriceController;
  late TextEditingController _salePriceController;

  bool _saving = false;
  DateTime _selectedDate = DateTime.now();

  int? _selectedProductId;
  int? _selectedUserId;
  int? _selectedWarehouseId;
  int? _selectedPersonId;

  // Usuario actual autenticado
  UserModel? _currentUser;

  // Mensaje dinámico para el precio de venta
  String _salePriceHelperText = 'Sugerido: 30% mayor al precio de entrada';

  @override
  void initState() {
    super.initState();
    final s = widget.stock;
    _quantityController =
        TextEditingController(text: s?.quantity.toString() ?? '');
    _entryPriceController =
        TextEditingController(text: s?.entryPrice.toString() ?? '');
    _salePriceController =
        TextEditingController(text: s?.salePrice.toString() ?? '');
    _selectedDate = s?.entryDate ?? DateTime.now();

    _selectedProductId = s?.productId;
    _selectedUserId = s?.userId;
    _selectedWarehouseId = s?.warehouseId;
    _selectedPersonId = s?.personId;

    // Agregar listeners para actualizar precios y porcentajes automáticamente
    _entryPriceController.addListener(_updateSuggestedSalePrice);
    _salePriceController.addListener(_updatePercentageMessage);

    // Cargar datos
    context.read<ProductCubit>().loadProducts(refresh: true);
    context.read<WarehouseCubit>().loadWarehouses();
    context.read<PersonCubit>().loadPersons(refresh: true);
  }

  Future<void> _saveForm() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedProductId == null) {
        NotificationHelper.showError(context, 'Debe seleccionar un producto');
        return;
      }

      if (_selectedUserId == null) {
        NotificationHelper.showError(
            context, 'Error: No se pudo obtener el usuario actual');
        return;
      }

      setState(() => _saving = true);
      final stock = StockModel(
        id: widget.stock?.id ?? 0,
        quantity: int.parse(_quantityController.text),
        entryPrice: double.parse(_entryPriceController.text),
        salePrice: double.parse(_salePriceController.text),
        productId: _selectedProductId!,
        userId: _selectedUserId!,
        warehouseId: _selectedWarehouseId,
        personId: _selectedPersonId,
        entryDate: _selectedDate,
        createdAt: widget.stock?.createdAt ?? DateTime.now(),
      );

      try {
        if (widget.stock == null) {
          await context.read<StockCubit>().createStock(stock);
          NotificationHelper.showSuccess(context, 'Stock creado correctamente');
        } else {
          await context.read<StockCubit>().updateStock(stock.id!, stock);
          NotificationHelper.showSuccess(
              context, 'Stock actualizado correctamente');
        }
        Navigator.pop(context);
      } on DioException catch (e) {
        NotificationHelper.showDioError(context, e,
            defaultMessage: 'Error guardando el stock');
        setState(() => _saving = false);
      } catch (e) {
        NotificationHelper.showError(
            context, 'Error inesperado: ${e.toString()}');
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.stock != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar Stock' : 'Registrar Stock'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildProductDropdown(),
              TextFormField(
                controller: _quantityController,
                decoration: const InputDecoration(labelText: 'Cantidad *'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Campo requerido';
                  }
                  final parsed = int.tryParse(value);
                  if (parsed == null) return 'Debe ser un número entero válido';
                  if (parsed < 0) return 'No puede ser negativo';
                  return null;
                },
                enabled: !_saving,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _entryPriceController,
                decoration:
                    const InputDecoration(labelText: 'Precio de Entrada *'),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Campo requerido';
                  }
                  final parsed = double.tryParse(value);
                  if (parsed == null) return 'Debe ser un número válido';
                  if (parsed < 0) return 'No puede ser negativo';
                  if (!_validateTwoDecimals(value)) {
                    return 'Máximo 2 decimales permitidos';
                  }
                  return null;
                },
                enabled: !_saving,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _salePriceController,
                decoration: InputDecoration(
                  labelText: 'Precio de Venta *',
                  helperText: _salePriceHelperText,
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Campo requerido';
                  }
                  final parsed = double.tryParse(value);
                  if (parsed == null) return 'Debe ser un número válido';
                  if (parsed < 0) return 'No puede ser negativo';
                  if (!_validateTwoDecimals(value)) {
                    return 'Máximo 2 decimales permitidos';
                  }

                  // Validar que el precio de venta sea mayor al precio de entrada
                  final entryPriceText = _entryPriceController.text;
                  if (entryPriceText.isNotEmpty) {
                    final entryPrice = double.tryParse(entryPriceText);
                    if (entryPrice != null && parsed <= entryPrice) {
                      return 'El precio de venta debe ser mayor al precio de entrada';
                    }
                  }

                  return null;
                },
                enabled: !_saving,
              ),
              const SizedBox(height: 8),
              CurrentUserField(
                onUserLoaded: (user) {
                  setState(() {
                    _currentUser = user;
                    _selectedUserId = user.id;
                  });
                },
              ),
              const SizedBox(height: 8),
              _buildWarehouseDropdown(),
              const SizedBox(height: 8),
              _buildPersonDropdown(),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ListTile(
                  title: const Text('Fecha de Entrada'),
                  subtitle: Text(
                    DateFormat('yyyy-MM-dd').format(_selectedDate),
                    style: TextStyle(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.6),
                    ),
                  ),
                  trailing: Icon(
                    Icons.calendar_today,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.4),
                  ),
                  enabled: false, // Campo de solo lectura
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
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.save),
                  onPressed: _saving ? null : _saveForm,
                  label: Text(_saving ? 'Guardando...' : 'Guardar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Función para validar que tenga máximo 2 decimales
  bool _validateTwoDecimals(String value) {
    final parts = value.split('.');
    return parts.length == 1 || (parts.length == 2 && parts[1].length <= 2);
  }

  Widget _buildProductDropdown() {
    return ProductDropdownWidget(
      selectedProductId: _selectedProductId,
      onChanged:
          _saving ? null : (val) => setState(() => _selectedProductId = val),
      enabled: !_saving,
      isRequired: true,
    );
  }

  Widget _buildWarehouseDropdown() {
    return BlocBuilder<WarehouseCubit, WarehouseState>(
      builder: (context, state) {
        if (state is WarehouseLoaded) {
          // Validar que el valor seleccionado existe en la lista de almacenes
          final validSelectedId =
              state.warehouses.any((w) => w.id == _selectedWarehouseId)
                  ? _selectedWarehouseId
                  : null;

          return DropdownButtonFormField<int>(
            value: validSelectedId,
            decoration: const InputDecoration(labelText: 'Almacén'),
            items: state.warehouses
                .map((w) => DropdownMenuItem(
                    value: w.id, child: Text(w.name ?? 'Sin nombre')))
                .toList(),
            onChanged: _saving
                ? null
                : (val) => setState(() => _selectedWarehouseId = val),
            validator: (val) => null, // Almacén es opcional
          );
        }
        return const LinearProgressIndicator();
      },
    );
  }

  Widget _buildPersonDropdown() {
    return BlocBuilder<PersonCubit, PersonState>(
      builder: (context, state) {
        if (state is PersonLoaded) {
          // Filtrar solo personas de tipo 'Supplier'
          final suppliers = state.persons
              .where((p) => p.type.toLowerCase() == 'supplier')
              .toList();

          // Validar que el valor seleccionado existe en la lista de proveedores
          final validSelectedId =
              suppliers.any((p) => p.id == _selectedPersonId)
                  ? _selectedPersonId
                  : null;

          return DropdownButtonFormField<int>(
            value: validSelectedId,
            decoration: const InputDecoration(labelText: 'Proveedor'),
            items: suppliers
                .map((p) => DropdownMenuItem(
                    value: p.id, child: Text(p.name ?? 'Sin nombre')))
                .toList(),
            onChanged: _saving
                ? null
                : (val) => setState(() => _selectedPersonId = val),
            validator: (val) => null, // Proveedor es opcional
          );
        }
        return const LinearProgressIndicator();
      },
    );
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _entryPriceController.removeListener(_updateSuggestedSalePrice);
    _entryPriceController.dispose();
    _salePriceController.removeListener(_updatePercentageMessage);
    _salePriceController.dispose();
    super.dispose();
  }

  void _updateSuggestedSalePrice() {
    final entryPriceText = _entryPriceController.text;
    if (entryPriceText.isNotEmpty) {
      final entryPrice = double.tryParse(entryPriceText);
      if (entryPrice != null && entryPrice > 0) {
        // Calcular precio de venta sugerido (30% de ganancia)
        final suggestedSalePrice = entryPrice * 1.30;
        _salePriceController.text = suggestedSalePrice.toStringAsFixed(2);

        // Actualizar mensaje de porcentaje
        _updatePercentageMessage();
      }
    }
  }

  void _updatePercentageMessage() {
    final entryPriceText = _entryPriceController.text;
    final salePriceText = _salePriceController.text;

    if (entryPriceText.isNotEmpty && salePriceText.isNotEmpty) {
      final entryPrice = double.tryParse(entryPriceText);
      final salePrice = double.tryParse(salePriceText);

      if (entryPrice != null && salePrice != null && entryPrice > 0) {
        // Calcular el porcentaje de ganancia
        final percentage = ((salePrice - entryPrice) / entryPrice) * 100;

        if (percentage > 0) {
          _salePriceHelperText =
              'Es el ${percentage.toStringAsFixed(1)}% mayor al precio de entrada';
        } else if (percentage < 0) {
          final lossPercentage = percentage * -1;
          _salePriceHelperText =
              'Es el ${lossPercentage.toStringAsFixed(1)}% menor al precio de entrada';
        } else {
          _salePriceHelperText = 'Es igual al precio de entrada';
        }

        // Actualizar la UI
        setState(() {});
      }
    } else if (entryPriceText.isNotEmpty) {
      _salePriceHelperText = 'Sugerido: 30% mayor al precio de entrada';
      setState(() {});
    } else {
      _salePriceHelperText = 'Sugerido: 30% mayor al precio de entrada';
      setState(() {});
    }
  }
}
