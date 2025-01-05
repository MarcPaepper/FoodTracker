// ignore_for_file: curly_braces_in_flow_control_structures


import 'package:flutter/material.dart';
import 'package:food_tracker/subviews/daily_targets_box.dart';
import 'package:food_tracker/widgets/datetime_selectors.dart';
import 'package:food_tracker/widgets/multi_value_listenable_builder.dart';

import '../services/data/data_objects.dart';
import '../services/data/data_service.dart';
import '../utility/theme.dart';
import 'food_box.dart';

import 'dart:developer' as devtools show log;

class AddMealBox extends StatefulWidget {
  // final DateTime copyDateTime;
  final ValueNotifier<DateTime> dateTimeNotifier;
  final Function(DateTime) onDateTimeChanged;
  final Map<int, Product> productsMap;
  final Function() onScrollButtonClicked;
  
  const AddMealBox({
    // required this.copyDateTime,
    required this.dateTimeNotifier,
    required this.onDateTimeChanged,
    required this.productsMap,
    required this.onScrollButtonClicked,
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
      _scrollController.jumpTo(widget.dateTimeNotifier.value.hour * 38.0);
    });
    
    super.initState();
  }
  
  @override
  Widget build(BuildContext context) {
    super.build(context);
    // devtools.log("Building AddMealBox");
    return ListTile(
      //tileColor: Colors.green,
      minVerticalPadding: 0,
      contentPadding: const EdgeInsets.all(0.0),
      title: Column(
        
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            decoration: const BoxDecoration(
              // color: Color.fromARGB(255, 200, 200, 200),
              color: Color.fromARGB(255, 197, 176, 202),
            ),
            child: const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 5),
                child: Text("New Meal"),
              ),
            ),
          ),
          const SizedBox(height: 14),
          MultiValueListenableBuilder(
            listenables: [widget.dateTimeNotifier, ingredientsNotifier],
            builder: (context, values, child) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: DailyTargetsBox(
                  values[0],
                  values[1],
                  (ingredients) {
                    ingredientsNotifier.value = ingredients;
                    Future(() {
                      setState(() {});
                    });
                  },
                  false,
                  false,
                ),
              );
            },
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
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
            )
          ),
          const SizedBox(height: 6),
          ValueListenableBuilder(
            valueListenable: widget.dateTimeNotifier,
            builder: (context, dateTime, child) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: FoodBox(
                  productsMap: widget.productsMap,
                  ingredientsNotifier: ingredientsNotifier,
                  ingredientAmountControllers: ingredientAmountControllers,
                  ingredientDropdownFocusNodes: ingredientDropdownFocusNodes,
                  requestIngredientFocus: _requestIngredientFocus,
                  refDate: dateTime,
                ),
              );
            }
          ),
          const SizedBox(height: 12),
          ValueListenableBuilder(
            valueListenable: ingredientsNotifier,
            builder: (context, ingredients, child) {
              return _buildAddMealButton(context, ingredients.isNotEmpty);
            },
          ),
        ],
      ),
    );
  }
  
  void updateDateTime(DateTime newDateTime) {
    // setState(() => dateTime = newDateTime);
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

        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: isVisible ? 39 : 0,
              height: 93,
              child: AnimatedOpacity(
                opacity: isVisible ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: AnimatedOpacity(
                  opacity: isVisible ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: ElevatedButton(
                    style: lightButtonStyle.copyWith(
                      padding: WidgetStateProperty.all(const EdgeInsets.all(0)),
                      backgroundColor: WidgetStateProperty.all(const Color.fromARGB(255, 187, 192, 255)),
                      foregroundColor: WidgetStateProperty.all(const Color.fromARGB(255, 79, 33, 243)),
                    ),
                    onPressed: isVisible ? widget.onScrollButtonClicked : null,
                    child: AnimatedOpacity(
                      opacity: isVisible ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 300),
                      child: AnimatedOpacity(
                        opacity: isVisible ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 300),
                        child: const Icon(Icons.keyboard_double_arrow_up)
                      ),
                    ),
                  ),
                ),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: isVisible ? 14 : 4,
            ),
          ],
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
      style: style,
      icon: Icon(Icons.send, color: Color.fromARGB(enabled ? 200 : 90, 0, 0, 0),),
      iconAlignment: IconAlignment.end,
      onPressed: enabled ? () {
        for (var ingredient in ingredientsNotifier.value) {
          _dataService.createMeal(
            Meal(
              id: -1,
              dateTime: widget.dateTimeNotifier.value,
              productQuantity: ingredient.$1,
            ),
          );
        }
        ingredientsNotifier.value = [];
        ingredientAmountControllers.clear();
      } : null,
      label: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 4),
        child: Text("Add Meal"),
      ),
    );
  }
}