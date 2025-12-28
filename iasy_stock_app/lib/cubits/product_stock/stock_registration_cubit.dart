import 'dart:io';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../models/menu/category_model.dart';
import '../../models/menu/person_model.dart';
import '../../models/menu/product_model.dart';
import '../../models/menu/warehouse_model.dart';
import '../../services/home/stock_service.dart';
import '../auth/auth_cubit.dart';
import '../auth/auth_state.dart';

// Estados para el registro de stock con reconocimiento
sealed class StockRegistrationState {}

class StockRegistrationInitial extends StockRegistrationState {}

class StockRegistrationLoading extends StockRegistrationState {}

class StockRegistrationFormDataLoaded extends StockRegistrationState {
  final List<ProductModel> products;
  final List<CategoryModel> categories;
  final List<WarehouseModel> warehouses;
  final List<PersonModel> persons;

  StockRegistrationFormDataLoaded({
    required this.products,
    required this.categories,
    required this.warehouses,
    required this.persons,
  });
}

class ProductRecognitionLoading extends StockRegistrationState {}

class ProductRecognitionCompleted extends StockRegistrationState {
  final Map<String, dynamic> recognitionData;

  ProductRecognitionCompleted(this.recognitionData);
}

class StockRegistrationCompleted extends StockRegistrationState {
  final Map<String, dynamic> registrationResult;

  StockRegistrationCompleted(this.registrationResult);
}

class StockRegistrationError extends StockRegistrationState {
  final String message;

  StockRegistrationError(this.message);
}

// Cubit para manejar el registro de stock con reconocimiento
class StockRegistrationCubit extends Cubit<StockRegistrationState> {
  final AuthCubit _authCubit;

  StockRegistrationCubit(this._authCubit) : super(StockRegistrationInitial());

  /// Carga los datos necesarios para el formulario de registro
  Future<void> loadFormData() async {
    emit(StockRegistrationLoading());

    try {
      final authState = _authCubit.state;
      if (authState is! AuthStateAuthenticated) {
        emit(StockRegistrationError('Usuario no autenticado'));
        return;
      }

      final token = authState.user.accessToken;
      final formData = await StockService.getStockFormData(token);

      // Convertir los datos del backend a modelos del frontend
      final products = (formData['products'] as List)
          .map((json) => ProductModel.fromJson(json))
          .toList();

      final categories = (formData['categories'] as List)
          .map((json) => CategoryModel.fromJson(json))
          .toList();

      final warehouses = (formData['warehouses'] as List)
          .map((json) => WarehouseModel.fromJson(json))
          .toList();

      final persons = (formData['persons'] as List)
          .map((json) => PersonModel.fromJson(json))
          .toList();

      emit(StockRegistrationFormDataLoaded(
        products: products,
        categories: categories,
        warehouses: warehouses,
        persons: persons,
      ));
    } catch (e) {
      emit(StockRegistrationError('Error al cargar datos del formulario: $e'));
    }
  }

  /// Realiza reconocimiento de producto desde imagen
  Future<void> recognizeProduct(File imageFile) async {
    emit(ProductRecognitionLoading());

    try {
      final authState = _authCubit.state;
      if (authState is! AuthStateAuthenticated) {
        emit(StockRegistrationError('Usuario no autenticado'));
        return;
      }

      final token = authState.user.accessToken;
      final recognitionData = await StockService.recognizeProduct(
        imageFile: imageFile,
        token: token,
      );

      emit(ProductRecognitionCompleted(recognitionData));
    } catch (e) {
      emit(StockRegistrationError('Error en reconocimiento de producto: $e'));
    }
  }

  /// Registra stock con reconocimiento inteligente
  Future<void> registerStockWithRecognition({
    required int? productId,
    required String? productName,
    required String? productDescription,
    required int? categoryId,
    required int quantity,
    required double entryPrice,
    required double salePrice,
    required int? warehouseId,
    required int? personId,
    required DateTime? entryDate,
    required File? imageFile,
    required Map<String, dynamic>? recognitionData,
  }) async {
    emit(StockRegistrationLoading());

    try {
      final authState = _authCubit.state;
      if (authState is! AuthStateAuthenticated) {
        emit(StockRegistrationError('Usuario no autenticado'));
        return;
      }

      final token = authState.user.accessToken;
      final result = await StockService.registerStockWithRecognition(
        productId: productId,
        productName: productName,
        productDescription: productDescription,
        categoryId: categoryId,
        quantity: quantity,
        entryPrice: entryPrice,
        salePrice: salePrice,
        warehouseId: warehouseId,
        personId: personId,
        entryDate: entryDate,
        imageFile: imageFile,
        recognitionData: recognitionData,
        token: token,
      );

      emit(StockRegistrationCompleted(result));
    } catch (e) {
      emit(StockRegistrationError('Error al registrar stock: $e'));
    }
  }

  /// Registra stock de forma tradicional (sin reconocimiento)
  Future<void> registerStockTraditional({
    required int productId,
    required int quantity,
    required double entryPrice,
    required double salePrice,
    required int? warehouseId,
    required int? personId,
    required DateTime? entryDate,
  }) async {
    emit(StockRegistrationLoading());

    try {
      final authState = _authCubit.state;
      if (authState is! AuthStateAuthenticated) {
        emit(StockRegistrationError('Usuario no autenticado'));
        return;
      }

      final token = authState.user.accessToken;
      final result = await StockService.registerStockWithRecognition(
        productId: productId,
        productName: null,
        productDescription: null,
        categoryId: null,
        quantity: quantity,
        entryPrice: entryPrice,
        salePrice: salePrice,
        warehouseId: warehouseId,
        personId: personId,
        entryDate: entryDate,
        imageFile: null,
        recognitionData: null,
        token: token,
      );

      emit(StockRegistrationCompleted(result));
    } catch (e) {
      emit(StockRegistrationError('Error al registrar stock: $e'));
    }
  }

  /// Resetea el estado
  void resetState() {
    emit(StockRegistrationInitial());
  }
}
