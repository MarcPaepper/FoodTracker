// ignore_for_file: curly_braces_in_flow_control_structures


import 'package:flutter/material.dart';
import 'package:food_tracker/subviews/daily_targets_box.dart';
import 'package:food_tracker/widgets/datetime_selectors.dart';
import 'package:food_tracker/widgets/multi_value_listenable_builder.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../constants/ui.dart';
import '../services/data/data_objects.dart';
import '../services/data/data_service.dart';
import '../utility/theme.dart';
import 'food_box.dart';

import 'dart:developer' as devtools show log;

import 'multi_opacity.dart';

class AddMealBox extends StatefulWidget {
  // final DateTime copyDateTime;
  final ValueNotifier<DateTime> dateTimeNotifier;
  final Function(DateTime) onDateTimeChanged;
  final Map<int, Product> productsMap;
  final Function() onScrollButtonClicked;
  final Function((double, bool)) onVisibilityChanged;
  
  const AddMealBox({
    // required this.copyDateTime,
    required this.dateTimeNotifier,
    required this.onDateTimeChanged,
    required this.productsMap,
    required this.onScrollButtonClicked,
    required this.onVisibilityChanged,
    super.key,
  });

  @override
  State<AddMealBox> createState() => _AddMealBoxState();
}

class _AddMealBoxState extends State<AddMealBox> with AutomaticKeepAliveClientMixin {
  // late DateTime dateTime;
  late final FixedExtentScrollController _scrollController;
  
  final ValueNotifier<List<(ProductQuantity, Color)>> ingredientsNotifier = ValueNotifier([]);
  // late final ValueNotifier<DateTime> dateTimeNotifier;
  List<TextEditingController> ingredientAmountControllers = [];
  final List<FocusNode> ingredientDropdownFocusNodes = [];
  final ValueNotifier<double> stripVisibilityNotifier = ValueNotifier(0.0);
  final ValueNotifier<double> columnVisibilityNotifier = ValueNotifier(0.0);
  final ValueNotifier<bool> topVisibleNotifier = ValueNotifier(true);
    
  final _dataService = DataService.current();
  
  @override
  bool get wantKeepAlive => true;
  
  @override
  void initState() {
    var now = DateTime.now();
    now = DateTime(now.year, now.month, now.day, now.hour);
    // dateTimeNotifier = ValueNotifier<DateTime>(now);
    // dateTime = widget.copyDateTime;
    // dateTime = DateTime.now();
    
    _scrollController = FixedExtentScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // _scrollController.jumpTo(widget.dateTimeNotifier.value.hour * 38.0 * gsf);
    });
    
    super.initState();
  }
  
  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    return ListTile(
      //tileColor: Colors.green,
      minVerticalPadding: 0,
      contentPadding: const EdgeInsets.all(0.0),
      title: VisibilityDetector(
        key: const Key("Add Meal Box"),
        onVisibilityChanged: (info) {
          // calculate how many pixels are visible
          double fraction = info.visibleBounds.height / (100 * gsf);
          if (fraction > 1) fraction = 1;
          
          // check whether part of the top is concealed
          bool topHidden = info.visibleBounds.top > 0;
          if (topHidden) fraction = 1;
          
          if (fraction != stripVisibilityNotifier.value) stripVisibilityNotifier.value = fraction;
          if (fraction != columnVisibilityNotifier.value) columnVisibilityNotifier.value = fraction;
          if ((!topHidden) != topVisibleNotifier.value) topVisibleNotifier.value = !topHidden;
          
          widget.onVisibilityChanged((fraction, !topHidden));
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container( // New Meal strip
              decoration: const BoxDecoration(
                // color: Color.fromARGB(255, 200, 200, 200),
                color: Color.fromARGB(255, 197, 176, 202),
              ),
              child: const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 5 * gsf),
                  child: Text("New Meal"),
                ),
              ),
            ),
            const SizedBox(height: 14 * gsf),
            Padding( // daily targets box
              padding: const EdgeInsets.symmetric(horizontal: 12 * gsf),
              child: MultiValueListenableBuilder(
                listenables: [widget.dateTimeNotifier, ingredientsNotifier],
                builder: (context, values, child) {
                  DateTime dateTime = values[0];
                  List<(ProductQuantity, Color)> ingredients = values[1];
                  
                  return DailyTargetsBox(
                    dateTime,
                    ingredients,
                    null,
                    (newIngredients) => ingredientsNotifier.value = newIngredients,
                    FoldMode.startUnfolded,
                    false,
                    false,
                  );
                },
              ),
            ),
            VisibilityDetector(
              key: const Key("Add Meal Column"),
              onVisibilityChanged: (info) {
                double fraction = info.visibleFraction;
                fraction = fraction > 0 ? 1 : stripVisibilityNotifier.value;
                if (columnVisibilityNotifier.value != fraction) columnVisibilityNotifier.value = fraction;
                widget.onVisibilityChanged((fraction, topVisibleNotifier.value));
              },
              child: Column(
                children: [
                  const SizedBox(height: 14 * gsf),
                  Padding( // date and time selectors
                    padding: const EdgeInsets.symmetric(horizontal: 12 * gsf),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _buildScrollButton(
                          widget.dateTimeNotifier,
                        ),
                        Expanded(
                          child: DateAndTimeTable(
                            dateTimeNotifier: widget.dateTimeNotifier,
                            updateDateTime:   updateDateTime,
                            scrollController: _scrollController,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6 * gsf),
                  Padding( // food box
                    padding: const EdgeInsets.symmetric(horizontal: 12 * gsf),
                    child: ValueListenableBuilder(
                      valueListenable: widget.dateTimeNotifier,
                      builder: (context, dateTime, child) {
                        return FoodBox(
                          productsMap: widget.productsMap,
                          ingredientsNotifier: ingredientsNotifier,
                          ingredientAmountControllers: ingredientAmountControllers,
                          ingredientDropdownFocusNodes: ingredientDropdownFocusNodes,
                          requestIngredientFocus: _requestIngredientFocus,
                          refDate: dateTime,
                        );
                      }
                    ),
                  ),
                  const SizedBox(height: 12 * gsf),
                  ValueListenableBuilder(
                    valueListenable: ingredientsNotifier,
                    builder: (context, ingredients, child) {
                      return _buildAddMealButton(context, ingredients.isNotEmpty);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  void updateDateTime(DateTime newDateTime) {
    // setState(() => dateTime = newDateTime); Why??
    widget.dateTimeNotifier.value = newDateTime;
    widget.onDateTimeChanged(newDateTime);
  }
  
  void _requestIngredientFocus(int index, int subIndex) {
    try {
      if (index < ingredientDropdownFocusNodes.length) {
        if (subIndex == 0) {
          // If sub index = 0, focus the product dropdown
          ingredientDropdownFocusNodes[index].requestFocus();
        } else {
          // If sub index = 1, focus the amount field
          ingredientDropdownFocusNodes[index].requestFocus();
          Future.delayed(const Duration(milliseconds: 20), () {
            for (var i = 0; i < 1; i++) FocusManager.instance.primaryFocus?.nextFocus();
          });
        }
      }
    } catch (e) {
      devtools.log("Error focusing ingredient $index: $e");
    }
  }
  
  Widget _buildScrollButton(ValueNotifier<DateTime> dateTimeNotifier) {
    return ValueListenableBuilder(
      valueListenable: dateTimeNotifier,
      builder: (context, dateTime, child) {
        var now = DateTime.now();
        bool isVisible = dateTime.isBefore(DateTime(now.year, now.month, now.day - 5));

        return Tooltip(
          message: "Scroll to selected date",
          textStyle: const TextStyle(
            fontSize: 14 * gsf,
            color: Colors.white,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: isVisible ? 39 * gsf : 0,
                height: 93 * gsf,
                child: MultiOpacity(
                  depth: 2,
                  opacity: isVisible ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: ElevatedButton(
                    style: lightButtonStyle.copyWith(
                      padding: WidgetStateProperty.all(const EdgeInsets.all(0)),
                      backgroundColor: WidgetStateProperty.all(const Color.fromARGB(255, 187, 192, 255)),
                      foregroundColor: WidgetStateProperty.all(const Color.fromARGB(255, 79, 33, 243)),
                    ),
                    onPressed: isVisible ? widget.onScrollButtonClicked : null,
                    child: MultiOpacity(
                      depth: 2,
                      opacity: isVisible ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 300),
                      child: const Icon(Icons.keyboard_double_arrow_up, size: 24 * gsf),
                    ),
                  ),
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: (isVisible ? 14 : 4) * gsf,
              ),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildAddMealButton(BuildContext context, bool enabled) {
    var style = addButtonStyle.copyWith(
      alignment: Alignment.center,
    );
    
    if (enabled) {
      style = style.copyWith(
        backgroundColor: WidgetStateProperty.all(Colors.teal.shade300),
      );
    }
    
    return ElevatedButton.icon(
      style: style.copyWith(
        padding: WidgetStateProperty.all(const EdgeInsets.symmetric(vertical: 19)),
      ),
      icon: Icon(Icons.send, color: Color.fromARGB(enabled ? 200 : 90, 0, 0, 0), size: 24 * gsf),
      iconAlignment: IconAlignment.end,
      onPressed: enabled ? () {
        _dataService.createMeals(
          ingredientsNotifier.value.map((ingredient) => Meal(
            id: -1,
            dateTime: widget.dateTimeNotifier.value,
            productQuantity: ingredient.$1,
          )).toList(),
        );
        ingredientsNotifier.value = [];
        ingredientAmountControllers.clear();
      } : null,
      label: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 4 * gsf, vertical: 0),
        child: Text("Add Meal", style: TextStyle(fontSize: 16 * gsf)),
      ),
    );
  }
}