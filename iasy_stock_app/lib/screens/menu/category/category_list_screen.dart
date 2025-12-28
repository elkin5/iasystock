import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../cubits/menu/category_cubit.dart';
import '../../../models/menu/category_model.dart';
import '../../../widgets/menu/generic_list_screen.dart';
import '../../../widgets/notification_helper.dart';

class CategoryListScreen extends StatefulWidget {
  const CategoryListScreen({super.key});

  @override
  State<CategoryListScreen> createState() => _CategoryListScreenState();
}

class _CategoryListScreenState extends State<CategoryListScreen> {
  @override
  void initState() {
    super.initState();
    context.read<CategoryCubit>().loadCategories(refresh: true);
  }

  Future<void> _navigateToForm({CategoryModel? category}) async {
    await context.push('/categories/form', extra: category);
    context.read<CategoryCubit>().loadCategories(refresh: true);
  }

  Future<void> _onDelete(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar categoría'),
        content: const Text('¿Seguro que deseas eliminar esta categoría?'),
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
        await context.read<CategoryCubit>().deleteCategory(id);
        NotificationHelper.showSuccess(
            context, 'Categoría eliminada correctamente');
        context.read<CategoryCubit>().loadCategories(refresh: true);
      } on DioException catch (e) {
        final message =
            e.response?.data['message'] ?? 'Error eliminando categoría';
        NotificationHelper.showError(context, message);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CategoryCubit, CategoryState>(
      builder: (context, state) {
        if (state is CategoryLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state is CategoryLoaded) {
          return GenericInfiniteListScreen<CategoryModel>(
            title: 'Categorías',
            items: state.categories,
            searchHint: 'Buscar por nombre o descripción...',
            searchTextExtractor: (cat) =>
                '${cat.name} ${cat.description ?? ''}',
            onAddPressed: () => _navigateToForm(),
            onLoadMore: () =>
                context.read<CategoryCubit>().loadMoreCategories(),
            isLoadingMore: state.isLoadingMore,
            hasMoreData: state.hasMoreData,
            itemBuilder: (context, category) => Card(
              margin: const EdgeInsets.symmetric(vertical: 6),
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                leading: const Icon(Icons.category,
                    size: 32, color: Colors.blueGrey),
                title: Text(category.name,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(category.description ?? 'Sin descripción'),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => EntityDetailDialog(
                      title: 'Detalle Categoría',
                      fields: {
                        'ID': category.id.toString(),
                        'Nombre': category.name,
                        'Descripción': category.description ?? '',
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
                        onPressed: () => _navigateToForm(category: category)),
                    IconButton(
                        icon: const Icon(Icons.delete, size: 20),
                        iconSize: 20,
                        padding: const EdgeInsets.all(4),
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                        onPressed: () => _onDelete(category.id!)),
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
