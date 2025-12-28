import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

import '../config/get_it_config.dart';
import '../services/menu/sale_item_service.dart';

final Logger log = Logger();

/// Widget que muestra el total calculado automáticamente de una venta
/// basado en la suma de todos los SaleItems asociados
class CalculatedTotalField extends StatefulWidget {
  /// ID de la venta para calcular el total
  final int? saleId;

  /// Texto de la etiqueta del campo
  final String labelText;

  /// Texto de ayuda adicional
  final String? helperText;

  /// Callback que se ejecuta cuando se calcula el total
  final Function(double)? onTotalCalculated;

  /// Si debe mostrar un indicador de carga
  final bool showLoadingIndicator;

  const CalculatedTotalField({
    super.key,
    this.saleId,
    this.labelText = 'Total',
    this.helperText,
    this.onTotalCalculated,
    this.showLoadingIndicator = true,
  });

  @override
  State<CalculatedTotalField> createState() => _CalculatedTotalFieldState();
}

class _CalculatedTotalFieldState extends State<CalculatedTotalField> {
  double? _calculatedTotal;
  bool _loadingTotal = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.saleId != null) {
      _calculateTotal();
    }
  }

  @override
  void didUpdateWidget(CalculatedTotalField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.saleId != oldWidget.saleId && widget.saleId != null) {
      _calculateTotal();
    }
  }

  Future<void> _calculateTotal() async {
    if (widget.saleId == null) return;

    setState(() {
      _loadingTotal = true;
      _errorMessage = null;
    });

    try {
      final saleItemService = getIt<SaleItemService>();
      final total =
          await saleItemService.calculateTotalBySaleId(widget.saleId!);

      if (mounted) {
        setState(() {
          _calculatedTotal = total;
          _loadingTotal = false;
          _errorMessage = null;
        });

        // Ejecutar callback si está definido
        widget.onTotalCalculated?.call(total);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingTotal = false;
          _errorMessage = 'Error al calcular total: ${e.toString()}';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.saleId == null) {
      return TextFormField(
        decoration: InputDecoration(
          labelText: widget.labelText,
          helperText: widget.helperText ?? 'Total se calculará automáticamente',
        ),
        controller: TextEditingController(text: '0.00'),
        enabled: false,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
        ),
      );
    }

    if (_loadingTotal && widget.showLoadingIndicator) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.labelText,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
          ),
          const SizedBox(height: 8),
          const LinearProgressIndicator(),
        ],
      );
    }

    if (_errorMessage != null) {
      return TextFormField(
        decoration: InputDecoration(
          labelText: widget.labelText,
          errorText: _errorMessage,
          helperText: widget.helperText,
        ),
        enabled: false,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
        ),
      );
    }

    return TextFormField(
      decoration: InputDecoration(
        labelText: widget.labelText,
        helperText: widget.helperText ?? 'Total calculado automáticamente',
      ),
      controller: TextEditingController(
        text: _calculatedTotal != null
            ? '\$${_calculatedTotal!.toStringAsFixed(2)}'
            : '0.00',
      ),
      enabled: false,
      style: TextStyle(
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
        fontWeight: FontWeight.bold,
      ),
    );
  }

  /// Obtiene el total calculado
  double? get calculatedTotal => _calculatedTotal;

  /// Indica si está cargando el total
  bool get isLoading => _loadingTotal;

  /// Indica si hay un error
  bool get hasError => _errorMessage != null;

  /// Recalcula el total manualmente
  Future<void> recalculate() async {
    await _calculateTotal();
  }
}
