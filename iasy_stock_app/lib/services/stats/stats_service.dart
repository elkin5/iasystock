import 'package:dio/dio.dart';

import '../../models/stats/sales_by_date_stat.dart';
import '../../models/stats/top_product_stat.dart';

class StatsService {
  final Dio _dio;

  StatsService(this._dio);

  Future<List<SalesByDateStat>> getSalesByDate({
    DateTime? from,
    DateTime? to,
  }) async {
    final query = <String, dynamic>{};
    if (from != null) {
      query['from'] = from.toIso8601String().split('T').first;
    }
    if (to != null) {
      query['to'] = to.toIso8601String().split('T').first;
    }

    final response = await _dio.get('/api/stats/sales-by-date', queryParameters: query);
    final data = response.data as List<dynamic>;
    return data.map((e) => SalesByDateStat.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<TopProductStat>> getTopProducts({int limit = 5}) async {
    final response = await _dio.get('/api/stats/top-products', queryParameters: {'limit': limit});
    final data = response.data as List<dynamic>;
    return data.map((e) => TopProductStat.fromJson(e as Map<String, dynamic>)).toList();
  }
}

