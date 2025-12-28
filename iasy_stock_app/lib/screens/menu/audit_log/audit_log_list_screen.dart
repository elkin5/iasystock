import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../cubits/menu/audit_log_cubit.dart';
import '../../../models/menu/audit_log_model.dart';
import '../../../widgets/notification_helper.dart';

class AuditLogListScreen extends StatefulWidget {
  const AuditLogListScreen({super.key});

  @override
  State<AuditLogListScreen> createState() => _AuditLogListScreenState();
}

class _AuditLogListScreenState extends State<AuditLogListScreen> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<AuditLogCubit>().loadLogs();
  }

  void _goToDetail(AuditLogModel log) {
    context.push('/audit-logs/detail', extra: log);
  }

  void _openFilters() {
    context.push('/audit-logs/filters');
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.trim().toLowerCase();
    });
  }

  List<AuditLogModel> _filterLogs(List<AuditLogModel> logs) {
    if (_searchQuery.isEmpty) return logs;
    return logs.where((log) {
      return log.action.toLowerCase().contains(_searchQuery) ||
          (log.description?.toLowerCase().contains(_searchQuery) ?? false);
    }).toList();
  }

  Future<void> _onDelete(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar registro'),
        content: const Text('¿Deseas eliminar este registro de auditoría?'),
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
        await context.read<AuditLogCubit>().deleteLogById(id);
        NotificationHelper.showSuccess(
            context, 'Registro eliminado correctamente');
        context.read<AuditLogCubit>().loadLogs();
      } catch (e) {
        NotificationHelper.showError(context, 'Error eliminando registro');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registros de Auditoría'),
        leading: IconButton(
            icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (_) => _onSearchChanged(),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search),
                      hintText: 'Buscar por acción o descripción...',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16)),
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 0, horizontal: 8),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.filter_list),
                  tooltip: 'Búsqueda avanzada',
                  onPressed: _openFilters,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: BlocBuilder<AuditLogCubit, AuditLogState>(
                builder: (context, state) {
                  if (state is AuditLogLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (state is AuditLogLoaded) {
                    final logs = _filterLogs(state.logs);

                    if (logs.isEmpty) {
                      return const Center(
                          child: Text('No se encontraron registros.'));
                    }

                    return ListView.builder(
                      itemCount: logs.length,
                      itemBuilder: (context, index) {
                        final log = logs[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          child: ListTile(
                            leading: const Icon(Icons.history,
                                size: 32, color: Colors.blueGrey),
                            title: Text(log.action,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(log.description ?? 'Sin descripción'),
                                Text('Usuario ID: ${log.userId}'),
                                Text(
                                    'Fecha: ${log.createdAt?.toString() ?? 'Sin fecha'}'),
                              ],
                            ),
                            onTap: () => _goToDetail(log),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete),
                              tooltip: 'Eliminar registro',
                              onPressed: () => _onDelete(log.id!),
                            ),
                          ),
                        );
                      },
                    );
                  }

                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
