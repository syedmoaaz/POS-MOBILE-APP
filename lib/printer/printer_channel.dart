import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class BondedPrinter {
  const BondedPrinter({required this.name, required this.address});

  final String name;
  final String address;
}

class PrinterChannel {
  static const _ch = MethodChannel('shopos/printer');

  Future<List<BondedPrinter>> bonded() async {
    if (kIsWeb) return const [];
    final raw = await _ch.invokeMethod<List<dynamic>>('bonded');
    return [
      for (final item in raw ?? const [])
        BondedPrinter(
          name: '${(item as Map)['name'] ?? ''}',
          address: '${item['address'] ?? ''}',
        ),
    ];
  }

  Future<void> printBytes({
    required String address,
    required Uint8List bytes,
  }) async {
    if (kIsWeb) {
      throw StateError('Bluetooth print phone pe chalega, Chrome pe nahi.');
    }
    await _ch.invokeMethod('print', {
      'address': address,
      'bytes': bytes,
    });
  }
}
