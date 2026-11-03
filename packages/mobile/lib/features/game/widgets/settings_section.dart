import 'package:flutter/material.dart';

/// A Settings section header: large and bold so each section stands out in the
/// scrolling list. Identical to the headers on the Memory Survival and
/// Intercept Echo Settings screens.
///
/// Shared by the Settings page's own sections and by [PurchaseSection].
class SettingsSectionHeader extends StatelessWidget {
  const SettingsSectionHeader(this.title, {super.key});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
        child: Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
