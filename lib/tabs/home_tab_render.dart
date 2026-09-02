part of '../main.dart';

class HomeTabView extends StatefulWidget {
  final MissionFitHomeState parent;

  const HomeTabView({super.key, required this.parent});

  Widget buildStreakCard() {
    final dayLabels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    final today = DateTime.now();
    final active = HomeTabLogic.weekActivity(
      today,
      parent._completedWorkoutDates,
    );

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
            'Streak Counter',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (index) {
              final isActive = active[index];
              return Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActive ? kMissionFitAccent : kMissionFitSurfaceSoft,
                  border: Border.all(
                    color: isActive ? kMissionFitLight : Colors.transparent,
                    width: 1.4,
                  ),
                ),
                child: Center(
                  child: Text(
                    dayLabels[index],
                    style: TextStyle(
                      color: isActive ? kMissionFitDominant : kMissionFitMuted,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 14),
          Text(
            '${HomeTabLogic.workoutStreakCount(parent._completedWorkoutDates)}-day streak!',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  @override
  State<HomeTabView> createState() => _HomeTabViewState();
}

class _HomeTabViewState extends State<HomeTabView> {
  DateTime _selectedWorkoutDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final weekday = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ][now.weekday - 1];
    final date = '${now.day} ${HomeTabLogic.monthName(now.month)} ${now.year}';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$weekday, $date',
            style: const TextStyle(
              color: kMissionFitMuted,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Welcome ${widget.parent._name}!',
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 22),
          _buildMetricGrid(),
          const SizedBox(height: 24),
          widget.buildStreakCard(),
          const SizedBox(height: 24),
          _buildWorkoutCalendar(),
          const SizedBox(height: 24),
          _buildQuickStartCard(),
        ],
      ),
    );
  }

  Widget _buildWorkoutCalendar() {
    final today = DateTime.now();
    final firstDate = DateTime(today.year, today.month, today.day);
    final dates = List.generate(
      14,
      (index) => firstDate.add(Duration(days: index)),
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
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              'Plan A Workout',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
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
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: kMissionFitSurface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
            ),
            title: Text(
              'Plan ${HomeTabLogic.monthName(date.month)} ${date.day}',
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: widget.parent._quickStart
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
          );
        },
      ),
    );
  }

  Widget _buildMetricGrid() {
    final tdee = widget.parent._calculateTdee();
    final calorieGoal = widget.parent._calculateCalorieGoal();
    final cutMultiplier = widget.parent._goal == 'Cut'
        ? 0.68
        : widget.parent._goal == 'Bulk'
        ? 0.94
        : 0.82;
    final waterTarget = widget.parent._goal == 'Cut'
        ? 2.5
        : widget.parent._goal == 'Bulk'
        ? 3.2
        : 2.8;
    final stepTarget = widget.parent._goal == 'Cut'
        ? 12000
        : widget.parent._goal == 'Bulk'
        ? 9000
        : 10000;

    final metrics = [
      _MetricCard(
        title: 'Calories Burned',
        value: '${(tdee * cutMultiplier).round()}',
        suffix: 'kcal',
        progress: widget.parent._goal == 'Cut'
            ? 0.72
            : widget.parent._goal == 'Bulk'
            ? 0.86
            : 0.8,
        progressColor: kMissionFitAccent,
      ),
      _MetricCard(
        title: 'Calories Consumed',
        value: '${calorieGoal.round()}',
        suffix: 'kcal',
        progress: FoodTabLogic.calorieProgress(
          entries: widget.parent._foodEntries,
          calorieGoal: calorieGoal,
        ),
        progressColor: kMissionFitSecondary,
      ),
      _MetricCard(
        title: 'Water Intake',
        value: waterTarget.toStringAsFixed(1),
        suffix: 'L',
        progress: widget.parent._goal == 'Cut'
            ? 0.65
            : widget.parent._goal == 'Bulk'
            ? 0.82
            : 0.75,
        progressColor: kMissionFitLight,
      ),
      _MetricCard(
        title: 'Steps Taken',
        value: stepTarget.toString(),
        suffix: ' / $stepTarget',
        progress: widget.parent._goal == 'Cut'
            ? 0.84
            : widget.parent._goal == 'Bulk'
            ? 0.75
            : 0.8,
        progressColor: kMissionFitAccent,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: metrics.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 1.45,
      ),
      itemBuilder: (context, index) => metrics[index],
    );
  }

  Widget _buildQuickStartCard() {
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
            'Quick Start',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 14),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: widget.parent._quickStart.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.7,
            ),
            itemBuilder: (context, index) {
              final label = widget.parent._quickStart[index];
              return InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => WorkoutDetailScreen(
                        workoutName: label,
                        exercises: widget.parent._exercises,
                        onComplete: () async {
                          await widget.parent._saveSettings();
                        },
                      ),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: kMissionFitSurfaceSoft,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Center(
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
