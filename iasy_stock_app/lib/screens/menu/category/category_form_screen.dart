import 'package:dio/dio.dart'; // Importamos Dio para capturar el tipo exacto
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../cubits/menu/category_cubit.dart';
import '../../../models/menu/category_model.dart';
import '../../../widgets/notification_helper.dart';

class CategoryFormScreen extends StatefulWidget {
  final CategoryModel? category;

  const CategoryFormScreen({super.key, this.category});

  @override
  State<CategoryFormScreen> createState() => _CategoryFormScreenState();
}

class _CategoryFormScreenState extends State<CategoryFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final category = widget.category;
    _nameController = TextEditingController(text: category?.name ?? '');
    _descriptionController =
        TextEditingController(text: category?.description ?? '');
  }

  Future<void> _saveForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _saving = true);
      final category = CategoryModel(
        id: widget.category?.id ?? 0,
        name: _nameController.text,
        description: _descriptionController.text,
      );

      try {
        if (widget.category == null) {
          await context.read<CategoryCubit>().createCategory(category);
          NotificationHelper.showSuccess(
              context, 'Categoría creada correctamente');
        } else {
          await context.read<CategoryCubit>().updateCategory(category);
          NotificationHelper.showSuccess(
              context, 'Categoría actualizada correctamente');
        }
        Navigator.pop(context);
      } on DioException catch (e) {
        // Capturamos el mensaje que viene del backend
        final message =
            e.response?.data['message'] ?? 'Error guardando la categoría';
        NotificationHelper.showError(context, message);
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
    final isEditing = widget.category != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar Categoría' : 'Crear Categoría'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
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
                decoration: const InputDecoration(labelText: 'Descripción'),
                maxLines: 3,
                enabled: !_saving,
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
}
