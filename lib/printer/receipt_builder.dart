import 'dart:typed_data';

class ReceiptData {
  const ReceiptData({
    required this.shopName,
    required this.address,
    required this.phone,
    required this.invoiceNo,
    required this.createdAt,
    required this.lines,
    required this.subtotal,
    required this.discount,
    required this.total,
    required this.tendered,
    required this.changeDue,
    required this.method,
    this.customerName,
    this.paperMm = 80,
  });

  final String shopName;
  final String address;
  final String phone;
  final String invoiceNo;
  final DateTime createdAt;
  final List<({String name, double qty, double price, double total})> lines;
  final double subtotal;
  final double discount;
  final double total;
  final double tendered;
  final double changeDue;
  final String method;
  final String? customerName;
  final int paperMm;
}

Uint8List buildEscPos(ReceiptData data) {
  final width = data.paperMm >= 80 ? 48 : 32;
  final out = BytesBuilder();

  void raw(List<int> b) => out.add(b);
  void text(String s, {bool bold = false, bool center = false, int size = 0}) {
    raw([0x1B, 0x61, center ? 1 : 0]);
    raw([0x1B, 0x21, (bold ? 0x08 : 0) | (size == 1 ? 0x10 : 0)]);
    raw([
      ...s.runes.map((r) => r < 128 ? r : 0x3F),
      0x0A,
    ]);
    raw([0x1B, 0x21, 0x00, 0x1B, 0x61, 0]);
  }

  String money(double n) => n.toStringAsFixed(0);
  String line(String left, String right) {
    final space = width - left.length - right.length;
    if (space < 1) {
      return '${left.substring(0, width - 1 - right.length)} $right';
    }
    return '$left${' ' * space}$right';
  }

  raw([0x1B, 0x40]);
  text(data.shopName, bold: true, center: true, size: 1);
  if (data.address.isNotEmpty) text(data.address, center: true);
  if (data.phone.isNotEmpty) text(data.phone, center: true);
  text('-' * width);
  text(line(data.invoiceNo, data.createdAt.toString().substring(0, 16)));
  if (data.customerName != null) text('Cust: ${data.customerName}');
  text('-' * width);
  for (final l in data.lines) {
    text(l.name);
    text(line('${l.qty} x ${money(l.price)}', money(l.total)));
  }
  text('-' * width);
  text(line('Subtotal', money(data.subtotal)));
  if (data.discount > 0) text(line('Discount', '-${money(data.discount)}'));
  text(line('TOTAL', money(data.total)), bold: true);
  text(line(data.method.toUpperCase(), money(data.tendered)));
  if (data.changeDue > 0) text(line('Change', money(data.changeDue)));
  text('-' * width);
  text('Thank you!', center: true);
  raw([0x0A, 0x0A, 0x1D, 0x56, 0x00]);
  return out.toBytes();
}

String receiptPreview(ReceiptData data) {
  final b = StringBuffer()
    ..writeln(data.shopName)
    ..writeln(data.invoiceNo)
    ..writeln('Total: ${data.total.toStringAsFixed(0)}');
  for (final l in data.lines) {
    b.writeln('${l.name}  ${l.qty} x ${l.price}');
  }
  return b.toString();
}
