import 'package:flutter/material.dart';

class UpgradeToPremiumScreen extends StatelessWidget {
  const UpgradeToPremiumScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final secondaryTextColor =
        Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black54;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Actualizar a Premium'),
        backgroundColor: primaryColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Descripción del plan premium
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Plan Premium',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'El Plan Premium ofrece acceso a todas las características avanzadas de la aplicación, incluyendo:',
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      '- Gestión avanzada de inventarios.',
                    ),
                    const Text(
                      '- Reportes detallados de ventas.',
                    ),
                    const Text(
                      '- Soporte técnico prioritario.',
                    ),
                    const Text(
                      '- Actualizaciones exclusivas.',
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Ventajas del plan premium
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ventajas de ser Premium',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '- Maximiza tu productividad con herramientas avanzadas.',
                    ),
                    const Text(
                      '- Acceso ilimitado a todas las funcionalidades.',
                    ),
                    const Text(
                      '- Mantente siempre actualizado con las últimas innovaciones.',
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Botón para actualizar
            Center(
              child: ElevatedButton.icon(
                onPressed: () {
                  // Acción para actualizar a premium
                  _showUpgradeDialog(context);
                },
                icon: const Icon(Icons.upgrade),
                label: const Text('Actualizar Ahora'),
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white, // Color del texto y del icono
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showUpgradeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Actualizar a Premium'),
          content: const Text(
              '¿Estás seguro de que deseas actualizar al Plan Premium?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Cierra el diálogo
              },
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                // Acción para confirmar la actualización
                Navigator.of(context).pop();
                _showSuccessMessage(context);
              },
              child: const Text('Confirmar'),
            ),
          ],
        );
      },
    );
  }

  void _showSuccessMessage(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('¡Actualización a Premium realizada con éxito!'),
        backgroundColor: Colors.green,
      ),
    );
  }
}
