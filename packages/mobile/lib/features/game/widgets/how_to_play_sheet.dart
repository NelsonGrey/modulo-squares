import 'package:flutter/material.dart';

/// Opens the falling-mode "How to Play" bottom sheet: a scrollable, plain
/// (unthemed) reference explaining the rules in more depth than the
/// pre-game overlay's four bullet points. Matches the pattern of the other
/// top-level `showXxx(context)` helpers in this feature (see
/// `showGameSettingsDialog`).
void showHowToPlaySheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder:
        (ctx) => DraggableScrollableSheet(
          initialChildSize: 0.65,
          maxChildSize: 0.92,
          minChildSize: 0.4,
          expand: false,
          builder:
              (_, controller) => Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        controller: controller,
                        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'How to Play',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 24),
                            const _HowToSection(
                              icon: Icons.arrow_downward,
                              title: 'The Falling Number',
                              body:
                                  'Each round a number falls from the top. '
                                  'Move it left or right before the timer drops it — '
                                  'or tap Drop to send it down instantly.',
                            ),
                            const SizedBox(height: 20),
                            const _HowToSection(
                              icon: Icons.inbox_outlined,
                              title: 'The Buckets',
                              body:
                                  'Ten buckets sit at the bottom — nine labelled 1–9 '
                                  'and one red Dead bucket marked with a no-entry icon. '
                                  'Their positions are shuffled each level. Land the '
                                  'tile where the number is exactly divisible by the '
                                  'bucket value (remainder = 0).',
                            ),
                            const SizedBox(height: 20),
                            const _HowToSection(
                              icon: Icons.calculate_outlined,
                              title: 'Scoring',
                              body:
                                  'Success → earn falling number × bucket value points.\n\n'
                                  'Miss → lose falling number × bucket value × remainder points.\n\n'
                                  'Dead bucket → lose the falling number outright.\n\n'
                                  'Tip: bucket 1 always divides any number, but normally scores 0 — '
                                  'use it to avoid a big penalty when no other bucket fits. The '
                                  'exception: if no bucket 2–9 divides evenly either (like 11, 13, '
                                  'or 17), bucket 1 becomes the highest divisor and pays out the '
                                  'falling number itself instead of 0.',
                            ),
                            const SizedBox(height: 20),
                            const _HowToSection(
                              icon: Icons.star,
                              title: 'Highest-Divisor Bonus',
                              body:
                                  'Every valid bucket scores and fills — but the bucket '
                                  'holding the highest number that still evenly divides '
                                  'the falling number is the best one. Work it out '
                                  'yourself and land there for a Bonus starburst: double '
                                  'score and double fill progress. Nothing on the board '
                                  'tells you which one it is in advance.',
                            ),
                            const SizedBox(height: 20),
                            const _HowToSection(
                              icon: Icons.grid_on_outlined,
                              title: 'Level Progress',
                              body:
                                  'Each successful match fills squares in the 10×10 grid. '
                                  'Fill all 100 to complete the level. '
                                  'Missed buckets create a deficit you must clear first.',
                            ),
                            const SizedBox(height: 20),
                            const _HowToSection(
                              icon: Icons.bolt,
                              title: 'Combos & Speed',
                              body:
                                  'Chain consecutive successful drops to build a combo. '
                                  'At combo 3, 5, and 8 your move speed increases — '
                                  'making it easier to line up the tile quickly.',
                            ),
                            const SizedBox(height: 20),
                            const _HowToSection(
                              icon: Icons.speed,
                              title: 'Difficulty',
                              body:
                                  'Settings → Gameplay lets you pick Easy, Normal, or '
                                  'Hard — it controls how fast the fall timer speeds up '
                                  'as you level up. Changing it applies immediately.',
                            ),
                            const SizedBox(height: 20),
                            const _HowToSection(
                              icon: Icons.trending_up,
                              title: 'Later Levels',
                              body:
                                  'Each level raises the number range and speeds up the '
                                  'fall timer. Higher numbers mean bigger rewards — and '
                                  'bigger penalties for a miss.',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
        ),
  );
}

class _HowToSection extends StatelessWidget {
  const _HowToSection({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.lightBlue.shade50,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.blueGrey.shade700, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                body,
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 14,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
