import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../cubits/menu/user_cubit.dart';
import '../../../models/menu/user_model.dart';
import '../../../widgets/menu/generic_list_screen.dart';
import '../../../widgets/notification_helper.dart';

class UserListScreen extends StatefulWidget {
  const UserListScreen({super.key});

  @override
  State<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  @override
  void initState() {
    super.initState();
    context.read<UserCubit>().loadUsers(refresh: true);
  }

  Future<void> _navigateToForm({UserModel? user}) async {
    await context.push('/users/form', extra: user);
    context.read<UserCubit>().loadUsers(refresh: true);
  }

  Future<void> _onDelete(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar usuario'),
        content: const Text('¿Seguro que deseas eliminar este usuario?'),
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
        await context.read<UserCubit>().deleteUser(id);
        NotificationHelper.showSuccess(
            context, 'Usuario eliminado correctamente');
        context.read<UserCubit>().loadUsers(refresh: true);
      } on DioException catch (e) {
        final message =
            e.response?.data['message'] ?? 'Error eliminando usuario';
        NotificationHelper.showError(context, message);
      } catch (e) {
        NotificationHelper.showError(context, 'Error eliminando usuario');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UserCubit, UserState>(
      builder: (context, state) {
        if (state is UserLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is UserLoaded) {
          return GenericInfiniteListScreen<UserModel>(
            title: 'Usuarios',
            items: state.users,
            searchHint: 'Buscar por username o email...',
            searchTextExtractor: (user) =>
                '${user.username} ${user.email ?? ''}',
            onAddPressed: () => _navigateToForm(),
            onLoadMore: () => context.read<UserCubit>().loadMoreUsers(),
            isLoadingMore: state.isLoadingMore,
            hasMoreData: state.hasMoreData,
            itemBuilder: (context, user) {
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 6),
                elevation: 2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  leading: Icon(
                    user.role?.toLowerCase() == 'admin'
                        ? Icons.verified_user
                        : Icons.person,
                    color: user.role?.toLowerCase() == 'admin'
                        ? Colors.green
                        : Colors.blueGrey,
                    size: 32,
                  ),
                  title: Text(user.username ?? 'Sin nombre',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user.email ?? 'Sin correo'),
                      Text('Rol: ${user.role}'),
                    ],
                  ),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => EntityDetailDialog(
                        title: 'Detalle Usuario',
                        fields: {
                          'ID': user.id.toString(),
                          'Username': user.username ?? 'Sin nombre',
                          'Email': user.email ?? 'No registrado',
                          'Rol': user.role ?? 'Sin rol',
                          'Creado': user.createdAt?.toString() ?? '',
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
                          onPressed: () => _navigateToForm(user: user)),
                      IconButton(
                          icon: const Icon(Icons.delete, size: 20),
                          iconSize: 20,
                          padding: const EdgeInsets.all(4),
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                          onPressed: () => _onDelete(user.id!)),
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
