import 'package:freezed_annotation/freezed_annotation.dart';

import '../../utils/converters.dart';

part 'person_model.freezed.dart';
part 'person_model.g.dart';

@freezed
class PersonModel with _$PersonModel {
  const factory PersonModel({
    int? id,
    required String name,
    int? identification,
    String? identificationType,
    int? cellPhone,
    String? email,
    String? address,
    @DateTimeConverter() DateTime? createdAt,
    required String type,
  }) = _PersonModel;

  factory PersonModel.fromJson(Map<String, dynamic> json) =>
      _$PersonModelFromJson(json);
}
