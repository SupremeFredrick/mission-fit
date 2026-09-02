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
          Row(
            children: [
              Expanded(
                child: Text(
                  '$weekday, $date',
                  style: const TextStyle(
                    color: kMissionFitMuted,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (widget.parent.canReadNativeHealthData)
                IconButton(
                  onPressed: widget.parent._isLoadingHealthData
                      ? null
                      : _syncNativeActivity,
                  icon: widget.parent._isLoadingHealthData
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.sync_rounded),
                  color: kMissionFitAccent,
                  tooltip: 'Sync device activity',
                ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            'Welcome ${widget.parent._profileName}!',
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 22),
          _buildMetricGrid(context),
          const SizedBox(height: 24),
          widget.buildStreakCard(),
          const SizedBox(height: 24),
          _buildDailyQuote(),
          const SizedBox(height: 24),
          _buildQuickStartCard(),
        ],
      ),
    );
  }

  Future<void> _syncNativeActivity() async {
    final loaded = await widget.parent.loadNativeActivityData();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          loaded ? 'Device activity updated' : 'Unable to read device activity',
        ),
      ),
    );
  }

  Widget _buildDailyQuote() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kMissionFitSurface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: kMissionFitBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Daily perspective',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Text(
            '"${widget.parent._dailyQuote}"',
            style: const TextStyle(fontSize: 16, height: 1.45),
          ),
          const SizedBox(height: 10),
          Text(
            widget.parent._dailyQuoteAuthor,
            style: const TextStyle(
              color: kMissionFitMuted,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricGrid(BuildContext context) {
    final tdee = widget.parent._calculateTdee();
    final calorieGoal = widget.parent._calculateCalorieGoal();
    final nativeCaloriesBurned = widget.parent._nativeCaloriesBurned;
    final nativeStepCount = widget.parent._nativeStepCount;
    final waterGoal = widget.parent.calculateWaterGoal();
    final stepTarget = widget.parent._goal == 'Cut'
        ? 12000
        : widget.parent._goal == 'Bulk'
        ? 9000
        : 10000;

    final metrics = [
      _MetricCard(
        title: 'Calories Burned',
        value: nativeCaloriesBurned == null
            ? 'N/A'
            : '${nativeCaloriesBurned.round()}',
        suffix: 'kcal',
        progress: nativeCaloriesBurned == null
            ? 0
            : (nativeCaloriesBurned / tdee).clamp(0.0, 1.0),
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
        value: widget.parent._waterConsumed.toStringAsFixed(1),
        suffix: ' / ${waterGoal.toStringAsFixed(1)} L',
        progress: (widget.parent._waterConsumed / waterGoal).clamp(0.0, 1.0),
        progressColor: kMissionFitLight,
        valueControls: _buildWaterIntakeAdjusters(),
      ),
      _MetricCard(
        title: 'Steps Taken',
        value: nativeStepCount == null ? 'N/A' : '$nativeStepCount',
        suffix: ' / $stepTarget',
        progress: nativeStepCount == null
            ? 0
            : (nativeStepCount / stepTarget).clamp(0.0, 1.0),
        progressColor: kMissionFitAccent,
      ),
    ];

    final useWideGrid = MediaQuery.sizeOf(context).width >= 840;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: metrics.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: useWideGrid ? 4 : 2,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: useWideGrid ? 1.1 : 1.05,
      ),
      itemBuilder: (context, index) => metrics[index],
    );
  }

  Widget _buildWaterIntakeAdjusters() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _waterButton(
          icon: Icons.add_rounded,
          tooltip: 'Increase water intake',
          onPressed: () => widget.parent.adjustWaterConsumed(0.25),
        ),
        const SizedBox(height: 4),
        _waterButton(
          icon: Icons.remove_rounded,
          tooltip: 'Decrease water intake',
          onPressed: () => widget.parent.adjustWaterConsumed(-0.25),
        ),
      ],
    );
  }

  Widget _waterButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      tooltip: tooltip,
      style: IconButton.styleFrom(
        minimumSize: const Size(28, 28),
        padding: EdgeInsets.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        backgroundColor: kMissionFitDominant,
        foregroundColor: kMissionFitAccent,
      ),
    );
  }

  Widget _buildQuickStartCard() {
    final useWideGrid = MediaQuery.sizeOf(context).width >= 840;

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
            itemCount: widget.parent._quickStartWorkoutNames.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: useWideGrid ? 4 : 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: useWideGrid ? 1.45 : 1.7,
            ),
            itemBuilder: (context, index) {
              final label = widget.parent._quickStartWorkoutNames[index];
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
                    color: kMissionFitAccent,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Center(
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: kMissionFitDominant,
                        fontWeight: FontWeight.w700,
                      ),
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
