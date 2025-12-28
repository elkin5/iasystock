import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../config/get_it_config.dart';
import '../../../cubits/stats/stats_cubit.dart';
import '../../../cubits/stats/stats_state.dart';
import '../../../models/stats/sales_by_date_stat.dart';
import '../../../models/stats/top_product_stat.dart';
import '../../../theme/app_colors.dart';
import '../../../widgets/home/general_sliver_app_bar.dart';
import '../../../widgets/notification_helper.dart';

enum ChartDataset { salesByDate, topProducts }
enum ChartType { line, bar, pie, barAmount }

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  ChartDataset _dataset = ChartDataset.salesByDate;
  ChartType _chartType = ChartType.line;
  // Métrica fija: monto (millones)
  DateTime? _from;
  DateTime? _to;
  int _topLimit = 5;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BlocProvider(
      create: (_) {
        final cubit = getIt<StatsCubit>();
        cubit.loadStats(from: _from, to: _to, topLimit: _topLimit);
        return cubit;
      },
      child: Scaffold(
        body: BlocConsumer<StatsCubit, StatsState>(
          listener: (context, state) {
            if (state is StatsError) {
              NotificationHelper.showError(context, state.message);
            }
          },
          builder: (context, state) {
            return RefreshIndicator(
              onRefresh: () async {
                context
                    .read<StatsCubit>()
                    .loadStats(from: _from, to: _to, topLimit: _topLimit);
              },
              child: CustomScrollView(
                slivers: [
                  GeneralSliverAppBar(
                    title: 'Estadísticas',
                    subtitle: 'Explora ventas y top productos',
                    icon: Icons.insights_rounded,
                    primaryColor: theme.primaryColor,
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(theme),
                          const SizedBox(height: 12),
                          _buildFilters(context, state),
                          const SizedBox(height: 12),
                          if (state is StatsLoading)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 32),
                              child:
                                  Center(child: CircularProgressIndicator()),
                            )
                          else if (state is StatsLoaded)
                            _buildChart(state)
                          else
                            const SizedBox.shrink(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Graficador dinámico',
          style: theme.textTheme.headlineSmall
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          'Explora ventas y top productos con distintos gráficos.',
          style: theme.textTheme.bodyMedium
              ?.copyWith(color: AppColors.textMuted(context)),
        ),
      ],
    );
  }

  Widget _buildFilters(BuildContext context, StatsState state) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildDropdown<ChartDataset>(
                label: 'Fuente',
                value: _dataset,
                items: const {
                  ChartDataset.salesByDate: 'Ventas por fecha',
                  ChartDataset.topProducts: 'Top productos',
                },
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    _dataset = value;
                    _chartType = value == ChartDataset.salesByDate
                        ? ChartType.line
                        : ChartType.bar;
                  });
                  context
                      .read<StatsCubit>()
                      .loadStats(from: _from, to: _to, topLimit: _topLimit);
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildDropdown<ChartType>(
                label: 'Tipo de gráfico',
                value: _chartType,
                items: _dataset == ChartDataset.salesByDate
                    ? {
                        ChartType.line: 'Línea',
                        ChartType.bar: 'Barras (monto)',
                      }
                    : {
                        ChartType.bar: 'Barras (cantidad)',
                        ChartType.pie: 'Dona (cantidad)',
                        ChartType.barAmount: 'Barras (ingresos)',
                      },
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _chartType = value);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_dataset == ChartDataset.salesByDate)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDateFilters(context),
              const SizedBox(height: 12),
              Text(
                'Métrica: Monto (millones)',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          )
        else
          _buildTopLimit(context),
      ],
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required T value,
    required Map<T, String> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 4),
        DropdownButtonFormField<T>(
          value: value,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
          items: items.entries
              .map((e) => DropdownMenuItem<T>(
                    value: e.key,
                    child: Text(e.value),
                  ))
              .toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildDateFilters(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    return Row(
      children: [
        Expanded(
          child: _DateButton(
            label: 'Desde',
            value: _from != null ? dateFormat.format(_from!) : 'Sin filtro',
            onPressed: () async {
              final picked = await _pickDate(initial: _from);
              setState(() => _from = picked);
              context
                  .read<StatsCubit>()
                  .loadStats(from: _from, to: _to, topLimit: _topLimit);
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _DateButton(
            label: 'Hasta',
            value: _to != null ? dateFormat.format(_to!) : 'Sin filtro',
            onPressed: () async {
              final picked = await _pickDate(initial: _to);
              setState(() => _to = picked);
              context
                  .read<StatsCubit>()
                  .loadStats(from: _from, to: _to, topLimit: _topLimit);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTopLimit(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Slider(
            value: _topLimit.toDouble(),
            min: 3,
            max: 10,
            divisions: 7,
            label: 'Top $_topLimit',
            onChanged: (value) {
              setState(() => _topLimit = value.round());
            },
            onChangeEnd: (_) => context
                .read<StatsCubit>()
                .loadStats(from: _from, to: _to, topLimit: _topLimit),
          ),
        ),
        Text('Top $_topLimit'),
      ],
    );
  }

  Future<DateTime?> _pickDate({DateTime? initial}) {
    final now = DateTime.now();
    return showDatePicker(
      context: context,
      initialDate: initial ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1),
    );
  }

  Widget _buildChart(StatsLoaded state) {
    if (_dataset == ChartDataset.salesByDate) {
      return _chartCard(_buildSalesChart(state.salesByDate));
    }
    return _chartCard(_buildTopProductsChart(state.topProducts));
  }

  Widget _buildSalesChart(List<SalesByDateStat> data) {
    if (data.isEmpty) {
      return const _EmptyChart(message: 'No hay ventas en el rango seleccionado.');
    }
    final sorted = List<SalesByDateStat>.from(data)
      ..sort((a, b) => a.date.compareTo(b.date));
    final dateFormat = DateFormat('dd/MM');

    if (_chartType == ChartType.bar) {
      return AspectRatio(
        aspectRatio: 1.6,
        child: BarChart(
          BarChartData(
            barGroups: [
              for (int i = 0; i < sorted.length; i++)
                BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: sorted[i].totalAmount.toDouble(),
                      color: Theme.of(context).primaryColor,
                    )
                  ],
                ),
            ],
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: AxisTitles(
                sideTitles: _rightNumericTitles(
                  unit: '\$ (millones)',
                  scaleToMillions: true,
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, _) {
                    final index = value.toInt();
                    if (index < 0 || index >= sorted.length) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(top: 6.0),
                      child: Text(
                        dateFormat.format(sorted[index].date),
                        style: const TextStyle(fontSize: 10),
                      ),
                    );
                  },
                  interval: 1,
                ),
              ),
            ),
            gridData: FlGridData(show: true),
          ),
        ),
      );
    }

    return AspectRatio(
      aspectRatio: 1.6,
      child: LineChart(
        LineChartData(
          lineBarsData: [
            LineChartBarData(
              isCurved: true,
              color: Theme.of(context).primaryColor,
              dotData: FlDotData(show: false),
              spots: [
                for (int i = 0; i < sorted.length; i++)
                  FlSpot(
                    i.toDouble(),
                    sorted[i].totalAmount.toDouble(),
                  ),
              ],
            ),
          ],
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(
              sideTitles: _rightNumericTitles(
                unit: '\$ (millones)',
                scaleToMillions: true,
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, _) {
                  final index = value.toInt();
                  if (index < 0 || index >= sorted.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 6.0),
                    child: Text(
                      dateFormat.format(sorted[index].date),
                      style: const TextStyle(fontSize: 10),
                    ),
                  );
                },
                interval: (sorted.length / 5).clamp(1, 5),
              ),
            ),
          ),
          gridData: FlGridData(show: true),
        ),
      ),
    );
  }

  Widget _buildTopProductsChart(List<TopProductStat> data) {
    if (data.isEmpty) {
      return const _EmptyChart(message: 'No hay productos vendidos para mostrar.');
    }

    if (_chartType == ChartType.pie) {
      final total = data.fold<int>(0, (sum, e) => sum + e.totalQuantity);
      return AspectRatio(
        aspectRatio: 1.2,
        child: PieChart(
          PieChartData(
            sections: [
              for (final item in data)
                PieChartSectionData(
                  value: item.totalQuantity.toDouble(),
                  title:
                      '${item.productName}\n${((item.totalQuantity / total) * 100).toStringAsFixed(1)}%',
                  titleStyle: const TextStyle(fontSize: 11),
                  color: _colorForIndex(item.productId.hashCode),
                ),
            ],
          ),
        ),
      );
    } else if (_chartType == ChartType.barAmount) {
      return _buildTopProductsAmountChart(data);
    }

    return AspectRatio(
      aspectRatio: 1.6,
      child: BarChart(
        BarChartData(
          barGroups: [
            for (int i = 0; i < data.length; i++)
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: data[i].totalQuantity.toDouble(),
                    color: Theme.of(context).primaryColor,
                  ),
                ],
              ),
          ],
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, _) {
                  final index = value.toInt();
                  if (index < 0 || index >= data.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 6.0),
                    child: Text(
                      data[index].productName,
                      style: const TextStyle(fontSize: 10),
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(
              sideTitles: _rightNumericTitles(
                unit: 'Cantidad',
                scaleToMillions: false,
              ),
            ),
          ),
          gridData: FlGridData(show: true),
        ),
      ),
    );
  }

  Widget _buildTopProductsAmountChart(List<TopProductStat> data) {
    if (data.isEmpty) {
      return const _EmptyChart(message: 'No hay productos vendidos para mostrar.');
    }

    return AspectRatio(
      aspectRatio: 1.6,
      child: BarChart(
        BarChartData(
          barGroups: [
            for (int i = 0; i < data.length; i++)
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: data[i].totalAmount,
                    color: AppColors.info(context),
                  ),
                ],
              ),
          ],
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, _) {
                  final index = value.toInt();
                  if (index < 0 || index >= data.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 6.0),
                    child: Text(
                      data[index].productName,
                      style: const TextStyle(fontSize: 10),
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(
              sideTitles: _rightNumericTitles(
                unit: _chartType == ChartType.barAmount ? '\$ (millones)' : 'Cantidad',
                scaleToMillions: _chartType == ChartType.barAmount,
              ),
            ),
          ),
          gridData: FlGridData(show: true),
        ),
      ),
    );
  }

  Color _colorForIndex(int index) {
    const palette = [
      Color(0xFF1976D2),
      Color(0xFF388E3C),
      Color(0xFFF57C00),
      Color(0xFFD32F2F),
      Color(0xFF7B1FA2),
      Color(0xFF0097A7),
      Color(0xFF5D4037),
    ];
    return palette[(index.abs()) % palette.length];
  }

  SideTitles _rightNumericTitles({required String unit, required bool scaleToMillions}) {
    return SideTitles(
      showTitles: true,
      reservedSize: 40,
      getTitlesWidget: (value, meta) {
        final isMax = (value - meta.max).abs() < 0.0001;
        final displayValue = scaleToMillions ? value / 1000000 : value;
        return Padding(
          padding: EdgeInsets.only(left: isMax ? 2 : 6, right: 4),
          child: Text(
            isMax
                ? unit
                : displayValue.toStringAsFixed(displayValue % 1 == 0 ? 0 : 1),
            style: const TextStyle(fontSize: 11),
          ),
        );
      },
    );
  }

  Widget _chartCard(Widget child) {
    return Card(
      margin: const EdgeInsets.only(top: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: child,
      ),
    );
  }
}

class _DateButton extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onPressed;

  const _DateButton({
    required this.label,
    required this.value,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 4),
        OutlinedButton.icon(
          onPressed: onPressed,
          icon: const Icon(Icons.event),
          label: Text(value),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyChart extends StatelessWidget {
  final String message;

  const _EmptyChart({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Icon(Icons.insights_outlined,
              color: AppColors.textMuted(context), size: 48),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textMuted(context)),
          ),
        ],
      ),
    );
  }
}
