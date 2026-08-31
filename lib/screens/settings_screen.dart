import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../printer/printer_channel.dart';
import '../providers/auth_provider.dart';
import '../providers/database_provider.dart';
import '../theme.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _name = TextEditingController();
  final _address = TextEditingController();
  final _phone = TextEditingController();
  var _loaded = false;

  @override
  void dispose() {
    _name.dispose();
    _address.dispose();
    _phone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shop = ref.watch(authProvider).shopId ?? '-';
    final async = ref.watch(settingsProvider);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (s) {
          if (s != null && !_loaded) {
            _loaded = true;
            _name.text = s.shopName;
            _address.text = s.address;
            _phone.text = s.phone;
          }
          final days = s?.licenseUntil == null
              ? 0
              : s!.licenseUntil!.difference(DateTime.now()).inDays;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              SoftCard(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: scheme.primaryContainer,
                    child: Icon(Icons.storefront_rounded, color: scheme.primary),
                  ),
                  title: const Text('Shop ID'),
                  subtitle: Text(shop),
                ),
              ),
              const SizedBox(height: 10),
              SoftCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextField(
                      controller: _name,
                      decoration: const InputDecoration(labelText: 'Shop name'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _address,
                      decoration: const InputDecoration(labelText: 'Address'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _phone,
                      decoration: const InputDecoration(labelText: 'Phone'),
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () async {
                        final id = ref.read(shopIdProvider);
                        if (id == null) return;
                        await ref.read(databaseProvider).updateShopProfile(
                              shopId: id,
                              shopName: _name.text,
                              address: _address.text,
                              phone: _phone.text,
                            );
                        ref.invalidate(settingsProvider);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Saved')),
                          );
                        }
                      },
                      child: const Text('Save shop info'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              SoftCard(
                child: ListTile(
                  leading: const Icon(Icons.verified_outlined),
                  title: const Text('License'),
                  subtitle: Text(
                    days < 0
                        ? 'Expired'
                        : '$days days left (printer bundle 1 month free)',
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SoftCard(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.print_rounded),
                      title: const Text('Thermal printer'),
                      subtitle: Text(
                        (s?.printerName.isNotEmpty == true)
                            ? s!.printerName
                            : (kIsWeb
                                ? 'Pair Android phone pe (Bluetooth)'
                                : 'Paired device select karein'),
                      ),
                    ),
                    if (!kIsWeb)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: OutlinedButton(
                          onPressed: () => _pickPrinter(context),
                          child: const Text('Choose bonded printer'),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.tonal(
                onPressed: () {
                  ref.read(authProvider.notifier).logout();
                  context.go('/login');
                },
                child: const Text('Logout'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _pickPrinter(BuildContext context) async {
    try {
      final list = await PrinterChannel().bonded();
      if (!context.mounted) return;
      if (list.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pehle Android Bluetooth se printer pair karo.'),
          ),
        );
        return;
      }
      final picked = await showModalBottomSheet<BondedPrinter>(
        context: context,
        builder: (ctx) => ListView(
          children: [
            for (final p in list)
              ListTile(
                title: Text(p.name),
                subtitle: Text(p.address),
                onTap: () => Navigator.pop(ctx, p),
              ),
          ],
        ),
      );
      final shopId = ref.read(shopIdProvider);
      if (picked == null || shopId == null) return;
      await ref.read(databaseProvider).updateShopProfile(
            shopId: shopId,
            printerAddress: picked.address,
            printerName: picked.name,
          );
      ref.invalidate(settingsProvider);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }
}
