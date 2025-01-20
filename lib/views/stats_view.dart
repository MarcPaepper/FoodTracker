import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:food_tracker/services/data/data_service.dart';
import 'package:food_tracker/utility/theme.dart';
import 'package:food_tracker/widgets/loading_page.dart';
import 'package:food_tracker/widgets/multi_stream_builder.dart';
import 'package:food_tracker/widgets/spacer_row.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/data/data_objects.dart';
import '../widgets/border_box.dart';
import '../widgets/datetime_selectors.dart';

import 'dart:developer' as devtools show log;


class StatsView extends StatefulWidget {
  final ValueNotifier<DateTime> globalDateTimeNotifier;
  
  const StatsView(
    this.globalDateTimeNotifier,
    {Key? key}
  ) : super(key: key);

  @override
  State<StatsView> createState() => _StatsViewState();
}

enum CalculationMethod {
  sum,
  avg,
}

class _StatsViewState extends State<StatsView> {
  late final DataService _dataService;
  Map<Target, bool> _activeTargets = {};
  TimeFrame _timeFrame = TimeFrame.day;
  CalculationMethod _calculationMethod = CalculationMethod.sum;
  bool includeEmptyDays = false;
  final ValueNotifier<DateTime> _dateTimeNotifier = ValueNotifier(DateTime.now());
  
  final textStyle = GoogleFonts.lato().copyWith(
    fontSize: 16,
    fontVariations: const [FontVariation('wdth', 150)], // Adjust 'wdth' value to stretch
  );
  
  @override
  void initState() {
    _dataService = DataService.current();
    super.initState();
  }
    
  @override
  Widget build(BuildContext context) {
    return MultiStreamBuilder(
      streams: [
        _dataService.streamProducts(),
        _dataService.streamNutritionalValues(),
        _dataService.streamTargets(),
        _dataService.streamMeals(),
      ],
      builder: (context, snapshots) {
        Widget? msg;
        
        if (snapshots.any((snap) => snap.hasError)) {
          msg = Text("Error: ${snapshots.firstWhere((snap) => snap.hasError).error}");
        } else if (snapshots.any((snap) => snap.connectionState == ConnectionState.waiting)) {
          msg = const Column(
            children: [
              SizedBox(height: 130),
              LoadingPage(),
            ],
          );
        }
        
        if (msg != null) {
          return msg;
        }
        
        final products = snapshots[0].data as List<Product>;
        final productsMap = Map<int, Product>.fromEntries(products.map((product) => MapEntry(product.id, product)));
        final nutvalues = snapshots[1].data as List<NutritionalValue>;
        final targets = snapshots[2].data as List<Target>;
        final meals = snapshots[3].data as List<Meal>;
        
        // check if there are new targets
        if (targets.any((target) => !_activeTargets.containsKey(target))) {
          var copy = Map<Target, bool>.from(_activeTargets);
          for (var target in targets) {
            if (!_activeTargets.containsKey(target)) {
              copy[target] = target.isPrimary;
            }
          }
          _activeTargets = copy;
        }
        
        bool isGlobal = _timeFrame == TimeFrame.day;
        ValueNotifier<DateTime> notifier = isGlobal ? widget.globalDateTimeNotifier : _dateTimeNotifier;
        
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Timeframe Dropdown
              Table(
                defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                columnWidths: const {
                  0: IntrinsicColumnWidth(),
                  1: IntrinsicColumnWidth(),
                  2: FlexColumnWidth(),
                },
                children: [
                  TableRow(
                    children: [
                      const Text("Timeframe:", style: TextStyle(fontSize: 16)),
                      const SizedBox(width: 12),
                      DropdownButtonFormField<TimeFrame>(
                        value: _timeFrame,
                        decoration: dropdownStyleEnabled,
                        onChanged: (TimeFrame? value) {
                          setState(() {
                            _timeFrame = value!;
                            if (value == TimeFrame.week) {
                              // set to monday
                              _dateTimeNotifier.value = DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1));
                            } else if (value == TimeFrame.month) {
                              // set to 10th of the month
                              _dateTimeNotifier.value = DateTime(DateTime.now().year, DateTime.now().month, 10);
                            }
                          });
                        },
                        items: [
                          DropdownMenuItem(
                            value: TimeFrame.day,
                            child: Text("Daily", style: textStyle),
                          ),
                          DropdownMenuItem(
                            value: TimeFrame.week,
                            child: Text("Weekly", style: textStyle),
                          ),
                          DropdownMenuItem(
                            value: TimeFrame.month,
                            child: Text("Monthly", style: textStyle),
                          ),
                        ],
                      ),
                    ]
                  ),
                  ...isGlobal ? [] : [
                    getSpacerRow(elements: 3, height: 12),
                    TableRow(
                      children: [
                        const Text("Calculate:", style: TextStyle(fontSize: 16)),
                        const SizedBox(width: 12),
                        DropdownButtonFormField<CalculationMethod>(
                          value: _calculationMethod,
                          decoration: dropdownStyleEnabled,
                          onChanged: (CalculationMethod? value) {
                            setState(() {
                              _calculationMethod = value!;
                            });
                          },
                          items: [
                            DropdownMenuItem(
                              value: CalculationMethod.avg,
                              child: Text("Daily Average", style: textStyle),
                            ),
                            DropdownMenuItem(
                              value: CalculationMethod.sum,
                              child: Text("Cumulative Sum", style: textStyle),
                            ),
                          ],
                        ),
                      ]
                    ),
                  ],
                ],
              ),
              ... (!isGlobal && _calculationMethod == CalculationMethod.avg) ? [
                const SizedBox(height: 10),
                SwitchListTile(
                  title: const Text("Include days with 0 meals", style: TextStyle(fontSize: 16)),
                  value: includeEmptyDays,
                  // controlAffinity: ListTileControlAffinity.leading,
                  visualDensity: VisualDensity.compact,
                  contentPadding: const EdgeInsets.all(0),
                  onChanged: (bool value) {
                    setState(() {
                      includeEmptyDays = value;
                    });
                  },
                ),
                const SizedBox(height: 10),
              ] : [const SizedBox(height: 14)],
              getDateTimeRow(context, false, null, _timeFrame, notifier, (newDT) => notifier.value = newDT),
              const SizedBox(height: 12),
              _buildTargetSelector(targets, productsMap, nutvalues),
            ],
          ),
        );
      }
    );
  }
  
  Widget _buildTargetSelector(List<Target> targets, Map<int, Product> productsMap, List<NutritionalValue> nutvalues) {
    return BorderBox(
      title: "Show Targets",
      child: ListTileTheme(
        contentPadding: const EdgeInsets.fromLTRB(8, 0, 0, 0),
        horizontalTitleGap: 6,
        child: Column(
          children: targets.map((target) {
            String name;
            if (target.trackedType == NutritionalValue) {
              var nutvalue = nutvalues.firstWhereOrNull((nutvalue) => nutvalue.id == target.trackedId);
              name = nutvalue?.name ?? "Unknown Nutritional Value";
            } else {
              var product = productsMap[target.trackedId];
              name = product?.name ?? "Unknown Product";
            }
            
            return CheckboxListTile(
              title: Text(name, style: const TextStyle(fontSize: 16)),
              value: _activeTargets[target],
              dense: true,
              controlAffinity: ListTileControlAffinity.leading,
              visualDensity: const VisualDensity(vertical: -1),
              onChanged: (bool? value) {
                setState(() {
                  _activeTargets[target] = value!;
                });
              },
            );
          }).toList(),
        ),
      ),
    );
  }
}