import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../cubits/auth/auth_cubit.dart';
import '../cubits/auth/auth_state.dart';
import 'main_screen.dart';

class UserOptionsScreen extends StatelessWidget {
  final Color primaryColor;
  final bool isDarkMode;
  final ValueChanged<bool> onThemeChanged;

  const UserOptionsScreen({
    super.key,
    required this.primaryColor,
    required this.isDarkMode,
    required this.onThemeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final options = _getOptions(context);

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          GeneralSliverAppBar(
            title: 'Perfil de Usuario',
            subtitle: 'Configuración y opciones',
            icon: Icons.person_rounded,
            primaryColor: theme.primaryColor,
            onLogout: () => context.read<AuthCubit>().signOut(),
          ),
        ],
        body: Column(
          children: [
            // Encabezado retraible se mueve al SliverAppBar

            // Lista adaptativa
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth >= 800;

                  if (isWide) {
                    return GridView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                      itemCount: options.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 20,
                        mainAxisSpacing: 20,
                        childAspectRatio: 3.2,
                      ),
                      itemBuilder: (context, index) => options[index],
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    itemCount: options.length,
                    itemBuilder: (context, index) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: options[index],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _getOptions(BuildContext context) {
    return [
      _buildOption(
        context,
        icon: Icons.edit,
        text: 'Editar Usuario',
        onTap: () => context.push('/user_config/edit_user'),
      ),
      _buildOption(
        context,
        icon: Icons.brightness_6,
        text: 'Cambiar Tema',
        onTap: () => context.push(
          Uri(
            path: '/user_config/change_theme',
            queryParameters: {
              'darkMode': isDarkMode.toString(),
            },
          ).toString(),
        ),
      ),
      _buildOption(
        context,
        icon: Icons.system_update,
        text: 'Actualizar Aplicación',
        onTap: () => context.push('/user_config/update_app'),
      ),
      _buildOption(
        context,
        icon: Icons.upgrade,
        text: 'Actualizar a Premium',
        onTap: () => context.push('/user_config/upgrade_premium'),
      ),
      _buildOption(
        context,
        icon: Icons.contact_support,
        text: 'Contacto',
        onTap: () => context.push('/user_config/contact'),
      ),
      _buildOption(
        context,
        icon: Icons.info,
        text: 'Acerca de',
        onTap: () => context.push('/user_config/about'),
      ),
      // Botón de logout
      _buildLogoutOption(context),
    ];
  }

  Widget _buildLogoutOption(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        if (state is AuthStateAuthenticated) {
          return _buildOption(
            context,
            icon: Icons.logout,
            text: 'Cerrar Sesión',
            onTap: () => _showLogoutDialog(context),
            isDestructive: true,
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cerrar Sesión'),
          content: const Text('¿Estás seguro de que quieres cerrar sesión?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.read<AuthCubit>().signOut();
              },
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              child: const Text('Cerrar Sesión'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildOption(BuildContext context,
      {required IconData icon,
      required String text,
      required VoidCallback onTap,
      bool isDestructive = false}) {
    final theme = Theme.of(context);
    final textColor =
        isDestructive ? theme.colorScheme.error : theme.colorScheme.onSurface;
    final iconColor = isDestructive
        ? theme.colorScheme.error
        : (theme.iconTheme.color ?? theme.colorScheme.onSurface);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDestructive
              ? theme.colorScheme.error.withOpacity(0.2)
              : theme.dividerColor.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          hoverColor: isDestructive
              ? theme.colorScheme.error.withOpacity(0.05)
              : theme.primaryColor.withOpacity(0.05),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDestructive
                        ? theme.colorScheme.error.withOpacity(0.1)
                        : theme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: iconColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    text,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: isDestructive
                        ? theme.colorScheme.error.withOpacity(0.1)
                        : theme.colorScheme.surfaceVariant.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: iconColor.withOpacity(0.7),
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
