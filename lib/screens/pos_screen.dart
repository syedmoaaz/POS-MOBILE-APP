import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/cart_line.dart';
import '../db/app_database.dart';
import '../printer/print_sale.dart';
import '../providers/cart_provider.dart';
import '../providers/database_provider.dart';
import '../providers/pos_session_provider.dart';
import '../theme.dart';
import 'barcode_scan_page.dart';
import 'pay_sheet.dart';
import 'unknown_barcode_sheet.dart';

final _pkr = NumberFormat.currency(locale: 'en_PK', symbol: 'Rs ');

class PosScreen extends ConsumerWidget {
  const PosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lines = ref.watch(cartProvider);
    final total = ref.watch(payableTotalProvider);
    final session = ref.watch(posSessionProvider);
    final products = ref.watch(productsProvider).valueOrNull ?? const [];
    final scheme = Theme.of(context).colorScheme;
    final license = ref.watch(settingsProvider).valueOrNull?.licenseUntil;
    final expired = license != null && license.isBefore(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sale'),
        actions: [
          IconButton(
            tooltip: 'Hold bill',
            onPressed: lines.isEmpty ? null : () => _hold(context, ref),
            icon: const Icon(Icons.pause_circle_outline_rounded),
          ),
          IconButton(
            tooltip: 'Held bills',
            onPressed: () => _recall(context, ref),
            icon: const Icon(Icons.inventory_outlined),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton.filledTonal(
              tooltip: 'Scan barcode',
              onPressed: () => _scan(context, ref),
              icon: const Icon(Icons.qr_code_scanner_rounded),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Name ya barcode se search',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: IconButton(
                  tooltip: 'Scan',
                  onPressed: () => _scan(context, ref),
                  icon: const Icon(Icons.qr_code_scanner_rounded),
                ),
              ),
              onSubmitted: (q) async {
                final shopId = ref.read(shopIdProvider);
                if (shopId == null || q.trim().isEmpty) return;
                final db = ref.read(databaseProvider);
                final byCode = await db.productByBarcode(shopId, q.trim());
                if (byCode != null) {
                  ref.read(cartProvider.notifier).addProduct(byCode);
                  return;
                }
                final match = products.where(
                  (p) => p.name.toLowerCase().contains(q.toLowerCase()),
                );
                if (match.isNotEmpty) {
                  ref.read(cartProvider.notifier).addProduct(match.first);
                }
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: ActionChip(
                    avatar: const Icon(Icons.person_outline, size: 18),
                    label: Text(session.customer?.name ?? 'Customer'),
                    onPressed: () => _pickCustomer(context, ref),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 120,
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: 'Disc',
                      isDense: true,
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    onChanged: (v) => ref
                        .read(posSessionProvider.notifier)
                        .setDiscount(double.tryParse(v) ?? 0),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: OutlinedButton.icon(
              onPressed: () => _openItemSheet(context, ref),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Item (name, qty, price)'),
            ),
          ),
          Expanded(
            child: lines.isEmpty
                ? const EmptyHint(
                    icon: Icons.shopping_bag_outlined,
                    text: 'Cart khali hai.\nItem add karo ya search karo.',
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                    itemCount: lines.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final line = lines[i];
                      return SoftCard(
                        child: Row(
                          children: [
                            QtyButton(
                              icon: Icons.remove_rounded,
                              onPressed: () => ref
                                  .read(cartProvider.notifier)
                                  .setQty(line.id, line.qty - 1),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 6),
                              child: Text(
                                '${line.qty}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            QtyButton(
                              icon: Icons.add_rounded,
                              onPressed: () => ref
                                  .read(cartProvider.notifier)
                                  .setQty(line.id, line.qty + 1),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    line.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    '${line.qty} × ${_pkr.format(line.unitPrice)}',
                                    style: TextStyle(
                                      color: scheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              _pkr.format(line.lineTotal),
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: SoftCard(
              padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total',
                          style: TextStyle(color: scheme.onSurfaceVariant),
                        ),
                        Text(
                          _pkr.format(total),
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 140,
                    child: FilledButton(
                      onPressed: lines.isEmpty || expired
                          ? null
                          : () => _pay(context, ref),
                      child: Text(expired ? 'Expired' : 'Pay'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _scan(BuildContext context, WidgetRef ref) async {
    final code = await scanBarcode(context);
    if (code == null || !context.mounted) return;
    await _applyBarcode(context, ref, code);
  }

  Future<void> _applyBarcode(
    BuildContext context,
    WidgetRef ref,
    String code,
  ) async {
    final shopId = ref.read(shopIdProvider);
    if (shopId == null) return;
    final product = await ref.read(databaseProvider).productByBarcode(shopId, code);
    if (product != null) {
      ref.read(cartProvider.notifier).addProduct(product);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${product.name} add ho gaya')),
      );
      return;
    }
    if (!context.mounted) return;
    final created = await showUnknownBarcodeSheet(context, barcode: code);
    if (created == null || !context.mounted) return;
    if (created.saveToInventory) {
      final saved = await ref.read(databaseProvider).addProduct(
            shopId: shopId,
            name: created.name,
            price: created.price,
            barcode: code,
            stockQty: created.stockQty,
          );
      ref.read(cartProvider.notifier).addProduct(saved);
    } else {
      ref.read(cartProvider.notifier).addOpenItem(
            name: created.name,
            qty: 1,
            unitPrice: created.price,
          );
    }
  }

  Future<void> _pay(BuildContext context, WidgetRef ref) async {
    final shopId = ref.read(shopIdProvider);
    final lines = ref.read(cartProvider);
    final total = ref.read(payableTotalProvider);
    final session = ref.read(posSessionProvider);
    if (shopId == null || lines.isEmpty) return;

    final settings = await ref.read(databaseProvider).ensureSettings(shopId);
    if (settings.licenseUntil != null &&
        settings.licenseUntil!.isBefore(DateTime.now())) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('License expire. Admin se renew karao.')),
      );
      return;
    }
    if (!context.mounted) return;

    final pay = await showPaySheet(
      context,
      total: total,
      allowCredit: session.customer != null,
    );
    if (pay == null || !context.mounted) return;

    try {
      final db = ref.read(databaseProvider);
      final result = await db.checkout(
        shopId: shopId,
        tendered: pay.tendered,
        method: pay.method,
        customerId: session.customer?.id,
        discount: session.discount,
        lines: [
          for (final l in lines)
            CheckoutLine(
              productId: l.productId,
              name: l.name,
              qty: l.qty,
              unitPrice: l.unitPrice,
            ),
        ],
      );
      ref.read(cartProvider.notifier).clear();
      ref.read(posSessionProvider.notifier).reset();
      if (!context.mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            title: Text(result.invoiceNo),
            content: Text(
              pay.method == 'cash'
                  ? 'Wapsi  ${_pkr.format(result.changeDue)}'
                  : '${pay.method} payment saved.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Close'),
              ),
              FilledButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  if (context.mounted) {
                    await printOrPreviewSale(context, ref, result.saleId);
                  }
                },
                child: const Text('Print'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Bill save nahi hua: $e')),
      );
    }
  }

  Future<void> _pickCustomer(BuildContext context, WidgetRef ref) async {
    final list = ref.read(customersProvider).valueOrNull ?? const [];
    final picked = await showModalBottomSheet<Customer?>(
      context: context,
      builder: (ctx) {
        return ListView(
          children: [
            ListTile(
              title: const Text('Walk-in (no customer)'),
              onTap: () => Navigator.pop(ctx, null),
            ),
            for (final c in list)
              ListTile(
                title: Text(c.name),
                subtitle: Text(_pkr.format(c.creditBalance)),
                onTap: () => Navigator.pop(ctx, c),
              ),
          ],
        );
      },
    );
    ref.read(posSessionProvider.notifier).setCustomer(picked);
  }

  Future<void> _hold(BuildContext context, WidgetRef ref) async {
    final shopId = ref.read(shopIdProvider);
    final lines = ref.read(cartProvider);
    if (shopId == null || lines.isEmpty) return;
    final session = ref.read(posSessionProvider);
    await ref.read(databaseProvider).saveHold(
          shopId: shopId,
          customerId: session.customer?.id,
          discount: session.discount,
          linesJson: ref.read(databaseProvider).encodeHoldLines([
            for (final l in lines)
              {
                'id': l.id,
                'name': l.name,
                'qty': l.qty,
                'unitPrice': l.unitPrice,
                'productId': l.productId,
              },
          ]),
        );
    ref.read(cartProvider.notifier).clear();
    ref.read(posSessionProvider.notifier).reset();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bill hold ho gayi')),
      );
    }
  }

  Future<void> _recall(BuildContext context, WidgetRef ref) async {
    final holds = ref.read(holdsProvider).valueOrNull ?? const [];
    if (holds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Koi hold bill nahi')),
      );
      return;
    }
    final picked = await showModalBottomSheet<HeldCart>(
      context: context,
      builder: (ctx) => ListView(
        children: [
          for (final h in holds)
            ListTile(
              title: Text('Hold ${h.createdAt.hour}:${h.createdAt.minute.toString().padLeft(2, '0')}'),
              onTap: () => Navigator.pop(ctx, h),
            ),
        ],
      ),
    );
    if (picked == null) return;
    final db = ref.read(databaseProvider);
    final maps = db.decodeHoldLines(picked.linesJson);
    ref.read(cartProvider.notifier).replaceAll([
      for (final m in maps)
        CartLine(
          id: '${m['id']}',
          name: '${m['name']}',
          qty: (m['qty'] as num).toDouble(),
          unitPrice: (m['unitPrice'] as num).toDouble(),
          productId: m['productId'] as String?,
        ),
    ]);
    ref.read(posSessionProvider.notifier).setDiscount(picked.discount);
    if (picked.customerId != null) {
      final c = await db.customerById(picked.customerId!);
      ref.read(posSessionProvider.notifier).setCustomer(c);
    }
    await db.deleteHold(picked.id);
  }

  Future<void> _openItemSheet(BuildContext context, WidgetRef ref) async {
    final name = TextEditingController();
    final qty = TextEditingController(text: '1');
    final price = TextEditingController();
    final save = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 8,
            bottom: MediaQuery.viewInsetsOf(ctx).bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Naya item', style: Theme.of(ctx).textTheme.titleLarge),
              const SizedBox(height: 16),
              TextField(
                controller: name,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: qty,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
                decoration: const InputDecoration(labelText: 'Quantity'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: price,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
                decoration: const InputDecoration(labelText: 'Price (Rs)'),
              ),
              const SizedBox(height: 18),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Cart mein add'),
              ),
            ],
          ),
        );
      },
    );
    if (save == true && name.text.trim().isNotEmpty) {
      final q = double.tryParse(qty.text) ?? 1;
      final p = double.tryParse(price.text) ?? 0;
      ref.read(cartProvider.notifier).addOpenItem(
            name: name.text,
            qty: q <= 0 ? 1 : q,
            unitPrice: p,
          );
    }
    name.dispose();
    qty.dispose();
    price.dispose();
  }
}
