import 'package:flutter/material.dart';

import 'package:life_app/features/home/casual_home_dashboard.dart';

/// Legacy wrapper preserved for source compatibility.
///
/// The active implementation is [CasualHomeDashboard].
@Deprecated(
  'FigmaHomeDashboard is legacy. '
  'Use CasualHomeDashboard from lib/features/home/casual_home_dashboard.dart',
)
class FigmaHomeDashboard extends StatelessWidget {
  const FigmaHomeDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return const CasualHomeDashboard();
  }
}
