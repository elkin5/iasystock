class SalesByDateStat {
  final DateTime date;
  final int totalSales;
  final double totalAmount;

  SalesByDateStat({
    required this.date,
    required this.totalSales,
    required this.totalAmount,
  });

  factory SalesByDateStat.fromJson(Map<String, dynamic> json) {
    DateTime parsedDate;
    final rawDate = json['date'] ?? json['sale_day'] ?? json['saleDay'];

    if (rawDate is String) {
      parsedDate = DateTime.parse(rawDate);
    } else if (rawDate is List) {
      // Manejo de formato [yyyy, mm, dd]
      final parts = rawDate.cast<int>();
      parsedDate = DateTime(parts[0], parts[1], parts[2]);
    } else {
      parsedDate = DateTime.now();
    }

    return SalesByDateStat(
      date: parsedDate,
      totalSales: (json['totalSales'] ?? json['total_sales'] ?? 0).toInt(),
      totalAmount:
          (json['totalAmount'] ?? json['total_amount'] ?? 0).toDouble(),
    );
  }
}
