import 'package:freezed_annotation/freezed_annotation.dart';

part 'sale_item_model.freezed.dart';
part 'sale_item_model.g.dart';

@freezed
class SaleItemModel with _$SaleItemModel {
  const factory SaleItemModel({
    int? id,
    required int saleId,
    required int productId,
    required int quantity,
    required double unitPrice,
    required double totalPrice,
  }) = _SaleItemModel;

  factory SaleItemModel.fromJson(Map<String, dynamic> json) =>
      _$SaleItemModelFromJson(json);
}
