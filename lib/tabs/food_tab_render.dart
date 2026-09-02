part of '../main.dart';

class FoodTabView extends StatefulWidget {
  final MissionFitHomeState parent;

  const FoodTabView({super.key, required this.parent});

  @override
  State<FoodTabView> createState() => _FoodTabViewState();
}

class _FoodTabViewState extends State<FoodTabView> {
  @override
  Widget build(BuildContext context) {
    final totalCalories = FoodTabLogic.totalCalories(
      widget.parent._foodEntries,
    );
    final totalProtein = FoodTabLogic.totalProtein(widget.parent._foodEntries);
    final totalCarbs = FoodTabLogic.totalCarbs(widget.parent._foodEntries);
    final totalFat = FoodTabLogic.totalFat(widget.parent._foodEntries);
    final calorieGoal = widget.parent._calculateCalorieGoal();
    final macroProteinTarget = (calorieGoal * 0.30 / 4).clamp(
      0,
      double.infinity,
    );
    final macroCarbTarget = (calorieGoal * 0.45 / 4).clamp(0, double.infinity);
    final macroFatTarget = (calorieGoal * 0.25 / 9).clamp(0, double.infinity);
    final progress = FoodTabLogic.calorieProgress(
      entries: widget.parent._foodEntries,
      calorieGoal: calorieGoal,
    );
    final caloriesLeft = (calorieGoal - totalCalories).clamp(
      0.0,
      double.infinity,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Daily Calories',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: kMissionFitAccent,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  widget.parent._goal,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: kMissionFitDominant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              SizedBox(
                width: 140,
                height: 140,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 120,
                      height: 120,
                      child: CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 12,
                        backgroundColor: kMissionFitSurfaceSoft,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          kMissionFitAccent,
                        ),
                      ),
                    ),
                    Text(
                      '${caloriesLeft.round()} kcal\nleft',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _MacroRow(
                      label: 'Protein',
                      value:
                          '${totalProtein.round()}/${macroProteinTarget.round()}g',
                    ),
                    _MacroRow(
                      label: 'Carbs',
                      value:
                          '${totalCarbs.round()}/${macroCarbTarget.round()}g',
                    ),
                    _MacroRow(
                      label: 'Fats',
                      value: '${totalFat.round()}/${macroFatTarget.round()}g',
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: kMissionFitSurface,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Food Log',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (sheetContext) =>
                              _FoodEntrySheet(parent: widget.parent),
                        );
                      },
                      borderRadius: BorderRadius.circular(999),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: const BoxDecoration(
                          color: kMissionFitAccent,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.add_rounded,
                          color: kMissionFitDominant,
                          size: 22,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (widget.parent._foodEntries.isEmpty)
                  const Text('No food items logged yet.'),
                ...widget.parent._foodEntries.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        IconButton(
                          onPressed: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (sheetContext) => _FoodEntrySheet(
                                parent: widget.parent,
                                initialEntry: item,
                                onSave: (updated) {
                                  widget.parent.setState(() {
                                    widget.parent._foodEntries[index] = updated;
                                  });
                                  widget.parent._saveSettings();
                                },
                              ),
                            );
                          },
                          icon: const Icon(Icons.edit_note_rounded),
                          color: kMissionFitAccent,
                          tooltip: 'Edit or delete food entry',
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: kMissionFitSurfaceSoft,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Wrap(
                                        spacing: 12,
                                        runSpacing: 8,
                                        children: [
                                          Text('${item.calories.round()} kcal'),
                                          Text('P ${item.protein.round()}g'),
                                          Text('C ${item.carbs.round()}g'),
                                          Text('F ${item.fat.round()}g'),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  onPressed: () {
                                    widget.parent.setState(() {
                                      widget.parent._foodEntries.removeAt(
                                        index,
                                      );
                                    });
                                    widget.parent._saveSettings();
                                  },
                                  icon: const Icon(Icons.close_rounded),
                                  color: Colors.redAccent,
                                  tooltip: 'Delete food entry',
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () {
                    widget.parent.setState(() => widget.parent._goal = 'Cut');
                    widget.parent._saveSettings();
                  },
                  child: _goalButton('Cut', kMissionFitLight),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: InkWell(
                  onTap: () {
                    widget.parent.setState(
                      () => widget.parent._goal = 'Maintain',
                    );
                    widget.parent._saveSettings();
                  },
                  child: _goalButton('Maintain', kMissionFitLight),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: InkWell(
                  onTap: () {
                    widget.parent.setState(() => widget.parent._goal = 'Bulk');
                    widget.parent._saveSettings();
                  },
                  child: _goalButton('Bulk', kMissionFitLight),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
