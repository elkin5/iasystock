import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class ContactScreen extends StatelessWidget {
  const ContactScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final secondaryTextColor =
        Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black54;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Contacto'),
        backgroundColor: primaryColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Encabezado
            Text(
              'Contáctanos',
              style: Theme.of(context)
                  .textTheme
                  .displayLarge
                  ?.copyWith(color: primaryColor),
            ),
            const SizedBox(height: 16),
            Text(
              'Estamos aquí para ayudarte. Puedes comunicarte con nosotros a través de nuestras redes sociales o los siguientes métodos de contacto:',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),

            // Redes sociales
            Text(
              'Redes Sociales',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(color: primaryColor),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSocialMediaIcon(FontAwesomeIcons.facebook, 'Facebook'),
                _buildSocialMediaIcon(FontAwesomeIcons.twitter, 'Twitter'),
                _buildSocialMediaIcon(FontAwesomeIcons.instagram, 'Instagram'),
                _buildSocialMediaIcon(FontAwesomeIcons.linkedin, 'LinkedIn'),
              ],
            ),
            const SizedBox(height: 24),

            // Métodos de contacto
            Text(
              'Información de Contacto',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(color: primaryColor),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.email, color: Colors.blue),
              title: const Text('Correo Electrónico'),
              subtitle: Text(
                'soporte@iasystock.com',
                style: TextStyle(color: secondaryTextColor),
              ),
              onTap: () {
                // Acción al tocar
              },
            ),
            ListTile(
              leading: const Icon(Icons.phone, color: Colors.green),
              title: const Text('Teléfono'),
              subtitle: Text(
                '+57 300 123 4567',
                style: TextStyle(color: secondaryTextColor),
              ),
              onTap: () {
                // Acción al tocar
              },
            ),
            ListTile(
              leading: const Icon(Icons.location_on, color: Colors.red),
              title: const Text('Dirección'),
              subtitle: Text(
                'Cra 45 #26-89, Bogotá, Colombia',
                style: TextStyle(color: secondaryTextColor),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialMediaIcon(IconData icon, String label) {
    return Column(
      children: [
        CircleAvatar(
          backgroundColor: Colors.grey[200],
          child: Icon(icon, color: Colors.blue),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
