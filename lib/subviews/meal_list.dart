import "dart:async";
import "dart:math";

import "package:collection/collection.dart";
import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:food_tracker/services/data/async_provider.dart";
import "package:scrollable_positioned_list/scrollable_positioned_list.dart";
import "package:universal_io/io.dart";
import "package:visibility_detector/visibility_detector.dart";

import "../constants/routes.dart";
import "../constants/ui.dart";
import "../services/data/data_objects.dart";
import "../services/data/data_service.dart";
import "../utility/data_logic.dart";
import "../utility/text_logic.dart";
import "../utility/theme.dart";
import "../widgets/add_meal_box.dart";
import "../widgets/expanding_sliver.dart";
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
  final ValueNotifier<(double, bool)> _addMealVisibilityNotifier = ValueNotifier((1.0,  true)); //double = fraction of top 100 pixels that are visible, bool = whether the top is visible
  final ValueNotifier<(DateTime, bool)?> _scrollNotifier = ValueNotifier(null); // The datetime which the scroll to date button was pressed + whether it was the scroll up button (true) or the scroll down button (false)
  late ValueNotifier<DateTime> dateTimeNotifier;
  
  Map<int, int> stripIndices = {}; // Key: days since 2000, Value: index of the strip in the list
  Map<int, int> mealIndices = {}; // Key: meal id, Value: index of the meal in the list
  
  final ValueNotifier<Map<int, (double, VisibilityInfo?)>> _visibleDaysNotifier = ValueNotifier({});
  // Key: days since 2000 (positive if referring to the bottom most meal of the date, negative if reffering to the date strip), Value: visible fraction of the element
  final ValueNotifier<List<int>> _allDaysNotifier = ValueNotifier([]);
  
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
    Meal? firstMeal = widget.meals.isEmpty ? null : widget.meals[0];
    int? firstDaySince2000 = firstMeal != null ? daysBetween(DateTime(2000), firstMeal.dateTime) : null;
    
    return MultiValueListenableBuilder(
      listenables: [
        _searchNotifier,
        _selectedMealNotifier,
      ],
      builder: (context, values, child) {
        List<Widget> children = [
          AddMealBox(
            dateTimeNotifier: dateTimeNotifier,
            onDateTimeChanged: (newDateTime) => Future.delayed(const Duration(milliseconds: 100), () => AsyncProvider.changeCompDT(newDateTime)),
            productsMap: widget.productsMap ?? {},
            onScrollButtonClicked: () => _scrollToSelectedDateStrip(dateTimeNotifier.value),
            onVisibilityChanged: (visibilityInfo) {
              if (_addMealVisibilityNotifier.value != visibilityInfo) {
                _addMealVisibilityNotifier.value = visibilityInfo;
                if (visibilityInfo.$1 > 0 && _scrollNotifier.value?.$2 == false) {
                  // Check whether the scroll datetime is in the future
                  DateTime now = DateTime.now();
                  if (_scrollNotifier.value!.$1.isAfter(now)) {
                    _scrollNotifier.value = (now, false);
                    // reset in 5 seconds
                    Future.delayed(const Duration(seconds: 5), () {
                      if (_scrollNotifier.value == (now, false)) {
                        _scrollNotifier.value = null;
                      }
                    });
                  }
                }
              }
            },
          ),
          const SizedBox(height: 5 * gsf),
        ];
        
        children.addAll(getMealTiles(context, dataService, widget.productsMap, widget.meals, widget.mealsMap, widget.loaded));
        
        return Column(
          verticalDirection: VerticalDirection.up,
          children: [
            Expanded(
              child: Stack(
                clipBehavior: Clip.hardEdge,
                children: [
                  ScrollablePositionedList.builder( // meal list
                    itemCount: children.length,
                    itemBuilder: (context, index) => children[index],
                    itemScrollController: _scrollController,
                    itemPositionsListener: _itemPositionsListener,
                    scrollOffsetListener: _scrollOffsetListener,
                    reverse: true,
                    physics: const ClampingScrollPhysics(),
                    padding: EdgeInsets.zero,
                  ),
                  // sticky header displaying the date of the highest visible meal
                  MultiValueListenableBuilder(
                    listenables: [
                      _visibleDaysNotifier,
                      _addMealVisibilityNotifier,
                    ],
                    builder: (context, values, child) {
                      double scrollProgress = 1.0;
                      double widthProgress = 0.0;
                      // devtools.log("Visible days: ${values[0]}");
                      if (values[0].isEmpty) return const SizedBox.shrink(); // if there are no visible days, show nothing
                      if (!values[1].$2) {
                         // If the user scrolled so far down, that the top of the add meal box is not fully visible anymore
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          _visibleDaysNotifier.value = {};
                        });
                        
                        return const SizedBox.shrink();
                      }
                      
                      // find lowest absolute value in the map. if there is a lowest positive and negative value, use the negative one
                      
                      const high = 100000000;
                      int lowestAbsKey = high;
                      int refDate2000 = high;
                      for (int key in values[0].keys) {
                        if (key.abs() < lowestAbsKey.abs()) {
                          lowestAbsKey = key;
                        } else if (key.abs() == lowestAbsKey.abs()) {
                          if (key < 0) lowestAbsKey = key;
                        }
                        
                        if (key < 0 && key.abs() < refDate2000.abs()) {
                          refDate2000 = key.abs();
                        }
                      }
                      
                      if (lowestAbsKey < 0) {
                        widthProgress = _visibleDaysNotifier.value[lowestAbsKey]!.$1;
                        if (-lowestAbsKey != firstDaySince2000) widthProgress *= 17.5 / 19.0;
                      } else {
                        // the lowest visible widget is a meal
                        var info = values[0][lowestAbsKey]!.$2;
                        
                        if (info == null) {
                          refDate2000 = lowestAbsKey.abs();
                        } else {
                          double concealedAtTop = info.visibleBounds.top;
                          double visibleAtBottom = info.size.height - concealedAtTop;
                          if (visibleAtBottom < (2.5 * gsf)) {
                            if (refDate2000 == high) return const SizedBox.shrink();
                            widthProgress = (18 + 1 * visibleAtBottom / (2.5 * gsf)) / 19.0;
                          } else {
                            scrollProgress = (visibleAtBottom - 2.5 * gsf) / (info.size.height - 2.5 * gsf);
                            refDate2000 = lowestAbsKey.abs();
                          }
                        }
                      }
                      
                      // convert days since 2000 to datetime
                      DateTime dateTime = DateTime(2000).add(Duration(days: refDate2000)).getDateOnly();
                      // convert date to natural string
                      String dateString = conditionallyRemoveYear(
                        context,
                        [dateTime],
                        showWeekDay: true,
                        removeYear: YearMode.ifCurrent,
                      ).first;
                      
                      // DateTime now = DateTime.now();
                      // int relativeDays = dateTime.difference(now.getDateOnly()).inDays.abs();
                      String text;
                      // if (relativeDays < 4) {
                      //   text = relativeDaysNatural(dateTime, now);
                      // } else {
                      text = convertToNaturalDateString(dateTime, dateString);
                      // }
                      
                      return ExpandingSliver(
                        text: text,
                        widthProgress: widthProgress,
                        scrollProgress: scrollProgress,
                      );
                    },
                  ),
                  Positioned( // scroll to bottom button
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
                                      // set notifier
                                      _scrollNotifier.value = (DateTime.now().add(const Duration(seconds: 20)), false);
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
                ],
              ),
            ),
            MultiValueListenableBuilder( // search bar
              listenables: [_addMealVisibilityNotifier],
              builder: (context, values, child) {
                double visibility = 1.0 - values[0].$1;
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
    List<int> newDays = [];
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
    DateTime d2000 = DateTime(2000);
    int lastYear = 0, lastMonth = 0, lastDay = 0;
    for (Meal meal in meals) {
      var mealDate = meal.dateTime;
      if (mealDate.year == lastYear && mealDate.month == lastMonth && mealDate.day == lastDay) continue;
      mealDate = mealDate.getDateOnly();
      var daysSince2000 = daysBetween(d2000, mealDate);
      dates[daysSince2000] = mealDate;
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
        child: Text("Copy datetime", style: tsNormal),
      ),
      PopupMenuItem(
        value: 3,
        height: 44 * gsf,
        padding: EdgeInsets.only(left: 12.0, right: 12.3),
        child: Text("Delete meal", style: tsNormal),
      ),
    ];
    
    // List<Widget> newDateChildren = [];
    for (int i = meals.length - 1; i >= 0; i--) {
      final meal = meals[i];
      final pId = meal.productQuantity.productId;
      final product = productsMap?[pId];
      final mealDate = meal.dateTime.getDateOnly();
      
      if (pId == null) {
        devtools.log("Error: Product id of meal is null");
        continue;
      }
      
      bool newDate = i == meals.length - 1;
      if (lastHeader.isBefore(mealDate)) {
        devtools.log('MealList: meals are not sorted by date');
      } else if (lastHeader.isAfter(mealDate)) {
        // meal belongs to an earlier date than current
        // children.addAll(newDateChildren);
        // newDateChildren = [];
        int daysSince2000 = daysBetween(d2000, lastHeader);
        newStripIndices[daysSince2000] = childCount;
        newDays.add(daysSince2000);
        children.add(getDateStrip(locale, lastHeader, dateStrings[daysSince2000]!, now, childCount));
        childCount++;
        lastHeader = mealDate;
        newDate = true;
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
      
      Widget newChild = ListTile(
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
                  // copy datetime to notifier
                  dateTimeNotifier.value = meal.dateTime;
                  // jump to bottom of the list
                  _scrollController.scrollTo(
                    index: 0,
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeInOut,
                  );
                } else if (value == 3) {
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
      );
      
      final int mealIndex = childCount;
      
      if (newDate) {
        newChild = VisibilityDetector(
          key: Key("Meal $mealIndex"),
          onVisibilityChanged: (VisibilityInfo info) {
            // if (info.visibleBounds.left > 0) return;
            var daysSince2000 = daysBetween(DateTime(2000), mealDate);
            // if part of the top is concealed, the strip is considered partially visible
            // if part of the bottom is concealed, the strip is considered fully visible
            double topConcealed = info.visibleBounds.top / info.size.height;
            double bottomBound = info.visibleBounds.bottom;
            double visibleFraction = 1 - topConcealed;
            if (info.visibleFraction > visibleFraction) visibleFraction = info.visibleFraction;
            if (bottomBound == 0 || info.visibleFraction == 0) visibleFraction = 0;
            
            // update the visible days map
            if (visibleFraction > 0) {
              if (_visibleDaysNotifier.value[daysSince2000]?.$1 != visibleFraction) {
                Map<int, (double, VisibilityInfo?)> visibleDays = checkContinuity(daysSince2000, _visibleDaysNotifier.value);
                
                visibleDays[daysSince2000] = (visibleFraction, info);
                _visibleDaysNotifier.value = Map.from(visibleDays);
              }
            } else {
              var positions = _itemPositionsListener.itemPositions.value;
              int lowestIndex = 10000000;
              int highestIndex = 0;
              for (var position in positions) {
                if (position.index < lowestIndex) lowestIndex = position.index;
                if (position.index > highestIndex) highestIndex = position.index;
              }
              // check whether item is below or above the middle
              
              double middleIndex = (lowestIndex + highestIndex) / 2;
              
              bool? scrolledUp;
              double? difference;
              if (_scrollNotifier.value != null) {
                difference = DateTime.now().difference(_scrollNotifier.value!.$1).inMilliseconds.toDouble() / 1000.0;
                scrolledUp = _scrollNotifier.value!.$2;
              }
              int scroll = 0;
              if (scrolledUp == true && difference! < 0.5) scroll = 1; // scrolled up
              if (scrolledUp == false && difference! < 3) scroll = -1; // scrolled down
              
              // remove if the meal is above the middle
              if ((mealIndex < middleIndex && scroll == 0 || scroll == 1) && _visibleDaysNotifier.value.keys.any((days) => days.abs() > daysSince2000)) {
                // meal exited the bottom
                _visibleDaysNotifier.value.removeWhere((key, value) => key.abs() > daysSince2000);
                _visibleDaysNotifier.value = Map.from(_visibleDaysNotifier.value);
              } else if (mealIndex > middleIndex && scroll == 0 || scroll == -1) {
                // meal exited the top
                // remove all entries at or below daysSince2000
                _visibleDaysNotifier.value.removeWhere((key, value) => key.abs() <= daysSince2000);
                _visibleDaysNotifier.value = Map.from(_visibleDaysNotifier.value);
              }
            }
          },
          child: newChild,
        );
      }
      
      children.add(newChild);
      childCount++;
      newMealIndices[meal.id] = childCount - 3;
    }
    
    // add the last date strip
    if (meals.isNotEmpty) {
      // children.addAll(newDateChildren);
      int daysSince2000 = daysBetween(d2000, lastHeader);
      newStripIndices[daysSince2000] = childCount;
      newDays.add(daysSince2000);
      children.add(getDateStrip(locale, lastHeader, dateStrings[daysSince2000]!, now, childCount, top: true));
      childCount++;
    }
    
    if (!const ListEquality().equals(newDays, _allDaysNotifier.value)) {
      _allDaysNotifier.value = newDays;
    }
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
  
  Widget getDateStrip(String locale, DateTime dateTime, String dateString, DateTime now, int index, {bool top = false}) {
    // convert date to natural string
    String text = convertToNaturalDateString(dateTime, dateString, now);
    var daysSince2000 = daysBetween(DateTime(2000), dateTime);
    
    return Padding(
      padding: EdgeInsets.only(top: top ? 4 : 3, bottom: 1.5) * gsf,
      // key: key,
      child: VisibilityDetector(
        key: Key("Date strip $daysSince2000"),
        onVisibilityChanged: (VisibilityInfo info) {
          // if part of the top is concealed, the strip is considered partially visible
          // if part of the bottom is concealed, the strip is considered fully visible
          double topConcealed = info.visibleBounds.top / info.size.height;
          double bottomVisible = info.visibleBounds.bottom / info.size.height;
          double visibleFraction = 1 - topConcealed;
          if (bottomVisible == 0 || info.visibleFraction == 0) visibleFraction = 0;
          
          // update the visible days map
          if (visibleFraction > 0) {
            if (_visibleDaysNotifier.value[-daysSince2000]?.$1 != visibleFraction) {
              _visibleDaysNotifier.value[-daysSince2000] = (visibleFraction, info);
              if (_visibleDaysNotifier.value[daysSince2000] == null) {
                _visibleDaysNotifier.value[daysSince2000] = (1, null);
              }
              _visibleDaysNotifier.value = Map.from(_visibleDaysNotifier.value);
            }
          } else {
            var positions = _itemPositionsListener.itemPositions.value;
            int lowestIndex = 10000000;
            int highestIndex = 0;
            for (var position in positions) {
              if (position.index < lowestIndex) lowestIndex = position.index;
              if (position.index > highestIndex) highestIndex = position.index;
            }
            
            // check whether item is below or above the middle
            double middleIndex = (lowestIndex + highestIndex) / 2;
            
            bool? scrolledUp;
            double? difference;
            if (_scrollNotifier.value != null) {
              difference = DateTime.now().difference(_scrollNotifier.value!.$1).inMilliseconds.toDouble() / 1000.0;
              scrolledUp = _scrollNotifier.value!.$2;
            }
            int scroll = 0;
            if (scrolledUp == true && difference! < 0.5) scroll = 1; // scrolled up
            if (scrolledUp == false && difference! < 3) scroll = -1; // scrolled down
            
            if (index < middleIndex && scroll == 0 || scroll == 1) {
              // strip exited the bottom
              // remove all entries at or above daysSince2000
              _visibleDaysNotifier.value.removeWhere((key, value) => key.abs() >= daysSince2000);
            } else {
              // strip exited the top
              // remove all entries below daysSince2000
              _visibleDaysNotifier.value.removeWhere((key, value) => key.abs() < daysSince2000);
            }
            
            // remove from the map
            _visibleDaysNotifier.value.remove(-daysSince2000);
            _visibleDaysNotifier.value = Map.from(_visibleDaysNotifier.value);
          }
        },
        child: Container( // floating date sliver
          color: const Color.fromARGB(255, 200, 200, 200),
          height: 32 * gsf,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 0) * gsf,
              child: ValueListenableBuilder(
                valueListenable: _visibleDaysNotifier,
                builder: (context, value, child) {
                  double visibleFraction = value[-daysSince2000]?.$1 ?? 1.0;
                  if (visibleFraction > 0 && visibleFraction < 1.0) {
                    return const Text("");
                  }
                  return Text(text, style: const TextStyle(fontSize: 15.5 * gsf));
                },
                child: Text(text, style: const TextStyle(fontSize: 15.5 * gsf))
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Map<int, (double, VisibilityInfo?)> checkContinuity(int daysSince2000, Map<int, (double, VisibilityInfo?)> newMap) {
    if (newMap[daysSince2000]?.$1 == null && _scrollNotifier.value?.$2 == false) {
      // The scroll down button was pressed recently
      double difference = DateTime.now().difference(_scrollNotifier.value!.$1).inMilliseconds.toDouble() / 1000.0;
      if (difference < 3) {
        // use the all days notifier to check if there are any days missing
        int lowestConsecutiveVisibleDay = daysSince2000;
        List<int> allDays = _allDaysNotifier.value;
        List<int> visibleDays = newMap.keys.map((key) => key.abs()).toSet().toList();
        for (int i = allDays.length - 1; i >= 0; i--) {
          int day = allDays[i];
          if (day > daysSince2000) continue;
          if (visibleDays.contains(day)) {
            lowestConsecutiveVisibleDay = day;
          } else {
            break;
          }
        }
        // remove all entries below lowestConsecutiveVisibleDay
        newMap.removeWhere((key, value) => key.abs() < lowestConsecutiveVisibleDay);
      }
    }
    return newMap;
  }
  
  void _scrollToSelectedDateStrip(DateTime targetDate) {
    _scrollNotifier.value = (DateTime.now().add(const Duration(seconds: 7)), true);
    // convert date to days since 2000
    int daysSince2000 = daysBetween(DateTime(2000), targetDate);
    devtools.log("Trying to scroll to $daysSince2000");
    // find the nearest date in the stripKeys after the target date
    int? closestDate;
    for (int date in stripIndices.keys) {
      if (date >= daysSince2000 && (closestDate == null || date < closestDate)) {
        closestDate = date;
      }
    }
    // if none was found, find the nearest date before the target date
    if (closestDate == 0) {
      for (int date in stripIndices.keys) {
        if (date < daysSince2000 && (closestDate == null || date > closestDate)) {
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
      curve: Curves.easeInOut,
    ).whenComplete(() {
      final now = DateTime.now();
      _scrollNotifier.value = (now, true);
      // reset after 5 seconds
      Future.delayed(const Duration(seconds: 5), () {
        if (_scrollNotifier.value == (now, true)) {
          _scrollNotifier.value =  null;
        }
      });
    });
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
    double lowIndex = lowestIndex + min(0.15 * span, 1);
    double highIndex = highestIndex - (0.15 * span).clamp(0, 2);
    
    if (mealIndex > lowIndex && mealIndex < highIndex) return;
    
    _scrollController.scrollTo(
      index: mealIndex,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      alignment: 0.35,
    );
  }
}