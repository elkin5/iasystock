import 'package:freezed_annotation/freezed_annotation.dart';

import '../../utils/converters.dart';

part 'promotion_model.freezed.dart';
part 'promotion_model.g.dart';

@freezed
class PromotionModel with _$PromotionModel {
  const factory PromotionModel({
    int? id,
    required String description,
    required double discountRate,
    @DateTimeConverter() DateTime? startDate,
    @DateTimeConverter() DateTime? endDate,
    int? productId,
    int? categoryId, // Changed from required int to int?
  }) = _PromotionModel;

  factory PromotionModel.fromJson(Map<String, dynamic> json) =>
      _$PromotionModelFromJson(json);
}
