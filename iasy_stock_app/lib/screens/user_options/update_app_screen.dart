import 'package:flutter/material.dart';

class UpdateAppScreen extends StatefulWidget {
  const UpdateAppScreen({super.key});

  @override
  _UpdateAppScreenState createState() => _UpdateAppScreenState();
}

class _UpdateAppScreenState extends State<UpdateAppScreen> {
  bool _autoUpdateEnabled = false;
  TimeOfDay _updateTime = TimeOfDay.now();

  void _pickUpdateTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _updateTime,
    );
    if (picked != null && picked != _updateTime) {
      setState(() {
        _updateTime = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Actualizaciones de la Aplicación'),
        backgroundColor: primaryColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Sección de búsqueda de actualizaciones
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Buscar Actualizaciones',
                      style: textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Comprueba si hay nuevas actualizaciones disponibles para instalar.',
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // Acción para buscar actualizaciones
                        },
                        icon: const Icon(Icons.search),
                        label: const Text('Buscar Actualizaciones'),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Sección de configuración de actualizaciones automáticas
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Actualizaciones Automáticas',
                      style: textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      value: _autoUpdateEnabled,
                      onChanged: (value) {
                        setState(() {
                          _autoUpdateEnabled = value;
                        });
                      },
                      title:
                          const Text('Habilitar actualizaciones automáticas'),
                    ),
                    if (_autoUpdateEnabled)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 16),
                          const Text('Configurar hora de actualización:'),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              ElevatedButton.icon(
                                onPressed: _pickUpdateTime,
                                icon: const Icon(Icons.access_time),
                                label: Text(
                                  'Hora: ${_updateTime.format(context)}',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Botón de guardar configuración
            Center(
              child: ElevatedButton.icon(
                onPressed: () {
                  // Guardar la configuración
                },
                icon: const Icon(Icons.save),
                label: const Text('Guardar Configuración'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
