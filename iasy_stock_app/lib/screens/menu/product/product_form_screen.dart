import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../cubits/menu/category_cubit.dart';
import '../../../cubits/menu/product_cubit.dart';
import '../../../models/menu/product_model.dart';
import '../../../widgets/notification_helper.dart';

class ProductFormScreen extends StatefulWidget {
  final ProductModel? product;

  const ProductFormScreen({super.key, this.product});

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _minimumController;
  DateTime? _expirationDate;
  int? _categoryId;
  bool _saving = false;
  Uint8List? _productImageBytes;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _nameController = TextEditingController(text: p?.name ?? '');
    _descriptionController = TextEditingController(text: p?.description ?? '');
    _minimumController =
        TextEditingController(text: p?.stockMinimum?.toString() ?? '');
    _expirationDate = p?.expirationDate;
    _categoryId = p?.categoryId;

    // Para edición, no manejamos la imagen desde imageUrl ya que es solo para mostrar
    // La imagen se debe seleccionar nuevamente al editar

    context.read<CategoryCubit>().loadCategories(refresh: true);
  }

  Future<void> _pickImage() async {
    // Mostrar diálogo para elegir entre cámara o galería
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Seleccionar imagen'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Tomar foto'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Desde galería'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();

      // Mostrar preview y confirmar
      if (mounted) {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Confirmar imagen'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.memory(bytes, height: 200),
                const SizedBox(height: 16),
                const Text('¿Desea usar esta imagen?'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Tomar de nuevo'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Aceptar'),
              ),
            ],
          ),
        );

        if (confirmed == true) {
          setState(() {
            _productImageBytes = bytes;
          });
        } else if (confirmed == false) {
          // Volver a llamar al método para tomar otra foto
          _pickImage();
        }
      }
    }
  }

  Future<void> _selectExpirationDate(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _expirationDate ?? now,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365 * 10)),
    );
    if (picked != null) {
      setState(() => _expirationDate = picked);
    }
  }

  Future<void> _saveForm() async {
    if (_formKey.currentState!.validate()) {
      // Validación de categoría
      if (_categoryId == null) {
        NotificationHelper.showError(context, 'Debe seleccionar la categoría');
        return;
      }

      setState(() => _saving = true);

      try {
        if (widget.product == null) {
          // Crear nuevo producto con reconocimiento usando form-data
          await context.read<ProductCubit>().createProductWithRecognition(
                name: _nameController.text.trim(),
                description: _descriptionController.text.trim().isEmpty
                    ? null
                    : _descriptionController.text.trim(),
                imageBytes: _productImageBytes,
                categoryId: _categoryId!,
                stockMinimum: _minimumController.text.trim().isEmpty
                    ? null
                    : int.tryParse(_minimumController.text.trim()),
                expirationDate: _expirationDate,
              );
          NotificationHelper.showSuccess(
              context, 'Producto creado correctamente');
        } else {
          // Para edición, crear el ProductModel y usar el método tradicional
          final product = ProductModel(
            id: widget.product!.id,
            name: _nameController.text.trim(),
            description: _descriptionController.text.trim().isEmpty
                ? null
                : _descriptionController.text.trim(),
            imageUrl: widget.product!.imageUrl,
            // Mantener la URL existente
            categoryId: _categoryId!,
            stockMinimum: _minimumController.text.trim().isEmpty
                ? null
                : int.tryParse(_minimumController.text.trim()),
            createdAt: widget.product!.createdAt,
            expirationDate: _expirationDate,
          );

          await context.read<ProductCubit>().updateProduct(product);
          NotificationHelper.showSuccess(
              context, 'Producto actualizado correctamente');
        }

        if (mounted) Navigator.pop(context);
      } on DioException catch (e) {
        NotificationHelper.showDioError(context, e,
            defaultMessage: 'Error guardando el producto');
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
    final isEditing = widget.product != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar Producto' : 'Registrar Producto'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nombre *'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Campo requerido' : null,
                enabled: !_saving,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                    labelText: 'Descripción *',
                    hintText: 'Descripción del producto'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Campo requerido' : null,
                enabled: !_saving,
                maxLines: 3,
              ),
              const SizedBox(height: 8),
              _buildCategoryDropdown(),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text("Imagen del Producto *"),
                subtitle: _productImageBytes == null
                    ? const Text("No seleccionada")
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Imagen seleccionada:"),
                          const SizedBox(height: 8),
                          Image.memory(_productImageBytes!, height: 100),
                        ],
                      ),
                trailing: IconButton(
                  icon: const Icon(Icons.image),
                  onPressed: _saving ? null : _pickImage,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _minimumController,
                decoration: const InputDecoration(
                    labelText: 'Stock mínimo', hintText: 'Ej: 10'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return null; // Campo opcional
                  }
                  final parsed = int.tryParse(value.trim());
                  if (parsed == null) return 'Debe ser un número entero válido';
                  if (parsed < 0) return 'No puede ser negativo';
                  return null;
                },
                enabled: !_saving,
              ),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Fecha de expiración'),
                subtitle: Text(
                  _expirationDate == null
                      ? 'No seleccionada'
                      : DateFormat('yyyy-MM-dd').format(_expirationDate!),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_expirationDate != null)
                      IconButton(
                        icon: const Icon(Icons.clear, color: Colors.red),
                        onPressed: _saving
                            ? null
                            : () => setState(() => _expirationDate = null),
                      ),
                    IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed:
                          _saving ? null : () => _selectExpirationDate(context),
                    ),
                  ],
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
                              strokeWidth: 2, color: Colors.white))
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

  Widget _buildCategoryDropdown() {
    return BlocBuilder<CategoryCubit, CategoryState>(
      builder: (context, state) {
        if (state is CategoryLoaded) {
          return DropdownButtonFormField<int>(
            value: _categoryId,
            decoration: const InputDecoration(labelText: 'Categoría *'),
            items: state.categories
                .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                .toList(),
            onChanged:
                _saving ? null : (val) => setState(() => _categoryId = val),
            validator: (val) => val == null ? 'Seleccione una categoría' : null,
          );
        }
        return const LinearProgressIndicator();
      },
    );
  }
}
