import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final secondaryTextColor =
        Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black54;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Acerca de'),
        backgroundColor: primaryColor,
      ),
      body: SingleChildScrollView(
        // <- clave para evitar overflow
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              const SizedBox(height: 32),

              // Logo
              Semantics(
                label: 'Logo de la aplicación',
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.grey[200],
                  child:
                      Icon(Icons.info_outline, size: 60, color: primaryColor),
                ),
              ),

              const SizedBox(height: 24),

              // Nombre de la marca
              Text(
                'KINSoft',
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      color: primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
              ),

              const SizedBox(height: 16),

              // Descripción
              Text(
                'Bienvenido a IASY Stock, una aplicación diseñada para simplificar la gestión de inventarios y ventas de tu negocio.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),

              const SizedBox(height: 32),

              // Versión
              Text(
                'Versión 0.0.1',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 16,
                      color: secondaryTextColor,
                    ),
              ),

              const SizedBox(height: 64),

              // Derechos reservados
              Text(
                '© 2025 Kinsoft Development. Todos los derechos reservados.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: secondaryTextColor,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
