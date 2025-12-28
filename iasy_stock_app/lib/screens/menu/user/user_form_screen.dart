import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../cubits/menu/user_cubit.dart';
import '../../../models/menu/user_model.dart';
import '../../../widgets/notification_helper.dart';

class UserFormScreen extends StatefulWidget {
  final UserModel? user;

  const UserFormScreen({super.key, this.user});

  @override
  State<UserFormScreen> createState() => _UserFormScreenState();
}

class _UserFormScreenState extends State<UserFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _usernameController;
  late TextEditingController _passwordController;
  late TextEditingController _emailController;
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  String _role = 'user';
  bool _isActive = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _usernameController =
        TextEditingController(text: widget.user?.username ?? '');
    _passwordController = TextEditingController();
    _emailController = TextEditingController(text: widget.user?.email ?? '');
    _firstNameController =
        TextEditingController(text: widget.user?.firstName ?? '');
    _lastNameController =
        TextEditingController(text: widget.user?.lastName ?? '');
    _role = widget.user?.role ?? 'user';
    _isActive = widget.user?.isActive ?? true;
  }

  Future<void> _saveForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _saving = true);

      final user = UserModel(
        id: widget.user?.id ?? 0,
        username: _usernameController.text,
        password: widget.user == null
            ? _passwordController.text
            : widget.user!.password,
        email: _emailController.text.isNotEmpty ? _emailController.text : null,
        firstName: _firstNameController.text.isNotEmpty
            ? _firstNameController.text
            : null,
        lastName: _lastNameController.text.isNotEmpty
            ? _lastNameController.text
            : null,
        role: _role,
        isActive: _isActive,
        createdAt: widget.user?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      try {
        if (widget.user == null) {
          await context.read<UserCubit>().createUser(user);
          NotificationHelper.showSuccess(
              context, 'Usuario creado correctamente');
        } else {
          await context.read<UserCubit>().updateUser(user);
          NotificationHelper.showSuccess(
              context, 'Usuario actualizado correctamente');
        }
        Navigator.pop(context);
      } on DioException catch (e) {
        final message =
            e.response?.data['message'] ?? 'Error guardando el usuario';
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
    final isEditing = widget.user != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar Usuario' : 'Crear Usuario'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _usernameController,
                decoration:
                    const InputDecoration(labelText: 'Nombre de usuario'),
                validator: _requiredValidator,
                enabled: !_saving,
              ),
              const SizedBox(height: 8),
              if (!isEditing)
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Contraseña'),
                  validator: _requiredValidator,
                  enabled: !_saving,
                ),
              if (isEditing)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline,
                          color: Colors.grey, size: 18),
                      const SizedBox(width: 4),
                      Text(
                        'La contraseña se mantiene igual',
                        style: TextStyle(color: Colors.grey[700], fontSize: 13),
                      ),
                    ],
                  ),
                ),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                    labelText: 'Correo electrónico (opcional)'),
                keyboardType: TextInputType.emailAddress,
                enabled: !_saving,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _firstNameController,
                decoration:
                    const InputDecoration(labelText: 'Nombre (opcional)'),
                enabled: !_saving,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _lastNameController,
                decoration:
                    const InputDecoration(labelText: 'Apellido (opcional)'),
                enabled: !_saving,
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _role,
                decoration: const InputDecoration(labelText: 'Rol'),
                items: const [
                  DropdownMenuItem(
                      value: 'admin', child: Text('Administrador')),
                  DropdownMenuItem(value: 'manager', child: Text('Gerente')),
                  DropdownMenuItem(value: 'user', child: Text('Usuario')),
                ],
                onChanged:
                    _saving ? null : (value) => setState(() => _role = value!),
                validator: _requiredValidator,
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                title: const Text('Usuario activo'),
                subtitle: Text(_isActive
                    ? 'El usuario puede acceder al sistema'
                    : 'El usuario no puede acceder al sistema'),
                value: _isActive,
                onChanged: _saving
                    ? null
                    : (value) => setState(() => _isActive = value),
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

  String? _requiredValidator(String? value) =>
      value == null || value.trim().isEmpty ? 'Campo requerido' : null;
}
