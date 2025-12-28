import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../cubits/menu/promotion_cubit.dart';
import '../../../models/menu/promotion_model.dart';
import '../../../widgets/menu/generic_list_screen.dart';
import '../../../widgets/notification_helper.dart';

class PromotionListScreen extends StatefulWidget {
  const PromotionListScreen({super.key});

  @override
  State<PromotionListScreen> createState() => _PromotionListScreenState();
}

class _PromotionListScreenState extends State<PromotionListScreen> {
  @override
  void initState() {
    super.initState();
    context.read<PromotionCubit>().loadPromotions();
  }

  Future<void> _navigateToForm({PromotionModel? promotion}) async {
    await context.push('/promotions/form', extra: promotion);
    context.read<PromotionCubit>().loadPromotions();
  }

  Future<void> _onDelete(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar promoción'),
        content: const Text('¿Estás seguro de eliminar esta promoción?'),
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
        await context.read<PromotionCubit>().deletePromotion(id);
        NotificationHelper.showSuccess(
            context, 'Promoción eliminada correctamente');
        context.read<PromotionCubit>().loadPromotions();
      } on DioException catch (e) {
        final message =
            e.response?.data['message'] ?? 'Error eliminando promoción';
        NotificationHelper.showError(context, message);
      } catch (e) {
        NotificationHelper.showError(context, 'Error eliminando promoción');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PromotionCubit, PromotionState>(
      builder: (context, state) {
        if (state is PromotionLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is PromotionLoaded) {
          return GenericListScreen<PromotionModel>(
            title: 'Promociones',
            items: state.promotions,
            searchHint: 'Buscar por descripción...',
            searchTextExtractor: (p) => p.description,
            onAddPressed: () => _navigateToForm(),
            itemBuilder: (context, promotion) {
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 6),
                elevation: 2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  leading: const Icon(Icons.percent,
                      size: 32, color: Colors.deepPurple),
                  title: Text(promotion.description,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Descuento: ${promotion.discountRate}%'),
                      Text(
                          'Desde: ${DateFormat('yyyy-MM-dd').format(promotion.startDate!)}'),
                      Text(
                          'Hasta: ${DateFormat('yyyy-MM-dd').format(promotion.endDate!)}'),
                    ],
                  ),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => EntityDetailDialog(
                        title: 'Detalle Promoción',
                        fields: {
                          'ID': promotion.id.toString(),
                          'Descripción': promotion.description,
                          'Descuento': '${promotion.discountRate}%',
                          'Inicio': DateFormat('yyyy-MM-dd')
                              .format(promotion.startDate!),
                          'Fin': DateFormat('yyyy-MM-dd')
                              .format(promotion.endDate!),
                          'Producto ID':
                              promotion.productId?.toString() ?? 'No asignado',
                          'Categoría ID': promotion.categoryId.toString(),
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
                              _navigateToForm(promotion: promotion)),
                      IconButton(
                          icon: const Icon(Icons.delete, size: 20),
                          iconSize: 20,
                          padding: const EdgeInsets.all(4),
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                          onPressed: () => _onDelete(promotion.id!)),
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
