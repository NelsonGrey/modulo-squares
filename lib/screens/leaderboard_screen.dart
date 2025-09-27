import 'package:flutter/material.dart';
import 'package:modulo/leaderboard_service.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leaderboard'),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: LeaderboardService.getTopScores(10),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final scores = snapshot.data ?? const [];
          if (scores.isEmpty) {
            return const Center(child: Text('No scores yet.'));
          }

          return ListView.builder(
            itemCount: scores.length,
            itemBuilder: (context, index) {
              final item = scores[index];
              return ListTile(
                leading: Text('#${index + 1}'),
                title: Text('Score: ${item['score']}'),
                subtitle: Text('Player: ${item['name']}'),
              );
            },
          );
        },
      ),
    );
  }
}
