import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../db/app_database.dart';
import 'auth_provider.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final shopIdProvider = Provider<String?>((ref) {
  return ref.watch(authProvider).shopId;
});

final productsProvider = StreamProvider<List<Product>>((ref) {
  final shopId = ref.watch(shopIdProvider);
  if (shopId == null) return Stream.value(const []);
  return ref.watch(databaseProvider).watchProducts(shopId);
});

final recentSalesProvider = StreamProvider<List<Sale>>((ref) {
  final shopId = ref.watch(shopIdProvider);
  if (shopId == null) return Stream.value(const []);
  return ref.watch(databaseProvider).watchRecentSales(shopId);
});

final customersProvider = StreamProvider<List<Customer>>((ref) {
  final shopId = ref.watch(shopIdProvider);
  if (shopId == null) return Stream.value(const []);
  return ref.watch(databaseProvider).watchCustomers(shopId);
});

final holdsProvider = StreamProvider<List<HeldCart>>((ref) {
  final shopId = ref.watch(shopIdProvider);
  if (shopId == null) return Stream.value(const []);
  return ref.watch(databaseProvider).watchHolds(shopId);
});

final settingsProvider = FutureProvider<ShopSetting?>((ref) async {
  final shopId = ref.watch(shopIdProvider);
  if (shopId == null) return null;
  return ref.watch(databaseProvider).ensureSettings(shopId);
});
