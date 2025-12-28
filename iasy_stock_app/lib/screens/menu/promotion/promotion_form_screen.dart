import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../cubits/menu/category_cubit.dart';
import '../../../cubits/menu/product_cubit.dart';
import '../../../cubits/menu/promotion_cubit.dart';
import '../../../models/menu/promotion_model.dart';
import '../../../widgets/notification_helper.dart';

class PromotionFormScreen extends StatefulWidget {
  final PromotionModel? promotion;

  const PromotionFormScreen({super.key, this.promotion});

  @override
  State<PromotionFormScreen> createState() => _PromotionFormScreenState();
}

class _PromotionFormScreenState extends State<PromotionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _descriptionController;
  late TextEditingController _discountRateController;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _saving = false;

  int? _selectedCategoryId;
  int? _selectedProductId;

  @override
  void initState() {
    super.initState();
    final p = widget.promotion;
    _descriptionController = TextEditingController(text: p?.description ?? '');
    _discountRateController =
        TextEditingController(text: p?.discountRate.toString() ?? '');
    _startDate = p?.startDate;
    _endDate = p?.endDate;
    _selectedCategoryId = p?.categoryId;
    _selectedProductId = p?.productId;

    context.read<CategoryCubit>().loadCategories(refresh: true);
    context.read<ProductCubit>().loadProducts(refresh: true);
  }

  Future<void> _selectDate(BuildContext context, bool isStart) async {
    final now = DateTime.now();
    final initial = isStart ? (_startDate ?? now) : (_endDate ?? now);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365 * 5)),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          // Si la fecha de fin es anterior a la nueva fecha de inicio, ajustarla
          if (_endDate != null && _endDate!.isBefore(picked)) {
            _endDate = picked;
          }
        } else {
          _endDate = picked;
          // Si la fecha de inicio es posterior a la nueva fecha de fin, ajustarla
          if (_startDate != null && _startDate!.isAfter(picked)) {
            _startDate = picked;
          }
        }
      });
    }
  }

  Future<void> _saveForm() async {
    if (_formKey.currentState!.validate()) {
      if (_startDate == null || _endDate == null) {
        NotificationHelper.showError(
            context, 'Debe seleccionar fechas de inicio y fin');
        return;
      }

      // Validar que la fecha de fin sea posterior o igual a la fecha de inicio
      if (_endDate!.isBefore(_startDate!)) {
        NotificationHelper.showError(context,
            'La fecha de fin debe ser posterior o igual a la fecha de inicio');
        return;
      }

      setState(() => _saving = true);

      final promotion = PromotionModel(
        id: widget.promotion?.id ?? 0,
        description: _descriptionController.text,
        discountRate: double.parse(_discountRateController.text),
        startDate: _startDate!,
        endDate: _endDate!,
        productId: _selectedProductId,
        categoryId: _selectedCategoryId, // Now optional
      );

      try {
        if (widget.promotion == null) {
          await context.read<PromotionCubit>().createPromotion(promotion);
          NotificationHelper.showSuccess(
              context, 'Promoción creada correctamente');
        } else {
          await context.read<PromotionCubit>().updatePromotion(promotion);
          NotificationHelper.showSuccess(
              context, 'Promoción actualizada correctamente');
        }
        if (mounted) Navigator.pop(context);
      } on DioException catch (e) {
        final message =
            e.response?.data['message'] ?? 'Error guardando la promoción';
        NotificationHelper.showError(context, message);
        if (mounted) setState(() => _saving = false);
      } catch (e) {
        NotificationHelper.showError(
            context, 'Error inesperado: ${e.toString()}');
        if (mounted) setState(() => _saving = false);
      }
    }
  }

  String? _validateDiscount(String? value) {
    if (value == null || value.isEmpty) return 'Campo requerido';
    final parsed = double.tryParse(value);
    if (parsed == null) return 'Debe ser un número válido';
    if (parsed < 1 || parsed > 99) return 'Debe estar entre 1 y 99';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.promotion != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar Promoción' : 'Registrar Promoción'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: BlocBuilder<CategoryCubit, CategoryState>(
          builder: (context, categoryState) {
            if (categoryState is CategoryLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (categoryState is CategoryLoaded) {
              final categories = categoryState.categories;

              return BlocBuilder<ProductCubit, ProductState>(
                builder: (context, productState) {
                  if (productState is ProductLoading) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (productState is ProductLoaded) {
                    final filteredProducts = productState.products
                        .where((p) => p.categoryId == _selectedCategoryId)
                        .toList();

                    return Form(
                      key: _formKey,
                      child: ListView(
                        children: [
                          TextFormField(
                            controller: _descriptionController,
                            decoration:
                                const InputDecoration(labelText: 'Descripción'),
                            validator: (value) => value == null || value.isEmpty
                                ? 'Campo requerido'
                                : null,
                            enabled: !_saving,
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _discountRateController,
                            decoration: const InputDecoration(
                                labelText: 'Descuento (%)'),
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            validator: _validateDiscount,
                            enabled: !_saving,
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<int>(
                            value: _selectedCategoryId,
                            decoration: const InputDecoration(
                                labelText: 'Categoría (opcional)'),
                            items: [
                              const DropdownMenuItem<int>(
                                value: null,
                                child: Text('Ninguna'),
                              ),
                              ...categories.map((c) {
                                return DropdownMenuItem(
                                  value: c.id,
                                  child: Text(c.name),
                                );
                              }),
                            ],
                            onChanged: _saving
                                ? null
                                : (val) {
                                    setState(() {
                                      _selectedCategoryId = val;
                                      _selectedProductId = null;
                                    });
                                  },
                            validator: (val) => null, // Categoría es opcional
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<int>(
                            value: _selectedProductId,
                            decoration: const InputDecoration(
                                labelText: 'Producto (opcional)'),
                            items: [
                              const DropdownMenuItem<int>(
                                value: null,
                                child: Text('Ninguno'),
                              ),
                              ...filteredProducts.map((p) {
                                return DropdownMenuItem(
                                  value: p.id,
                                  child: Text(p.name),
                                );
                              }),
                            ],
                            onChanged: _saving
                                ? null
                                : (val) =>
                                    setState(() => _selectedProductId = val),
                          ),
                          const SizedBox(height: 8),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Fecha de inicio'),
                            subtitle: Text(
                              _startDate == null
                                  ? 'Seleccione una fecha'
                                  : DateFormat('yyyy-MM-dd')
                                      .format(_startDate!),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.calendar_today),
                              onPressed: _saving
                                  ? null
                                  : () => _selectDate(context, true),
                            ),
                          ),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Fecha de fin'),
                            subtitle: Text(
                              _endDate == null
                                  ? 'Seleccione una fecha'
                                  : DateFormat('yyyy-MM-dd').format(_endDate!),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.calendar_today),
                              onPressed: _saving
                                  ? null
                                  : () => _selectDate(context, false),
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
                    );
                  } else {
                    return const Center(
                        child: Text('Error cargando productos'));
                  }
                },
              );
            } else {
              return const Center(child: Text('Error cargando categorías'));
            }
          },
        ),
      ),
    );
  }
}
