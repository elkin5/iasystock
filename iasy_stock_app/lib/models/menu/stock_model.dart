import 'package:freezed_annotation/freezed_annotation.dart';

import '../../utils/converters.dart';

part 'stock_model.freezed.dart';
part 'stock_model.g.dart';

@freezed
class StockModel with _$StockModel {
  const factory StockModel({
    int? id,
    required int quantity,
    required double entryPrice,
    required double salePrice,
    required int productId,
    required int userId,
    int? warehouseId,
    int? personId,
    @DateTimeConverter() DateTime? entryDate,
    @DateTimeConverter() DateTime? createdAt,
  }) = _StockModel;

  factory StockModel.fromJson(Map<String, dynamic> json) =>
      _$StockModelFromJson(json);
}
