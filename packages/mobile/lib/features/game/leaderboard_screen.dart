import 'package:flutter/material.dart';
import 'package:modulo_squares/core/services/leaderboard_service.dart';
import 'package:modulo_squares/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  static const String _weeklyTopLimitPrefKey = 'weeklyLeaderboardTopLimit';
  static const String _weeklySelectedWeekPrefKey =
      'weeklyLeaderboardSelectedWeek';
  late final List<int> _recentWeeks;
  late int _selectedWeekId;
  int _selectedTopLimit = 25;

  @override
  void initState() {
    super.initState();
    _recentWeeks = LeaderboardService.recentWeekIds(count: 8);
    _selectedWeekId =
        _recentWeeks.contains(widget.weekId)
            ? widget.weekId
            : _recentWeeks.first;
    _restoreSelectedWeekId();
    _restoreWeeklyTopLimit();
  }

  Future<void> _restoreSelectedWeekId() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getInt(_weeklySelectedWeekPrefKey);
    if (!mounted || saved == null) return;
    if (!_recentWeeks.contains(saved)) return;

    setState(() {
      _selectedWeekId = saved;
    });
  }

  Future<void> _persistSelectedWeekId(int weekId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_weeklySelectedWeekPrefKey, weekId);
  }

  Future<void> _restoreWeeklyTopLimit() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getInt(_weeklyTopLimitPrefKey);
    if (!mounted || saved == null) return;
    if (![10, 25, 50].contains(saved)) return;

    setState(() {
      _selectedTopLimit = saved;
    });
  }

  Future<void> _persistWeeklyTopLimit(int limit) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_weeklyTopLimitPrefKey, limit);
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
                      _persistSelectedWeekId(value);
                    },
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Leaderboard Depth',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children:
                        [10, 25, 50].map((limit) {
                          return ChoiceChip(
                            label: Text('Top $limit'),
                            selected: _selectedTopLimit == limit,
                            onSelected: (selected) {
                              if (!selected) return;
                              setState(() {
                                _selectedTopLimit = limit;
                              });
                              _persistWeeklyTopLimit(limit);
                            },
                          );
                        }).toList(),
                  ),
                  const SizedBox(height: 6),
                  FutureBuilder<({int weekId, int rank, String badge})?>(
                    future: LeaderboardService.getBestWeeklySeasonSnapshot(
                      playerName: widget.playerName,
                      weekIds: _recentWeeks,
                    ),
                    builder: (context, snapshot) {
                      final titleStyle = Theme.of(context).textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w700);
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Row(
                          children: [
                            Text('Season Summary', style: titleStyle),
                            const SizedBox(width: 8),
                            const SizedBox(
                              height: 14,
                              width: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ],
                        );
                      }
                      if (snapshot.hasError || snapshot.data == null) {
                        return const Text(
                          'Season Summary: No rank in recent weeks yet.',
                        );
                      }

                      final best = snapshot.data!;
                      return Text(
                        'Season Summary: Best #${best.rank} (${best.badge}) in week ${best.weekId}',
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  const _TrendLegendRow(),
                  const SizedBox(height: 8),
                  FutureBuilder<
                    List<
                      ({
                        int weekId,
                        int? rank,
                        String? badge,
                        String trend,
                        int? delta,
                      })
                    >
                  >(
                    future: LeaderboardService.getWeeklySeasonProgressWithTrend(
                      playerName: widget.playerName,
                      weekIds: _recentWeeks,
                    ),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Text('Recent Weeks: Loading...');
                      }

                      final progress = snapshot.data ?? const [];
                      if (progress.isEmpty) {
                        return const Text('Recent Weeks: No data yet.');
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Recent Weeks Trend',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 6),
                          ...progress.map((item) {
                            final trendIcon = switch (item.trend) {
                              'improving' => Icons.trending_up,
                              'stable' => Icons.trending_flat,
                              'declining' => Icons.trending_down,
                              _ => Icons.remove,
                            };
                            final trendColor = switch (item.trend) {
                              'improving' => Colors.green,
                              'stable' => Colors.amber,
                              'declining' => Colors.red,
                              _ => Colors.grey,
                            };

                            if (item.rank == null) {
                              return Row(
                                children: [
                                  Icon(trendIcon, size: 16, color: trendColor),
                                  const SizedBox(width: 6),
                                  Text('Week ${item.weekId}: No rank'),
                                ],
                              );
                            }

                            String deltaText = '';
                            final d = item.delta;
                            if (d != null && d != 0) {
                              if (d > 0) {
                                deltaText = ' (+$d better)';
                              } else {
                                deltaText = ' (${d.abs()} worse)';
                              }
                            }

                            return Row(
                              children: [
                                Icon(trendIcon, size: 16, color: trendColor),
                                const SizedBox(width: 6),
                                Text(
                                  'Week ${item.weekId}: #${item.rank} (${item.badge})$deltaText',
                                ),
                              ],
                            );
                          }),
                        ],
                      );
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
            stream: LeaderboardService.getTopWeeklyScores(
              _selectedWeekId,
              _selectedTopLimit,
            ),
            emptyText: l10n.noScoresYet,
            includeBadge: true,
          ),
        ),
      ],
    );
  }
}

class _TrendLegendRow extends StatelessWidget {
  const _TrendLegendRow();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: const [
        _TrendLegendChip(
          icon: Icons.trending_up,
          color: Colors.green,
          label: 'Improving',
        ),
        _TrendLegendChip(
          icon: Icons.trending_flat,
          color: Colors.amber,
          label: 'Stable',
        ),
        _TrendLegendChip(
          icon: Icons.trending_down,
          color: Colors.red,
          label: 'Declining',
        ),
      ],
    );
  }
}

class _TrendLegendChip extends StatelessWidget {
  const _TrendLegendChip({
    required this.icon,
    required this.color,
    required this.label,
  });

  final IconData icon;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      labelPadding: const EdgeInsets.symmetric(horizontal: 4),
      visualDensity: VisualDensity.compact,
      avatar: Icon(icon, size: 14, color: color),
      label: Text(label, style: const TextStyle(fontSize: 12)),
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
