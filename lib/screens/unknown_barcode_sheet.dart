import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class UnknownBarcodeResult {
  const UnknownBarcodeResult({
    required this.name,
    required this.price,
    required this.saveToInventory,
    this.stockQty = 0,
  });

  final String name;
  final double price;
  final bool saveToInventory;
  final double stockQty;
}

Future<UnknownBarcodeResult?> showUnknownBarcodeSheet(
  BuildContext context, {
  required String barcode,
}) {
  return showModalBottomSheet<UnknownBarcodeResult>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => _UnknownSheet(barcode: barcode),
  );
}

class _UnknownSheet extends StatefulWidget {
  const _UnknownSheet({required this.barcode});

  final String barcode;

  @override
  State<_UnknownSheet> createState() => _UnknownSheetState();
}

class _UnknownSheetState extends State<_UnknownSheet> {
  late final TextEditingController _name;
  final _price = TextEditingController();
  final _stock = TextEditingController(text: '0');
  var _save = true;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController();
  }

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    _stock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 8,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Product nahi mila', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 6),
          Text('Barcode: ${widget.barcode}'),
          const SizedBox(height: 16),
          TextField(
            controller: _name,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Name'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _price,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            ],
            decoration: const InputDecoration(labelText: 'Price (Rs)'),
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Inventory mein bhi save'),
            value: _save,
            onChanged: (v) => setState(() => _save = v),
          ),
          if (_save)
            TextField(
              controller: _stock,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              decoration: const InputDecoration(labelText: 'Opening stock'),
            ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () {
              final name = _name.text.trim().isEmpty
                  ? widget.barcode
                  : _name.text.trim();
              Navigator.pop(
                context,
                UnknownBarcodeResult(
                  name: name,
                  price: double.tryParse(_price.text) ?? 0,
                  saveToInventory: _save,
                  stockQty: double.tryParse(_stock.text) ?? 0,
                ),
              );
            },
            child: const Text('Cart mein add'),
          ),
        ],
      ),
    );
  }
}
