import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:food_tracker/services/data/data_service.dart';
import 'package:food_tracker/utility/theme.dart';
import 'package:food_tracker/widgets/loading_page.dart';
import 'package:food_tracker/widgets/multi_stream_builder.dart';
import 'package:food_tracker/widgets/multi_value_listenable_builder.dart';
import 'package:food_tracker/widgets/spacer_row.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/ui.dart';
import '../services/data/data_objects.dart';
import '../subviews/daily_targets_box.dart';
import '../utility/data_logic.dart';
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

class _StatsViewState extends State<StatsView> with AutomaticKeepAliveClientMixin {
  late final DataService _dataService;
  Map<Target, bool> _activeTargets = {};
  bool _isLineGraph = false;
  TimeFrame _timeFrame = TimeFrame.day;
  CalculationMethod _calculationMethod = CalculationMethod.avg;
  bool includeEmptyDays = false;
  final ValueNotifier<DateTime> _dateTimeNotifier = ValueNotifier(DateTime.now());
  bool sortByRelevancy = true;
  
  List<Meal> relevantMeals = [];
  
  int hash = 0;
  (Map<Target, Map<Product?, double>>, List<Product>)? dailyTargetProgressData;
  
  final textStyle = GoogleFonts.lato().copyWith(
    fontSize: 16 * gsf,
    fontVariations: const [FontVariation('wdth', 150)], // Adjust 'wdth' value to stretch
    color: Colors.black,
  );
  
  @override
  void initState() {
    _dataService = DataService.current();
    super.initState();
  }
  
  @override
  bool get wantKeepAlive => true;
    
  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    return MultiValueListenableBuilder(
      listenables: [
        _dateTimeNotifier,
        widget.globalDateTimeNotifier,
      ],
      builder: (context, values, child) {
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
                  SizedBox(height: 130 * gsf),
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
            
            // hash consists of products, nutvalues, targets, meals and settings
            ListEquality leq = const ListEquality();
            MapEquality meq = const MapEquality();
            int newHash = Object.hash(leq.hash(products), leq.hash(nutvalues), leq.hash(targets), leq.hash(meals), meq.hash(_activeTargets), _timeFrame, _calculationMethod, includeEmptyDays, sortByRelevancy, notifier.value);
            if (hash != newHash) {
              DateTime start = notifier.value;
              DateTime end;
              if (_timeFrame == TimeFrame.day) {
                end = start;
              } else if (_timeFrame == TimeFrame.week) {
                end = start.add(const Duration(days: 6));
              } else {
                end = start.add(const Duration(days: 30));
                end = DateTime(end.year, end.month, 1);
                end = end.subtract(const Duration(days: 1));
                start = DateTime(start.year, start.month, 1);
              }
              relevantMeals = meals.where((meal) => isDateInsideInterval(meal.dateTime, start, end) == 0).toList();
              var activeTargets = _activeTargets.entries.where((entry) => entry.value).map((entry) => entry.key.copyWith(newIsPrimary: true)).toList();
              dailyTargetProgressData = getDailyTargetProgress(notifier.value, activeTargets, productsMap, nutvalues, relevantMeals, [], sortByRelevancy, maxProducts: 1000);
              hash = newHash;
              if (!isGlobal && _calculationMethod == CalculationMethod.avg) { // calculate daily average
                var dt1970 = DateTime(1970);
                // count how many days have at least one meal
                int startDay = daysBetween(dt1970, start);
                int endDay = daysBetween(dt1970, end);
                int dayCount = endDay - startDay + 1;
                if (!includeEmptyDays) {
                  Set<int> days = {};
                  for (var meal in relevantMeals) {
                    days.add(daysBetween(dt1970, meal.dateTime));
                  }
                  dayCount = days.length;
                }
                // divide all values by dayCount
                if (dayCount != 0) {
                  dailyTargetProgressData = (dailyTargetProgressData!.$1.map((target, map) {
                    var newMap = Map<Product?, double>.fromEntries(map.entries.map((entry) {
                      double newValue = entry.value / dayCount;
                      return MapEntry(entry.key, newValue);
                    }));
                    return MapEntry(target, newMap);
                  }), dailyTargetProgressData!.$2);
                }
              }
            }
            
            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 13) * gsf,
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
                        // // dropdown to select line / bar graph
                        // TableRow(
                        //   children: [
                        //     const Text("Graph type:", style: TextStyle(fontSize: 16 * gsf)),
                        //     const SizedBox(width: 12 * gsf),
                        //     DropdownButtonFormField<bool>( // TODO: add icon
                        //       value: _isLineGraph,
                        //       decoration: dropdownStyleEnabled,
                        //       style: const TextStyle(fontSize: (kIsWeb ? 47 : 40) * gsf, color: Colors.black),
                        //       icon: const Icon(Icons.arrow_drop_down),
                        //       iconSize: 24 * gsf,
                        //       isDense: true,
                        //       isExpanded: true,
                        //       onChanged: (bool? value) {
                        //         if (value == null || value == _isLineGraph) return;
                        //         setState(() => _isLineGraph = value);
                        //       },
                        //       items: [
                        //         DropdownMenuItem(
                        //           value: true,
                        //           child: Padding(
                        //             padding: const EdgeInsets.symmetric(vertical: 25 * gsf - 25),
                        //             child: Text("Line Graph", style: textStyle),
                        //           ),
                        //         ),
                        //         DropdownMenuItem(
                        //           value: false,
                        //           child: Padding(
                        //             padding: const EdgeInsets.symmetric(vertical: 25 * gsf - 25),
                        //             child: Text("Bar Graph", style: textStyle),
                        //           ),
                        //         ),
                        //       ],
                        //     ),
                        //   ]
                        // ),
                        // getSpacerRow(elements: 3, height: 12 * gsf),
                        TableRow(
                          children: [
                            const Text("Timeframe:", style: TextStyle(fontSize: 16 * gsf)),
                            const SizedBox(width: 12 * gsf),
                            DropdownButtonFormField<TimeFrame>(
                              value: _timeFrame,
                              decoration: dropdownStyleEnabled,
                              style: const TextStyle(fontSize: (kIsWeb ? 47 : 40) * gsf, color: Colors.black),
                              icon: const Icon(Icons.arrow_drop_down),
                              iconSize: 24 * gsf,
                              isDense: true,
                              isExpanded: true,
                              onChanged: (TimeFrame? value) {
                                setState(() {
                                  _timeFrame = value!;
                                  if (value == TimeFrame.week) {
                                    // set to monday
                                    DateTime newDT = DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1));
                                    _dateTimeNotifier.value = DateTime(newDT.year, newDT.month, newDT.day);
                                  } else if (value == TimeFrame.month) {
                                    // set to 10th of the month
                                    _dateTimeNotifier.value = DateTime(DateTime.now().year, DateTime.now().month, 10);
                                  }
                                });
                              },
                              items: [
                                DropdownMenuItem(
                                  value: TimeFrame.day,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 25 * gsf - 25),
                                    child: Text("Daily", style: textStyle),
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: TimeFrame.week,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 25 * gsf - 25),
                                    child: Text("Weekly", style: textStyle),
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: TimeFrame.month,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 25 * gsf - 25),
                                    child: Text("Monthly", style: textStyle),
                                  ),
                                ),
                              ],
                            ),
                          ]
                        ),
                        ...isGlobal ? [] : [
                          getSpacerRow(elements: 3, height: 12 * gsf),
                          TableRow(
                            children: [
                              const Text("Calculate:", style: TextStyle(fontSize: 16 * gsf)),
                              const SizedBox(width: 12 * gsf),
                              DropdownButtonFormField<CalculationMethod>(
                                value: _calculationMethod,
                                decoration: dropdownStyleEnabled,
                                style: const TextStyle(fontSize: (kIsWeb ? 47 : 40) * gsf, color: Colors.black),
                                icon: const Icon(Icons.arrow_drop_down),
                                iconSize: 24 * gsf,
                                isDense: true,
                                isExpanded: true,
                                onChanged: (CalculationMethod? value) {
                                  setState(() {
                                    _calculationMethod = value!;
                                  });
                                },
                                items: [
                                  DropdownMenuItem(
                                    value: CalculationMethod.avg,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 25 * gsf - 25),
                                      child: Text("Daily Average", style: textStyle),
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value: CalculationMethod.sum,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 25 * gsf - 25),
                                      child: Text("Cumulative Sum", style: textStyle),
                                    ),
                                  ),
                                ],
                              ),
                            ]
                          ),
                        ],
                      ],
                    ),
                    ... (!isGlobal && _calculationMethod == CalculationMethod.avg) ? [
                      const SizedBox(height: 10 * gsf),
                      SwitchListTile(
                        title: const Text("Include days with 0 meals", style: TextStyle(fontSize: 16 * gsf)),
                        value: includeEmptyDays,
                        // controlAffinity: ListTileControlAffinity.leading,
                        visualDensity: VisualDensity.compact,
                        dense: true,
                        contentPadding: const EdgeInsets.all(0),
                        onChanged: (bool value) {
                          setState(() {
                            includeEmptyDays = value;
                          });
                        },
                      ),
                      const SizedBox(height: 10 * gsf),
                    ] : [const SizedBox(height: 14 * gsf)],
                    getDateTimeRow(context, false, null, _timeFrame, notifier, (newDT) => notifier.value = newDT),
                    const SizedBox(height: 12 * gsf),
                    _buildGraphBox(productsMap, nutvalues, targets),
                    const SizedBox(height: 12 * gsf),
                    _buildSortingSelector(),
                    const SizedBox(height: 12 * gsf),
                    _buildTargetSelector(targets, productsMap, nutvalues),
                  ],
                ),
              ),
            );
          }
        );
      }
    );
  }
  
  Widget _buildGraphBox(Map<int, Product> productsMap, List<NutritionalValue> nutvalues, List<Target> targets) {
    if (dailyTargetProgressData == null) {
      return const LoadingPage();
    }
    
    var isGlobal = _timeFrame == TimeFrame.day;
    ValueNotifier<DateTime> notifier = isGlobal ? widget.globalDateTimeNotifier : _dateTimeNotifier;
    
    Map<Target, Map<Product?, double>> progress = dailyTargetProgressData!.$1;
    List<Product> contributingProducts = dailyTargetProgressData!.$2;
    List<(ProductQuantity, Color)> ingredients = [];
    for (int i = 0; i < contributingProducts.length; i++) {
      Product product = contributingProducts[i];
      ingredients.add((ProductQuantity(productId: product.id, amount: 1, unit: product.defaultUnit), productColors[i % productColors.length]));
      // devtools.log("product $i: ${product.name} color: ${productColors[i % productColors.length]}");
    }
    
    TimeFormat tf;
    switch (_timeFrame) {
      case TimeFrame.day:
        tf = TimeFormat.hours;
        break;
      case TimeFrame.week:
        tf = TimeFormat.weekdays;
        break;
      case TimeFrame.month:
      default:
        tf = TimeFormat.days;
        break;
    }
    
    return DailyTargetsBox(
      notifier.value,
      ingredients,
      relevantMeals,
      (newIngredients) => devtools.log("new ingredients: $newIngredients"),
      FoldMode.neverFold,
      false,
      true,
      tf,
      null, null, null, null, null, null, null, null, null, null,
      progress,
    );
  }
  
  Widget _buildSortingSelector() {
    // return Placeholder();
    return Row(
      children: [
        const Text("Sort products by", style: TextStyle(fontSize: 16 * gsf)),
        const SizedBox(width: 12),
        Expanded(
          child: DropdownButtonFormField<bool>(
            value: sortByRelevancy,
            decoration: dropdownStyleEnabled,
            style: const TextStyle(fontSize: (kIsWeb ? 47 : 40) * gsf, color: Colors.black),
            icon: const Icon(Icons.arrow_drop_down),
            iconSize: 24,
            isDense: true,
            onChanged: (bool? value) {
              setState(() {
                sortByRelevancy = value!;
              });
            },
            items: const [
              DropdownMenuItem(
                value: true,
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 25 * gsf - 25),
                  child: Text("Relevancy", style: TextStyle(fontSize: 16 * gsf)),
                ),
              ),
              DropdownMenuItem(
                value: false,
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 25 * gsf - 25),
                  child: Text("Time (first occurence)", style: TextStyle(fontSize: 16 * gsf)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildTargetSelector(List<Target> targets, Map<int, Product> productsMap, List<NutritionalValue> nutvalues) {
    return BorderBox(
      title: "Show Targets",
      horizontalPadding: 0,
      child: ListTileTheme(
        contentPadding: const EdgeInsets.fromLTRB(8, 0, 0, 0) * gsf,
        horizontalTitleGap: 6 * gsf,
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
              title: Text(name, style: const TextStyle(fontSize: 16 * gsf)),
              value: _activeTargets[target],
              dense: true,
              controlAffinity: ListTileControlAffinity.leading,
              visualDensity: const VisualDensity(vertical: -1 * gsf),
              onChanged: (bool? value) {
                var newTargets = Map<Target, bool>.from(_activeTargets);
                newTargets[target] = value!;
                devtools.log("newTargets: $newTargets");
                setState(() {
                  _activeTargets = newTargets;
                });
              },
            );
          }).toList(),
        ),
      ),
    );
  }
}