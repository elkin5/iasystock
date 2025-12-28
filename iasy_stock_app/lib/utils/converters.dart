import 'package:json_annotation/json_annotation.dart';

class DateTimeConverter implements JsonConverter<DateTime?, dynamic> {
  const DateTimeConverter();

  @override
  DateTime? fromJson(dynamic date) {
    if (date == null) {
      return null;
    } else if (date is String) {
      return DateTime.parse(date);
    } else if (date is List) {
      // Si viene como array [year, month, day, hour, minute, second, millisecond]
      if (date.length >= 3) {
        final year = date[0] as int;
        final month = date[1] as int;
        final day = date[2] as int;

        if (date.length >= 6) {
          final hour = date[3] as int;
          final minute = date[4] as int;
          final second = date[5] as int;

          int millisecond = 0;
          int microsecond = 0;

          if (date.length >= 7) {
            final subSecond = date[6] as int;

            if (subSecond >= 1000000) {
              // Valor en nanosegundos (ej. 584696000 => 0.584696 segundos)
              millisecond = subSecond ~/ 1000000;
              microsecond = (subSecond % 1000000) ~/ 1000;
            } else if (subSecond >= 1000) {
              // Valor en microsegundos
              millisecond = subSecond ~/ 1000;
              microsecond = subSecond % 1000;
            } else {
              // Valor en milisegundos
              millisecond = subSecond;
            }
          }

          if (date.length >= 8) {
            // Algunos serializadores envían microsegundos separados
            final extra = date[7] as int;

            if (extra >= 1000) {
              millisecond += extra ~/ 1000;
              microsecond += extra % 1000;
            } else {
              microsecond += extra;
            }
          }

          if (microsecond >= 1000) {
            millisecond += microsecond ~/ 1000;
            microsecond = microsecond % 1000;
          }

          return DateTime(
            year,
            month,
            day,
            hour,
            minute,
            second,
            millisecond,
            microsecond,
          );
        } else {
          return DateTime(year, month, day);
        }
      } else {
        throw FormatException('Array de fecha inválido: $date');
      }
    } else {
      throw FormatException('Formato de fecha no soportado: $date');
    }
  }

  @override
  String? toJson(DateTime? date) => date?.toIso8601String();
}
