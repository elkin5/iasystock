import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../cubits/product_identification/multiple_detection_cubit.dart';
import '../../cubits/product_identification/multiple_detection_state.dart';
import '../../models/product_identification/product_identification_models.dart';

/// Pantalla para detección múltiple de productos en una sola imagen
///
/// Permite:
/// - Capturar/seleccionar imagen con múltiples productos
/// - Ver resultados de detección con bounding boxes
/// - Editar selección y cantidades
/// - Confirmar productos para agregar a stock/venta
class MultipleDetectionScreen extends StatefulWidget {
  /// Callback opcional que se ejecuta cuando el usuario confirma los productos
  /// Recibe el resultado con los productos seleccionados y sus cantidades
  final void Function(MultipleProductDetectionResult result)? onConfirm;

  /// Bytes de imagen inicial (opcional)
  /// Si se proporciona, la pantalla se salta la vista inicial de selección de imagen
  final Uint8List? initialImageBytes;

  const MultipleDetectionScreen({
    Key? key,
    this.onConfirm,
    this.initialImageBytes,
  }) : super(key: key);

  @override
  State<MultipleDetectionScreen> createState() =>
      _MultipleDetectionScreenState();
}

class _MultipleDetectionScreenState extends State<MultipleDetectionScreen> {
  final ImagePicker _picker = ImagePicker();
  Uint8List? _capturedImageBytes;

  @override
  void initState() {
    super.initState();
    // Si se proporciona una imagen inicial, usarla
    if (widget.initialImageBytes != null) {
      _capturedImageBytes = widget.initialImageBytes;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detección Múltiple'),
        backgroundColor: theme.primaryColor,
      ),
      body: BlocConsumer<MultipleDetectionCubit, MultipleDetectionState>(
        listener: (context, state) {
          if (state is MultipleDetectionError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 4),
              ),
            );
          } else if (state is MultipleDetectionSuccess) {
            // Auto-confirmar si todos los productos tienen alta confianza (≥60%)
            // Igual que el flujo individual: auto-confirma sin pantalla intermedia
            final allHighConfidence = state.result.productGroups.every(
              (group) => group.averageConfidence >= 0.6,
            );

            if (allHighConfidence) {
              // Confirmar automáticamente y ejecutar callback
              Future.microtask(() {
                if (widget.onConfirm != null) {
                  widget.onConfirm!(state.result);
                  Navigator.of(context).pop();
                }
              });
            } else {
              // Si hay productos con baja confianza, ir DIRECTO a pantalla de edición
              // Igual que el flujo individual va directo a ProductIdentificationConfirmationScreen
              Future.microtask(() {
                context.read<MultipleDetectionCubit>().startEditingSelection();
              });
            }
          }
        },
        builder: (context, state) {
          if (state is MultipleDetectionInitial) {
            return _buildInitialView(theme);
          } else if (state is MultipleDetectionProcessing) {
            return _buildProcessingView(state, theme);
          } else if (state is MultipleDetectionSuccess) {
            // Mostrar pantalla de procesamiento mientras se auto-confirma
            return _buildProcessingView(
              const MultipleDetectionProcessing(
                  message: 'Confirmando productos...'),
              theme,
            );
          } else if (state is MultipleDetectionEditingSelection) {
            return _buildEditingView(state, theme);
          } else if (state is MultipleDetectionError) {
            return _buildErrorView(state, theme);
          }

          return const Center(child: Text('Estado desconocido'));
        },
      ),
    );
  }

  /// Vista inicial: botones para capturar/seleccionar imagen
  Widget _buildInitialView(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.scanner,
              size: 100,
              color: theme.primaryColor.withOpacity(0.6),
            ),
            const SizedBox(height: 24),
            const Text(
              'Detección Múltiple de Productos',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'Captura una imagen con varios productos '
              'y el sistema los detectará automáticamente',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            ElevatedButton.icon(
              onPressed: _captureFromCamera,
              icon: const Icon(Icons.camera_alt),
              label: const Text('Tomar Foto'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                textStyle: const TextStyle(fontSize: 18),
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _pickFromGallery,
              icon: const Icon(Icons.photo_library),
              label: const Text('Seleccionar de Galería'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                textStyle: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Vista de procesamiento: spinner con mensaje
  Widget _buildProcessingView(
      MultipleDetectionProcessing state, ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (_capturedImageBytes != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.memory(
                _capturedImageBytes!,
                width: 200,
                height: 200,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 32),
          ],
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(theme.primaryColor),
          ),
          const SizedBox(height: 24),
          Text(
            state.message,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Esto puede tomar unos segundos...',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  /// Vista de edición: permite marcar/desmarcar y modificar cantidades
  Widget _buildEditingView(
      MultipleDetectionEditingSelection state, ThemeData theme) {
    return Column(
      children: [
        // Header con resumen de selección
        Container(
          width: double.infinity,
          color: theme.primaryColor.withOpacity(0.1),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                'Editando Selección',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: theme.primaryColor,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatCard(
                    icon: Icons.check_box,
                    label: 'Seleccionados',
                    value: '${state.selectedGroups.length}',
                    color: theme.primaryColor,
                  ),
                  _buildStatCard(
                    icon: Icons.shopping_cart,
                    label: 'Total Items',
                    value: '${state.totalSelectedQuantity}',
                    color: theme.primaryColor,
                  ),
                ],
              ),
            ],
          ),
        ),

        // Lista de productos con checkboxes
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: state.result.productGroups.length,
            itemBuilder: (context, index) {
              final group = state.result.productGroups[index];
              final isSelected = state.isGroupSelected(group);
              final quantity = state.getQuantityForGroup(group);

              return _buildEditableProductCard(
                group: group,
                isSelected: isSelected,
                quantity: quantity,
                onToggle: () {
                  context
                      .read<MultipleDetectionCubit>()
                      .toggleGroupSelection(group);
                },
                onIncrement: () {
                  context
                      .read<MultipleDetectionCubit>()
                      .incrementQuantity(group);
                },
                onDecrement: () {
                  context
                      .read<MultipleDetectionCubit>()
                      .decrementQuantity(group);
                },
              );
            },
          ),
        ),

        // Botones de acción
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Botones de selección rápida
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        context.read<MultipleDetectionCubit>().selectAll();
                      },
                      child: const Text('Seleccionar Todo'),
                    ),
                  ),
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        context.read<MultipleDetectionCubit>().deselectAll();
                      },
                      child: const Text('Deseleccionar Todo'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Botones principales
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        context.read<MultipleDetectionCubit>().cancelEditing();
                      },
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: state.selectedGroups.isEmpty
                          ? null
                          : () {
                              // Crear resultado directamente con productos seleccionados y cantidades modificadas
                              final updatedGroups =
                                  state.selectedGroups.map((group) {
                                final quantity =
                                    state.getQuantityForGroup(group);
                                return DetectedProductGroup(
                                  product: group.product,
                                  quantity: quantity,
                                  averageConfidence: group.averageConfidence,
                                  detections: group.detections,
                                  isConfirmed: group.isConfirmed,
                                );
                              }).toList();

                              final result = MultipleProductDetectionResult(
                                status: state.result.status,
                                productGroups: updatedGroups,
                                totalDetections: state.result.totalDetections,
                                uniqueProducts: updatedGroups.length,
                                requiresValidation:
                                    updatedGroups.any((g) => !g.isConfirmed),
                                processingTimeMs: state.result.processingTimeMs,
                                metadata: state.result.metadata,
                              );

                              // Ejecutar callback DIRECTAMENTE sin cambiar estado
                              if (widget.onConfirm != null) {
                                // Cerrar PRIMERO la pantalla
                                Navigator.of(context).pop();

                                // Luego ejecutar callback después de que se cierre
                                Future.delayed(
                                    const Duration(milliseconds: 100), () {
                                  widget.onConfirm!(result);
                                });
                              } else {
                                // Si no hay callback, solo mostrar mensaje
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Confirmados ${state.selectedGroups.length} productos',
                                    ),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            },
                      icon: const Icon(Icons.check),
                      label: const Text('Confirmar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primaryColor,
                        foregroundColor:
                            Colors.white, // Color del texto e icono
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Vista de error
  Widget _buildErrorView(MultipleDetectionError state, ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: Colors.red.shade300,
            ),
            const SizedBox(height: 24),
            const Text(
              'Error en la Detección',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              state.message,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                context.read<MultipleDetectionCubit>().reset();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Intentar Nuevamente'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Card estadística
  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  /// Card de producto editable
  Widget _buildEditableProductCard({
    required DetectedProductGroup group,
    required bool isSelected,
    required int quantity,
    required VoidCallback onToggle,
    required VoidCallback onIncrement,
    required VoidCallback onDecrement,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isSelected ? Colors.orange.shade50 : null,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            // Checkbox
            Checkbox(
              value: isSelected,
              onChanged: (_) => onToggle(),
              activeColor: Colors.orange,
            ),
            const SizedBox(width: 8),
            // Información del producto
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    group.product.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Confianza: ${(group.averageConfidence * 100).toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            // Controles de cantidad
            Row(
              children: [
                IconButton(
                  onPressed: quantity > 0 ? onDecrement : null,
                  icon: const Icon(Icons.remove_circle_outline),
                  color: Colors.orange,
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$quantity',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: onIncrement,
                  icon: const Icon(Icons.add_circle_outline),
                  color: Colors.orange,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Captura imagen desde la cámara
  Future<void> _captureFromCamera() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (photo != null) {
        // Leer bytes de la imagen (compatible con web y móvil)
        final imageBytes = await photo.readAsBytes();
        final imageName = photo.name;

        setState(() {
          _capturedImageBytes = imageBytes;
        });

        if (!mounted) return;

        // Detectar productos
        context.read<MultipleDetectionCubit>().detectMultipleProducts(
              imageBytes: imageBytes,
              imageName: imageName,
              source: 'MOBILE_APP',
            );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al capturar imagen: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Selecciona imagen desde la galería
  Future<void> _pickFromGallery() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (photo != null) {
        // Leer bytes de la imagen (compatible con web y móvil)
        final imageBytes = await photo.readAsBytes();
        final imageName = photo.name;

        setState(() {
          _capturedImageBytes = imageBytes;
        });

        if (!mounted) return;

        // Detectar productos
        context.read<MultipleDetectionCubit>().detectMultipleProducts(
              imageBytes: imageBytes,
              imageName: imageName,
              source: 'MOBILE_APP',
            );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al seleccionar imagen: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
