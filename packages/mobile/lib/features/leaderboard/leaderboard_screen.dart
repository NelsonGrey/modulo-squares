import 'package:flutter/material.dart';
import 'package:modulo_squares/core/services/leaderboard_service.dart';
import 'package:modulo_squares/core/services/error_handler.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leaderboard'),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: LeaderboardService.getTopScoresWithCache(10),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            ErrorHandler().logError('Leaderboard stream', snapshot.error);
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text('Failed to load leaderboard'),
                  const SizedBox(height: 8),
                  const Text('Please check your connection and try again.'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () async {
                      await LeaderboardService.refreshLeaderboardCache();
                      (context as Element).markNeedsBuild();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final scores = snapshot.data ?? const [];
          if (scores.isEmpty) {
            return const Center(child: Text('No scores yet.'));
          }

          return RefreshIndicator(
            onRefresh: LeaderboardService.refreshLeaderboardCache,
            child: ListView.builder(
              itemCount: scores.length,
              itemBuilder: (context, index) {
                final item = scores[index];
                return ListTile(
                  leading: Text('#${index + 1}'),
                  title: Text('Score: ${item['score']}'),
                  subtitle: Text('Player: ${item['name']}'),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
