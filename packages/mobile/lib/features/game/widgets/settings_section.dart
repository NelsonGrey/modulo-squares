import 'package:flutter/material.dart';

/// A collapsible Settings section: a header row that expands to reveal its
/// content, so every section is visible (even collapsed) without scrolling
/// to discover it — unlike a flat scrollable list, users can see up front
/// how many sections exist.
///
/// Shared by the settings dialog's own sections (Gameplay, Account, Legal &
/// Support) and by [PurchaseSection].
class SettingsSection extends StatelessWidget {
  const SettingsSection({
    super.key,
    required this.title,
    required this.children,
    this.initiallyExpanded = false,
  });

  final String title;
  final List<Widget> children;
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ExpansionTile(
          initiallyExpanded: initiallyExpanded,
          tilePadding: const EdgeInsets.fromLTRB(16, 0, 8, 0),
          childrenPadding: EdgeInsets.zero,
          title: Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          children: children,
        ),
        const Divider(height: 1),
      ],
    );
  }
}
