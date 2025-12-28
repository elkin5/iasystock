import 'package:flutter_bloc/flutter_bloc.dart';

import '../../models/cart_sale/cart_sale_model.dart';
import '../../models/menu/person_model.dart';
import '../../models/menu/product_model.dart';
import '../../models/menu/sale_item_model.dart';
import '../../models/menu/sale_model.dart';
import '../../services/cart_sale/cart_sale_service.dart';
import 'cart_sale_state.dart';

class CartSaleCubit extends Cubit<CartSaleState> {
  CartSaleCubit({required CartSaleService cartSaleService})
      : _cartSaleService = cartSaleService,
        super(_createInitialState());
  final CartSaleService _cartSaleService;

  static CartSaleState _createInitialState() {
    final emptySale = SaleModel(
      userId: 1, // TODO: Obtener userId real
      totalAmount: 0.0,
      saleDate: DateTime.now(),
    );

    return CartSaleLoaded(
      sale: emptySale,
      saleItems: const [],
      products: const {},
      selectedClient: null,
      isNewSaleMode: true,
      isResumeSaleMode: false,
    );
  }

  // Inicializar nueva venta
  void startNewSale() {
    final emptySale = SaleModel(
      userId: 1, // TODO: Obtener userId real
      totalAmount: 0.0,
      saleDate: DateTime.now(),
      // payMethod: 'Efectivo',
      // state: 'Pendiente',
    );

    emit(CartSaleLoaded(
      sale: emptySale,
      saleItems: const [],
      products: const {},
      isNewSaleMode: true,
    ));
  }

  // Buscar venta pendiente
  Future<void> searchPendingSale(String saleId) async {
    emit(CartSaleLoading());

    try {
      // TODO: Implementar búsqueda de venta pendiente desde el backend
      // Por ahora simulamos una búsqueda exitosa
      await Future.delayed(const Duration(seconds: 1));

      if (!isClosed) {
        emit(CartSaleLoaded(
          sale: SaleModel(
            userId: 1,
            // TODO: Obtener userId real
            totalAmount: 0.0,
            saleDate: DateTime.now(),
            payMethod: 'Efectivo',
            state: 'Pendiente',
          ),
          saleItems: [],
          products: {},
          isNewSaleMode: false,
          isResumeSaleMode: true,
        ));
      }
    } catch (e) {
      if (!isClosed) {
        emit(CartSaleError(message: 'Error al buscar la venta: $e'));
      }
    }
  }

  // Seleccionar cliente
  void selectClient(PersonModel client) {
    if (state is CartSaleLoaded) {
      final currentState = state as CartSaleLoaded;

      // Actualizar la venta con el personId del cliente
      final updatedSale = currentState.sale.copyWith(
        personId: client.id,
      );

      emit(currentState.copyWith(
        selectedClient: client,
        sale: updatedSale,
      ));
    }
  }

  // Obtener precio de venta del stock más reciente del producto
  Future<double> _getProductSalePrice(int productId) async {
    try {
      final stocks = await _cartSaleService.getStocksByProductId(productId);

      if (stocks.isNotEmpty) {
        // Obtener el stock más reciente (por fecha de entrada)
        stocks.sort((a, b) => (b.entryDate ?? DateTime.now())
            .compareTo(a.entryDate ?? DateTime.now()));
        final latestStock = stocks.first;

        return latestStock.salePrice;
      }
    } catch (e) {
      rethrow;
    }

    return 0.0; // Precio por defecto si no se puede obtener
  }

  // Agregar producto al carrito
  Future<void> addProductToCart(ProductModel product,
      {int quantity = 1}) async {
    if (state is CartSaleLoaded) {
      final currentState = state as CartSaleLoaded;

      // Verificar si el producto ya existe en el carrito
      final existingItemIndex = currentState.saleItems.indexWhere(
        (item) => item.productId == (product.id ?? 0),
      );

      List<SaleItemModel> updatedItems;
      final Map<int, ProductModel> updatedProducts =
          Map.from(currentState.products);

      // Agregar el producto al mapa si no existe
      if (product.id != null) {
        updatedProducts[product.id!] = product;
      }

      if (existingItemIndex != -1) {
        // Si ya existe, validar que no exceda el stock al aumentar la cantidad
        final existingItem = currentState.saleItems[existingItemIndex];
        final newTotalQuantity = existingItem.quantity + quantity;

        // Validar stock disponible
        if (product.stockQuantity != null &&
            newTotalQuantity > product.stockQuantity!) {
          throw Exception(
              'Stock insuficiente. Disponible: ${product.stockQuantity}, solicitado: $newTotalQuantity');
        }

        updatedItems = List.from(currentState.saleItems);
        updatedItems[existingItemIndex] = SaleItemModel(
          id: existingItem.id,
          saleId: existingItem.saleId,
          productId: existingItem.productId,
          quantity: newTotalQuantity,
          unitPrice: existingItem.unitPrice,
          totalPrice: existingItem.unitPrice * newTotalQuantity,
        );
      } else {
        // Si no existe, validar que la cantidad no exceda el stock disponible
        if (product.stockQuantity != null &&
            quantity > product.stockQuantity!) {
          throw Exception(
              'Stock insuficiente para ${product.name}. Disponible: ${product.stockQuantity}');
        }

        // Obtener precio de venta del stock más reciente
        double unitPrice = 0.0;
        try {
          unitPrice = await _getProductSalePrice(product.id ?? 0);
        } catch (e) {
          rethrow;
        }

        // Agregar nuevo item
        final newItem = SaleItemModel(
          saleId: currentState.sale.id ?? 0,
          productId: product.id ?? 0,
          quantity: quantity,
          unitPrice: unitPrice,
          totalPrice: unitPrice * quantity,
        );

        updatedItems = [...currentState.saleItems, newItem];
      }

      // Calcular nuevo total
      final newTotal =
          updatedItems.fold<double>(0, (sum, item) => sum + item.totalPrice);

      // Crear nueva venta
      final updatedSale = currentState.sale.copyWith(totalAmount: newTotal);

      for (int i = 0; i < updatedItems.length; i++) {
        final item = updatedItems[i];
      }

      emit(currentState.copyWith(
        sale: updatedSale,
        saleItems: updatedItems,
        products: updatedProducts,
      ));
    }
  }

  // Actualizar cantidad de un producto
  void updateProductQuantity(int productId, int newQuantity) {
    if (state is CartSaleLoaded) {
      final currentState = state as CartSaleLoaded;

      // Validar que la nueva cantidad no exceda el stock disponible
      final product = currentState.products[productId];
      if (product != null && product.stockQuantity != null) {
        if (newQuantity > product.stockQuantity!) {
          return; // No actualizar si excede el stock
        }
      }

      final updatedItems = currentState.saleItems.map((item) {
        if (item.productId == productId) {
          return SaleItemModel(
            id: item.id,
            saleId: item.saleId,
            productId: item.productId,
            quantity: newQuantity,
            unitPrice: item.unitPrice,
            totalPrice: item.unitPrice * newQuantity,
          );
        }
        return item;
      }).toList();

      // Calcular nuevo total
      final newTotal =
          updatedItems.fold<double>(0, (sum, item) => sum + item.totalPrice);

      // Crear nueva venta
      final updatedSale = currentState.sale.copyWith(totalAmount: newTotal);

      emit(currentState.copyWith(sale: updatedSale, saleItems: updatedItems));
    }
  }

  // Eliminar producto del carrito
  void removeProductFromCart(int productId) {
    if (state is CartSaleLoaded) {
      final currentState = state as CartSaleLoaded;

      final updatedItems = currentState.saleItems
          .where((item) => item.productId != productId)
          .toList();

      // Calcular nuevo total
      final newTotal =
          updatedItems.fold<double>(0, (sum, item) => sum + item.totalPrice);

      // Crear nueva venta
      final updatedSale = currentState.sale.copyWith(totalAmount: newTotal);

      emit(currentState.copyWith(
        sale: updatedSale,
        saleItems: updatedItems,
      ));
    }
  }

  // Guardar venta pendiente
  Future<void> savePendingSale() async {
    if (state is CartSaleLoaded) {
      final currentState =
          state as CartSaleLoaded; // Capturar el estado ANTES de emitir
      emit(CartSaleSaving());

      try {
        // Crear el modelo de venta con el cliente seleccionado
        final saleModel = currentState.sale.copyWith(
          personId: currentState.selectedClient?.id,
          state: 'Pendiente',
        );

        // Crear el modelo completo del carrito
        final cartSaleModel = CartSaleModel(
          sale: saleModel,
          saleItems: currentState.saleItems,
        );

        // Validar que los datos estén listos para guardar
        final validation = cartSaleModel.validateForPendingSave();
        if (!validation.isValid) {
          emit(CartSaleError(
              message: 'Datos incompletos: ${validation.errorMessage}'));
          return;
        }

        try {
          // Procesar el carrito en el backend
          final response =
              await _cartSaleService.processCart(cartData: cartSaleModel);

          emit(CartSaleSaved(
            savedSale: response.sale,
            savedItems: response.saleItems,
          ));
        } catch (e) {
          emit(CartSaleError(
              message: e.toString() ?? 'Error guardando venta pendiente'));
          return;
        }

        // Volver al estado inicial después de un momento
        await Future.delayed(const Duration(seconds: 1));
        if (!isClosed) {
          emit(CartSaleInitial());
        }
      } catch (e) {
        emit(CartSaleError(message: 'Error al guardar la venta: $e'));
      }
    }
  }

  // Procesar pago
  Future<void> processPayment({String? payMethod}) async {
    if (state is CartSaleLoaded) {
      final currentState =
          state as CartSaleLoaded; // Capturar el estado ANTES de emitir
      emit(CartSalePaymentProcessing());

      try {
        // Crear el modelo de venta completada
        final saleModel = currentState.sale.copyWith(
          personId: currentState.selectedClient?.id,
          state: 'Completada',
          saleDate: DateTime.now(),
          payMethod: payMethod,
        );

        // Crear el modelo completo del carrito
        final cartSaleModel = CartSaleModel(
          sale: saleModel,
          saleItems: currentState.saleItems,
        );

        // Validar que los datos estén completos para procesar el pago
        final validation = cartSaleModel.validateForBackend();
        if (!validation.isValid) {
          emit(CartSaleError(
              message:
                  'Datos incompletos para procesar pago: ${validation.errorMessage}'));
          return;
        }

        try {
          // Procesar el carrito en el backend - SIGUIENDO EXACTAMENTE el patrón de SaleCubit.createSale()
          final response = await _cartSaleService.processCart(
            cartData: cartSaleModel,
          );

          emit(CartSalePaymentCompleted(
            completedSale: saleModel,
            transactionId: 'txn_${DateTime.now().millisecondsSinceEpoch}',
          ));
        } catch (e) {
          emit(CartSaleError(message: e.toString()));
          return;
        }

        // Volver al estado inicial después de un momento
        await Future.delayed(const Duration(seconds: 2));
        if (!isClosed) {
          emit(CartSaleInitial());
        }
      } catch (e) {
        emit(CartSaleError(message: 'Error al procesar el pago: $e'));
      }
    }
  }

  // Obtener el modelo completo del carrito listo para enviar al backend
  CartSaleModel? getCartModelForBackend(String state) {
    if (this.state is CartSaleLoaded) {
      final currentState = this.state as CartSaleLoaded;

      final saleModel = currentState.sale.copyWith(
        personId: currentState.selectedClient?.id,
        saleDate: DateTime.now(),
      );

      final cartModel = CartSaleModel(
        sale: saleModel,
        saleItems: currentState.saleItems,
      );

      return cartModel;
    }

    return null;
  }

  // Descartar venta
  void discardSale() {
    emit(CartSaleInitial());
  }

  // Forzar reinicio completo del carrito
  void forceRestart() {
    // Limpiar completamente el estado
    emit(CartSaleInitial());

    // Reiniciar después de un delay más largo para asegurar limpieza completa
    Future.delayed(const Duration(milliseconds: 200), () {
      if (!isClosed) {
        startNewSale();
      }
    });
  }

  // Limpiar completamente el carrito y reiniciar
  void clearCartAndRestart() {
    // Emitir estado inicial primero para limpiar completamente
    emit(CartSaleInitial());

    // Luego crear un nuevo estado limpio después de un breve delay
    Future.delayed(const Duration(milliseconds: 100), () {
      if (!isClosed) {
        final emptySale = SaleModel(
          userId: 1, // TODO: Obtener userId real
          totalAmount: 0.0,
          saleDate: DateTime.now(),
        );

        emit(CartSaleLoaded(
          sale: emptySale,
          saleItems: const [],
          products: const {},
          selectedClient: null,
          isNewSaleMode: true,
          isResumeSaleMode: false,
        ));
      }
    });
  }
}
