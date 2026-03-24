import 'package:flutter/material.dart';
import 'package:modulo_squares/core/services/leaderboard_service.dart';
import 'package:modulo_squares/l10n/app_localizations.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({
    super.key,
    required this.playerName,
    this.challengeId,
    this.startOnDaily = false,
  });

  final String playerName;
  final int? challengeId;
  final bool startOnDaily;

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final int _activeWeekId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.startOnDaily ? 1 : 0,
    );
    _activeWeekId = LeaderboardService.currentWeekId();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leaderboards'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Global'),
            Tab(text: 'Daily'),
            Tab(text: 'Weekly'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _LeaderboardList(
            title: l10n.globalLeaderboard,
            stream: LeaderboardService.getTopScores(25),
            emptyText: l10n.noScoresYet,
          ),
          _DailyLeaderboardTab(
            challengeId: widget.challengeId,
            playerName: widget.playerName,
          ),
          _WeeklyLeaderboardTab(
            weekId: _activeWeekId,
            playerName: widget.playerName,
          ),
        ],
      ),
    );
  }
}

class _WeeklyLeaderboardTab extends StatefulWidget {
  const _WeeklyLeaderboardTab({required this.weekId, required this.playerName});

  final int weekId;
  final String playerName;

  @override
  State<_WeeklyLeaderboardTab> createState() => _WeeklyLeaderboardTabState();
}

class _WeeklyLeaderboardTabState extends State<_WeeklyLeaderboardTab> {
  late final List<int> _recentWeeks;
  late int _selectedWeekId;

  @override
  void initState() {
    super.initState();
    _recentWeeks = LeaderboardService.recentWeekIds(count: 8);
    _selectedWeekId =
        _recentWeeks.contains(widget.weekId)
            ? widget.weekId
            : _recentWeeks.first;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Weekly Ladder',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 6),
                  DropdownButton<int>(
                    value: _selectedWeekId,
                    isExpanded: true,
                    items:
                        _recentWeeks
                            .map(
                              (w) => DropdownMenuItem<int>(
                                value: w,
                                child: Text('Week $w'),
                              ),
                            )
                            .toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        _selectedWeekId = value;
                      });
                    },
                  ),
                  const SizedBox(height: 6),
                  FutureBuilder<int?>(
                    future: LeaderboardService.getWeeklyRank(
                      _selectedWeekId,
                      widget.playerName,
                    ),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Text('Checking your weekly rank...');
                      }
                      if (snapshot.hasError) {
                        return const Text(
                          'Could not fetch your weekly rank yet.',
                        );
                      }
                      final rank = snapshot.data;
                      if (rank == null) {
                        return const Text(
                          'No weekly rank yet. Complete a level to enter this week\'s ladder.',
                        );
                      }
                      final badge = LeaderboardService.weeklyBadgeForRank(rank);
                      return Text('Your weekly rank: #$rank  Badge: $badge');
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: _LeaderboardList(
            title: 'Weekly Top Scores',
            stream: LeaderboardService.getTopWeeklyScores(_selectedWeekId, 25),
            emptyText: l10n.noScoresYet,
            includeBadge: true,
          ),
        ),
      ],
    );
  }
}

class _DailyLeaderboardTab extends StatelessWidget {
  const _DailyLeaderboardTab({
    required this.challengeId,
    required this.playerName,
  });

  final int? challengeId;
  final String playerName;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (challengeId == null) {
      return Center(
        child: Text(
          'Daily leaderboard becomes available after entering Daily Challenge mode.',
          textAlign: TextAlign.center,
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Daily Challenge: $challengeId',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 6),
                  FutureBuilder<int?>(
                    future: LeaderboardService.getDailyRank(
                      challengeId!,
                      playerName,
                    ),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Text('Checking your rank...');
                      }
                      if (snapshot.hasError) {
                        return const Text('Could not fetch your rank yet.');
                      }
                      final rank = snapshot.data;
                      if (rank == null) {
                        return const Text(
                          'No rank yet. Complete and submit your daily score to appear on the board.',
                        );
                      }
                      return Text('Your current rank: #$rank');
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: _LeaderboardList(
            title: 'Daily Top Scores',
            stream: LeaderboardService.getTopDailyScores(challengeId!, 25),
            emptyText: l10n.noScoresYet,
          ),
        ),
      ],
    );
  }
}

class _LeaderboardList extends StatelessWidget {
  const _LeaderboardList({
    required this.title,
    required this.stream,
    required this.emptyText,
    this.includeBadge = false,
  });

  final String title;
  final Stream<List<Map<String, dynamic>>> stream;
  final String emptyText;
  final bool includeBadge;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: StreamBuilder<List<Map<String, dynamic>>>(
        stream: stream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Failed to load $title. Please try again.',
                textAlign: TextAlign.center,
              ),
            );
          }
          final rows = snapshot.data ?? const <Map<String, dynamic>>[];
          if (rows.isEmpty) {
            return Center(child: Text(emptyText));
          }

          return ListView.separated(
            itemCount: rows.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final row = rows[index];
              return ListTile(
                leading: CircleAvatar(child: Text('#${index + 1}')),
                title: Text(row['name']?.toString() ?? 'Unknown'),
                subtitle:
                    includeBadge
                        ? Text(
                          'Badge: ${LeaderboardService.weeklyBadgeForRank(index + 1)}',
                        )
                        : null,
                trailing: Text(row['score']?.toString() ?? '0'),
              );
            },
          );
        },
      ),
    );
  }
}
