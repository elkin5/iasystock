import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../cubits/menu/general_settings_cubit.dart';
import '../../../models/menu/general_settings_model.dart';
import '../../../widgets/menu/generic_list_screen.dart';
import '../../../widgets/notification_helper.dart';

class GeneralSettingsListScreen extends StatefulWidget {
  const GeneralSettingsListScreen({super.key});

  @override
  State<GeneralSettingsListScreen> createState() =>
      _GeneralSettingsListScreenState();
}

class _GeneralSettingsListScreenState extends State<GeneralSettingsListScreen> {
  @override
  void initState() {
    super.initState();
    context.read<GeneralSettingsCubit>().loadSettings();
  }

  Future<void> _navigateToForm({GeneralSettingsModel? setting}) async {
    await context.push('/general_settings/form', extra: setting);
    context.read<GeneralSettingsCubit>().loadSettings();
  }

  Future<void> _onDelete(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar configuración'),
        content: const Text('¿Seguro que deseas eliminar esta configuración?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child:
                  const Text('Eliminar', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await context.read<GeneralSettingsCubit>().deleteSetting(id);
        NotificationHelper.showSuccess(
            context, 'Configuración eliminada correctamente');
        context.read<GeneralSettingsCubit>().loadSettings();
      } on DioException catch (e) {
        final message =
            e.response?.data['message'] ?? 'Error eliminando configuración';
        NotificationHelper.showError(context, message);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GeneralSettingsCubit, GeneralSettingsState>(
      builder: (context, state) {
        if (state is GeneralSettingsLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is GeneralSettingsLoaded) {
          return GenericListScreen<GeneralSettingsModel>(
            title: 'Configuraciones Generales',
            items: state.settings,
            searchHint: 'Buscar por clave, valor o descripción...',
            searchTextExtractor: (s) =>
                '${s.key} ${s.value ?? ''} ${s.description ?? ''}',
            onAddPressed: () => _navigateToForm(),
            itemBuilder: (context, setting) => Card(
              margin: const EdgeInsets.symmetric(vertical: 6),
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                leading:
                    const Icon(Icons.settings, size: 32, color: Colors.teal),
                title: Text(setting.key,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Valor: ${setting.value ?? 'Sin valor'}'),
                    Text(setting.description ?? 'Sin descripción'),
                  ],
                ),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => EntityDetailDialog(
                      title: 'Detalle Configuración',
                      fields: {
                        'ID': setting.id.toString(),
                        'Clave': setting.key,
                        'Valor': setting.value ?? '',
                        'Descripción': setting.description ?? '',
                      },
                    ),
                  );
                },
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                        icon: const Icon(Icons.edit, size: 20),
                        iconSize: 20,
                        padding: const EdgeInsets.all(4),
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                        onPressed: () => _navigateToForm(setting: setting)),
                    IconButton(
                        icon: const Icon(Icons.delete, size: 20),
                        iconSize: 20,
                        padding: const EdgeInsets.all(4),
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                        onPressed: () => _onDelete(setting.id!)),
                  ],
                ),
              ),
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}
