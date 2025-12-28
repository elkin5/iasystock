import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../cubits/menu/general_settings_cubit.dart';
import '../../../models/menu/general_settings_model.dart';
import '../../../widgets/notification_helper.dart';

class GeneralSettingsFormScreen extends StatefulWidget {
  final GeneralSettingsModel? setting;

  const GeneralSettingsFormScreen({super.key, this.setting});

  @override
  State<GeneralSettingsFormScreen> createState() =>
      _GeneralSettingsFormScreenState();
}

class _GeneralSettingsFormScreenState extends State<GeneralSettingsFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _keyController;
  late TextEditingController _valueController;
  late TextEditingController _descriptionController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final s = widget.setting;
    _keyController = TextEditingController(text: s?.key ?? '');
    _valueController = TextEditingController(text: s?.value ?? '');
    _descriptionController = TextEditingController(text: s?.description ?? '');
  }

  Future<void> _saveForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _saving = true);

      final setting = GeneralSettingsModel(
        id: widget.setting?.id ?? 0,
        key: _keyController.text,
        value: _valueController.text,
        description: _descriptionController.text.isNotEmpty
            ? _descriptionController.text
            : null,
      );

      try {
        if (widget.setting == null) {
          await context.read<GeneralSettingsCubit>().createSetting(setting);
          NotificationHelper.showSuccess(
              context, 'Configuración creada correctamente');
        } else {
          await context.read<GeneralSettingsCubit>().updateSetting(setting);
          NotificationHelper.showSuccess(
              context, 'Configuración actualizada correctamente');
        }
        if (mounted) Navigator.pop(context);
      } on DioException catch (e) {
        final message =
            e.response?.data['message'] ?? 'Error guardando la configuración';
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
    final isEditing = widget.setting != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar Configuración' : 'Crear Configuración'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _keyController,
                decoration: const InputDecoration(labelText: 'Clave'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Campo requerido' : null,
                enabled: !_saving,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _valueController,
                decoration: const InputDecoration(labelText: 'Valor'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Campo requerido' : null,
                enabled: !_saving,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                decoration:
                    const InputDecoration(labelText: 'Descripción (opcional)'),
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
