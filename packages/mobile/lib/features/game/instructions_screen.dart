import 'package:flutter/material.dart';

class InstructionsScreen extends StatelessWidget {
  const InstructionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('How to Play')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _Section(
              title: 'Objective',
              body:
                  'Clear the board by combining tiles using modulo collisions before you run out of moves.',
            ),
            const SizedBox(height: 16),
            const _Section(
              title: 'Controls',
              body:
                  'Tap a tile then tap an adjacent target to move. You can also swipe to slide until blocked by a tile, obstacle, or boundary.',
            ),
            const SizedBox(height: 8),
            _ControlsVisual(),
            const SizedBox(height: 16),
            const _Section(
              title: 'Modulo Rule',
              body:
                  'A move can collide only when the moving tile value is less than or equal to the target value. The result is target % source. If remainder is 0, the target clears.',
            ),
            const SizedBox(height: 8),
            Text('Examples', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            _ModuloExamples(),
            const SizedBox(height: 16),
            Text('Legend', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            const _Legend(),
            const SizedBox(height: 16),
            Text(
              'Grid Preview',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const _BoardPreview(),
            const SizedBox(height: 16),
            const _Section(
              title: 'Special Tiles',
              body:
                  'Obstacle tiles block movement. Bonus tiles grant extra score when used in a collision.',
            ),
            const SizedBox(height: 16),
            const _Section(
              title: 'Levels',
              body:
                  'Standard mode increases grid size by level: Level 1 is 2x2, Level 2 is 3x3, Level 3 is 4x4, and so on. Boards start filled. Daily mode gives one shared 4x4 puzzle per day.',
            ),
            const SizedBox(height: 16),
            const _Section(
              title: 'Mercy Spawn',
              body:
                  'If one tile remains and moves are left, a helper tile can spawn with a score penalty.',
            ),
            const SizedBox(height: 16),
            const _Section(
              title: 'Scoring',
              body:
                  'You gain points from valid moves and collisions. Bonus tiles award extra points.',
            ),
            const SizedBox(height: 16),
            const _Section(
              title: 'Leaderboard',
              body:
                  'Submit high scores in standard mode and daily mode to compete with other players.',
            ),
            const SizedBox(height: 24),
            Text('Tips', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            const Text(
              'Plan 2-3 moves ahead, preserve flexible low-value tiles, and avoid dead-end corners.',
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final String body;
  const _Section({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Text(body),
      ],
    );
  }
}

class _ControlsVisual extends StatelessWidget {
  const _ControlsVisual();

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.bodyMedium;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Column(
          children: [
            const Icon(Icons.touch_app, size: 32),
            const SizedBox(height: 4),
            Text('Tap', style: textStyle),
          ],
        ),
        Column(
          children: [
            Row(
              children: const [
                Icon(Icons.arrow_back),
                SizedBox(width: 4),
                Icon(Icons.arrow_upward),
                SizedBox(width: 4),
                Icon(Icons.arrow_downward),
                SizedBox(width: 4),
                Icon(Icons.arrow_forward),
              ],
            ),
            const SizedBox(height: 4),
            Text('Swipe', style: textStyle),
          ],
        ),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();
  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _LegendItem(
          color: Theme.of(context).colorScheme.secondaryContainer,
          icon: null,
          label: 'Normal Tile',
          subtitle: 'Standard numbered tile.',
          value: '8',
        ),
        _LegendItem(
          color: Colors.black87,
          icon: Icons.block,
          label: 'Obstacle Tile',
          subtitle: 'Blocks movement and cannot be entered.',
        ),
        _LegendItem(
          color: Colors.greenAccent.shade700,
          icon: Icons.star,
          label: 'Bonus Tile',
          subtitle: 'Collision grants bonus points.',
          value: '5',
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final IconData? icon;
  final String label;
  final String subtitle;
  final String? value;
  const _LegendItem({
    required this.color,
    required this.label,
    required this.subtitle,
    this.icon,
    this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _TileBox(color: color, icon: icon, value: value),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            SizedBox(width: 180, child: Text(subtitle)),
          ],
        ),
      ],
    );
  }
}

class _BoardPreview extends StatelessWidget {
  const _BoardPreview();
  @override
  Widget build(BuildContext context) {
    // A small 4x4 filled preview with mixed tiles
    final tiles = <_PreviewTile>[
      _PreviewTile.normal('12'),
      _PreviewTile.normal('3'),
      _PreviewTile.obstacle(),
      _PreviewTile.bonus('4'),
      _PreviewTile.normal('5'),
      _PreviewTile.normal('7'),
      _PreviewTile.normal('9'),
      _PreviewTile.normal('2'),
      _PreviewTile.normal('6'),
      _PreviewTile.bonus('3'),
      _PreviewTile.normal('8'),
      _PreviewTile.obstacle(),
      _PreviewTile.normal('10'),
      _PreviewTile.normal('11'),
      _PreviewTile.normal('1'),
      _PreviewTile.normal('4'),
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 1,
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
      ),
      itemCount: tiles.length,
      itemBuilder: (context, index) {
        final t = tiles[index];
        return _TileBox(color: t.color, icon: t.icon, value: t.value);
      },
    );
  }
}

class _ModuloExamples extends StatelessWidget {
  const _ModuloExamples();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ExampleRow(
          left: const _TileBox(color: Colors.teal, value: '3'),
          right: const _TileBox(color: Colors.teal, value: '12'),
          caption: 'Move 3 into 12: 12 % 3 = 0, so the target clears.',
        ),
        const SizedBox(height: 8),
        _ExampleRow(
          left: const _TileBox(color: Colors.teal, value: '5'),
          right: const _TileBox(color: Colors.teal, value: '12'),
          caption: 'Move 5 into 12: 12 % 5 = 2, so the target becomes 2.',
        ),
      ],
    );
  }
}

class _ExampleRow extends StatelessWidget {
  final Widget left;
  final Widget right;
  final String caption;
  const _ExampleRow({
    required this.left,
    required this.right,
    required this.caption,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            left,
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward, size: 18),
            const SizedBox(width: 8),
            right,
          ],
        ),
        const SizedBox(height: 4),
        Text(caption),
      ],
    );
  }
}

class _TileBox extends StatelessWidget {
  final Color color;
  final IconData? icon;
  final String? value;
  const _TileBox({required this.color, this.icon, this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (value != null)
            Text(
              value!,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          if (icon != null)
            Positioned(
              right: 4,
              bottom: 4,
              child: Icon(icon, size: 14, color: Colors.black87),
            ),
        ],
      ),
    );
  }
}

class _PreviewTile {
  final Color color;
  final IconData? icon;
  final String? value;
  const _PreviewTile(this.color, {this.icon, this.value});
  factory _PreviewTile.normal(String v) => _PreviewTile(Colors.teal, value: v);
  factory _PreviewTile.obstacle() =>
      const _PreviewTile(Colors.black87, icon: Icons.block);
  factory _PreviewTile.bonus(String v) =>
      _PreviewTile(Colors.greenAccent.shade700, icon: Icons.star, value: v);
}
