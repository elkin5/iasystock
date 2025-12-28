import 'package:flutter_bloc/flutter_bloc.dart';

import '../../models/stats/sales_by_date_stat.dart';
import '../../models/stats/top_product_stat.dart';
import '../../services/stats/stats_service.dart';
import 'stats_state.dart';

class StatsCubit extends Cubit<StatsState> {
  final StatsService statsService;

  StatsCubit(this.statsService) : super(const StatsInitial());

  Future<void> loadStats({
    DateTime? from,
    DateTime? to,
    int topLimit = 5,
  }) async {
    emit(const StatsLoading());
    try {
      final sales = await statsService.getSalesByDate(from: from, to: to);
      final topProducts = await statsService.getTopProducts(limit: topLimit);
      emit(StatsLoaded(salesByDate: sales, topProducts: topProducts));
    } catch (e) {
      emit(StatsError('No se pudieron cargar las estadísticas: $e'));
    }
  }

  void updateTopLimit(int limit) {
    final currentState = state;
    if (currentState is StatsLoaded) {
      loadStats(topLimit: limit);
    }
  }

  void updateDateRange(DateTime? from, DateTime? to) {
    final currentState = state;
    if (currentState is StatsLoaded) {
      loadStats(from: from, to: to, topLimit: currentState.topProducts.length);
    }
  }
}

