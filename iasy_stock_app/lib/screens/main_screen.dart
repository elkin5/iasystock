import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../cubits/auth/auth_cubit.dart';
import '../cubits/auth/auth_state.dart';
import '../theme/app_colors.dart';

class MainScreen extends StatefulWidget {
  final bool isDarkMode;
  final ValueChanged<bool> onThemeChanged;
  final Widget child; // 👈 Recibe el contenido dinámico desde el router

  const MainScreen({
    super.key,
    required this.isDarkMode,
    required this.onThemeChanged,
    required this.child,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 1;

  // Las rutas a las que se debe navegar con BottomNavigationBar
  final List<String> _tabs = ['/menu', '/home', '/user'];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    // Navegación declarativa a la ruta correspondiente
    // usando GoRouter
    Future.microtask(() {
      if (mounted) context.go(_tabs[index]);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final location = GoRouterState.of(context).uri.toString();
    final index = _tabs.indexWhere((tab) => location.startsWith(tab));
    if (index != -1 && index != _selectedIndex) {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    final accentColor = Theme.of(context).colorScheme.secondary;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: const Center(
          child: Text('IASY STOCK'),
        ),
      ),
      body: widget.child, // 👈 renderiza la ruta activa
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: backgroundColor,
        selectedItemColor: accentColor,
        unselectedItemColor: AppColors.textMuted(context),
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.menu), label: 'Menu'),
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Usuario'),
        ],
      ),
    );
  }
}

/// Widget generalizado para SliverAppBar con título, subtítulo y información del usuario
class GeneralSliverAppBar extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color? primaryColor;
  final double expandedHeight;
  final bool showUserInfo;
  final VoidCallback? onLogout;

  const GeneralSliverAppBar({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.primaryColor,
    this.expandedHeight = 200.0,
    this.showUserInfo = true,
    this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final resolvedPrimaryColor = primaryColor ?? theme.primaryColor;

    return SliverAppBar(
      expandedHeight: expandedHeight,
      floating: false,
      pinned: false,
      backgroundColor: resolvedPrimaryColor,
      flexibleSpace: FlexibleSpaceBar(
        background: _buildHeader(context, theme, resolvedPrimaryColor),
      ),
    );
  }

  Widget _buildHeader(
      BuildContext context, ThemeData theme, Color primaryColor) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            primaryColor,
            primaryColor.withOpacity(0.8),
            AppColors.primary(context).withOpacity(0.6),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SafeArea(
        top: true,
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          child: Column(
            children: [
              Row(
                children: [
                  // Icono de la aplicación
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.onPrimary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.onPrimary.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      icon,
                      color: AppColors.onPrimary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: theme.textTheme.displayMedium?.copyWith(
                            color: AppColors.onPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 24,
                          ),
                        ),
                        Text(
                          subtitle,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppColors.onPrimary.withOpacity(0.9),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Avatar del usuario con menú desplegable
                  if (showUserInfo)
                    BlocBuilder<AuthCubit, AuthState>(
                      builder: (context, state) {
                        if (state is AuthStateAuthenticated) {
                          return PopupMenuButton<String>(
                            icon: CircleAvatar(
                              radius: 24,
                              backgroundColor:
                                  AppColors.onPrimary.withOpacity(0.2),
                              child: Text(
                                state.user.firstName.isNotEmpty
                                    ? state.user.firstName[0].toUpperCase()
                                    : state.user.username.isNotEmpty
                                        ? state.user.username[0].toUpperCase()
                                        : 'U',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            onSelected: (value) {
                              if (value == 'logout' && onLogout != null) {
                                _showLogoutDialog(context, onLogout!);
                              } else if (value == 'profile') {
                                context.push('/user');
                              } else if (value == 'menu') {
                                context.push('/menu');
                              }
                            },
                            itemBuilder: (BuildContext context) => [
                              const PopupMenuItem<String>(
                                value: 'menu',
                                child: Row(
                                  children: [
                                    Icon(Icons.menu, size: 18),
                                    SizedBox(width: 8),
                                    Text('Menú Principal'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem<String>(
                                value: 'profile',
                                child: Row(
                                  children: [
                                    Icon(Icons.person, size: 18),
                                    SizedBox(width: 8),
                                    Text('Perfil'),
                                  ],
                                ),
                              ),
                              const PopupMenuItem<String>(
                                value: 'logout',
                                child: Row(
                                  children: [
                                    Icon(Icons.logout,
                                        size: 18, color: Colors.red),
                                    SizedBox(width: 8),
                                    Text('Cerrar Sesión',
                                        style: TextStyle(color: Colors.red)),
                                  ],
                                ),
                              ),
                            ],
                          );
                        }
                        return const CircleAvatar(
                          radius: 24,
                          backgroundImage: AssetImage('assets/user_avatar.png'),
                        );
                      },
                    ),
                ],
              ),
              if (showUserInfo) ...[
                const SizedBox(height: 12),
                // Información del usuario
                BlocBuilder<AuthCubit, AuthState>(
                  builder: (context, state) {
                    if (state is AuthStateAuthenticated) {
                      final user = state.user;
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.person_outline_rounded,
                              color: Colors.white.withOpacity(0.8),
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Bienvenido, ${user.firstName} ${user.lastName}',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            if (user.roles.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  user.roles.first,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, VoidCallback onLogout) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                onLogout();
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
}
