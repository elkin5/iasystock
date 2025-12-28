import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../cubits/menu/sale_cubit.dart';
import '../../../models/menu/sale_model.dart';
import '../../../models/menu/person_model.dart';
import '../../../models/menu/user_model.dart';
import '../../../widgets/menu/generic_list_screen.dart';
import '../../../widgets/notification_helper.dart';
import '../../../services/menu/person_service.dart';
import '../../../services/menu/user_service.dart';
import '../../../config/get_it_config.dart';

class SaleListScreen extends StatefulWidget {
  const SaleListScreen({super.key});

  @override
  State<SaleListScreen> createState() => _SaleListScreenState();
}

class _SaleListScreenState extends State<SaleListScreen> {
  @override
  void initState() {
    super.initState();
    context.read<SaleCubit>().loadSales();
  }

  Future<void> _navigateToForm({SaleModel? sale}) async {
    await context.push('/sales/form', extra: sale);
    context.read<SaleCubit>().loadSales();
  }

  Future<void> _showSaleDetail(SaleModel sale) async {
    try {
      // Obtener información del cliente si existe
      String clientInfo = 'Sin cliente';
      if (sale.personId != null) {
        try {
          final personService = getIt<PersonService>();
          final person = await personService.getById(sale.personId!);
          clientInfo =
              '${person.name} (${person.identificationType}: ${person.identification})';
        } catch (e) {
          clientInfo = 'Cliente ID: ${sale.personId}';
        }
      }

      // Obtener información del usuario
      String userInfo = 'Usuario ID: ${sale.userId}';
      try {
        final userService = getIt<UserService>();
        final user = await userService.getById(sale.userId);
        userInfo =
            '${user.firstName ?? ''} ${user.lastName ?? ''} (${user.username})'
                .trim();
      } catch (e) {
        // Mantener el ID si no se puede obtener el nombre
      }

      // Usar el monto total almacenado en la base de datos
      String totalInfo = '\$${sale.totalAmount.toStringAsFixed(2)}';

      // Formatear fecha de creación con tiempo completo
      String createdAtInfo = 'Sin fecha';
      if (sale.createdAt != null) {
        createdAtInfo =
            DateFormat('yyyy-MM-dd HH:mm:ss').format(sale.createdAt!);
      }

      // Formatear fecha de venta
      String saleDateInfo = 'Sin fecha';
      if (sale.saleDate != null) {
        saleDateInfo =
            DateFormat('yyyy-MM-dd HH:mm:ss').format(sale.saleDate!);
      }

      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => EntityDetailDialog(
            title: 'Detalle Venta #${sale.id}',
            fields: {
              'ID': sale.id.toString(),
              'Cliente': clientInfo,
              'Usuario': userInfo,
              'Monto total': totalInfo,
              'Método de pago': sale.payMethod ?? 'Sin método',
              'Estado': sale.state ?? 'Sin estado',
              'Fecha venta': saleDateInfo,
              'Fecha creación': createdAtInfo,
            },
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        NotificationHelper.showError(
            context, 'Error al cargar detalles: ${e.toString()}');
      }
    }
  }

  Future<void> _onDelete(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar venta'),
        content: const Text('¿Seguro que deseas eliminar esta venta?'),
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
        await context.read<SaleCubit>().deleteSale(id);
        NotificationHelper.showSuccess(
            context, 'Venta eliminada correctamente');
        context.read<SaleCubit>().loadSales();
      } on DioException catch (e) {
        final message = e.response?.data['message'] ?? 'Error eliminando venta';
        NotificationHelper.showError(context, message);
      } catch (e) {
        NotificationHelper.showError(context, 'Error eliminando venta');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SaleCubit, SaleState>(
      builder: (context, state) {
        if (state is SaleLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is SaleLoaded) {
          return GenericListScreen<SaleModel>(
            title: 'Ventas',
            items: state.sales,
            searchHint: 'Buscar por estado o monto...',
            searchTextExtractor: (s) => "${s.state} ${s.totalAmount}",
            onAddPressed: () => _navigateToForm(),
            itemBuilder: (context, sale) {
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 6),
                elevation: 2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  leading: const Icon(Icons.point_of_sale,
                      size: 32, color: Colors.blueGrey),
                  title: Text('Venta #${sale.id}',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    'Total: \$${sale.totalAmount} — Estado: ${sale.state ?? 'Sin estado'}\n'
                    'Fecha: ${sale.saleDate != null ? DateFormat('yyyy-MM-dd HH:mm:ss').format(sale.saleDate!) : 'Sin fecha'}',
                  ),
                  onTap: () => _showSaleDetail(sale),
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
                          onPressed: () => _navigateToForm(sale: sale)),
                      IconButton(
                          icon: const Icon(Icons.delete, size: 20),
                          iconSize: 20,
                          padding: const EdgeInsets.all(4),
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                          onPressed: () => _onDelete(sale.id!)),
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
