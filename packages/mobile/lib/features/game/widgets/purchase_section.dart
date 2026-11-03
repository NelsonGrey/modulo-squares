import 'package:flutter/material.dart';
import 'package:modulo_squares/core/services/purchase_service.dart';
import 'package:modulo_squares/features/game/widgets/settings_section.dart';

/// The "Purchases" section of the Settings page: remove_ads/premium status,
/// the Remove Ads purchase button (with its own error handling UI), and
/// Restore Purchases.
///
/// This is presentation only — the actual `InAppPurchase` stream wiring
/// (listening for purchase updates, verifying receipts, etc.) lives in
/// [PurchaseService], which the Settings page looks up once and hands to
/// this widget. On a successful restore this widget reports the refreshed
/// `adsRemoved` value back up via [onAdsRemovedChanged] so the page's local
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
    return Column(
      children: [
        const SettingsSectionHeader('Purchases'),
        ListTile(
          leading: Icon(
            adsRemoved ? Icons.check_circle_outline : Icons.tv_off_outlined,
          ),
          title: Text(adsRemoved ? 'Ad-free' : 'Ads on'),
          subtitle: Text(
            adsRemoved
                ? 'You will never see an ad in this game.'
                : 'Short ads play between levels.',
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
                'Remove Ads — '
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
