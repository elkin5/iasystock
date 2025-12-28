import 'package:freezed_annotation/freezed_annotation.dart';

import '../../utils/converters.dart';

part 'warehouse_model.freezed.dart';
part 'warehouse_model.g.dart';

@freezed
class WarehouseModel with _$WarehouseModel {
  const factory WarehouseModel({
    int? id,
    required String name,
    String? location,
    @DateTimeConverter() DateTime? createdAt,
  }) = _WarehouseModel;

  factory WarehouseModel.fromJson(Map<String, dynamic> json) =>
      _$WarehouseModelFromJson(json);
}
