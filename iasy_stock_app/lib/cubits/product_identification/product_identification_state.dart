import 'package:equatable/equatable.dart';

import '../../models/product_identification/product_identification_models.dart';

/// Estados para el Cubit de identificación inteligente de productos
abstract class ProductIdentificationState extends Equatable {
  const ProductIdentificationState();

  @override
  List<Object?> get props => [];
}

/// Estado inicial
class ProductIdentificationInitial extends ProductIdentificationState {}

/// Procesando imagen para identificación
class ProductIdentificationProcessing extends ProductIdentificationState {
  final String message;

  const ProductIdentificationProcessing({
    this.message = 'Procesando imagen...',
  });

  @override
  List<Object?> get props => [message];
}

/// Producto identificado exitosamente
class ProductIdentificationSuccess extends ProductIdentificationState {
  final ProductIdentificationResult result;

  const ProductIdentificationSuccess({
    required this.result,
  });

  @override
  List<Object?> get props => [result];

  // Helpers para acceso rápido
  bool get requiresValidation => result.requiresValidation;

  bool get isNewProduct => !result.isExisting;

  bool get isExistingProduct => result.isExisting;

  bool get hasAlternatives => result.alternativeMatches.isNotEmpty;

  double get confidence => result.confidence;

  ProductSummary get product => result.product;

  List<IdentificationMatch> get alternatives => result.alternativeMatches;
}

/// Error en identificación
class ProductIdentificationError extends ProductIdentificationState {
  final String message;
  final dynamic error;

  const ProductIdentificationError({
    required this.message,
    this.error,
  });

  @override
  List<Object?> get props => [message, error];
}

/// Validación en progreso
class ProductValidationProcessing extends ProductIdentificationState {
  final String message;

  const ProductValidationProcessing({
    this.message = 'Guardando validación...',
  });

  @override
  List<Object?> get props => [message];
}

/// Validación guardada exitosamente
class ProductValidationSuccess extends ProductIdentificationState {
  final ProductIdentificationValidation validation;

  const ProductValidationSuccess({
    required this.validation,
  });

  @override
  List<Object?> get props => [validation];
}

/// Cargando configuración/métricas
class ProductIdentificationConfigLoading extends ProductIdentificationState {}

/// Configuración cargada
class ProductIdentificationConfigLoaded extends ProductIdentificationState {
  final IdentificationThresholdConfig config;

  const ProductIdentificationConfigLoaded({
    required this.config,
  });

  @override
  List<Object?> get props => [config];
}

/// Métricas cargadas
class ProductIdentificationMetricsLoaded extends ProductIdentificationState {
  final AccuracyMetrics metrics;

  const ProductIdentificationMetricsLoaded({
    required this.metrics,
  });

  @override
  List<Object?> get props => [metrics];
}
