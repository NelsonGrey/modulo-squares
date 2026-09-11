import 'package:flutter/material.dart';
import 'package:modulo_squares/core/services/purchase_service.dart';
import 'package:modulo_squares/features/game/widgets/settings_section.dart';

/// The "Purchases" section of the settings dialog: remove_ads/premium status,
/// the Unlock Premium purchase button (with its own error handling UI), and
/// Restore Purchases.
///
/// This is presentation only — the actual `InAppPurchase` stream wiring
/// (listening for purchase updates, verifying receipts, etc.) lives in
/// [PurchaseService], which the settings dialog looks up once and hands to
/// this widget. On a successful restore this widget reports the refreshed
/// `adsRemoved` value back up via [onAdsRemovedChanged] so the dialog's local
/// state (and this widget's own display) stays in sync.
class PurchaseSection extends StatelessWidget {
  const PurchaseSection({
    super.key,
    required this.purchaseService,
    required this.adsRemoved,
    required this.onAdsRemovedChanged,
  });

  final PurchaseService purchaseService;
  final bool adsRemoved;
  final ValueChanged<bool> onAdsRemovedChanged;

  @override
  Widget build(BuildContext context) {
    return SettingsSection(
      title: 'Purchases',
      children: [
        ListTile(
          leading: Icon(
            adsRemoved ? Icons.check_circle_outline : Icons.tv_off_outlined,
            color: adsRemoved ? Colors.green : Colors.orange,
          ),
          title: Text(adsRemoved ? 'Ad-Free' : 'Ads Enabled'),
          subtitle: Text(
            adsRemoved
                ? 'Enjoy the game without interruptions'
                : 'Short ads play between levels',
          ),
        ),
        if (!adsRemoved)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
            child: FilledButton(
              onPressed: () async {
                try {
                  await purchaseService.purchaseAdRemoval();
                  // Payment sheet is handled by the store;
                  // result arrives via purchaseStream.
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        e.toString().replaceFirst('Exception: ', ''),
                      ),
                      duration: const Duration(seconds: 4),
                    ),
                  );
                }
              },
              child: Text(
                'Unlock Premium  —  '
                '${purchaseService.getProductPrice('remove_ads')}',
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: OutlinedButton(
            onPressed: () async {
              await purchaseService.restorePurchases();
              onAdsRemovedChanged(purchaseService.adsRemoved);
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Purchases restored successfully.'),
                ),
              );
            },
            child: const Text('Restore Purchases'),
          ),
        ),
      ],
    );
  }
}
