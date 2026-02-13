import 'package:flutter/material.dart';

import 'package:life_app/features/home/casual_home_dashboard.dart';

/// Legacy wrapper preserved for source compatibility.
///
/// The active implementation is [CasualHomeDashboard].
@Deprecated(
  'ImprovedHomeDashboard is legacy. '
  'Use CasualHomeDashboard from lib/features/home/casual_home_dashboard.dart',
)
class ImprovedHomeDashboard extends StatelessWidget {
  const ImprovedHomeDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return const CasualHomeDashboard();
  }
}
