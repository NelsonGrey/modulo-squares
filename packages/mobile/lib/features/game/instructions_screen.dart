import 'package:flutter/material.dart';
import 'package:modulo_squares/l10n/app_localizations.dart';

class InstructionsScreen extends StatelessWidget {
  const InstructionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.instructionsTitle),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Section(title: l10n.objectiveTitle, body: l10n.objectiveBody),
            const SizedBox(height: 16),
            _Section(title: l10n.controlsTitle, body: l10n.controlsBody),
            const SizedBox(height: 8),
            _ControlsVisual(),
            const SizedBox(height: 16),
            _Section(title: l10n.moduloRuleTitle, body: l10n.moduloRuleBody),
            const SizedBox(height: 8),
            Text(l10n.moduloExamplesTitle, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            _ModuloExamples(),
            const SizedBox(height: 16),
            Text(l10n.legendTitle, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            const _Legend(),
            const SizedBox(height: 16),
            Text(l10n.gridPreviewTitle, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            const _BoardPreview(),
            const SizedBox(height: 16),
            _Section(title: l10n.specialTilesTitle, body: l10n.specialTilesBody),
            const SizedBox(height: 16),
            _Section(title: l10n.levelsTitle, body: l10n.levelsBody),
            const SizedBox(height: 16),
            _Section(title: l10n.mercyTitle, body: l10n.mercyBody),
            const SizedBox(height: 16),
            _Section(title: l10n.scoringTitle, body: l10n.scoringBody),
            const SizedBox(height: 16),
            _Section(title: l10n.leaderboardTitle, body: l10n.leaderboardBody),
            const SizedBox(height: 24),
            Text(l10n.tipsTitle, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(l10n.tipsBody),
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
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textStyle = Theme.of(context).textTheme.bodyMedium;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Column(
          children: [
            const Icon(Icons.touch_app, size: 32),
            const SizedBox(height: 4),
            Text(l10n.tapLabel, style: textStyle),
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
            Text(l10n.swipeLabel, style: textStyle),
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
    final l10n = AppLocalizations.of(context);
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _LegendItem(
          color: Theme.of(context).colorScheme.secondaryContainer,
          icon: null,
          label: l10n.normalTitle,
          subtitle: l10n.normalSubtitle,
          value: '8',
        ),
        _LegendItem(
          color: Colors.black87,
          icon: Icons.block,
          label: l10n.obstacleTitle,
          subtitle: l10n.obstacleSubtitle,
        ),
        _LegendItem(
          color: Colors.greenAccent.shade700,
          icon: Icons.star,
          label: l10n.bonusTitle,
          subtitle: l10n.bonusSubtitle,
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
            Text(label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
            SizedBox(
              width: 180,
              child: Text(subtitle),
            ),
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
    // A small 4x4 preview with mixed tiles
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
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ExampleRow(
          left: const _TileBox(color: Colors.teal, value: '12'),
          right: const _TileBox(color: Colors.teal, value: '3'),
          caption: l10n.moduloExampleClearCaption,
        ),
        const SizedBox(height: 8),
        _ExampleRow(
          left: const _TileBox(color: Colors.teal, value: '12'),
          right: const _TileBox(color: Colors.teal, value: '5'),
          caption: l10n.moduloExampleTransformCaption,
        ),
      ],
    );
  }
}

class _ExampleRow extends StatelessWidget {
  final Widget left;
  final Widget right;
  final String caption;
  const _ExampleRow({required this.left, required this.right, required this.caption});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            left,
            const SizedBox(width: 8),
            const Icon(Icons.add, size: 18),
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
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
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
  factory _PreviewTile.obstacle() => const _PreviewTile(Colors.black87, icon: Icons.block);
  factory _PreviewTile.bonus(String v) => _PreviewTile(Colors.greenAccent.shade700, icon: Icons.star, value: v);
}
