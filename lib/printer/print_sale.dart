import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../db/app_database.dart';
import '../printer/printer_channel.dart';
import '../printer/receipt_builder.dart';
import '../providers/database_provider.dart';

final _pkr = NumberFormat.currency(locale: 'en_PK', symbol: 'Rs ');

Future<ReceiptData> receiptForSale(AppDatabase db, Sale sale) async {
  final items = await db.itemsForSale(sale.id);
  final settings = await db.ensureSettings(sale.shopId);
  final pays = await db.paymentsForSale(sale.id);
  String? customerName;
  if (sale.customerId != null) {
    customerName = (await db.customerById(sale.customerId!))?.name;
  }
  return ReceiptData(
    shopName: settings.shopName,
    address: settings.address,
    phone: settings.phone,
    invoiceNo: sale.invoiceNo,
    createdAt: sale.createdAt,
    lines: [
      for (final i in items)
        (name: i.nameSnapshot, qty: i.qty, price: i.unitPrice, total: i.lineTotal),
    ],
    subtotal: sale.subtotal,
    discount: sale.discount,
    total: sale.total,
    tendered: sale.tendered,
    changeDue: sale.changeDue,
    method: pays.isEmpty ? 'cash' : pays.first.method,
    customerName: customerName,
    paperMm: settings.paperMm,
  );
}

Future<void> printOrPreviewSale(
  BuildContext context,
  WidgetRef ref,
  String saleId,
) async {
  final db = ref.read(databaseProvider);
  final sale = await db.saleById(saleId);
  if (sale == null || !context.mounted) return;
  final data = await receiptForSale(db, sale);
  final settings = await db.ensureSettings(sale.shopId);
  final bytes = buildEscPos(data);

  if (!kIsWeb && settings.printerAddress.isNotEmpty) {
    try {
      await PrinterChannel().printBytes(
        address: settings.printerAddress,
        bytes: bytes,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Slip print ho gayi')),
        );
      }
      return;
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Print fail: $e')),
      );
    }
  }

  if (!context.mounted) return;
  await showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(data.invoiceNo),
      content: SingleChildScrollView(
        child: Text(
          '${data.shopName}\n'
          '${data.address}\n'
          '${[for (final l in data.lines) '${l.name}  ${l.qty} x ${_pkr.format(l.price)}'].join('\n')}\n'
          'Total ${_pkr.format(data.total)}\n'
          '${kIsWeb ? '\nBluetooth print Android phone pe hoga.' : 'Printer Settings mein pair karein.'}',
        ),
      ),
      actions: [
        FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
      ],
    ),
  );
}
