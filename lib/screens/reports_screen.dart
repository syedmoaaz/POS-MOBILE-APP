import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../printer/print_sale.dart';
import '../providers/database_provider.dart';
import '../theme.dart';

final _pkr = NumberFormat.currency(locale: 'en_PK', symbol: 'Rs ');
final _time = DateFormat('dd MMM, hh:mm a');

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(recentSalesProvider);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Reports')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (sales) {
          final today = DateTime.now();
          final todays = sales.where(
            (s) =>
                s.status == 'completed' &&
                s.createdAt.year == today.year &&
                s.createdAt.month == today.month &&
                s.createdAt.day == today.day,
          );
          final todayTotal = todays.fold<double>(0, (sum, s) => sum + s.total);
          final cash = todays.fold<double>(0, (sum, s) => sum + s.tendered);

          if (sales.isEmpty) {
            return const EmptyHint(
              icon: Icons.receipt_long_outlined,
              text: 'Abhi koi saved bill nahi.',
            );
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              SoftCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Z-Report (aaj)', style: TextStyle(color: scheme.onSurfaceVariant)),
                    const SizedBox(height: 4),
                    Text(
                      _pkr.format(todayTotal),
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    Text('${todays.length} bills  ·  tendered ${_pkr.format(cash)}'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Bills',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              ...sales.map(
                (s) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: SoftCard(
                    onTap: () => _openSale(context, ref, s.id, s.invoiceNo, s.status),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                s.invoiceNo,
                                style: const TextStyle(fontWeight: FontWeight.w700),
                              ),
                              Text(
                                '${_time.format(s.createdAt)}  ·  ${s.status}',
                                style: TextStyle(color: scheme.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          _pkr.format(s.total),
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _openSale(
    BuildContext context,
    WidgetRef ref,
    String id,
    String invoice,
    String status,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(title: Text(invoice), subtitle: Text(status)),
            ListTile(
              leading: const Icon(Icons.print_rounded),
              title: const Text('Reprint'),
              onTap: () async {
                Navigator.pop(ctx);
                await printOrPreviewSale(context, ref, id);
              },
            ),
            if (status == 'completed')
              ListTile(
                leading: const Icon(Icons.undo_rounded),
                title: const Text('Return / refund'),
                onTap: () async {
                  Navigator.pop(ctx);
                  await ref.read(databaseProvider).returnSale(id);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Return save. Stock wapas.')),
                    );
                  }
                },
              ),
          ],
        ),
      ),
    );
  }
}
