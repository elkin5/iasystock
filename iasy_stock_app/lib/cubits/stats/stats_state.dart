import '../../models/stats/sales_by_date_stat.dart';
import '../../models/stats/top_product_stat.dart';

abstract class StatsState {
  const StatsState();
}

class StatsInitial extends StatsState {
  const StatsInitial();
}

class StatsLoading extends StatsState {
  const StatsLoading();
}

class StatsLoaded extends StatsState {
  final List<SalesByDateStat> salesByDate;
  final List<TopProductStat> topProducts;

  const StatsLoaded({
    this.salesByDate = const [],
    this.topProducts = const [],
  });
}

class StatsError extends StatsState {
  final String message;

  const StatsError(this.message);
}

