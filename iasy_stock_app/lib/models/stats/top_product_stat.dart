class TopProductStat {
  final int productId;
  final String productName;
  final int totalQuantity;
  final double totalAmount;

  TopProductStat({
    required this.productId,
    required this.productName,
    required this.totalQuantity,
    required this.totalAmount,
  });

  factory TopProductStat.fromJson(Map<String, dynamic> json) {
    return TopProductStat(
      productId: (json['productId'] ?? json['product_id'] ?? 0).toInt(),
      productName: json['productName'] ??
          json['product_name'] ??
          'Producto ${json['productId'] ?? ''}',
      totalQuantity:
          (json['totalQuantity'] ?? json['total_quantity'] ?? 0).toInt(),
      totalAmount:
          (json['totalAmount'] ?? json['total_amount'] ?? 0).toDouble(),
    );
  }
}

