import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../db/app_database.dart';
import '../models/cart_line.dart';

class CartNotifier extends Notifier<List<CartLine>> {
  static const _uuid = Uuid();

  @override
  List<CartLine> build() => const [];

  void addOpenItem({
    required String name,
    required double qty,
    required double unitPrice,
  }) {
    state = [
      ...state,
      CartLine(
        id: _uuid.v4(),
        name: name.trim(),
        qty: qty,
        unitPrice: unitPrice,
      ),
    ];
  }

  void addProduct(Product product) {
    final existing = state.indexWhere((l) => l.productId == product.id);
    if (existing >= 0) {
      final line = state[existing];
      final next = [...state];
      next[existing] = line.copyWith(qty: line.qty + 1);
      state = next;
      return;
    }
    state = [
      ...state,
      CartLine(
        id: _uuid.v4(),
        productId: product.id,
        name: product.name,
        qty: 1,
        unitPrice: product.price,
      ),
    ];
  }

  void setQty(String lineId, double qty) {
    if (qty <= 0) {
      state = state.where((l) => l.id != lineId).toList();
      return;
    }
    state = [
      for (final l in state)
        if (l.id == lineId) l.copyWith(qty: qty) else l,
    ];
  }

  void remove(String lineId) {
    state = state.where((l) => l.id != lineId).toList();
  }

  void replaceAll(List<CartLine> lines) => state = List.of(lines);

  void clear() => state = const [];
}

final cartProvider =
    NotifierProvider<CartNotifier, List<CartLine>>(CartNotifier.new);

final cartTotalProvider = Provider<double>((ref) {
  return ref.watch(cartProvider).fold(0, (sum, l) => sum + l.lineTotal);
});
