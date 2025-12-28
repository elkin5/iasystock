import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../cubits/menu/warehouse_cubit.dart';
import '../../../models/menu/warehouse_model.dart';
import '../../../widgets/menu/generic_list_screen.dart';
import '../../../widgets/notification_helper.dart';

class WarehouseListScreen extends StatefulWidget {
  const WarehouseListScreen({super.key});

  @override
  State<WarehouseListScreen> createState() => _WarehouseListScreenState();
}

class _WarehouseListScreenState extends State<WarehouseListScreen> {
  @override
  void initState() {
    super.initState();
    context.read<WarehouseCubit>().loadWarehouses();
  }

  Future<void> _navigateToForm({WarehouseModel? warehouse}) async {
    await context.push('/warehouses/form', extra: warehouse);
    context.read<WarehouseCubit>().loadWarehouses();
  }

  Future<void> _onDelete(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar almacén'),
        content: const Text('¿Seguro que deseas eliminar este almacén?'),
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
        await context.read<WarehouseCubit>().deleteWarehouse(id);
        NotificationHelper.showSuccess(
            context, 'Almacén eliminado correctamente');
        context.read<WarehouseCubit>().loadWarehouses();
      } on DioException catch (e) {
        final message =
            e.response?.data['message'] ?? 'Error eliminando almacén';
        NotificationHelper.showError(context, message);
      } catch (e) {
        NotificationHelper.showError(context, 'Error eliminando almacén');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WarehouseCubit, WarehouseState>(
      builder: (context, state) {
        if (state is WarehouseLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is WarehouseLoaded) {
          return GenericListScreen<WarehouseModel>(
            title: 'Almacenes',
            items: state.warehouses,
            searchHint: 'Buscar por nombre o ubicación...',
            searchTextExtractor: (w) => '${w.name} ${w.location ?? ''}',
            onAddPressed: () => _navigateToForm(),
            itemBuilder: (context, warehouse) {
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 6),
                elevation: 2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  leading: const Icon(Icons.warehouse,
                      color: Colors.brown, size: 32),
                  title: Text(warehouse.name ?? 'Sin nombre',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(warehouse.location ?? 'Sin ubicación'),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => EntityDetailDialog(
                        title: 'Detalle Almacén',
                        fields: {
                          'ID': warehouse.id.toString(),
                          'Nombre': warehouse.name ?? 'Sin nombre',
                          'Ubicación': warehouse.location ?? 'No especificada',
                          'Creado': warehouse.createdAt?.toString() ?? '',
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
                          onPressed: () =>
                              _navigateToForm(warehouse: warehouse)),
                      IconButton(
                          icon: const Icon(Icons.delete, size: 20),
                          iconSize: 20,
                          padding: const EdgeInsets.all(4),
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                          onPressed: () => _onDelete(warehouse.id!)),
                    ],
                  ),
                ),
              );
            },
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}
