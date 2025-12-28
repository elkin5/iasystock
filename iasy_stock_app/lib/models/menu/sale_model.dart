import 'package:freezed_annotation/freezed_annotation.dart';

import '../../utils/converters.dart';

part 'sale_model.freezed.dart';
part 'sale_model.g.dart';

@freezed
class SaleModel with _$SaleModel {
  const factory SaleModel({
    int? id,
    int? personId,
    required int userId,
    required double totalAmount,
    @DateTimeConverter() DateTime? saleDate,
    String? payMethod,
    String? state,
    @DateTimeConverter() DateTime? createdAt,
  }) = _SaleModel;

  factory SaleModel.fromJson(Map<String, dynamic> json) =>
      _$SaleModelFromJson(json);
}
