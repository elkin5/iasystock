import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../cubits/product_stock/stock_registration_cubit.dart';
import '../../../cubits/auth/auth_cubit.dart';
import '../../../cubits/menu/person_cubit.dart';
import '../../../cubits/menu/product_cubit.dart';
import '../../../cubits/menu/stock_cubit.dart';
import '../../../cubits/menu/user_cubit.dart';
import '../../../cubits/menu/warehouse_cubit.dart';
import '../../../models/menu/stock_model.dart';
import '../../../models/menu/product_model.dart';
import '../../../widgets/notification_helper.dart';

class EnhancedStockRegistrationScreen extends StatefulWidget {
  final ProductModel? product;
  final String? initialQuantity;
  final File? imageFile;

  const EnhancedStockRegistrationScreen({
    super.key,
    this.product,
    this.initialQuantity,
    this.imageFile,
  });

  @override
  State<EnhancedStockRegistrationScreen> createState() =>
      _EnhancedStockRegistrationScreenState();
}

class _EnhancedStockRegistrationScreenState
    extends State<EnhancedStockRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _quantityController;
  late TextEditingController _entryPriceController;
  late TextEditingController _salePriceController;

  bool _isStockIn = true;
  bool _isStockOut = false;
  bool _saving = false;
  DateTime _selectedDate = DateTime.now();

  int? _selectedProductId;
  int? _selectedUserId;
  int? _selectedWarehouseId;
  int? _selectedPersonId;

  // Estados para el flujo mejorado
  int _currentStep = 0;
  final int _totalSteps = 3;

  @override
  void initState() {
    super.initState();
    _quantityController =
        TextEditingController(text: widget.initialQuantity ?? '1');
    _entryPriceController = TextEditingController();
    _salePriceController = TextEditingController();

    // Pre-llenar datos si viene de reconocimiento
    // if (widget.product != null) {
    //   _selectedProductId = widget.product!.id;
    //   if (widget.product!.price != null) {
    //     _entryPriceController.text = widget.product!.price!.toString();
    //     _salePriceController.text = (widget.product!.price! * 1.2).toStringAsFixed(2);
    //   }
    // }

    _loadRequiredData();
  }

  void _loadRequiredData() {
    context.read<ProductCubit>().loadProducts();
    context.read<UserCubit>().loadUsers();
    context.read<WarehouseCubit>().loadWarehouses();
    context.read<PersonCubit>().loadPersons();
  }

  Future<void> _saveForm() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedProductId == null ||
          _selectedUserId == null ||
          _selectedWarehouseId == null ||
          _selectedPersonId == null) {
        NotificationHelper.showError(
            context, 'Debe completar todos los campos requeridos');
        return;
      }

      setState(() => _saving = true);

      try {
        // Usar el nuevo cubit para registro con reconocimiento
        await context.read<StockRegistrationCubit>().registerStockTraditional(
              productId: _selectedProductId!,
              quantity: int.parse(_quantityController.text),
              entryPrice: double.parse(_entryPriceController.text),
              salePrice: double.parse(_salePriceController.text),
              warehouseId: _selectedWarehouseId!,
              personId: _selectedPersonId!,
              entryDate: _selectedDate,
            );

        NotificationHelper.showSuccess(
            context, 'Stock registrado correctamente');

        if (mounted) {
          Navigator.pop(context);
        }
      } catch (e) {
        NotificationHelper.showError(
            context, 'Error inesperado: ${e.toString()}');
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _selectDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (pickedDate != null) {
      setState(() => _selectedDate = pickedDate);
    }
  }

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      setState(() => _currentStep++);
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<StockRegistrationCubit, StockRegistrationState>(
      listener: (context, state) {
        if (state is StockRegistrationCompleted) {
          setState(() => _saving = false);
          NotificationHelper.showSuccess(
              context, 'Stock registrado correctamente');
          if (mounted) {
            Navigator.pop(context);
          }
        } else if (state is StockRegistrationError) {
          setState(() => _saving = false);
          NotificationHelper.showError(context, state.message);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Registro de Stock'),
          backgroundColor: Theme.of(context).primaryColor,
          actions: [
            // Indicador de progreso
            Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: Text(
                  '${_currentStep + 1}/$_totalSteps',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            // Barra de progreso
            LinearProgressIndicator(
              value: (_currentStep + 1) / _totalSteps,
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).primaryColor,
              ),
            ),

            Expanded(
              child: Form(
                key: _formKey,
                child: _buildCurrentStep(),
              ),
            ),

            // Botones de navegación
            _buildNavigationButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildProductSelectionStep();
      case 1:
        return _buildStockDetailsStep();
      case 2:
        return _buildConfirmationStep();
      default:
        return _buildProductSelectionStep();
    }
  }

  Widget _buildProductSelectionStep() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Seleccionar Producto',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Selecciona el producto que deseas registrar en stock',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),

          // Mostrar imagen si está disponible
          if (widget.imageFile != null) ...[
            Center(
              child: Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(
                    widget.imageFile!,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          _buildProductDropdown(),
          const SizedBox(height: 16),
          _buildQuantityField(),
        ],
      ),
    );
  }

  Widget _buildStockDetailsStep() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Detalles del Stock',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Ingresa los precios y detalles del movimiento',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _entryPriceController,
            decoration: const InputDecoration(
              labelText: 'Precio de Entrada',
              prefixText: '\$ ',
              border: OutlineInputBorder(),
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Campo requerido';
              }
              final parsed = double.tryParse(value);
              if (parsed == null) return 'Debe ser un número válido';
              if (parsed < 0) return 'No puede ser negativo';
              return null;
            },
            enabled: !_saving,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _salePriceController,
            decoration: const InputDecoration(
              labelText: 'Precio de Venta',
              prefixText: '\$ ',
              border: OutlineInputBorder(),
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Campo requerido';
              }
              final parsed = double.tryParse(value);
              if (parsed == null) return 'Debe ser un número válido';
              if (parsed < 0) return 'No puede ser negativo';
              return null;
            },
            enabled: !_saving,
          ),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Fecha de Entrada'),
            subtitle: Text(DateFormat('yyyy-MM-dd').format(_selectedDate)),
            trailing: const Icon(Icons.calendar_today),
            onTap: _saving ? null : _selectDate,
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmationStep() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Confirmar Registro',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Revisa los datos antes de confirmar el registro',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Resumen del Registro',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildSummaryRow('Producto', _getProductName()),
                  _buildSummaryRow('Cantidad', _quantityController.text),
                  _buildSummaryRow(
                      'Precio Entrada', '\$${_entryPriceController.text}'),
                  _buildSummaryRow(
                      'Precio Venta', '\$${_salePriceController.text}'),
                  _buildSummaryRow('Almacén', _getWarehouseName()),
                  _buildSummaryRow('Proveedor', _getPersonName()),
                  _buildSummaryRow(
                      'Fecha', DateFormat('yyyy-MM-dd').format(_selectedDate)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildUserDropdown(),
          const SizedBox(height: 16),
          _buildWarehouseDropdown(),
          const SizedBox(height: 16),
          _buildPersonDropdown(),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildQuantityField() {
    return TextFormField(
      controller: _quantityController,
      decoration: const InputDecoration(
        labelText: 'Cantidad',
        border: OutlineInputBorder(),
      ),
      keyboardType: TextInputType.number,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Campo requerido';
        }
        final parsed = int.tryParse(value);
        if (parsed == null) return 'Debe ser un número entero válido';
        if (parsed <= 0) return 'Debe ser mayor a 0';
        return null;
      },
      enabled: !_saving,
    );
  }

  Widget _buildProductDropdown() {
    return BlocBuilder<ProductCubit, ProductState>(
      builder: (context, state) {
        if (state is ProductLoaded) {
          return DropdownButtonFormField<int>(
            value: _selectedProductId,
            decoration: const InputDecoration(
              labelText: 'Producto',
              border: OutlineInputBorder(),
            ),
            items: state.products
                .map((p) => DropdownMenuItem(
                      value: p.id,
                      child: Text(p.name ?? 'Sin nombre'),
                    ))
                .toList(),
            onChanged: _saving
                ? null
                : (val) => setState(() => _selectedProductId = val),
            validator: (val) => val == null ? 'Seleccione un producto' : null,
          );
        }
        return const LinearProgressIndicator();
      },
    );
  }

  Widget _buildUserDropdown() {
    return BlocBuilder<UserCubit, UserState>(
      builder: (context, state) {
        if (state is UserLoaded) {
          return DropdownButtonFormField<int>(
            value: _selectedUserId,
            decoration: const InputDecoration(
              labelText: 'Usuario Responsable',
              border: OutlineInputBorder(),
            ),
            items: state.users
                .map((u) => DropdownMenuItem(
                      value: u.id,
                      child: Text(u.username ?? 'Sin nombre'),
                    ))
                .toList(),
            onChanged:
                _saving ? null : (val) => setState(() => _selectedUserId = val),
            validator: (val) => val == null ? 'Seleccione un usuario' : null,
          );
        }
        return const LinearProgressIndicator();
      },
    );
  }

  Widget _buildWarehouseDropdown() {
    return BlocBuilder<WarehouseCubit, WarehouseState>(
      builder: (context, state) {
        if (state is WarehouseLoaded) {
          return DropdownButtonFormField<int>(
            value: _selectedWarehouseId,
            decoration: const InputDecoration(
              labelText: 'Almacén',
              border: OutlineInputBorder(),
            ),
            items: state.warehouses
                .map((w) => DropdownMenuItem(
                      value: w.id,
                      child: Text(w.name ?? 'Sin nombre'),
                    ))
                .toList(),
            onChanged: _saving
                ? null
                : (val) => setState(() => _selectedWarehouseId = val),
            validator: (val) => val == null ? 'Seleccione un almacén' : null,
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
          // Filtrar solo proveedores
          final suppliers =
              state.persons.where((p) => p.type == 'Supplier').toList();

          return DropdownButtonFormField<int>(
            value: _selectedPersonId,
            decoration: const InputDecoration(
              labelText: 'Proveedor',
              border: OutlineInputBorder(),
            ),
            items: suppliers
                .map((p) => DropdownMenuItem(
                      value: p.id,
                      child: Text(p.name ?? 'Sin nombre'),
                    ))
                .toList(),
            onChanged: _saving
                ? null
                : (val) => setState(() => _selectedPersonId = val),
            validator: (val) => val == null ? 'Seleccione un proveedor' : null,
          );
        }
        return const LinearProgressIndicator();
      },
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _previousStep,
                icon: const Icon(Icons.arrow_back),
                label: const Text('Anterior'),
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: 16),
          Expanded(
            child: _currentStep == _totalSteps - 1
                ? ElevatedButton.icon(
                    onPressed: _saving ? null : _saveForm,
                    icon: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.save),
                    label: Text(_saving ? 'Guardando...' : 'Confirmar'),
                  )
                : ElevatedButton.icon(
                    onPressed: _nextStep,
                    icon: const Icon(Icons.arrow_forward),
                    label: const Text('Siguiente'),
                  ),
          ),
        ],
      ),
    );
  }

  String _getProductName() {
    if (_selectedProductId == null) return 'No seleccionado';
    // Aquí podrías obtener el nombre del producto desde el cubit
    return 'Producto ID: $_selectedProductId';
  }

  String _getWarehouseName() {
    if (_selectedWarehouseId == null) return 'No seleccionado';
    return 'Almacén ID: $_selectedWarehouseId';
  }

  String _getPersonName() {
    if (_selectedPersonId == null) return 'No seleccionado';
    return 'Proveedor ID: $_selectedPersonId';
  }
}
