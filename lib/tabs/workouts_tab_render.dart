part of '../main.dart';

class WorkoutsTabView extends StatefulWidget {
  final MissionFitHomeState parent;

  const WorkoutsTabView({super.key, required this.parent});

  @override
  State<WorkoutsTabView> createState() => _WorkoutsTabViewState();
}

class _WorkoutsTabViewState extends State<WorkoutsTabView> {
  @override
  Widget build(BuildContext context) {
    final weekdayNames = [
      'Sunday',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
    ];
    final todayName = weekdayNames[DateTime.now().weekday % 7];
    final currentWorkout = widget.parent.workoutForDate(DateTime.now());
    final bodyMapItems = WorkoutsTabLogic.bodyMapStatus(
      widget.parent._exercises,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text(
            WorkoutsTabLogic.dateString(),
            style: const TextStyle(
              color: kMissionFitMuted,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 22),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: kMissionFitSurfaceStrong,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      todayName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      currentWorkout,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => WorkoutDetailScreen(
                          workoutName: currentWorkout,
                          exercises: widget.parent.exercisesForWorkout(
                            currentWorkout,
                          ),
                          onComplete: () async {
                            await widget.parent._saveSettings();
                          },
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kMissionFitAccent,
                    foregroundColor: kMissionFitDominant,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text('Start'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          HomeTabView(parent: widget.parent).buildStreakCard(),
          const SizedBox(height: 18),
          _buildBodyMapPreview(bodyMapItems),
          const SizedBox(height: 18),
          _buildPresetWorkoutTiles(),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => WorkoutBuilderScreen(
                          onSave: (workoutName, exercises) {
                            widget.parent.setState(() {
                              widget.parent._workoutName = workoutName;
                              widget.parent._exercises = exercises;
                              if (!widget.parent._quickStart.contains(
                                workoutName,
                              )) {
                                widget.parent._quickStart.add(workoutName);
                              }
                              widget.parent._quickStartWorkouts[workoutName] =
                                  List<WorkoutExercise>.from(exercises);
                            });
                            widget.parent._saveSettings();
                          },
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Create A New Workout!'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kMissionFitAccent,
                    foregroundColor: kMissionFitDominant,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: widget.parent._showQuickStartEditor,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: kMissionFitSecondary),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('Edit Quick Start'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPresetWorkoutTiles() {
    final presets = widget.parent._quickStart.toList();
    if (presets.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Preset Workouts',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        ...presets.map(
          (workout) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => WorkoutDetailScreen(
                      workoutName: workout,
                      exercises: widget.parent.exercisesForWorkout(workout),
                      onComplete: () async {
                        await widget.parent._saveSettings();
                      },
                    ),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: kMissionFitSurfaceSoft,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    workout,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBodyMapPreview(Map<String, bool> bodyMapItems) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: kMissionFitSurface,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Body Map',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: Align(
              alignment: Alignment.center,
              child: SizedBox(
                width: 220,
                height: 280,
                child: CustomPaint(painter: _BodyMapPainter(bodyMapItems)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
