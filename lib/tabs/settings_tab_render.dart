part of '../main.dart';

class SettingsTabView extends StatefulWidget {
  final MissionFitHomeState parent;

  const SettingsTabView({super.key, required this.parent});

  @override
  State<SettingsTabView> createState() => _SettingsTabViewState();
}

class _SettingsTabViewState extends State<SettingsTabView> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Profile',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          _settingField(
            'Name',
            widget.parent._profileName,
            (value) => widget.parent.setState(
              () => widget.parent._profileName = value,
            ),
          ),
          _settingField(
            'Age',
            widget.parent._age,
            (value) => widget.parent.setState(() => widget.parent._age = value),
          ),
          _unitTextField(
            label: 'Height',
            value: widget.parent._heightValue.toStringAsFixed(
              widget.parent._heightValue.truncateToDouble() ==
                      widget.parent._heightValue
                  ? 0
                  : 1,
            ),
            unit: widget.parent._heightUnit,
            units: const ['cm', 'in'],
            onChangedValue: (value) {
              final parsed = double.tryParse(value) ?? 0;
              widget.parent.setState(() => widget.parent._heightValue = parsed);
            },
            onChangedUnit: (value) {
              widget.parent.setState(() => widget.parent._heightUnit = value);
            },
          ),
          _unitTextField(
            label: 'Weight',
            value: widget.parent._weightValue.toStringAsFixed(
              widget.parent._weightValue.truncateToDouble() ==
                      widget.parent._weightValue
                  ? 0
                  : 1,
            ),
            unit: widget.parent._weightUnit,
            units: const ['kg', 'lbs'],
            onChangedValue: (value) {
              final parsed = double.tryParse(value) ?? 0;
              widget.parent.setState(() => widget.parent._weightValue = parsed);
            },
            onChangedUnit: (value) {
              widget.parent.setState(() => widget.parent._weightUnit = value);
            },
          ),
          const SizedBox(height: 20),
          const Text(
            'Body Metrics',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: DropdownButtonFormField<String>(
              initialValue: widget.parent._sex,
              decoration: InputDecoration(
                labelText: 'Sex',
                filled: true,
                fillColor: kMissionFitSurfaceStrong,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
              items: const ['Male', 'Female']
                  .map(
                    (value) => DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                widget.parent.setState(() => widget.parent._sex = value);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: DropdownButtonFormField<String>(
              initialValue: widget.parent._activityLevel,
              decoration: InputDecoration(
                labelText: 'Activity Level',
                filled: true,
                fillColor: kMissionFitSurfaceStrong,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
              items:
                  const ['Sedentary', 'Light', 'Moderate', 'Active', 'Extreme']
                      .map(
                        (value) => DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        ),
                      )
                      .toList(),
              onChanged: (value) {
                if (value == null) return;
                widget.parent.setState(
                  () => widget.parent._activityLevel = value,
                );
              },
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                await widget.parent._saveSettings();
                if (!mounted) return;
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Settings saved locally')),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: kMissionFitAccent,
                foregroundColor: kMissionFitDominant,
              ),
              child: const Text('Save Settings'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _settingField(
    String label,
    String value,
    ValueChanged<String> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        initialValue: value,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: kMissionFitSurfaceStrong,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
        onChanged: onChanged,
      ),
    );
  }

  Widget _unitTextField({
    required String label,
    required String value,
    required String unit,
    required List<String> units,
    required ValueChanged<String> onChangedValue,
    required ValueChanged<String> onChangedUnit,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: TextFormField(
              initialValue: value,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              decoration: InputDecoration(
                labelText: label,
                filled: true,
                fillColor: kMissionFitSurfaceStrong,
                border: OutlineInputBorder(
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(14),
                  ),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: onChangedValue,
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 92,
            child: DropdownButtonFormField<String>(
              initialValue: units.contains(unit) ? unit : units.first,
              decoration: InputDecoration(
                filled: true,
                fillColor: kMissionFitSurfaceStrong,
                border: OutlineInputBorder(
                  borderRadius: const BorderRadius.horizontal(
                    right: Radius.circular(14),
                  ),
                  borderSide: BorderSide.none,
                ),
              ),
              items: units
                  .map(
                    (item) => DropdownMenuItem<String>(
                      value: item,
                      child: Text(item),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  onChangedUnit(value);
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
