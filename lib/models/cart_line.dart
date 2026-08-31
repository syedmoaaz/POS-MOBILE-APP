class CartLine {
  const CartLine({
    required this.id,
    required this.name,
    required this.qty,
    required this.unitPrice,
    this.productId,
  });

  final String id;
  final String? productId;
  final String name;
  final double qty;
  final double unitPrice;

  double get lineTotal => qty * unitPrice;

  CartLine copyWith({double? qty, double? unitPrice, String? name}) {
    return CartLine(
      id: id,
      productId: productId,
      name: name ?? this.name,
      qty: qty ?? this.qty,
      unitPrice: unitPrice ?? this.unitPrice,
    );
  }
}
