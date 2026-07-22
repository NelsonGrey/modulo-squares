import 'package:flutter/material.dart';
import 'package:modulo_squares/core/services/leaderboard_service.dart';
import 'package:modulo_squares/l10n/app_localizations.dart';

mixin GameDialogs {
  void showEndDialog(
    BuildContext context,
    String title,
    String message,
    bool showLeaderboardOption,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return AlertDialog(
          title: Text(title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [Text(message)],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void showLeaderboardDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.globalLeaderboard),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: LeaderboardService.getTopScores(10),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Text(AppLocalizations.of(context)!.noScoresYet),
                  );
                }
                final scores = snapshot.data!;
                return ListView.builder(
                  itemCount: scores.length,
                  itemBuilder: (_, index) {
                    final item = scores[index];
                    return ListTile(
                      leading: Text('#${index + 1}'),
                      title: Text(item['name']),
                      trailing: Text(item['score'].toString()),
                    );
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(AppLocalizations.of(context)!.close),
            ),
          ],
        );
      },
    );
  }

  void showDailyLeaderboardDialog(BuildContext context, int challengeId) {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text('Daily Leaderboard ($challengeId)'),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: LeaderboardService.getTopDailyScores(challengeId, 10),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Text(AppLocalizations.of(context)!.noScoresYet),
                  );
                }
                final scores = snapshot.data!;
                return ListView.builder(
                  itemCount: scores.length,
                  itemBuilder: (_, index) {
                    final item = scores[index];
                    return ListTile(
                      leading: Text('#${index + 1}'),
                      title: Text(item['name']),
                      trailing: Text(item['score'].toString()),
                    );
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(AppLocalizations.of(context)!.close),
            ),
          ],
        );
      },
    );
  }

  void showSpecialTilesInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Special Tiles'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                leading: const Icon(Icons.block, color: Colors.black87),
                title: const Text('Obstacle Tile'),
                subtitle: const Text('Blocks movement and cannot be entered.'),
              ),
              ListTile(
                leading: const Icon(Icons.star, color: Colors.green),
                title: const Text('Bonus Tile'),
                subtitle: const Text('Collision grants bonus points.'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(AppLocalizations.of(context)!.close),
            ),
          ],
        );
      },
    );
  }

  void showPurchaseDialog(BuildContext context, dynamic purchaseService) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Unlock Premium'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (purchaseService.adsRemoved)
                const ListTile(
                  leading: Icon(Icons.check_circle, color: Colors.green),
                  title: Text('Ads Removed'),
                  subtitle: Text('You have successfully removed ads!'),
                )
              else
                ListTile(
                  leading: const Icon(Icons.block, color: Colors.orange),
                  title: const Text('Unlock Premium'),
                  subtitle: Text(
                    'Price: ${purchaseService.getProductPrice('remove_ads')}',
                  ),
                  trailing: ElevatedButton(
                    onPressed: () async {
                      Navigator.of(context).pop();
                      try {
                        await purchaseService.purchaseAdRemoval();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Purchase completed! Ads removed.'),
                          ),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Purchase failed: $e')),
                        );
                      }
                    },
                    child: const Text('Buy'),
                  ),
                ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () async {
                  await purchaseService.restorePurchases();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Purchase restoration attempted.'),
                    ),
                  );
                },
                child: const Text('Restore Purchases'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}
