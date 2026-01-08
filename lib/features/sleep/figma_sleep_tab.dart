import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
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
///
/// Features:
/// - iOS-style time picker with CupertinoPicker for hours and minutes
/// - 12-hour format with AM/PM selection
/// - Dual mode: duration-based or target time-based sleep scheduling
/// - Automatic hour adjustment when scrolling through minute boundaries
/// - AM/PM auto-toggle when crossing 11h↔12h boundary
/// - Tap-to-edit functionality for direct time input
/// - Looping dials for continuous scrolling
/// - Background sound selection with modal bottom sheet
/// - Minute-based time calculation (excludes seconds for accuracy)
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
  int _duration = 0; // minutes - start from 0
  bool _useTargetTime = false; // false = duration mode, true = target time mode
  TimeOfDay? _targetTime;
  bool _isAM = true; // for 12-hour format
  int _previousMinute = 0; // for detecting minute boundary crossing

  // Picker controllers for duration
  late FixedExtentScrollController _durationHourController;
  late FixedExtentScrollController _durationMinuteController;
  // Picker controllers for target time (12-hour format)
  late FixedExtentScrollController _targetHourController;
  late FixedExtentScrollController _targetMinuteController;
  late FixedExtentScrollController _amPmController;

  late List<AnimationController> _starControllers;
  late List<Animation<double>> _starAnimations;
  late AnimationController _glowController;

  @override
  void initState() {
    super.initState();

    // Initialize picker controllers
    final durationHours = _duration ~/ 60;
    final durationMinutes = _duration % 60;
    _durationHourController = FixedExtentScrollController(initialItem: durationHours);
    _durationMinuteController = FixedExtentScrollController(initialItem: durationMinutes ~/ 5);

    // Set target time to current time
    final now = TimeOfDay.now();
    _targetTime = now;

    // Convert to 12-hour format
    int hour12 = now.hour % 12;
    if (hour12 == 0) hour12 = 12; // 0시 → 12시
    _isAM = now.hour < 12;

    _targetHourController = FixedExtentScrollController(initialItem: hour12 - 1); // 1-12 → 0-11
    _targetMinuteController = FixedExtentScrollController(initialItem: now.minute);
    _amPmController = FixedExtentScrollController(initialItem: _isAM ? 0 : 1);
    _previousMinute = now.minute; // Initialize previous minute

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
    _durationHourController.dispose();
    _durationMinuteController.dispose();
    _targetHourController.dispose();
    _targetMinuteController.dispose();
    _amPmController.dispose();
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
    // Calculate actual duration based on mode
    int actualDuration;
    String note;

    if (_useTargetTime && _targetTime != null) {
      // Calculate duration until target time
      final now = DateTime.now();
      var target = DateTime(
        now.year,
        now.month,
        now.day,
        _targetTime!.hour,
        _targetTime!.minute,
      );

      if (target.isBefore(now)) {
        target = target.add(const Duration(days: 1));
      }

      actualDuration = target.difference(now).inMinutes;
      note = '${_selectedSound.emoji} ${_selectedSound.name} - ${_targetTime!.format(context)}까지';
    } else {
      actualDuration = _duration;
      note = '${_selectedSound.emoji} ${_selectedSound.name} - ${_duration}min';
    }

    AnalyticsService.logEvent('figma_sleep_log', {
      'sound': _selectedSound.name,
      'duration': actualDuration,
      'mode': _useTargetTime ? 'target_time' : 'duration',
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
      ..endedAt = now.add(Duration(minutes: actualDuration))
      ..deviceId = settings.deviceId
      ..tags = [_selectedSound.name, 'figma-sleep']
      ..note = note;

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

  /// Calculates time remaining until target wake-up time
  ///
  /// Uses minute-based calculation (excludes seconds) to prevent
  /// "23시간 59분" display issues when setting current time as target.
  /// If target is in the past or equal to current time, assumes next day.
  String _getTimeUntilTarget() {
    if (_targetTime == null) return '';

    final now = DateTime.now();
    // 초 단위를 0으로 설정하여 분 단위로만 계산
    final currentTime = DateTime(now.year, now.month, now.day, now.hour, now.minute);
    var target = DateTime(
      currentTime.year,
      currentTime.month,
      currentTime.day,
      _targetTime!.hour,
      _targetTime!.minute,
    );

    // If target time is earlier than now, it means tomorrow
    if (target.isBefore(currentTime) || target == currentTime) {
      target = target.add(const Duration(days: 1));
    }

    final difference = target.difference(currentTime);
    final hours = difference.inHours;
    final minutes = difference.inMinutes % 60;

    // 24시간 0분인 경우 0분으로 표시
    if (hours == 24 && minutes == 0) {
      return '0분 남음';
    } else if (hours > 0) {
      return '$hours시간 $minutes분 남음';
    } else {
      return '$minutes분 남음';
    }
  }

  Future<void> _showDirectInputDialog({
    required BuildContext context,
    required String title,
    required String hintText,
    required int maxValue,
    required int currentValue,
    required ValueChanged<int> onSubmit,
  }) async {
    final controller = TextEditingController(text: currentValue.toString());
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: hintText,
            border: const OutlineInputBorder(),
          ),
          autofocus: true,
          onSubmitted: (value) {
            final num = int.tryParse(value);
            if (num != null && num >= 0 && num <= maxValue) {
              onSubmit(num);
              Navigator.pop(context);
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () {
              final num = int.tryParse(controller.text);
              if (num != null && num >= 0 && num <= maxValue) {
                onSubmit(num);
                Navigator.pop(context);
              }
            },
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  void _showSoundSelectionModal(BuildContext context, ThemeData theme, bool isDark) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [
                    const Color(0xFF1a0f2e),
                    const Color(0xFF0f0a1a),
                  ]
                : [
                    const Color(0xFFF5E8FF),
                    const Color(0xFFFFFFFF),
                  ],
          ),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.volume_up,
                      color: isDark ? Colors.white : AppTheme.electricViolet,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Select Ambient Sound',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ...soundPresets.map((sound) {
                  final isSelected = _selectedSound.id == sound.id;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: GlassCard(
                      onTap: () {
                        setState(() => _selectedSound = sound);
                        Navigator.pop(context);
                      },
                      padding: const EdgeInsets.all(20),
                      borderRadius: 20,
                      gradient: isSelected
                          ? LinearGradient(
                              colors: [
                                AppTheme.electricViolet.withValues(alpha: 0.3),
                                Colors.pink.withValues(alpha: 0.2),
                              ],
                            )
                          : null,
                      child: Row(
                        children: [
                          Text(
                            sound.emoji,
                            style: const TextStyle(fontSize: 32),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
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
                                        ? Colors.white.withValues(alpha: 0.7)
                                        : theme.colorScheme.onSurface.withValues(alpha: 0.7),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            Icon(
                              Icons.check_circle,
                              color: AppTheme.electricViolet,
                            ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
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
                          AppTheme.electricViolet.withValues(alpha: 0.2 + _glowController.value * 0.15),
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
                          Colors.pink.withValues(alpha: 0.2 + (1 - _glowController.value) * 0.15),
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
                        color: Colors.white.withValues(alpha: _starAnimations[index].value * 0.7),
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
                            ? AppTheme.electricViolet.withValues(alpha: 0.8)
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
                                AppTheme.electricViolet.withValues(alpha: 0.2),
                                Colors.pink.withValues(alpha: 0.15),
                              ]
                            : [
                                AppTheme.electricViolet.withValues(alpha: 0.12),
                                Colors.pink.withValues(alpha: 0.08),
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
                                            ? AppTheme.electricViolet.withValues(alpha: 0.8)
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
                                        ? Colors.white.withValues(alpha: 0.1)
                                        : AppTheme.electricViolet.withValues(alpha: 0.15),
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
                    // Duration selector with dial
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
                          const SizedBox(height: 20),
                          // Mode toggle (Duration vs Target Time)
                          Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => setState(() => _useTargetTime = false),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    decoration: BoxDecoration(
                                      gradient: !_useTargetTime
                                          ? LinearGradient(
                                              colors: [
                                                AppTheme.electricViolet,
                                                Colors.pink,
                                              ],
                                            )
                                          : null,
                                      color: _useTargetTime
                                          ? isDark
                                              ? Colors.white.withValues(alpha: 0.1)
                                              : Colors.white.withValues(alpha: 0.5)
                                          : null,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '지속시간',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: !_useTargetTime ? Colors.white : AppTheme.electricViolet,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => setState(() => _useTargetTime = true),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    decoration: BoxDecoration(
                                      gradient: _useTargetTime
                                          ? LinearGradient(
                                              colors: [
                                                AppTheme.electricViolet,
                                                Colors.pink,
                                              ],
                                            )
                                          : null,
                                      color: !_useTargetTime
                                          ? isDark
                                              ? Colors.white.withValues(alpha: 0.1)
                                              : Colors.white.withValues(alpha: 0.5)
                                          : null,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '목표시간',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: _useTargetTime ? Colors.white : AppTheme.electricViolet,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          // Duration dial or target time picker
                          if (!_useTargetTime) ...[
                            // iOS-style scrollable picker for duration
                            Container(
                              height: 200,
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // Hour picker
                                  Expanded(
                                    child: Column(
                                      children: [
                                        GestureDetector(
                                          onTap: () => _showDirectInputDialog(
                                            context: context,
                                            title: '시간 입력',
                                            hintText: '0-24',
                                            maxValue: 24,
                                            currentValue: _duration ~/ 60,
                                            onSubmit: (value) {
                                              setState(() {
                                                final minutes = _duration % 60;
                                                _duration = (value * 60) + minutes;
                                                _durationHourController.jumpToItem(value);
                                              });
                                            },
                                          ),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                '시간',
                                                style: theme.textTheme.bodySmall?.copyWith(
                                                  color: isDark
                                                      ? Colors.white.withValues(alpha: 0.5)
                                                      : AppTheme.electricViolet.withValues(alpha: 0.5),
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              Icon(
                                                Icons.edit,
                                                size: 12,
                                                color: isDark
                                                    ? Colors.white.withValues(alpha: 0.3)
                                                    : AppTheme.electricViolet.withValues(alpha: 0.3),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Expanded(
                                          child: CupertinoPicker(
                                            scrollController: _durationHourController,
                                            itemExtent: 50,
                                            onSelectedItemChanged: (index) {
                                              setState(() {
                                                final minutes = (_duration % 60);
                                                _duration = (index * 60) + minutes;
                                              });
                                            },
                                            selectionOverlay: Container(
                                              decoration: BoxDecoration(
                                                border: Border.symmetric(
                                                  horizontal: BorderSide(
                                                    color: AppTheme.electricViolet.withValues(alpha: 0.3),
                                                    width: 2,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            children: List.generate(25, (index) {
                                              return Center(
                                                child: Text(
                                                  '$index',
                                                  style: theme.textTheme.headlineSmall?.copyWith(
                                                    color: isDark ? Colors.white : AppTheme.electricViolet,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                              );
                                            }),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 20),
                                  // Minute picker
                                  Expanded(
                                    child: Column(
                                      children: [
                                        GestureDetector(
                                          onTap: () => _showDirectInputDialog(
                                            context: context,
                                            title: '분 입력',
                                            hintText: '0-55 (5분 단위)',
                                            maxValue: 55,
                                            currentValue: _duration % 60,
                                            onSubmit: (value) {
                                              // Round to nearest 5
                                              final roundedValue = (value / 5).round() * 5;
                                              setState(() {
                                                final hours = _duration ~/ 60;
                                                _duration = (hours * 60) + roundedValue;
                                                _durationMinuteController.jumpToItem(roundedValue ~/ 5);
                                              });
                                            },
                                          ),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                '분',
                                                style: theme.textTheme.bodySmall?.copyWith(
                                                  color: isDark
                                                      ? Colors.white.withValues(alpha: 0.5)
                                                      : AppTheme.electricViolet.withValues(alpha: 0.5),
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              Icon(
                                                Icons.edit,
                                                size: 12,
                                                color: isDark
                                                    ? Colors.white.withValues(alpha: 0.3)
                                                    : AppTheme.electricViolet.withValues(alpha: 0.3),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Expanded(
                                          child: CupertinoPicker(
                                            scrollController: _durationMinuteController,
                                            itemExtent: 50,
                                            onSelectedItemChanged: (index) {
                                              setState(() {
                                                final hours = (_duration ~/ 60);
                                                _duration = (hours * 60) + (index * 5);
                                              });
                                            },
                                            selectionOverlay: Container(
                                              decoration: BoxDecoration(
                                                border: Border.symmetric(
                                                  horizontal: BorderSide(
                                                    color: AppTheme.electricViolet.withValues(alpha: 0.3),
                                                    width: 2,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            children: List.generate(12, (index) {
                                              final minute = index * 5;
                                              return Center(
                                                child: Text(
                                                  '$minute',
                                                  style: theme.textTheme.headlineSmall?.copyWith(
                                                    color: isDark ? Colors.white : AppTheme.electricViolet,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                              );
                                            }),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ] else ...[
                            // iOS-style scrollable picker for target time (12-hour format)
                            Column(
                              children: [
                                Container(
                                  height: 200,
                                  padding: const EdgeInsets.symmetric(horizontal: 20),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      // AM/PM picker (왼쪽으로 이동)
                                      Expanded(
                                        flex: 1,
                                        child: Column(
                                          children: [
                                            Text(
                                              '',
                                              style: theme.textTheme.bodySmall?.copyWith(
                                                color: isDark
                                                    ? Colors.white.withValues(alpha: 0.5)
                                                    : AppTheme.electricViolet.withValues(alpha: 0.5),
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Expanded(
                                              child: CupertinoPicker(
                                                scrollController: _amPmController,
                                                itemExtent: 50,
                                                onSelectedItemChanged: (index) {
                                                  setState(() {
                                                    _isAM = index == 0;
                                                    // 시간 다이얼의 현재 위치를 읽어옴
                                                    final hour12 = _targetHourController.selectedItem + 1;

                                                    // 12시간 → 24시간 변환
                                                    final hour24 = _isAM
                                                        ? (hour12 == 12 ? 0 : hour12)
                                                        : (hour12 == 12 ? 12 : hour12 + 12);

                                                    _targetTime = TimeOfDay(
                                                      hour: hour24,
                                                      minute: _targetTime?.minute ?? 0,
                                                    );
                                                  });
                                                },
                                                selectionOverlay: Container(
                                                  decoration: BoxDecoration(
                                                    border: Border.symmetric(
                                                      horizontal: BorderSide(
                                                        color: AppTheme.electricViolet.withValues(alpha: 0.3),
                                                        width: 2,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                children: [
                                                  Center(
                                                    child: Text(
                                                      '오전',
                                                      style: theme.textTheme.titleMedium?.copyWith(
                                                        color: isDark ? Colors.white : AppTheme.electricViolet,
                                                        fontWeight: FontWeight.w700,
                                                      ),
                                                    ),
                                                  ),
                                                  Center(
                                                    child: Text(
                                                      '오후',
                                                      style: theme.textTheme.titleMedium?.copyWith(
                                                        color: isDark ? Colors.white : AppTheme.electricViolet,
                                                        fontWeight: FontWeight.w700,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      // Hour picker (1-12)
                                      Expanded(
                                        child: Column(
                                          children: [
                                            GestureDetector(
                                              onTap: () => _showDirectInputDialog(
                                                context: context,
                                                title: '시 입력',
                                                hintText: '1-12',
                                                maxValue: 12,
                                                currentValue: (_targetTime?.hour ?? 0) % 12 == 0 ? 12 : (_targetTime?.hour ?? 0) % 12,
                                                onSubmit: (value) {
                                                  if (value >= 1 && value <= 12) {
                                                    setState(() {
                                                      // 12시간 → 24시간 변환
                                                      int hour24;
                                                      if (_isAM) {
                                                        // 오전: 12시 = 0, 1-11시 = 1-11
                                                        hour24 = value == 12 ? 0 : value;
                                                      } else {
                                                        // 오후: 12시 = 12, 1-11시 = 13-23
                                                        hour24 = value == 12 ? 12 : value + 12;
                                                      }
                                                      _targetTime = TimeOfDay(
                                                        hour: hour24,
                                                        minute: _targetTime?.minute ?? 0,
                                                      );
                                                      _targetHourController.jumpToItem(value - 1);
                                                    });
                                                  }
                                                },
                                              ),
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Text(
                                                    '시',
                                                    style: theme.textTheme.bodySmall?.copyWith(
                                                      color: isDark
                                                          ? Colors.white.withValues(alpha: 0.5)
                                                          : AppTheme.electricViolet.withValues(alpha: 0.5),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Icon(
                                                    Icons.edit,
                                                    size: 12,
                                                    color: isDark
                                                        ? Colors.white.withValues(alpha: 0.3)
                                                        : AppTheme.electricViolet.withValues(alpha: 0.3),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Expanded(
                                              child: CupertinoPicker(
                                                scrollController: _targetHourController,
                                                itemExtent: 50,
                                                looping: true,
                                                onSelectedItemChanged: (index) {
                                                  setState(() {
                                                    final hour12 = index + 1; // 0-11 → 1-12

                                                    // 이전 시간 값 구하기
                                                    final currentHour12 = ((_targetTime?.hour ?? 0) % 12) == 0
                                                        ? 12
                                                        : ((_targetTime?.hour ?? 0) % 12);

                                                    // 11↔12 경계를 넘을 때 AM/PM 전환
                                                    if (currentHour12 == 11 && hour12 == 12) {
                                                      // 11→12: AM↔PM 전환
                                                      _isAM = !_isAM;
                                                      _amPmController.jumpToItem(_isAM ? 0 : 1);
                                                    } else if (currentHour12 == 12 && hour12 == 11) {
                                                      // 12→11 (역방향): AM↔PM 전환
                                                      _isAM = !_isAM;
                                                      _amPmController.jumpToItem(_isAM ? 0 : 1);
                                                    }

                                                    // 12시간 → 24시간 변환
                                                    final hour24 = _isAM
                                                        // 오전: 12시 = 0, 1-11시 = 1-11
                                                        ? (hour12 == 12 ? 0 : hour12)
                                                        // 오후: 12시 = 12, 1-11시 = 13-23
                                                        : (hour12 == 12 ? 12 : hour12 + 12);
                                                    _targetTime = TimeOfDay(
                                                      hour: hour24,
                                                      minute: _targetTime?.minute ?? 0,
                                                    );
                                                  });
                                                },
                                                selectionOverlay: Container(
                                                  decoration: BoxDecoration(
                                                    border: Border.symmetric(
                                                      horizontal: BorderSide(
                                                        color: AppTheme.electricViolet.withValues(alpha: 0.3),
                                                        width: 2,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                children: List.generate(12, (index) {
                                                  return Center(
                                                    child: Text(
                                                      '${index + 1}', // 1-12
                                                      style: theme.textTheme.headlineSmall?.copyWith(
                                                        color: isDark ? Colors.white : AppTheme.electricViolet,
                                                        fontWeight: FontWeight.w700,
                                                      ),
                                                    ),
                                                  );
                                                }),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      // Minute picker
                                      Expanded(
                                        child: Column(
                                          children: [
                                            GestureDetector(
                                              onTap: () => _showDirectInputDialog(
                                                context: context,
                                                title: '분 입력',
                                                hintText: '0-59',
                                                maxValue: 59,
                                                currentValue: _targetTime?.minute ?? 0,
                                                onSubmit: (value) {
                                                  setState(() {
                                                    _targetTime = TimeOfDay(
                                                      hour: _targetTime?.hour ?? 0,
                                                      minute: value,
                                                    );
                                                    _targetMinuteController.jumpToItem(value);
                                                    _previousMinute = value; // Update previous minute
                                                  });
                                                },
                                              ),
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Text(
                                                    '분',
                                                    style: theme.textTheme.bodySmall?.copyWith(
                                                      color: isDark
                                                          ? Colors.white.withValues(alpha: 0.5)
                                                          : AppTheme.electricViolet.withValues(alpha: 0.5),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Icon(
                                                    Icons.edit,
                                                    size: 12,
                                                    color: isDark
                                                        ? Colors.white.withValues(alpha: 0.3)
                                                        : AppTheme.electricViolet.withValues(alpha: 0.3),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Expanded(
                                              child: CupertinoPicker(
                                                scrollController: _targetMinuteController,
                                                itemExtent: 50,
                                                looping: true,
                                                onSelectedItemChanged: (index) {
                                                  setState(() {
                                                    final newMinute = index;
                                                    var hourAdjustment = 0;

                                                    // Detect minute boundary crossing
                                                    if (_previousMinute == 59 && newMinute == 0) {
                                                      // 59 → 0: increment hour
                                                      hourAdjustment = 1;
                                                    } else if (_previousMinute == 0 && newMinute == 59) {
                                                      // 0 → 59: decrement hour
                                                      hourAdjustment = -1;
                                                    }

                                                    _previousMinute = newMinute;

                                                    // Calculate new hour if needed
                                                    if (hourAdjustment != 0) {
                                                      final currentHour24 = _targetTime?.hour ?? 0;
                                                      final currentHour12 = (currentHour24 % 12) == 0
                                                          ? 12
                                                          : (currentHour24 % 12);
                                                      final newHour12Raw = currentHour12 + hourAdjustment;

                                                      // 먼저 AM/PM 전환 체크 (11↔12 경계)
                                                      final shouldToggleAmPm = (currentHour12 == 11 && newHour12Raw == 12) ||
                                                          (currentHour12 == 12 && newHour12Raw == 11);
                                                      if (shouldToggleAmPm) {
                                                        _isAM = !_isAM;
                                                      }

                                                      // Handle hour boundary wrapping
                                                      final newHour12 = newHour12Raw == 0
                                                          ? 12
                                                          : (newHour12Raw == 13 ? 1 : newHour12Raw);

                                                      // 12시간 → 24시간 변환
                                                      final hour24 = _isAM
                                                          ? (newHour12 == 12 ? 0 : newHour12)
                                                          : (newHour12 == 12 ? 12 : newHour12 + 12);

                                                      _targetTime = TimeOfDay(
                                                        hour: hour24,
                                                        minute: newMinute,
                                                      );

                                                      // Update pickers (이게 onSelectedItemChanged를 트리거함)
                                                      // 하지만 이미 _targetTime을 설정했으므로 괜찮음
                                                      _targetHourController.jumpToItem(newHour12 - 1);
                                                      if (shouldToggleAmPm) {
                                                        _amPmController.jumpToItem(_isAM ? 0 : 1);
                                                      }
                                                    } else {
                                                      _targetTime = TimeOfDay(
                                                        hour: _targetTime?.hour ?? 0,
                                                        minute: newMinute,
                                                      );
                                                    }
                                                  });
                                                },
                                                selectionOverlay: Container(
                                                  decoration: BoxDecoration(
                                                    border: Border.symmetric(
                                                      horizontal: BorderSide(
                                                        color: AppTheme.electricViolet.withValues(alpha: 0.3),
                                                        width: 2,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                children: List.generate(60, (index) {
                                                  return Center(
                                                    child: Text(
                                                      '$index',
                                                      style: theme.textTheme.headlineSmall?.copyWith(
                                                        color: isDark ? Colors.white : AppTheme.electricViolet,
                                                        fontWeight: FontWeight.w700,
                                                      ),
                                                    ),
                                                  );
                                                }),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                // Show remaining time
                                Text(
                                  _getTimeUntilTarget(),
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? AppTheme.electricViolet.withValues(alpha: 0.8)
                                        : AppTheme.electricViolet,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Sound selection button
                    GlassCard(
                      onTap: () => _showSoundSelectionModal(context, theme, isDark),
                      padding: const EdgeInsets.all(20),
                      borderRadius: 20,
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppTheme.electricViolet.withValues(alpha: 0.3),
                                  Colors.pink.withValues(alpha: 0.3),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.volume_up,
                              color: isDark ? Colors.white : AppTheme.electricViolet,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Ambient Sounds',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    color: isDark
                                        ? Colors.white.withValues(alpha: 0.7)
                                        : theme.colorScheme.onSurface.withValues(alpha: 0.7),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${_selectedSound.emoji} ${_selectedSound.name}',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? Colors.white : theme.colorScheme.onSurface,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.5)
                                : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                        ],
                      ),
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
                                  ? Colors.white.withValues(alpha: 0.1)
                                  : AppTheme.electricViolet.withValues(alpha: 0.2),
                              thumbColor: AppTheme.electricViolet,
                              overlayColor: AppTheme.electricViolet.withValues(alpha: 0.2),
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
                                      ? AppTheme.electricViolet.withValues(alpha: 0.6)
                                      : AppTheme.electricViolet,
                                  fontSize: 11,
                                ),
                              ),
                              Text(
                                'Perfect',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: isDark
                                      ? AppTheme.electricViolet.withValues(alpha: 0.6)
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
                                .withValues(alpha: 0.4),
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
                                            ? Colors.white.withValues(alpha: 0.7)
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
                                      ? AppTheme.electricViolet.withValues(alpha: 0.8)
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
