import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../cubits/menu/person_cubit.dart';
import '../../../models/menu/person_model.dart';
import '../../../widgets/notification_helper.dart';

class PersonFormScreen extends StatefulWidget {
  final PersonModel? person;

  const PersonFormScreen({super.key, this.person});

  @override
  State<PersonFormScreen> createState() => _PersonFormScreenState();
}

class _PersonFormScreenState extends State<PersonFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _identificationController;
  late TextEditingController _emailController;
  late TextEditingController _cellPhoneController;
  late TextEditingController _addressController;

  String _type = 'Customer';
  String _identificationType = 'CC';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final p = widget.person;
    _nameController = TextEditingController(text: p?.name ?? '');
    _identificationController =
        TextEditingController(text: p?.identification?.toString() ?? '');
    _cellPhoneController =
        TextEditingController(text: p?.cellPhone?.toString() ?? '');
    _emailController = TextEditingController(text: p?.email ?? '');
    _addressController = TextEditingController(text: p?.address ?? '');
    _identificationType = p?.identificationType ?? 'CC';
    _type = p?.type ?? 'Customer';
  }

  Future<void> _saveForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _saving = true);

      final person = PersonModel(
        id: widget.person?.id ?? 0,
        name: _nameController.text,
        identification: _identificationController.text.isNotEmpty
            ? int.parse(_identificationController.text)
            : null,
        identificationType: _identificationType,
        cellPhone: _cellPhoneController.text.isNotEmpty
            ? int.parse(_cellPhoneController.text)
            : null,
        email: _emailController.text.isNotEmpty ? _emailController.text : null,
        address:
            _addressController.text.isNotEmpty ? _addressController.text : null,
        createdAt: widget.person?.createdAt ?? DateTime.now(),
        type: _type,
      );

      try {
        if (widget.person == null) {
          await context.read<PersonCubit>().createPerson(person);
          NotificationHelper.showSuccess(
              context, 'Persona registrada correctamente');
        } else {
          await context.read<PersonCubit>().updatePerson(person);
          NotificationHelper.showSuccess(
              context, 'Persona actualizada correctamente');
        }
        if (mounted) Navigator.pop(context);
      } on DioException catch (e) {
        NotificationHelper.showDioError(context, e,
            defaultMessage: 'Error guardando la persona');
        if (mounted) setState(() => _saving = false);
      } catch (e) {
        NotificationHelper.showError(
            context, 'Error inesperado: ${e.toString()}');
        if (mounted) setState(() => _saving = false);
      }
    }
  }

  String? _validateNumericNoDecimals(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return 'Campo requerido';
    }
    final parsed = double.tryParse(value);
    if (parsed == null) return '$fieldName debe ser numérico';
    if (parsed < 0) return '$fieldName no puede ser negativo';
    if (parsed % 1 != 0) return '$fieldName no puede tener decimales';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.person != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar Persona' : 'Registrar Persona'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
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
                  controller: _identificationController,
                  decoration:
                      const InputDecoration(labelText: 'Identificación'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      return _validateNumericNoDecimals(
                          value, 'Identificación');
                    }
                    return null;
                  },
                  enabled: !_saving,
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _identificationType,
                  decoration: const InputDecoration(
                      labelText: 'Tipo de identificación'),
                  items: const [
                    DropdownMenuItem(
                        value: 'CC', child: Text('Cédula de Ciudadanía')),
                    DropdownMenuItem(
                        value: 'CE', child: Text('Cédula de Extranjería')),
                    DropdownMenuItem(value: 'NIT', child: Text('NIT')),
                    DropdownMenuItem(
                        value: 'PASAPORTE', child: Text('Pasaporte')),
                  ],
                  onChanged: _saving
                      ? null
                      : (value) => setState(() => _identificationType = value!),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _cellPhoneController,
                  decoration:
                      const InputDecoration(labelText: 'Teléfono celular'),
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      return _validateNumericNoDecimals(value, 'Teléfono');
                    }
                    return null;
                  },
                  enabled: !_saving,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emailController,
                  decoration:
                      const InputDecoration(labelText: 'Correo electrónico'),
                  keyboardType: TextInputType.emailAddress,
                  enabled: !_saving,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _addressController,
                  decoration: const InputDecoration(labelText: 'Dirección'),
                  enabled: !_saving,
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _type,
                  decoration: const InputDecoration(labelText: 'Tipo'),
                  items: const [
                    DropdownMenuItem(value: 'Customer', child: Text('Cliente')),
                    DropdownMenuItem(
                        value: 'Supplier', child: Text('Proveedor')),
                  ],
                  onChanged: _saving
                      ? null
                      : (value) => setState(() => _type = value!),
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
      ),
    );
  }
}
