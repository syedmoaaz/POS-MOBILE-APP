import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:uuid/uuid.dart';

part 'app_database.g.dart';

const _uuid = Uuid();

class Products extends Table {
  TextColumn get id => text()();
  TextColumn get shopId => text()();
  TextColumn get name => text()();
  TextColumn get barcode => text().nullable()();
  TextColumn get sku => text().nullable()();
  RealColumn get price => real()();
  RealColumn get cost => real().withDefault(const Constant(0))();
  RealColumn get stockQty => real().withDefault(const Constant(0))();
  RealColumn get lowStockAt => real().withDefault(const Constant(5))();
  BoolColumn get active => boolean().withDefault(const Constant(true))();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

class Customers extends Table {
  TextColumn get id => text()();
  TextColumn get shopId => text()();
  TextColumn get name => text()();
  TextColumn get phone => text().nullable()();
  RealColumn get creditBalance => real().withDefault(const Constant(0))();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

class Sales extends Table {
  TextColumn get id => text()();
  TextColumn get shopId => text()();
  TextColumn get invoiceNo => text()();
  TextColumn get customerId => text().nullable()();
  RealColumn get subtotal => real()();
  RealColumn get discount => real().withDefault(const Constant(0))();
  RealColumn get tax => real().withDefault(const Constant(0))();
  RealColumn get total => real()();
  RealColumn get tendered => real()();
  RealColumn get changeDue => real().withDefault(const Constant(0))();
  TextColumn get status => text().withDefault(const Constant('completed'))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

class SaleItems extends Table {
  TextColumn get id => text()();
  TextColumn get saleId => text()();
  TextColumn get productId => text().nullable()();
  TextColumn get nameSnapshot => text()();
  RealColumn get qty => real()();
  RealColumn get unitPrice => real()();
  RealColumn get itemDiscount => real().withDefault(const Constant(0))();
  RealColumn get lineTotal => real()();

  @override
  Set<Column> get primaryKey => {id};
}

class Payments extends Table {
  TextColumn get id => text()();
  TextColumn get saleId => text()();
  TextColumn get method => text()();
  RealColumn get amount => real()();

  @override
  Set<Column> get primaryKey => {id};
}

class ShopMeta extends Table {
  TextColumn get shopId => text()();
  IntColumn get nextInvoice => integer().withDefault(const Constant(1))();

  @override
  Set<Column> get primaryKey => {shopId};
}

class HeldCarts extends Table {
  TextColumn get id => text()();
  TextColumn get shopId => text()();
  TextColumn get customerId => text().nullable()();
  TextColumn get linesJson => text()();
  RealColumn get discount => real().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

class ShopSettings extends Table {
  TextColumn get shopId => text()();
  TextColumn get shopName => text().withDefault(const Constant('My Shop'))();
  TextColumn get address => text().withDefault(const Constant(''))();
  TextColumn get phone => text().withDefault(const Constant(''))();
  IntColumn get paperMm => integer().withDefault(const Constant(80))();
  TextColumn get printerAddress => text().withDefault(const Constant(''))();
  TextColumn get printerName => text().withDefault(const Constant(''))();
  DateTimeColumn get licenseUntil => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {shopId};
}

class CheckoutLine {
  const CheckoutLine({
    this.productId,
    required this.name,
    required this.qty,
    required this.unitPrice,
  });

  final String? productId;
  final String name;
  final double qty;
  final double unitPrice;

  double get lineTotal => qty * unitPrice;
}

@DriftDatabase(
  tables: [
    Products,
    Customers,
    Sales,
    SaleItems,
    Payments,
    ShopMeta,
    HeldCarts,
    ShopSettings,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _open());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.createTable(customers);
        await m.createTable(heldCarts);
        await m.createTable(shopSettings);
      }
    },
  );

  static QueryExecutor _open() => driftDatabase(name: 'shop_pos');

  Stream<List<Product>> watchProducts(String shopId) {
    return (select(products)
          ..where((t) => t.shopId.equals(shopId) & t.active.equals(true))
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .watch();
  }

  Future<Product?> productByBarcode(String shopId, String code) {
    return (select(products)..where(
          (t) =>
              t.shopId.equals(shopId) &
              t.barcode.equals(code) &
              t.active.equals(true),
        ))
        .getSingleOrNull();
  }

  Future<Product> addProduct({
    required String shopId,
    required String name,
    required double price,
    String? barcode,
    double stockQty = 0,
  }) {
    return into(products).insertReturning(
      ProductsCompanion.insert(
        id: _uuid.v4(),
        shopId: shopId,
        name: name.trim(),
        barcode: Value(
          barcode == null || barcode.trim().isEmpty ? null : barcode.trim(),
        ),
        price: price,
        stockQty: Value(stockQty),
      ),
    );
  }

  Stream<List<Customer>> watchCustomers(String shopId) {
    return (select(customers)
          ..where((t) => t.shopId.equals(shopId))
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .watch();
  }

  Future<Customer> addCustomer({
    required String shopId,
    required String name,
    String? phone,
  }) {
    return into(customers).insertReturning(
      CustomersCompanion.insert(
        id: _uuid.v4(),
        shopId: shopId,
        name: name.trim(),
        phone: Value(phone?.trim().isEmpty == true ? null : phone?.trim()),
      ),
    );
  }

  Future<Customer?> customerById(String id) {
    return (select(customers)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Stream<List<Sale>> watchRecentSales(String shopId) {
    return (select(sales)
          ..where((t) => t.shopId.equals(shopId))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
          ..limit(120))
        .watch();
  }

  Future<Sale?> saleById(String id) {
    return (select(sales)..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  Future<List<SaleItem>> itemsForSale(String saleId) {
    return (select(saleItems)..where((t) => t.saleId.equals(saleId))).get();
  }

  Future<List<Payment>> paymentsForSale(String saleId) {
    return (select(payments)..where((t) => t.saleId.equals(saleId))).get();
  }

  Stream<List<HeldCart>> watchHolds(String shopId) {
    return (select(heldCarts)
          ..where((t) => t.shopId.equals(shopId))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch();
  }

  Future<ShopSetting> ensureSettings(String shopId) async {
    final existing = await (select(shopSettings)
          ..where((t) => t.shopId.equals(shopId)))
        .getSingleOrNull();
    if (existing != null) return existing;
    return into(shopSettings).insertReturning(
      ShopSettingsCompanion.insert(
        shopId: shopId,
        licenseUntil: Value(DateTime.now().add(const Duration(days: 30))),
      ),
    );
  }

  Future<void> updateShopProfile({
    required String shopId,
    String? shopName,
    String? address,
    String? phone,
    String? printerAddress,
    String? printerName,
    int? paperMm,
  }) {
    return (update(shopSettings)..where((t) => t.shopId.equals(shopId))).write(
      ShopSettingsCompanion(
        shopName: shopName != null ? Value(shopName) : const Value.absent(),
        address: address != null ? Value(address) : const Value.absent(),
        phone: phone != null ? Value(phone) : const Value.absent(),
        printerAddress:
            printerAddress != null ? Value(printerAddress) : const Value.absent(),
        printerName:
            printerName != null ? Value(printerName) : const Value.absent(),
        paperMm: paperMm != null ? Value(paperMm) : const Value.absent(),
      ),
    );
  }

  Future<void> saveHold({
    required String shopId,
    String? customerId,
    required String linesJson,
    required double discount,
  }) {
    return into(heldCarts).insert(
      HeldCartsCompanion.insert(
        id: _uuid.v4(),
        shopId: shopId,
        customerId: Value(customerId),
        linesJson: linesJson,
        discount: Value(discount),
      ),
    );
  }

  Future<void> deleteHold(String id) {
    return (delete(heldCarts)..where((t) => t.id.equals(id))).go();
  }

  Future<({String invoiceNo, double changeDue, String saleId})> checkout({
    required String shopId,
    required List<CheckoutLine> lines,
    required double tendered,
    required String method,
    String? customerId,
    double discount = 0,
  }) {
    return transaction(() async {
      var meta = await (select(shopMeta)..where((t) => t.shopId.equals(shopId)))
          .getSingleOrNull();
      meta ??= await into(shopMeta).insertReturning(
        ShopMetaCompanion.insert(shopId: shopId),
      );

      final invoiceNo = 'INV-${meta.nextInvoice.toString().padLeft(4, '0')}';
      await (update(shopMeta)..where((t) => t.shopId.equals(shopId))).write(
        ShopMetaCompanion(nextInvoice: Value(meta.nextInvoice + 1)),
      );

      final saleId = _uuid.v4();
      var subtotal = 0.0;
      for (final line in lines) {
        subtotal += line.lineTotal;
      }
      final total = (subtotal - discount).clamp(0, double.infinity).toDouble();
      final paid = method == 'card' || method == 'credit' ? total : tendered;
      final changeDue = method == 'cash'
          ? (paid - total).clamp(0, double.infinity).toDouble()
          : 0.0;

      await into(sales).insert(
        SalesCompanion.insert(
          id: saleId,
          shopId: shopId,
          invoiceNo: invoiceNo,
          customerId: Value(customerId),
          subtotal: subtotal,
          discount: Value(discount),
          total: total,
          tendered: paid,
          changeDue: Value(changeDue),
        ),
      );

      for (final line in lines) {
        await into(saleItems).insert(
          SaleItemsCompanion.insert(
            id: _uuid.v4(),
            saleId: saleId,
            productId: Value(line.productId),
            nameSnapshot: line.name,
            qty: line.qty,
            unitPrice: line.unitPrice,
            lineTotal: line.lineTotal,
          ),
        );
        if (line.productId != null) {
          final product = await (select(products)
                ..where((t) => t.id.equals(line.productId!)))
              .getSingleOrNull();
          if (product != null) {
            await (update(products)..where((t) => t.id.equals(product.id)))
                .write(
              ProductsCompanion(
                stockQty: Value(product.stockQty - line.qty),
                updatedAt: Value(DateTime.now()),
              ),
            );
          }
        }
      }

      await into(payments).insert(
        PaymentsCompanion.insert(
          id: _uuid.v4(),
          saleId: saleId,
          method: method,
          amount: total,
        ),
      );

      if (method == 'credit' && customerId != null) {
        final c = await (select(customers)..where((t) => t.id.equals(customerId)))
            .getSingleOrNull();
        if (c != null) {
          await (update(customers)..where((t) => t.id.equals(customerId))).write(
            CustomersCompanion(
              creditBalance: Value(c.creditBalance + total),
              updatedAt: Value(DateTime.now()),
            ),
          );
        }
      }

      return (invoiceNo: invoiceNo, changeDue: changeDue, saleId: saleId);
    });
  }

  Future<void> returnSale(String saleId) {
    return transaction(() async {
      final sale = await saleById(saleId);
      if (sale == null || sale.status != 'completed') return;
      final items = await itemsForSale(saleId);
      for (final item in items) {
        if (item.productId == null) continue;
        final product = await (select(products)
              ..where((t) => t.id.equals(item.productId!)))
            .getSingleOrNull();
        if (product != null) {
          await (update(products)..where((t) => t.id.equals(product.id))).write(
            ProductsCompanion(
              stockQty: Value(product.stockQty + item.qty),
              updatedAt: Value(DateTime.now()),
            ),
          );
        }
      }
      if (sale.customerId != null) {
        final pays = await paymentsForSale(saleId);
        final wasCredit = pays.any((p) => p.method == 'credit');
        if (wasCredit) {
          final c = await (select(customers)
                ..where((t) => t.id.equals(sale.customerId!)))
              .getSingleOrNull();
          if (c != null) {
            await (update(customers)
                  ..where((t) => t.id.equals(sale.customerId!)))
                .write(
              CustomersCompanion(
                creditBalance: Value(
                  (c.creditBalance - sale.total)
                      .clamp(0, double.infinity)
                      .toDouble(),
                ),
                updatedAt: Value(DateTime.now()),
              ),
            );
          }
        }
      }
      await (update(sales)..where((t) => t.id.equals(saleId))).write(
        const SalesCompanion(status: Value('returned')),
      );
    });
  }

  String encodeHoldLines(List<Map<String, dynamic>> lines) => jsonEncode(lines);

  List<Map<String, dynamic>> decodeHoldLines(String json) {
    final raw = jsonDecode(json);
    if (raw is! List) return [];
    return raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }
}
