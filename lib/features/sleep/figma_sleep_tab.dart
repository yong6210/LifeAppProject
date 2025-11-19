import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:life_app/design/app_theme.dart';
import 'package:life_app/models/session.dart';
import 'package:life_app/providers/session_providers.dart';
import 'package:life_app/providers/settings_providers.dart';
import 'package:life_app/services/analytics/analytics_service.dart';
import 'package:life_app/widgets/glass_card.dart';

/// Sound preset configuration matching Figma design
class SoundPreset {
  const SoundPreset({
    required this.id,
    required this.name,
    required this.emoji,
    required this.description,
  });

  final String id;
  final String name;
  final String emoji;
  final String description;
}

/// Figma-styled sleep tab with cosmic dreams design
class FigmaSleepTab extends ConsumerStatefulWidget {
  const FigmaSleepTab({super.key});

  @override
  ConsumerState<FigmaSleepTab> createState() => _FigmaSleepTabState();
}

class _FigmaSleepTabState extends ConsumerState<FigmaSleepTab>
    with TickerProviderStateMixin {
  static const soundPresets = [
    SoundPreset(
      id: 'rain',
      name: 'Rain',
      emoji: '🌧️',
      description: 'Gentle rainfall',
    ),
    SoundPreset(
      id: 'ocean',
      name: 'Ocean',
      emoji: '🌊',
      description: 'Peaceful waves',
    ),
    SoundPreset(
      id: 'wind',
      name: 'Wind',
      emoji: '🍃',
      description: 'Soft breeze',
    ),
    SoundPreset(
      id: 'cosmic',
      name: 'Cosmic',
      emoji: '✨',
      description: 'Space ambience',
    ),
  ];

  SoundPreset _selectedSound = soundPresets[0];
  double _volume = 60;
  bool _isPlaying = false;
  int _duration = 30; // minutes

  late List<AnimationController> _starControllers;
  late List<Animation<double>> _starAnimations;
  late AnimationController _glowController;

  @override
  void initState() {
    super.initState();

    // Create star animations
    _starControllers = List.generate(
      20,
      (index) => AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 1000 + (index * 100)),
      )..repeat(reverse: true),
    );

    _starAnimations = _starControllers.map((controller) {
      return Tween<double>(begin: 0.3, end: 1.0).animate(controller);
    }).toList();

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    for (var controller in _starControllers) {
      controller.dispose();
    }
    _glowController.dispose();
    super.dispose();
  }

  void _handleStartSleep() {
    setState(() {
      _isPlaying = !_isPlaying;
    });

    if (_isPlaying) {
      AnalyticsService.logEvent('figma_sleep_start', {
        'sound': _selectedSound.name,
        'duration': _duration,
        'volume': _volume,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🌙 Sleep mode activated - Drift into peaceful dreams with ${_selectedSound.name}'),
          backgroundColor: AppTheme.electricViolet,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _handleLogSleep() async {
    AnalyticsService.logEvent('figma_sleep_log', {
      'sound': _selectedSound.name,
      'duration': _duration,
    });

    // Get session repository and settings
    final repo = ref.read(sessionRepoProvider);
    final settings = await ref.read(settingsFutureProvider.future);

    if (repo == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Database not ready. Please try again.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Create and save sleep session
    final now = DateTime.now().toUtc();
    final session = Session()
      ..type = 'sleep'
      ..startedAt = now
      ..endedAt = now.add(Duration(minutes: _duration))
      ..deviceId = settings.deviceId
      ..tags = [_selectedSound.name, 'figma-sleep']
      ..note = '${_selectedSound.emoji} ${_selectedSound.name} - ${_duration}min';

    try {
      await repo.add(session);

      setState(() {
        _isPlaying = false;
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('💤 Rest logged! Sweet dreams! Recovery is progress.'),
          backgroundColor: AppTheme.electricViolet,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving sleep: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Get today's sleep minutes from actual database
    final todaySummaryAsync = ref.watch(todaySummaryProvider);
    final todaySleepMinutes = todaySummaryAsync.maybeWhen(
      data: (summary) => summary.sleep,
      orElse: () => 0,
    );

    final sleepHours = todaySleepMinutes ~/ 60;
    final sleepMins = todaySleepMinutes % 60;
    final sleepPercent = (todaySleepMinutes / 480 * 100).clamp(0, 100);
    final random = math.Random(42); // Seeded for consistent star positions

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [
                    const Color(0xFF1a0f2e),
                    const Color(0xFF0f0a1a),
                    const Color(0xFF0a0510),
                  ]
                : [
                    const Color(0xFFF5E8FF),
                    const Color(0xFFEED8FF),
                    const Color(0xFFFFFFFF),
                  ],
          ),
        ),
        child: Stack(
          children: [
            // Animated background blobs
            Positioned(
              top: MediaQuery.of(context).size.height * 0.25,
              left: MediaQuery.of(context).size.width * 0.25,
              child: AnimatedBuilder(
                animation: _glowController,
                builder: (context, child) {
                  return Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppTheme.electricViolet.withOpacity(0.2 + _glowController.value * 0.15),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Positioned(
              bottom: MediaQuery.of(context).size.height * 0.25,
              right: MediaQuery.of(context).size.width * 0.25,
              child: AnimatedBuilder(
                animation: _glowController,
                builder: (context, child) {
                  return Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Colors.pink.withOpacity(0.2 + (1 - _glowController.value) * 0.15),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            // Animated stars
            ...List.generate(20, (index) {
              final top = random.nextDouble() * MediaQuery.of(context).size.height;
              final left = random.nextDouble() * MediaQuery.of(context).size.width;
              return Positioned(
                top: top,
                left: left,
                child: AnimatedBuilder(
                  animation: _starAnimations[index],
                  builder: (context, child) {
                    return Container(
                      width: 3,
                      height: 3,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(_starAnimations[index].value * 0.7),
                        shape: BoxShape.circle,
                      ),
                    );
                  },
                ),
              );
            }),
            // Content
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Back button
                    Row(
                      children: [
                        GlassCard(
                          onTap: () => Navigator.of(context).pop(),
                          padding: const EdgeInsets.all(12),
                          borderRadius: 12,
                          child: Icon(
                            Icons.arrow_back_ios_new,
                            size: 20,
                            color: isDark ? Colors.white : AppTheme.electricViolet,
                          ),
                        ),
                        const Spacer(),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Header badge
                    GlassCard(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      margin: const EdgeInsets.only(bottom: 16),
                      borderRadius: 20,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.nightlight_round,
                            size: 18,
                            color: AppTheme.electricViolet,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Cosmic Dreams',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : AppTheme.electricViolet,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.auto_awesome,
                            size: 14,
                            color: Colors.pink,
                          ),
                        ],
                      ),
                    ),
                    // Title
                    ShaderMask(
                      shaderCallback: (bounds) => LinearGradient(
                        colors: [
                          AppTheme.electricViolet,
                          Colors.pink,
                        ],
                      ).createShader(bounds),
                      child: Text(
                        'Rest & Recharge',
                        style: theme.textTheme.headlineLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Journey to the stars ✨',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: isDark
                            ? AppTheme.electricViolet.withOpacity(0.8)
                            : AppTheme.electricViolet,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Dream Bank card
                    GlassCard(
                      padding: const EdgeInsets.all(24),
                      borderRadius: 24,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isDark
                            ? [
                                AppTheme.electricViolet.withOpacity(0.2),
                                Colors.pink.withOpacity(0.15),
                              ]
                            : [
                                AppTheme.electricViolet.withOpacity(0.12),
                                Colors.pink.withOpacity(0.08),
                              ],
                      ),
                      shadowColor: AppTheme.electricViolet,
                      shadowOpacity: 0.25,
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Text(
                                sleepPercent >= 100 ? '🌟' : '🌙',
                                style: const TextStyle(fontSize: 40),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Dream Bank',
                                      style: theme.textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: isDark ? Colors.white : theme.colorScheme.onSurface,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${sleepHours}h ${sleepMins}m / 8h',
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        color: isDark
                                            ? AppTheme.electricViolet.withOpacity(0.8)
                                            : AppTheme.electricViolet,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '${sleepPercent.round()}%',
                                style: theme.textTheme.displaySmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.electricViolet,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Progress bar
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Stack(
                              children: [
                                Container(
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? Colors.white.withOpacity(0.1)
                                        : AppTheme.electricViolet.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                FractionallySizedBox(
                                  widthFactor: sleepPercent / 100,
                                  child: Container(
                                    height: 16,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          AppTheme.electricViolet,
                                          Colors.pink,
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Duration selector
                    GlassCard(
                      padding: const EdgeInsets.all(20),
                      borderRadius: 20,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.nightlight_round,
                                size: 18,
                                color: isDark ? Colors.white : AppTheme.electricViolet,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Dream Duration',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? Colors.white : theme.colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [10, 20, 30, 60].map((mins) {
                              final isSelected = _duration == mins;
                              return Expanded(
                                child: Padding(
                                  padding: EdgeInsets.only(
                                    right: mins != 60 ? 8 : 0,
                                  ),
                                  child: Container(
                                    height: 48,
                                    decoration: BoxDecoration(
                                      gradient: isSelected
                                          ? LinearGradient(
                                              colors: [
                                                AppTheme.electricViolet,
                                                Colors.pink,
                                              ],
                                            )
                                          : null,
                                      color: !isSelected
                                          ? isDark
                                              ? Colors.white.withOpacity(0.1)
                                              : Colors.white.withOpacity(0.7)
                                          : null,
                                      borderRadius: BorderRadius.circular(12),
                                      border: !isSelected
                                          ? Border.all(
                                              color: AppTheme.electricViolet.withOpacity(0.3),
                                              width: 2,
                                            )
                                          : null,
                                      boxShadow: isSelected
                                          ? [
                                              BoxShadow(
                                                color: AppTheme.electricViolet.withOpacity(0.4),
                                                blurRadius: 12,
                                                offset: const Offset(0, 4),
                                              ),
                                            ]
                                          : null,
                                    ),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: () => setState(() => _duration = mins),
                                        borderRadius: BorderRadius.circular(12),
                                        child: Center(
                                          child: Text(
                                            '${mins}m',
                                            style: theme.textTheme.titleSmall?.copyWith(
                                              fontWeight: FontWeight.w700,
                                              color: isSelected
                                                  ? Colors.white
                                                  : isDark
                                                      ? AppTheme.electricViolet
                                                      : AppTheme.electricViolet,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Sound selection
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Row(
                            children: [
                              Icon(
                                Icons.volume_up,
                                size: 18,
                                color: isDark ? Colors.white : AppTheme.electricViolet,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Ambient Sounds',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? Colors.white : theme.colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 1.3,
                          ),
                          itemCount: soundPresets.length,
                          itemBuilder: (context, index) {
                            final sound = soundPresets[index];
                            final isSelected = _selectedSound.id == sound.id;
                            return GlassCard(
                              onTap: () => setState(() => _selectedSound = sound),
                              padding: const EdgeInsets.all(20),
                              borderRadius: 20,
                              gradient: isSelected
                                  ? LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: isDark
                                          ? [
                                              AppTheme.electricViolet.withOpacity(0.3),
                                              Colors.pink.withOpacity(0.2),
                                            ]
                                          : [
                                              AppTheme.electricViolet.withOpacity(0.15),
                                              Colors.pink.withOpacity(0.1),
                                            ],
                                    )
                                  : null,
                              shadowColor: isSelected ? AppTheme.electricViolet : null,
                              shadowOpacity: isSelected ? 0.3 : 0.2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    sound.emoji,
                                    style: const TextStyle(fontSize: 32),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    sound.name,
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? Colors.white : theme.colorScheme.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    sound.description,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: isDark
                                          ? AppTheme.electricViolet.withOpacity(0.8)
                                          : AppTheme.electricViolet,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Volume control
                    GlassCard(
                      padding: const EdgeInsets.all(20),
                      borderRadius: 20,
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.volume_up,
                                    size: 18,
                                    color: isDark ? Colors.white : AppTheme.electricViolet,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Volume',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? Colors.white : theme.colorScheme.onSurface,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                '${_volume.round()}%',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.electricViolet,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SliderTheme(
                            data: SliderThemeData(
                              activeTrackColor: AppTheme.electricViolet,
                              inactiveTrackColor: isDark
                                  ? Colors.white.withOpacity(0.1)
                                  : AppTheme.electricViolet.withOpacity(0.2),
                              thumbColor: AppTheme.electricViolet,
                              overlayColor: AppTheme.electricViolet.withOpacity(0.2),
                              trackHeight: 6,
                            ),
                            child: Slider(
                              value: _volume,
                              onChanged: (value) => setState(() => _volume = value),
                              min: 0,
                              max: 100,
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Whisper',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: isDark
                                      ? AppTheme.electricViolet.withOpacity(0.6)
                                      : AppTheme.electricViolet,
                                  fontSize: 11,
                                ),
                              ),
                              Text(
                                'Perfect',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: isDark
                                      ? AppTheme.electricViolet.withOpacity(0.6)
                                      : AppTheme.electricViolet,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Action buttons
                    Container(
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: _isPlaying
                            ? LinearGradient(
                                colors: [
                                  Colors.grey.shade600,
                                  Colors.grey.shade700,
                                ],
                              )
                            : LinearGradient(
                                colors: [
                                  AppTheme.electricViolet,
                                  Colors.pink,
                                ],
                              ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: (_isPlaying ? Colors.grey : AppTheme.electricViolet)
                                .withOpacity(0.4),
                            blurRadius: 16,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _handleStartSleep,
                          borderRadius: BorderRadius.circular(16),
                          child: Center(
                            child: Text(
                              _isPlaying ? 'Stop Session' : 'Begin Dream Journey',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 18,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (_isPlaying) ...[
                      const SizedBox(height: 12),
                      GlassCard(
                        onTap: _handleLogSleep,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        borderRadius: 12,
                        child: Center(
                          child: Text(
                            'Log Sleep Now',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: AppTheme.electricViolet,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    // Sleep wisdom
                    GlassCard(
                      padding: const EdgeInsets.all(20),
                      borderRadius: 20,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '🌟',
                                style: TextStyle(fontSize: 32),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Sleep Science',
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: isDark ? Colors.white : theme.colorScheme.onSurface,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Quality sleep is when your body repairs muscles, consolidates memories, and balances hormones. The cosmic sounds help your brain enter deeper sleep stages naturally. ✨',
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        color: isDark
                                            ? Colors.white.withOpacity(0.7)
                                            : theme.colorScheme.onSurfaceVariant,
                                        height: 1.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ...['🌙 Cool, dark room = better sleep', '✨ No screens 1 hour before bed', '🌟 Consistent sleep schedule helps'].map((tip) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text(
                                tip,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: isDark
                                      ? AppTheme.electricViolet.withOpacity(0.8)
                                      : AppTheme.electricViolet,
                                  fontSize: 11,
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
