import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../cubits/menu/person_cubit.dart';
import '../../../models/menu/person_model.dart';
import '../../../widgets/menu/generic_list_screen.dart';
import '../../../widgets/notification_helper.dart';

class PersonListScreen extends StatefulWidget {
  const PersonListScreen({super.key});

  @override
  State<PersonListScreen> createState() => _PersonListScreenState();
}

class _PersonListScreenState extends State<PersonListScreen> {
  @override
  void initState() {
    super.initState();
    context.read<PersonCubit>().loadPersons(refresh: true);
  }

  Future<void> _navigateToForm({PersonModel? person}) async {
    await context.push('/persons/form', extra: person);
    context.read<PersonCubit>().loadPersons(refresh: true);
  }

  Future<void> _onDelete(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar persona'),
        content: const Text('¿Estás seguro de eliminar esta persona?'),
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
        await context.read<PersonCubit>().deletePerson(id);
        NotificationHelper.showSuccess(
            context, 'Persona eliminada correctamente');
        context.read<PersonCubit>().loadPersons(refresh: true);
      } catch (e) {
        NotificationHelper.showError(context, 'Error eliminando persona');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PersonCubit, PersonState>(
      builder: (context, state) {
        if (state is PersonLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is PersonLoaded) {
          return GenericInfiniteListScreen<PersonModel>(
            title: 'Personas',
            items: state.persons,
            searchHint: 'Buscar por nombre, email o identificación...',
            searchTextExtractor: (p) =>
                '${p.name} ${p.email ?? ''} ${p.identification}',
            onAddPressed: () => _navigateToForm(),
            onLoadMore: () => context.read<PersonCubit>().loadMorePersons(),
            isLoadingMore: state.isLoadingMore,
            hasMoreData: state.hasMoreData,
            itemBuilder: (context, person) => Card(
              margin: const EdgeInsets.symmetric(vertical: 6),
              elevation: 2,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: ListTile(
                leading: Icon(
                  person.type?.toLowerCase() == 'cliente'
                      ? Icons.person
                      : Icons.business,
                  color: person.type?.toLowerCase() == 'cliente'
                      ? Colors.blue
                      : Colors.orange,
                  size: 32,
                ),
                title: Text(person.name ?? 'Sin nombre',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        'Identificación: ${person.identification ?? 'Sin ID'}'),
                    Text('Correo: ${person.email ?? 'Sin correo'}'),
                    Text('Tipo: ${person.type}'),
                  ],
                ),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => EntityDetailDialog(
                      title: 'Detalle Persona',
                      fields: {
                        'ID': person.id.toString(),
                        'Nombre': person.name ?? 'Sin nombre',
                        'Identificación':
                            person.identification?.toString() ?? 'Sin ID',
                        'Tipo de identificación':
                            person.identificationType ?? 'Sin tipo',
                        'Correo': person.email ?? '',
                        'Teléfono':
                            person.cellPhone?.toString() ?? 'Sin teléfono',
                        'Dirección': person.address ?? '',
                        'Tipo': person.type ?? 'Sin tipo',
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
                        onPressed: () => _navigateToForm(person: person)),
                    IconButton(
                        icon: const Icon(Icons.delete, size: 20),
                        iconSize: 20,
                        padding: const EdgeInsets.all(4),
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                        onPressed: () => _onDelete(person.id!)),
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
