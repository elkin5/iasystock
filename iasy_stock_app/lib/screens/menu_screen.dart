import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../cubits/auth/auth_cubit.dart';
import '../cubits/auth/auth_state.dart';
import '../services/menu_service.dart';
import '../widgets/auth/role_info_widget.dart';
import '../widgets/menu/menu_card.dart';
import '../widgets/menu/menu_item.dart';
import 'main_screen.dart';

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  bool _showAccessInfo = false;
  bool _showGroupedView = false;
  bool _showRoleInfo = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentLocation = GoRouterState.of(context).uri.toString();

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          GeneralSliverAppBar(
            title: 'Menu de gestión',
            subtitle: 'Sistema de Gestión',
            icon: Icons.inventory_2_rounded,
            primaryColor: theme.primaryColor,
            onLogout: () => context.read<AuthCubit>().signOut(),
          ),
        ],
        body: Column(
          children: [
            Expanded(
              child: BlocBuilder<AuthCubit, AuthState>(
                builder: (context, state) {
                  if (state is AuthStateAuthenticated) {
                    final user = state.user;
                    final accessibleItems =
                        MenuService.getMenuItemsForUser(user.roles);

                    return Column(
                      children: [
                        if (_showRoleInfo)
                          Flexible(
                            child: RoleInfoWidget(
                              showDetailedInfo: true,
                              onToggle: () {
                                setState(() {
                                  _showRoleInfo = !_showRoleInfo;
                                });
                              },
                            ),
                          ),
                        Expanded(
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final isWide = constraints.maxWidth >= 800;

                              if (_showGroupedView) {
                                return _buildGroupedView(
                                    currentLocation, user.roles, isWide);
                              } else {
                                return isWide
                                    ? _buildGridView(
                                        accessibleItems, currentLocation)
                                    : _buildListView(
                                        accessibleItems, currentLocation);
                              }
                            },
                          ),
                        ),
                      ],
                    );
                  } else {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridView(List<MenuItem> items, String currentLocation) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      itemCount: items.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
        childAspectRatio: _showAccessInfo ? 2.6 : 3.2,
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        final isSelected = currentLocation.startsWith(item.route);
        return MenuCard(
          item: item,
          isSelected: isSelected,
          showAccessInfo: _showAccessInfo,
        );
      },
    );
  }

  Widget _buildListView(List<MenuItem> items, String currentLocation) {
    return ListView.builder(
      itemCount: items.length,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemBuilder: (context, index) {
        final item = items[index];
        final isSelected = currentLocation.startsWith(item.route);
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: MenuCard(
            item: item,
            isSelected: isSelected,
            showAccessInfo: _showAccessInfo,
          ),
        );
      },
    );
  }

  Widget _buildGroupedView(
      String currentLocation, List<String> userRoles, bool isWide) {
    final groupedItems = MenuService.getMenuItemsGroupedByAccess(userRoles);
    final sortedGroups = MenuAccessType.values
        .where((type) => groupedItems.containsKey(type))
        .toList();

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      itemCount: sortedGroups.length,
      itemBuilder: (context, groupIndex) {
        final accessType = sortedGroups[groupIndex];
        final items = groupedItems[accessType]!;

        return _buildGroupSection(accessType, items, currentLocation, isWide);
      },
    );
  }

  Widget _buildGroupSection(MenuAccessType accessType, List<MenuItem> items,
      String currentLocation, bool isWide) {
    final theme = Theme.of(context);
    final accessColor = MenuService.getAccessColor(accessType, context);
    final accessIcon = MenuService.getAccessIcon(accessType);
    final accessDescription = MenuService.getAccessDescription(accessType);

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: accessColor.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  accessColor.withOpacity(0.15),
                  accessColor.withOpacity(0.08),
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: accessColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(accessIcon, color: accessColor, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        accessDescription,
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: accessColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${items.length} elemento${items.length != 1 ? 's' : ''} disponible${items.length != 1 ? 's' : ''}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: accessColor.withOpacity(0.8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: isWide
                ? _buildGroupedGridView(items, currentLocation)
                : _buildListView(items, currentLocation),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupedGridView(List<MenuItem> items, String currentLocation) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: _showAccessInfo ? 2.6 : 3.2,
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        final isSelected = currentLocation.startsWith(item.route);
        return MenuCard(
          item: item,
          isSelected: isSelected,
          showAccessInfo: _showAccessInfo,
        );
      },
    );
  }
}
