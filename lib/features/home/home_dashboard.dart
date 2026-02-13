import 'package:flutter/material.dart';

import 'package:life_app/features/home/casual_home_dashboard.dart';

/// Compatibility wrapper.
///
/// Use [CasualHomeDashboard] directly for new code.
@Deprecated(
  'HomeDashboardTab is a compatibility wrapper. '
  'Use CasualHomeDashboard from lib/features/home/casual_home_dashboard.dart',
)
class HomeDashboardTab extends StatelessWidget {
  const HomeDashboardTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const CasualHomeDashboard();
  }
}
