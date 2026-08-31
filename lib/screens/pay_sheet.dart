import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

final _pkr = NumberFormat.currency(locale: 'en_PK', symbol: 'Rs ');

class PayResult {
  const PayResult({required this.tendered, required this.method});

  final double tendered;
  final String method;
}

Future<PayResult?> showPaySheet(
  BuildContext context, {
  required double total,
  bool allowCredit = false,
}) {
  return showModalBottomSheet<PayResult>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => _PaySheet(total: total, allowCredit: allowCredit),
  );
}

class _PaySheet extends StatefulWidget {
  const _PaySheet({required this.total, required this.allowCredit});

  final double total;
  final bool allowCredit;

  @override
  State<_PaySheet> createState() => _PaySheetState();
}

class _PaySheetState extends State<_PaySheet> {
  String _method = 'cash';
  late final TextEditingController _tendered;

  @override
  void initState() {
    super.initState();
    _tendered = TextEditingController(
      text: widget.total == widget.total.roundToDouble()
          ? widget.total.toStringAsFixed(0)
          : widget.total.toStringAsFixed(2),
    );
    _tendered.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tendered.dispose();
    super.dispose();
  }

  double get _paid {
    if (_method == 'card' || _method == 'credit') return widget.total;
    return double.tryParse(_tendered.text) ?? 0;
  }

  double get _change => (_paid - widget.total).clamp(0, double.infinity);

  bool get _canConfirm =>
      _method != 'cash' || _paid + 0.0001 >= widget.total;

  void _setQuick(double amount) {
    _tendered.text = amount == amount.roundToDouble()
        ? amount.toStringAsFixed(0)
        : amount.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    const quick = [500.0, 1000.0, 5000.0];

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
          Text('Payment', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'Total  ${_pkr.format(widget.total)}',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          SegmentedButton<String>(
            segments: [
              const ButtonSegment(
                value: 'cash',
                label: Text('Cash'),
                icon: Icon(Icons.payments_outlined),
              ),
              const ButtonSegment(
                value: 'card',
                label: Text('Card'),
                icon: Icon(Icons.credit_card),
              ),
              if (widget.allowCredit)
                const ButtonSegment(
                  value: 'credit',
                  label: Text('Udhaar'),
                  icon: Icon(Icons.handshake_outlined),
                ),
            ],
            selected: {_method},
            onSelectionChanged: (s) => setState(() => _method = s.first),
          ),
          if (_method == 'cash') ...[
            const SizedBox(height: 16),
            TextField(
              controller: _tendered,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              decoration: const InputDecoration(
                labelText: 'Cash received',
                prefixText: 'Rs  ',
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ActionChip(
                  label: const Text('Exact'),
                  onPressed: () => _setQuick(widget.total),
                ),
                for (final q in quick)
                  if (q >= widget.total)
                    ActionChip(
                      label: Text(_pkr.format(q)),
                      onPressed: () => _setQuick(q),
                    ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _canConfirm
                    ? scheme.primaryContainer.withValues(alpha: 0.55)
                    : scheme.errorContainer.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  Text(
                    _canConfirm ? 'Wapsi (change)' : 'Kam paisa',
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  ),
                  const Spacer(),
                  Text(
                    _pkr.format(_canConfirm ? _change : widget.total - _paid),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 18),
          FilledButton(
            onPressed: _canConfirm
                ? () => Navigator.pop(
                      context,
                      PayResult(tendered: _paid, method: _method),
                    )
                : null,
            child: const Text('Complete sale'),
          ),
        ],
      ),
    );
  }
}
