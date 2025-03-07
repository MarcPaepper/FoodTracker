import "dart:async";
import "dart:math";

import "package:collection/collection.dart";
import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:food_tracker/services/data/async_provider.dart";
import "package:scrollable_positioned_list/scrollable_positioned_list.dart";
import "package:universal_io/io.dart";

import "../constants/routes.dart";
import "../constants/ui.dart";
import "../services/data/data_objects.dart";
import "../services/data/data_service.dart";
import "../utility/data_logic.dart";
import "../utility/text_logic.dart";
import "../utility/theme.dart";
import "../widgets/add_meal_box.dart";
import "../widgets/loading_page.dart";

import "dart:developer" as devtools show log;

import "../widgets/multi_opacity.dart";
import "../widgets/multi_value_listenable_builder.dart";
import "../widgets/search_field.dart";

const TextStyle normalProductStyle = TextStyle(fontSize: 16.5 * gsf, color: Colors.black);
const TextStyle highlightProductStyle = TextStyle(fontSize: 16.5 * gsf, color: Colors.black, backgroundColor: Color.fromARGB(80, 255, 0, 212));
const TextStyle selectedProductStyle = TextStyle(fontSize: 16.5 * gsf, color: Colors.black, backgroundColor: Color.fromARGB(255, 255, 200, 0));

class MealList extends StatefulWidget {
  final Map<int, Product>? productsMap;
  final List<Meal> meals;
  final Map<int, Meal> mealsMap;
  final ValueNotifier<DateTime> dateTimeNotifier;
  final bool loaded;
  
  const MealList({
    required this.productsMap,
    required this.meals,
    required this.mealsMap,
    required this.dateTimeNotifier,
    required this.loaded,
    super.key,
  });

  @override
  State<MealList> createState() => _MealListState();
}

class _MealListState extends State<MealList> {
  final DataService dataService = DataService.current();
  final ItemScrollController _scrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener = ItemPositionsListener.create();
  final ScrollOffsetListener _scrollOffsetListener = ScrollOffsetListener.create();
  final ValueNotifier<bool> _isButtonVisible = ValueNotifier(false);
  final ValueNotifier<List<int>?> _foundMealsNotifier = ValueNotifier(null); // If searching, contains the ids of the found meals
  final ValueNotifier<int?> _selectedMealNotifier = ValueNotifier(null); // If searching, contains the id of the highlighted meal
  final TextEditingController _searchController = TextEditingController();
  final ValueNotifier<String> _searchNotifier = ValueNotifier("");
  final ValueNotifier<double> _addMealVisibilityNotifier = ValueNotifier(1.0);
  late ValueNotifier<DateTime> dateTimeNotifier;
  
  Map<int, int> stripIndices = {}; // Key: days since 1970, Value: index of the strip in the list
  Map<int, int> mealIndices = {}; // Key: meal id, Value: index of the meal in the list
  
  @override
  void initState() {
    super.initState();
    dateTimeNotifier = widget.dateTimeNotifier;
    // _visibilityController.addListener(_updateButtonVisibility);
    _itemPositionsListener.itemPositions.addListener(_updateButtonVisibility);
  }
  
  @override
  void dispose() {
    _itemPositionsListener.itemPositions.removeListener(_updateButtonVisibility);
    _isButtonVisible.dispose();
    super.dispose();
  }

  void _updateButtonVisibility() {
    // Check the scroll position to determine visibility
    bool shouldBeVisible = _itemPositionsListener.itemPositions.value.every((position) => position.index > 35);
    if (shouldBeVisible != _isButtonVisible.value) {
      _isButtonVisible.value = shouldBeVisible;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return MultiValueListenableBuilder(
      listenables: [
        _searchNotifier,
        _selectedMealNotifier,
      ],
      builder: (context, value, child) {
        List<Widget> children = [
          AddMealBox(
            dateTimeNotifier: dateTimeNotifier,
            onDateTimeChanged: (newDateTime) => Future.delayed(const Duration(milliseconds: 100), () => AsyncProvider.changeCompDT(newDateTime)),
            productsMap: widget.productsMap ?? {},
            onScrollButtonClicked: () => _scrollToSelectedDateStrip(dateTimeNotifier.value),
            onVisibilityChanged: (visibility) => _addMealVisibilityNotifier.value = visibility,
          ),
          const SizedBox(height: 5 * gsf),
        ];
        
        children.addAll(getMealTiles(context, dataService, widget.productsMap, widget.meals, widget.mealsMap, widget.loaded));
        
        return Stack(
          children: [
            ScrollablePositionedList.builder(
              itemCount: children.length,
              itemBuilder: (context, index) => children[index],
              itemScrollController: _scrollController,
              itemPositionsListener: _itemPositionsListener,
              scrollOffsetListener: _scrollOffsetListener,
              reverse: true,
              physics: const ClampingScrollPhysics(),
              padding: EdgeInsets.zero,
            ),
            Positioned(
              bottom: 16.0 * gsf,
              left: 16.0 * gsf,
              child: ValueListenableBuilder<bool>(
                valueListenable: _isButtonVisible,
                builder: (context, isVisible, child) {
                  return SizedBox(
                    width: 45 * gsf,
                    height: 45 * gsf,
                    child: Center(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: (isVisible ? 45 : 0) * gsf,
                        height: (isVisible ? 45 : 0) * gsf,
                        child: AnimatedOpacity(
                          opacity: isVisible ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 300),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10) * gsf,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.8),
                                  blurRadius: 4.0 * gsf,
                                  spreadRadius: 0.0,
                                  offset: const Offset(-0.3, 0.2) * gsf,
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              style: lightButtonStyle.copyWith(
                                shadowColor: WidgetStateProperty.all(Colors.black),
                                padding: WidgetStateProperty.all(const EdgeInsets.all(0)),
                                backgroundColor: WidgetStateProperty.all(const Color.fromARGB(255, 182, 188, 255)),
                                foregroundColor: WidgetStateProperty.all(const Color.fromARGB(255, 41, 1, 185)),
                              ),
                              onPressed: () {
                                _scrollController.scrollTo(
                                  index: 0,
                                  duration: const Duration(milliseconds: 500),
                                  curve: Curves.easeInOut,
                                );
                              },
                              child: MultiOpacity(
                                depth: 3,
                                opacity: isVisible ? 1.0 : 0.0,
                                duration: const Duration(milliseconds: 300),
                                child: const Icon(Icons.keyboard_double_arrow_down, size: 24 * gsf),
                              ),
                            ),
                          )
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            // green search bar at the top
            Positioned(
              top: 0,
              left: 0,  // Added left constraint
              right: 0, // Added right constraint
              child: MultiValueListenableBuilder(
                listenables: [_addMealVisibilityNotifier],
                builder: (context, values, child) {
                  double visibility = 1.0 - values[0];
                  if (_searchNotifier.value.isNotEmpty) visibility = 1.0;
                  
                  return Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).appBarTheme.backgroundColor,
                    ),
                    child: SearchField(
                      textController: _searchController,
                      hintText: 'Search meals',
                      whiteMode: true,
                      isDense: true,
                      visibility: visibility,
                      onChanged: (String value) {
                        if (value != _searchNotifier.value) {
                          _searchNotifier.value = value;
                        }
                      },
                      foundMeals: _foundMealsNotifier.value,
                      selectedMeal: _selectedMealNotifier.value,
                      onMealSelected: (int mealId) {
                        _selectedMealNotifier.value = mealId;
                        int? mealIndex = mealIndices[mealId];
                        if (mealIndex != null) _scrollMealIntoView(mealIndex);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
    
  }

  List<Widget> getMealTiles(BuildContext context, DataService dataService, Map<int, Product>? productsMap, List<Meal> meals, Map<int, Meal> mealsMap, bool loaded) {
    DateTime now = DateTime.now();
    
    if (!loaded) return const [LoadingPage()];
    List<Widget> children = [];
    int childCount = 2;
    Map<int, int> newStripIndices = {};
    Map<int, int> newMealIndices = {};                                                                                                   
    DateTime lastHeader = DateTime(0);
    if (meals.isNotEmpty) {
      var lastMeal = meals[meals.length - 1];
      var lastDate = lastMeal.dateTime;
      lastHeader = DateTime(lastDate.year, lastDate.month, lastDate.day);
    }
    
    String search = _searchNotifier.value.toLowerCase();
    var searchWords = search.toLowerCase().split(" ")..removeWhere((element) => element == "");
    List<int>? foundMeals; // ids of the found meals
    
    // update the found meals list
    if (search.isEmpty) {
      _foundMealsNotifier.value = null;
      _selectedMealNotifier.value = null;
    } else {
      foundMeals = [];
      bool selectedMealStillFound = false;
      for (int i = 0; i < meals.length; i++) {
        var meal = meals[i];
        var product = productsMap?[meal.productQuantity.productId];
        var name = product?.name.toLowerCase() ?? "";
        if (searchWords.every((word) => name.contains(word))) {
          foundMeals.add(meal.id);
          if (_selectedMealNotifier.value == meal.id) selectedMealStillFound = true;
        }
      }
      if (!const ListEquality().equals(foundMeals, _foundMealsNotifier.value)) _foundMealsNotifier.value = foundMeals;
      if (!selectedMealStillFound) {
        if (foundMeals.isEmpty) {
          _selectedMealNotifier.value = null;
        } else {
          // find the nearest found meal to the current scroll position
          
          // find the lowest and highest scroll item index that is currently visible
          int lowestIndex = 10000000;
          int highestIndex = 0;
          for (var position in _itemPositionsListener.itemPositions.value) {
            if (position.index < lowestIndex) lowestIndex = position.index;
            if (position.index > highestIndex) highestIndex = position.index;
          }
          double middleIndex = (lowestIndex + highestIndex) / 2 - 3;
          if (lowestIndex == 0) middleIndex = max(0, middleIndex - 10);
          
          // select the found meal that is closest to the current scroll position
          int closestIndex = 0;
          double closestDistance = double.infinity;
          for (int i = 0; i < foundMeals.length; i++) {
            var meal = mealsMap[foundMeals[i]];
            if (meal == null) continue;
            var mealIndex = mealIndices[foundMeals[i]] ?? 0;
            double distance = (mealIndex - middleIndex).abs();
            if (distance < closestDistance) {
              closestDistance = distance;
              closestIndex = i;
            }
          }
          _selectedMealNotifier.value = foundMeals[closestIndex];
          int? mealIndex = mealIndices[foundMeals[closestIndex]];
          if (mealIndex != null) _scrollMealIntoView(mealIndex);
        }
      }
    }
    
    final textScaler = MediaQuery.textScalerOf(context);
    Map<int, Widget> pT = {}; // productTexts: Key: product id, Value: product name text
    
    String locale = kIsWeb ? Localizations.localeOf(context).toString() : Platform.localeName;
    Map<int, DateTime> dates = {};
    DateTime d1970 = DateTime(1970);
    int lastYear = 0, lastMonth = 0, lastDay = 0;
    for (Meal meal in meals) {
      var mealDate = meal.dateTime;
      if (mealDate.year == lastYear && mealDate.month == lastMonth && mealDate.day == lastDay) continue;
      mealDate = mealDate.getDateOnly();
      var daysSince1970 = daysBetween(d1970, mealDate);
      dates[daysSince1970] = mealDate;
      lastYear = mealDate.year;
      lastMonth = mealDate.month;
      lastDay = mealDate.day;
    }
    
    List<String> dateStringsList = conditionallyRemoveYear(locale, dates.values.toList(), showWeekDay: true, now: now, removeYear: YearMode.ifCurrent);
    Map<int, String> dateStrings = Map.fromIterables(dates.keys, dateStringsList);
    
    // --- Styles ---
    
    const tsProd = TextStyle(fontSize: 14 * gsf, color: Color.fromARGB(255, 0, 85, 255));
    const tsHour = TextStyle(fontSize: 14 * gsf);
    const tsSpan = TextStyle(
      fontSize: 16.5 * gsf,
      height: 1.5,
      leadingDistribution: TextLeadingDistribution.even,
      letterSpacing: 0.5,
    );
    var popupButtonStyle = ButtonStyle(
      padding: WidgetStateProperty.all<EdgeInsetsGeometry>(const EdgeInsets.symmetric(horizontal: 4, vertical: 4) * gsf),
      minimumSize: WidgetStateProperty.all<Size>(const Size(0, 0)),
    );
    
    // --- constant Widgets ---
    
    var popupEntries = const [
      PopupMenuItem(
        value: 0,
        height: 44 * gsf,
        padding: EdgeInsets.only(left: 12.0, right: 12.3),
        child: Text("Edit meal", style: tsNormal),
      ),
      PopupMenuItem(
        value: 1,
        height: 44 * gsf,
        padding: EdgeInsets.only(left: 12.0, right: 12.3),
        child: Text("Edit product", style: tsNormal),
      ),
      PopupMenuItem(
        value: 2,
        height: 44 * gsf,
        padding: EdgeInsets.only(left: 12.0, right: 12.3),
        child: Text("Delete meal", style: tsNormal),
      ),
    ];
    
    for (int i = meals.length - 1; i >= 0; i--) {
      final meal = meals[i];
      final pId = meal.productQuantity.productId;
      final product = productsMap?[pId];
      final mealDate = meal.dateTime.getDateOnly();
      
      if (pId == null) {
        devtools.log("Error: Product id of meal is null");
        continue;
      }
      
      if (lastHeader.isBefore(mealDate)) {
        devtools.log('MealList: meals are not sorted by date');
      } else if (lastHeader.isAfter(mealDate)) {
        // use days of lastHeader since 1970 as the key
        int daysSince1970 = daysBetween(d1970, lastHeader);
        newStripIndices[daysSince1970] = childCount;
        var result = getDateStrip(locale, lastHeader, dateStrings[daysSince1970]!, now);
        children.add(result.$1);
        childCount++;
        lastHeader = mealDate;
      } else if (i < meals.length - 1) {
        children.add(_buildHorizontalLine());
        childCount++;
      }
      
      var unitName = unitToString(meal.productQuantity.unit);
      if (meal.productQuantity.unit == Unit.quantity) unitName = product?.quantityName ?? "x";
      var productName = product?.name ?? 'Unknown';
      var amountText = '${truncateZeros(meal.productQuantity.amount)}\u2009$unitName';
      var hourText = '${meal.dateTime.hour}h';
      
      bool isSelected = _selectedMealNotifier.value == meal.id;
      dynamic nameText = pT[pId];
      if (nameText == null || isSelected) {
        List<InlineSpan> spans;
        if (searchWords.isEmpty || !(foundMeals?.contains(meal.id) ?? true)) {
          spans = [TextSpan(text: productName, style: normalProductStyle)];
        } else {
          var style = isSelected ? selectedProductStyle : highlightProductStyle;
          spans = highlightOccurrences(productName, searchWords, normalProductStyle, style);
        }
        nameText = RichText(
          text: TextSpan(
            style: tsSpan,
            children: spans,
          ),
          textScaler: textScaler,
        );
        if (!isSelected) pT[pId] = nameText;
      }
      
      children.add(
        ListTile(
          title: Row(
            children: [
              const SizedBox(width: 12 * gsf),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 2.5 * gsf), // anti gsf
                    nameText,
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(amountText, style: tsProd),//, height: 1)),
                        Text(hourText, style: tsHour),//, height: 1)),
                      ],
                    ),
                    const SizedBox(height: 2 * gsf), // anti gsf
                  ],
                ),
              ),
              PopupMenuButton(
                iconSize: 24 * gsf,
                style: popupButtonStyle,
                itemBuilder: (context) => popupEntries,
                onSelected: (int value) {
                  if (value == 0) {
                    // edit meal
                    Navigator.pushNamed(context, editMealRoute, arguments: meal.id);
                  } else if (value == 1) {
                    // edit product
                    var prodName = product?.name;
                    if (prodName != null) Navigator.pushNamed(context, editProductRoute, arguments: (prodName, false));
                  } else if (value == 2) {
                    // delete
                    dataService.deleteMeal(meal.id);
                  }
                },
              ),
              const SizedBox(width: kIsWeb ? 6 * gsf : 0),
            ],
          ),
          minVerticalPadding: 0,
          visualDensity: const VisualDensity(vertical: -4, horizontal: 0),
          contentPadding: EdgeInsets.zero,
        ),
      );
      childCount++;
      newMealIndices[meal.id] = childCount - 3;
    }
    
    if (meals.isNotEmpty) {
      int daysSince1970 = daysBetween(d1970, lastHeader);
      newStripIndices[daysSince1970] = childCount;
      children.add(getDateStrip(locale, lastHeader, dateStrings[daysSince1970]!, now).$1);
      childCount++;
    }
    
    children.add(
      Container(
        height: 54 * gsf,
        color: Colors.grey.shade300,
      )
    );
    
    if (!mapEquals(stripIndices, newStripIndices)) {
      stripIndices = newStripIndices;
    }
    if (!mapEquals(mealIndices, newMealIndices)) {
      mealIndices = newMealIndices;
    }
    
    return children;
  }

  Widget _buildHorizontalLine() =>
    const Divider(
      indent: 7 * gsf,
      endIndent: 10 * gsf,
      height: 1 * gsf,
      thickness: 1 * gsf,
    );

  (Widget, double, double) getDateStrip(String locale, DateTime dateTime, String dateString, DateTime now) {
    // Convert date to natural string
    String text;
    int relativeDays = dateTime.difference(DateTime.now()).inDays.abs();
    DateTime now1 = DateTime.now();
    double dur1 = 0;
    if (relativeDays <= 7) {
      text = "${relativeDaysNatural(dateTime, now)} ($dateString)";
    } else {
      text = dateString;
      dur1 = DateTime.now().difference(now1).inMicroseconds.toDouble();
    }
    now1 = DateTime.now();
    
    Widget p = Padding(
      padding: const EdgeInsets.only(top: 3, bottom: 1.5) * gsf,
      // key: key,
      child: Container(
        color: const Color.fromARGB(255, 200, 200, 200),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 0) * gsf,
            child: Text(text, style: const TextStyle(fontSize: 15.5 * gsf)),
          ),
        ),
      ),
    );
    double dur2 = DateTime.now().difference(now1).inMicroseconds.toDouble();
    return (p, dur1, dur2);
  }
  
  void _scrollToSelectedDateStrip(DateTime targetDate) {
    // convert date to days since 1970
    int daysSince1970 = daysBetween(DateTime(1970), targetDate);
    devtools.log("Trying to scroll to $daysSince1970");
    // find the nearest date in the stripKeys after the target date
    int? closestDate;
    for (int date in stripIndices.keys) {
      if (date >= daysSince1970 && (closestDate == null || date < closestDate)) {
        closestDate = date;
      }
    }
    // if none was found, find the nearest date before the target date
    if (closestDate == 0) {
      for (int date in stripIndices.keys) {
        if (date < daysSince1970 && (closestDate == null || date > closestDate)) {
          closestDate = date;
        }
      }
    }
    devtools.log("Closest date: $closestDate");
    if (closestDate == null) return;
    
    // Find the first date after the closest date
    int nextDate = closestDate;
    // for (int date in stripKeys.keys) {
    // reverse order
    for (int i = stripIndices.keys.length - 1; i >= 0; i--) {
      int date = stripIndices.keys.elementAt(i);
      if (date > closestDate) {
        nextDate = date;
        break;
      }
    }
    
    int scrollToIndex = stripIndices[closestDate]!;
    if (nextDate != closestDate) {
      scrollToIndex = stripIndices[nextDate]! + 1;
    }
    
    _scrollController.scrollTo(
      index: scrollToIndex,
      duration: const Duration(milliseconds: 1000),
      curve: Curves.easeOut,
    );
  }
  
  void _scrollMealIntoView(int mealIndex) {
    // Check whether the meal is already visible
    var positions = _itemPositionsListener.itemPositions.value;
    int lowestIndex = 10000000;
    int highestIndex = 0;
    for (var position in positions) {
      if (position.index < lowestIndex) lowestIndex = position.index;
      if (position.index > highestIndex) highestIndex = position.index;
    }
    int span = highestIndex - lowestIndex;
    double lowIndex = lowestIndex + min(0.25 * span, 1);
    double highIndex = highestIndex - min(0.25 * span, 5);
    devtools.log("Lowest $lowestIndex, low $lowIndex, target $mealIndex, high $highIndex, highest $highestIndex, span $span");
    if (mealIndex > lowIndex && mealIndex < highIndex) return;
    
    _scrollController.scrollTo(
      index: mealIndex,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      alignment: 0.35,
    );
  }
}