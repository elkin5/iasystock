import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'action_selection_screen.dart';

class ConfirmImageScreen extends StatelessWidget {
  final Uint8List imageBytes;
  final String imageName;

  const ConfirmImageScreen({
    Key? key,
    required this.imageBytes,
    required this.imageName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Confirmar Imagen')),
      body: Column(
        children: [
          Expanded(
            child: Image.memory(
              imageBytes,
              fit: BoxFit.contain,
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('¿Quieres usar esta imagen?',
                style: TextStyle(fontSize: 18)),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.refresh),
                label: const Text('Volver a Tomar'),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ActionSelectionScreen(
                        imageBytes: imageBytes,
                        imageName: imageName,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.check),
                label: const Text('Aceptar Imagen'),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
