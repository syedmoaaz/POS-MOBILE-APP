import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../db/app_database.dart';
import 'cart_provider.dart';

class PosSession {
  const PosSession({this.customer, this.discount = 0});

  final Customer? customer;
  final double discount;

  PosSession copyWith({Customer? customer, double? discount, bool clearCustomer = false}) {
    return PosSession(
      customer: clearCustomer ? null : (customer ?? this.customer),
      discount: discount ?? this.discount,
    );
  }
}

class PosSessionNotifier extends Notifier<PosSession> {
  @override
  PosSession build() => const PosSession();

  void setCustomer(Customer? c) =>
      state = state.copyWith(customer: c, clearCustomer: c == null);

  void setDiscount(double d) =>
      state = state.copyWith(discount: d < 0 ? 0 : d);

  void reset() => state = const PosSession();
}

final posSessionProvider =
    NotifierProvider<PosSessionNotifier, PosSession>(PosSessionNotifier.new);

final payableTotalProvider = Provider<double>((ref) {
  final sub = ref.watch(cartTotalProvider);
  final d = ref.watch(posSessionProvider).discount;
  return (sub - d).clamp(0, double.infinity).toDouble();
});
