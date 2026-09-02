part of '../main.dart';

class WorkoutsTabView extends StatefulWidget {
  final MissionFitHomeState parent;

  const WorkoutsTabView({super.key, required this.parent});

  @override
  State<WorkoutsTabView> createState() => _WorkoutsTabViewState();
}

class _WorkoutsTabViewState extends State<WorkoutsTabView> {
  DateTime _selectedWorkoutDate = DateTime.now();

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
    final currentWorkout = widget.parent.plannedWorkoutForDate(DateTime.now());
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
                      currentWorkout ?? 'Rest day',
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                ElevatedButton(
                  onPressed: currentWorkout == null
                      ? null
                      : () {
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
                  child: Text(currentWorkout == null ? 'Plan' : 'Start'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          HomeTabView(parent: widget.parent).buildStreakCard(),
          const SizedBox(height: 18),
          _buildWorkoutCalendar(),
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
                              if (!widget.parent._quickStartWorkoutNames
                                  .contains(workoutName)) {
                                widget.parent._quickStartWorkoutNames.add(
                                  workoutName,
                                );
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
                  label: const Text('Create workout'),
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

  Widget _buildWorkoutCalendar() {
    final today = DateTime.now();
    final firstDate = DateTime(today.year, today.month, today.day);
    final firstWeekday = firstDate.subtract(
      Duration(days: firstDate.weekday - 1),
    );
    final dates = List.generate(
      14,
      (index) => firstWeekday.add(Duration(days: index)),
    );
    const weekdayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 18),
      decoration: BoxDecoration(
        color: kMissionFitSurface,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${HomeTabLogic.monthName(today.month)} ${today.year}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Plan a workout',
                  style: TextStyle(
                    color: kMissionFitMuted,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: weekdayLabels
                .map(
                  (label) => Expanded(
                    child: Center(
                      child: Text(
                        label,
                        style: const TextStyle(
                          color: kMissionFitMuted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 8),
          for (var week = 0; week < 2; week++) ...[
            Row(
              children: dates.sublist(week * 7, week * 7 + 7).map((date) {
                final isSelected =
                    date.year == _selectedWorkoutDate.year &&
                    date.month == _selectedWorkoutDate.month &&
                    date.day == _selectedWorkoutDate.day;
                final hasPlan = widget.parent._plannedWorkouts.containsKey(
                  widget.parent._dateKey(date),
                );
                return Expanded(
                  child: InkWell(
                    onTap: () {
                      setState(() => _selectedWorkoutDate = date);
                      _showWorkoutPlanner(date);
                    },
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      height: 42,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected
                            ? kMissionFitSecondary
                            : Colors.transparent,
                        border: Border.all(
                          color: hasPlan
                              ? kMissionFitAccent
                              : Colors.transparent,
                          width: 1.2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '${date.day}',
                          style: TextStyle(
                            color: isSelected ? Colors.white : kMissionFitMuted,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            if (week == 0) const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }

  void _showWorkoutPlanner(DateTime date) {
    String? selectedWorkout =
        widget.parent._plannedWorkouts[widget.parent._dateKey(date)];

    showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: kMissionFitSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: Text('Plan ${HomeTabLogic.monthName(date.month)} ${date.day}'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: widget.parent._quickStartWorkoutNames
                  .map(
                    (workout) => CheckboxListTile(
                      value: selectedWorkout == workout,
                      activeColor: kMissionFitAccent,
                      checkColor: kMissionFitDominant,
                      contentPadding: EdgeInsets.zero,
                      title: Text(workout),
                      controlAffinity: ListTileControlAffinity.trailing,
                      onChanged: (selected) {
                        setDialogState(() {
                          selectedWorkout = selected == true ? workout : null;
                        });
                      },
                    ),
                  )
                  .toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (selectedWorkout != null) {
                  widget.parent.planWorkout(date, selectedWorkout!);
                }
                Navigator.pop(dialogContext);
              },
              child: const Text('Done'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetWorkoutTiles() {
    final presets = widget.parent._quickStartWorkoutNames.toList();
    if (presets.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Workouts',
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
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        workout,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    IconButton(
                      onPressed: () =>
                          widget.parent.removeQuickStartWorkout(workout),
                      icon: const Icon(Icons.close_rounded),
                      color: kMissionFitMuted,
                      tooltip: 'Remove $workout',
                    ),
                  ],
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
                width: 300,
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
