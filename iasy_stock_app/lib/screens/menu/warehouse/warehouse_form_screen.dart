import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../cubits/menu/warehouse_cubit.dart';
import '../../../models/menu/warehouse_model.dart';
import '../../../widgets/notification_helper.dart';

class WarehouseFormScreen extends StatefulWidget {
  final WarehouseModel? warehouse;

  const WarehouseFormScreen({super.key, this.warehouse});

  @override
  State<WarehouseFormScreen> createState() => _WarehouseFormScreenState();
}

class _WarehouseFormScreenState extends State<WarehouseFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _locationController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.warehouse?.name ?? '');
    _locationController =
        TextEditingController(text: widget.warehouse?.location ?? '');
  }

  Future<void> _saveForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _saving = true);

      final warehouse = WarehouseModel(
        id: widget.warehouse?.id ?? 0,
        name: _nameController.text.trim(),
        location: _locationController.text.trim().isNotEmpty
            ? _locationController.text.trim()
            : null,
        createdAt: widget.warehouse?.createdAt ?? DateTime.now(),
      );

      try {
        if (warehouse.id == null || warehouse.id == 0) {
          await context.read<WarehouseCubit>().createWarehouse(warehouse);
          NotificationHelper.showSuccess(
              context, 'Almacén creado correctamente');
        } else {
          await context.read<WarehouseCubit>().updateWarehouse(warehouse);
          NotificationHelper.showSuccess(
              context, 'Almacén actualizado correctamente');
        }
        Navigator.pop(context);
      } on DioException catch (e) {
        final message =
            e.response?.data['message'] ?? 'Error guardando el almacén';
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
    final isEditing = widget.warehouse != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar Almacén' : 'Registrar Almacén'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration:
                    const InputDecoration(labelText: 'Nombre del Almacén *'),
                validator: _requiredValidator,
                enabled: !_saving,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(labelText: 'Ubicación'),
                enabled: !_saving,
              ),
              const SizedBox(height: 24),
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

  String? _requiredValidator(String? value) =>
      value == null || value.trim().isEmpty ? 'Campo requerido' : null;
}
