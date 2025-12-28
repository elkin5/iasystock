import 'package:freezed_annotation/freezed_annotation.dart';

import '../../utils/converters.dart';

part 'product_model.freezed.dart';
part 'product_model.g.dart';

@freezed
class ProductModel with _$ProductModel {
  const factory ProductModel({
    int? id,
    required String name,
    String? description,
    String? imageUrl,
    required int categoryId,
    int? stockQuantity,
    int? stockMinimum,
    @DateTimeConverter() DateTime? createdAt,
    @DateTimeConverter() DateTime? expirationDate,
  }) = _ProductModel;

  factory ProductModel.fromJson(Map<String, dynamic> json) =>
      _$ProductModelFromJson(json);
}
