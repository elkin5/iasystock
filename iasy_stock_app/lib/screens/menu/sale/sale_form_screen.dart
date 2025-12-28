import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../cubits/menu/person_cubit.dart';
import '../../../cubits/menu/sale_cubit.dart';
import '../../../models/menu/sale_model.dart';
import '../../../models/menu/user_model.dart';
import '../../../widgets/notification_helper.dart';
import '../../../widgets/current_user_field.dart';
import '../../../widgets/calculated_total_field.dart';

class SaleFormScreen extends StatefulWidget {
  final SaleModel? sale;

  const SaleFormScreen({super.key, this.sale});

  @override
  State<SaleFormScreen> createState() => _SaleFormScreenState();
}

class _SaleFormScreenState extends State<SaleFormScreen> {
  final _formKey = GlobalKey<FormState>();
  DateTime? _saleDate;
  String? _selectedPerson;
  int? _selectedUserId;
  String? _selectedState;
  String? _selectedPayMethod;
  bool _saving = false;
  double _calculatedTotal = 0.0;

  final List<String> _states = ['Pendiente', 'Completada', 'Cancelada'];
  final List<String> _payMethods = [
    'Efectivo',
    'Tarjeta',
    'Electrónico',
    'Otro'
  ];

  @override
  void initState() {
    super.initState();
    final s = widget.sale;
    _saleDate = s?.saleDate ?? DateTime.now();
    _selectedState = s?.state ?? 'Pendiente';
    _selectedPayMethod = s?.payMethod ?? 'Efectivo';
    if (s != null) {
      _selectedPerson = s.personId?.toString();
      _selectedUserId = s.userId;
      _calculatedTotal = s.totalAmount;
    }

    context.read<PersonCubit>().findByType('Customer');
  }

  Future<void> _saveForm() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedUserId == null) {
        NotificationHelper.showError(
            context, 'Error: No se pudo obtener el usuario actual');
        return;
      }

      if (_selectedPerson == null) {
        NotificationHelper.showError(
            context, 'Debe seleccionar un cliente para la venta');
        return;
      }

      setState(() => _saving = true);

      final sale = SaleModel(
        id: widget.sale?.id ?? 0,
        personId: int.parse(_selectedPerson!),
        userId: _selectedUserId!,
        totalAmount: _calculatedTotal,
        saleDate: _saleDate,
        payMethod: _selectedPayMethod,
        state: _selectedState,
        createdAt: widget.sale?.createdAt ?? DateTime.now(),
      );

      try {
        if (widget.sale == null) {
          await context.read<SaleCubit>().createSale(sale);
          NotificationHelper.showSuccess(
              context, 'Venta registrada correctamente');
        } else {
          await context.read<SaleCubit>().updateSale(sale);
          NotificationHelper.showSuccess(
              context, 'Venta actualizada correctamente');
        }
        if (mounted) Navigator.pop(context);
      } on DioException catch (e) {
        final message =
            e.response?.data['message'] ?? 'Error guardando la venta';
        NotificationHelper.showError(context, message);
        if (mounted) setState(() => _saving = false);
      } catch (e) {
        NotificationHelper.showError(
            context, 'Error inesperado: ${e.toString()}');
        if (mounted) setState(() => _saving = false);
      }
    }
  }

  String? _getValidSelectedPerson(List<dynamic> persons) {
    if (_selectedPerson == null) return null;

    // Verificar si el cliente seleccionado existe en la lista
    final personExists =
        persons.any((person) => person.id?.toString() == _selectedPerson);
    if (personExists) {
      return _selectedPerson;
    }

    // Si no existe, limpiar la selección
    _selectedPerson = null;
    return null;
  }

  List<DropdownMenuItem<String>> _buildPersonDropdownItems(
      List<dynamic> persons) {
    // Eliminar duplicados basándose en el ID
    final uniquePersons = <int, dynamic>{};
    for (final person in persons) {
      if (person.id != null) {
        uniquePersons[person.id] = person;
      }
    }

    return uniquePersons.values.map((person) {
      return DropdownMenuItem(
        value: person.id?.toString(),
        child: Text(person.name ?? 'Sin nombre'),
      );
    }).toList();
  }

  String? _getValidSelectedPayMethod() {
    if (_selectedPayMethod == null) return 'Efectivo';

    // Verificar si el método de pago seleccionado existe en la lista
    if (_payMethods.contains(_selectedPayMethod)) {
      return _selectedPayMethod;
    }

    // Si no existe, usar el valor por defecto
    _selectedPayMethod = 'Efectivo';
    return 'Efectivo';
  }

  String? _getValidSelectedState() {
    if (_selectedState == null) return 'Pendiente';

    // Verificar si el estado seleccionado existe en la lista
    if (_states.contains(_selectedState)) {
      return _selectedState;
    }

    // Si no existe, usar el valor por defecto
    _selectedState = 'Pendiente';
    return 'Pendiente';
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.sale != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar Venta' : 'Registrar Venta'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: BlocBuilder<PersonCubit, PersonState>(
          builder: (context, personState) {
            if (personState is PersonLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (personState is PersonLoaded) {
              final persons = personState.persons;

              return Form(
                key: _formKey,
                child: ListView(
                  children: [
                    DropdownButtonFormField<String>(
                      value: _getValidSelectedPerson(persons),
                      decoration: const InputDecoration(labelText: 'Cliente *'),
                      items: _buildPersonDropdownItems(persons),
                      onChanged: _saving
                          ? null
                          : (val) => setState(() => _selectedPerson = val),
                      validator: (value) =>
                          value == null ? 'Debe seleccionar un cliente' : null,
                    ),
                    const SizedBox(height: 8),
                    CurrentUserField(
                      onUserLoaded: (user) {
                        setState(() {
                          _selectedUserId = user.id;
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    CalculatedTotalField(
                      saleId: widget.sale?.id,
                      onTotalCalculated: (total) {
                        setState(() {
                          _calculatedTotal = total;
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _getValidSelectedPayMethod(),
                      decoration:
                          const InputDecoration(labelText: 'Método de pago'),
                      items: _payMethods.map((method) {
                        return DropdownMenuItem(
                          value: method,
                          child: Text(method),
                        );
                      }).toList(),
                      onChanged: _saving
                          ? null
                          : (val) => setState(() => _selectedPayMethod = val),
                      validator: (value) => null, // Método de pago es opcional
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _getValidSelectedState(),
                      decoration: const InputDecoration(labelText: 'Estado'),
                      items: _states.map((state) {
                        return DropdownMenuItem(
                          value: state,
                          child: Text(state),
                        );
                      }).toList(),
                      onChanged: _saving
                          ? null
                          : (val) => setState(() => _selectedState = val),
                      validator: (value) => null, // Estado es opcional
                    ),
                    const SizedBox(height: 8),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Fecha de venta'),
                      subtitle: Text(
                        _saleDate == null
                            ? 'Fecha no disponible'
                            : DateFormat('yyyy-MM-dd HH:mm:ss')
                                .format(_saleDate!),
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
                      enabled: false,
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
              return const Center(child: Text('Error cargando clientes'));
            }
          },
        ),
      ),
    );
  }
}
