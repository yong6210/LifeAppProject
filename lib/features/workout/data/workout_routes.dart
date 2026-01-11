import 'package:life_app/features/workout/models/workout_navigator_models.dart';

final List<WorkoutNavigatorRoute> workoutNavigatorRoutes = [
  const WorkoutNavigatorRoute(
    id: 'run_park_loop',
    title: 'Park Loop (5 km)',
    description:
        'Flat paved loop with two gradual inclines. Ideal for an even tempo.',
    discipline: WorkoutDiscipline.running,
    intensity: WorkoutIntensity.moderate,
    distanceKm: 5.2,
    estimatedMinutes: 32,
    mapAssetPath: 'assets/maps/run_park_loop.png',
    segments: [
      WorkoutNavigatorSegment(
        startOffset: Duration.zero,
        endOffset: Duration(minutes: 5),
        focus: 'Warm-up',
        cue: 'Start with a light jog and focus on relaxed breathing.',
      ),
      WorkoutNavigatorSegment(
        startOffset: Duration(minutes: 5),
        endOffset: Duration(minutes: 25),
        focus: 'Steady pace',
        cue: 'Hold conversational pace, reset shoulders at the midpoint.',
      ),
      WorkoutNavigatorSegment(
        startOffset: Duration(minutes: 25),
        endOffset: Duration(minutes: 32),
        focus: 'Finish strong',
        cue: 'Increase cadence on the final incline and cool down at the gate.',
      ),
    ],
    voiceCues: [
      WorkoutNavigatorCue(
        offset: Duration(minutes: 5),
        message: 'Head into your steady pace and keep breathing rhythmically.',
      ),
      WorkoutNavigatorCue(
        offset: Duration(minutes: 25),
        message: 'Final push coming up—lift your knees slightly and stay tall.',
      ),
    ],
    offlineSummary: '''
- Warm up with 5 minutes of easy jogging.
- Settle into a steady tempo for 20 minutes.
- Finish with a 7 minute push, then walk to cool down.''',
  ),
  const WorkoutNavigatorRoute(
    id: 'run_river_trail',
    title: 'River Trail Cruise (8 km)',
    description:
        'Gravel path along the river with light shade. Minimal traffic on weekday mornings.',
    discipline: WorkoutDiscipline.running,
    intensity: WorkoutIntensity.light,
    distanceKm: 8.0,
    estimatedMinutes: 52,
    mapAssetPath: 'assets/maps/run_river_trail.png',
    segments: [
      WorkoutNavigatorSegment(
        startOffset: Duration.zero,
        endOffset: Duration(minutes: 10),
        focus: 'Easy jog',
        cue: 'Stay relaxed and let your breathing guide the effort.',
      ),
      WorkoutNavigatorSegment(
        startOffset: Duration(minutes: 10),
        endOffset: Duration(minutes: 40),
        focus: 'Cruise',
        cue: 'Hold a pace where you can chat in short sentences.',
      ),
      WorkoutNavigatorSegment(
        startOffset: Duration(minutes: 40),
        endOffset: Duration(minutes: 52),
        focus: 'Cool-down',
        cue: 'Ease to a jog and finish with a short walk by the bridge.',
      ),
    ],
    voiceCues: [
      WorkoutNavigatorCue(
        offset: Duration(minutes: 10),
        message: 'Find your cruise effort—aim for conversation pace.',
      ),
      WorkoutNavigatorCue(
        offset: Duration(minutes: 40),
        message: 'Ease off the throttle and prepare to cool down.',
      ),
    ],
    offlineSummary: '''
- Jog lightly for 10 minutes while warming up.
- Maintain conversation pace along the river loop.
- Cool down with a relaxed jog and finish walking.''',
  ),
  const WorkoutNavigatorRoute(
    id: 'run_neighborhood_easy',
    title: 'Neighborhood Shake-out (3 km)',
    description:
        'Short residential loop with minimal traffic. Perfect for recovery pace runs.',
    discipline: WorkoutDiscipline.running,
    intensity: WorkoutIntensity.light,
    distanceKm: 3.2,
    estimatedMinutes: 22,
    segments: [
      WorkoutNavigatorSegment(
        startOffset: Duration.zero,
        endOffset: Duration(minutes: 5),
        focus: 'Walk & mobilise',
        cue: 'Start with a brisk walk and ankle rolls.',
      ),
      WorkoutNavigatorSegment(
        startOffset: Duration(minutes: 5),
        endOffset: Duration(minutes: 17),
        focus: 'Shake-out jog',
        cue: 'Keep the pace gentle; focus on smooth strides.',
      ),
      WorkoutNavigatorSegment(
        startOffset: Duration(minutes: 17),
        endOffset: Duration(minutes: 22),
        focus: 'Cooldown walk',
        cue: 'Gradually slow to a walk and let your breathing settle.',
      ),
    ],
    voiceCues: [
      WorkoutNavigatorCue(
        offset: Duration(minutes: 5),
        message: 'Ease into a gentle jog—this is all about recovery.',
      ),
    ],
    offlineSummary: '''
- Brisk walk for 5 minutes.
- Jog easily around your block, focusing on relaxed strides.
- Finish with a short walk and light stretching.''',
  ),
  const WorkoutNavigatorRoute(
    id: 'ride_greenbelt',
    title: 'Greenbelt Spin (12 km)',
    description:
        'Smooth cycling path with gentle rollers. Watch for families near the playground section.',
    discipline: WorkoutDiscipline.cycling,
    intensity: WorkoutIntensity.moderate,
    distanceKm: 12.0,
    estimatedMinutes: 38,
    mapAssetPath: 'assets/maps/ride_greenbelt.png',
    segments: [
      WorkoutNavigatorSegment(
        startOffset: Duration.zero,
        endOffset: Duration(minutes: 7),
        focus: 'Spin-up',
        cue: 'Spin comfortably at 85 RPM and check posture.',
      ),
      WorkoutNavigatorSegment(
        startOffset: Duration(minutes: 7),
        endOffset: Duration(minutes: 30),
        focus: 'Rolling effort',
        cue: 'Hold steady effort; shift smoothly on rollers.',
      ),
      WorkoutNavigatorSegment(
        startOffset: Duration(minutes: 30),
        endOffset: Duration(minutes: 38),
        focus: 'Easy spin',
        cue: 'Downshift and let the legs flush out before finishing.',
      ),
    ],
    voiceCues: [
      WorkoutNavigatorCue(
        offset: Duration(minutes: 7),
        message: 'Roll into your main effort—keep cadence in the 90 range.',
      ),
    ],
    offlineSummary: '''
- Spin up for 7 minutes and check posture.
- Maintain steady effort through rolling hills.
- Cool down with an easy spin back to the start.''',
  ),
  const WorkoutNavigatorRoute(
    id: 'ride_commute_intervals',
    title: 'City Commute Sprint (18 km)',
    description:
        'Urban bike lanes with two timed traffic light sections. Great for interval style ride.',
    discipline: WorkoutDiscipline.cycling,
    intensity: WorkoutIntensity.vigorous,
    distanceKm: 18.4,
    estimatedMinutes: 45,
    mapAssetPath: 'assets/maps/ride_commute.png',
    segments: [
      WorkoutNavigatorSegment(
        startOffset: Duration.zero,
        endOffset: Duration(minutes: 5),
        focus: 'Warm-up spin',
        cue: 'Stay in easy gear and bring cadence to 90 RPM.',
      ),
      WorkoutNavigatorSegment(
        startOffset: Duration(minutes: 5),
        endOffset: Duration(minutes: 35),
        focus: 'Intervals',
        cue:
            'Alternate 2 minutes strong / 2 minutes steady. Use traffic lights as recovery.',
      ),
      WorkoutNavigatorSegment(
        startOffset: Duration(minutes: 35),
        endOffset: Duration(minutes: 45),
        focus: 'Cool-down',
        cue: 'Shift down and cruise back, rolling shoulders and relaxing grip.',
      ),
    ],
    voiceCues: [
      WorkoutNavigatorCue(
        offset: Duration(minutes: 7),
        message: 'First hard effort—stand for 30 seconds then settle.',
      ),
      WorkoutNavigatorCue(
        offset: Duration(minutes: 33),
        message: 'Last push—focus on clean pedal strokes.',
      ),
    ],
    offlineSummary: '''
- Easy spin for 5 minutes.
- Perform 2-minute surges followed by 2-minute steady spins for 25 minutes.
- Finish with an easy 10-minute commute pace cooldown.''',
  ),
];
