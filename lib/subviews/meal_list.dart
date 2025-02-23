import "dart:async";

import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:food_tracker/services/data/async_provider.dart";
import "package:scrollable_positioned_list/scrollable_positioned_list.dart";

import "../constants/routes.dart";
import "../constants/ui.dart";
import "../services/data/data_objects.dart";
import "../services/data/data_service.dart";
import "../utility/text_logic.dart";
import "../utility/theme.dart";
import "../widgets/add_meal_box.dart";
import "../widgets/loading_page.dart";

import "dart:developer" as devtools show log;

import "../widgets/multi_opacity.dart";
import "../widgets/multi_value_listenable_builder.dart";
import "../widgets/search_field.dart";

const TextStyle normalProductStyle = TextStyle(fontSize: 16.5 * gsf);
const TextStyle highlightProductStyle = TextStyle(fontSize: 16.5 * gsf, backgroundColor: Color.fromARGB(80, 255, 0, 212));

class MealList extends StatefulWidget {
  final Map<int, Product>? productsMap;
  final List<Meal> meals;
  final ValueNotifier<DateTime> dateTimeNotifier;
  final bool loaded;
  
  const MealList({
    required this.productsMap,
    required this.meals,
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
  final TextEditingController _searchController = TextEditingController();
  final ValueNotifier<double> _addMealVisibilityNotifier = ValueNotifier(1.0);
  late ValueNotifier<DateTime> dateTimeNotifier;
  
  Map<int, int> stripKeys = {}; // Key: days since 1970, Value: index of the strip in the list
  
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
    return ValueListenableBuilder(
      valueListenable: _searchController,
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
        
        List<Widget> mealTiles = getMealTiles(context, dataService, widget.productsMap, widget.meals, widget.loaded);
        children.addAll(mealTiles);
        
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
                listenables: [_addMealVisibilityNotifier, _searchController],
                builder: (context, values, child) {
                  double visibility = 1.0 - values[0];
                  if (_searchController.text.isNotEmpty) visibility = 1.0;
                  
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
                      onChanged: (String value) {},
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

  List<Widget> getMealTiles(BuildContext context, DataService dataService, Map<int, Product>? productsMap, List<Meal> meals, bool loaded) {
    if (!loaded) return const [LoadingPage()];
    
    List<Widget> children = [];
    Map<int, int> newKeys = {};
    // List<Widget> currentDayChildren = [];                                                                                                       
    DateTime lastHeader = DateTime(0);
    if (meals.isNotEmpty) {
      var lastMeal = meals[meals.length - 1];
      var lastDate = lastMeal.dateTime;
      lastHeader = DateTime(lastDate.year, lastDate.month, lastDate.day);
    }
    
    // List<Meal> filteredMeals;
    String search = _searchController.text.toLowerCase();
    var searchWords = search.toLowerCase().split(" ");
    // remove empty
    searchWords.removeWhere((element) => element == "");
    devtools.log("length: ${searchWords.length}");
    final textScaler = MediaQuery.textScalerOf(context);
    
    Map<int, Widget> pT = {}; // productTexts: Key: product id, Value: product name text
    
    for (int i = meals.length - 1; i >= 0; i--) {
      final meal = meals[i];
      final pId = meal.productQuantity.productId;
      final product = productsMap?[pId];
      final mealDate = DateTime(meal.dateTime.year, meal.dateTime.month, meal.dateTime.day);
      
      if (pId == null) {
        devtools.log("Error: Product id of meal is null");
        continue;
      }
      
      if (lastHeader.isBefore(mealDate)) {
        devtools.log('MealList: meals are not sorted by date');
      } else if (lastHeader.isAfter(mealDate)) {
        // use days of lastHeader since 1970 as the key
        int daysSince1970 = lastHeader.difference(DateTime(1970)).inDays;
        newKeys[daysSince1970] = children.length + 2;
        children.add(getDateStrip(context, lastHeader));
        lastHeader = mealDate;
      } else if (i < meals.length - 1) {
        children.add(_buildHorizontalLine());
      }
      
      var unitName = unitToString(meal.productQuantity.unit);
      if (meal.productQuantity.unit == Unit.quantity) unitName = product?.quantityName ?? "x";
      var productName = product?.name ?? 'Unknown';
      var amountText = '${truncateZeros(meal.productQuantity.amount)}\u2009$unitName';
      var hourText = '${meal.dateTime.hour}h';
      
      dynamic nameText = pT[pId];
      if (nameText == null) {
        List<InlineSpan> spans;
        if (searchWords.isEmpty) {
          spans = [TextSpan(text: productName, style: normalProductStyle)];
          // nameText = Text.rich(TextSpan(text: productName, style: const TextStyle(fontSize: 16.5 * gsf)));
        } else {
          spans = highlightOccurrences(productName, searchWords, normalProductStyle, highlightProductStyle);
        }
        nameText = RichText(
          text: TextSpan(
            style: const TextStyle(
              fontSize: 16.5 * gsf,
              height: 1.5,
              // fontWeight: FontWeight.w300,
              letterSpacing: 0.5,
            ),
            children: spans,
          ),
          textScaler: textScaler,
        );
        pT[pId] = nameText;
      }
      
      children.add(
        ListTile(
          // minTileHeight: 4,
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
                        Text(amountText, style: const TextStyle(fontSize: 14 * gsf, color: Color.fromARGB(255, 0, 85, 255))),//, height: 1)),
                        Text(hourText, style: const TextStyle(fontSize: 14 * gsf)),//, height: 1)),
                      ],
                    ),
                    const SizedBox(height: 2 * gsf), // anti gsf
                  ],
                ),
              ),
              PopupMenuButton(
                iconSize: (kIsWeb ? 24 : 24) * gsf,
                style: ButtonStyle(
                  padding: WidgetStateProperty.all<EdgeInsetsGeometry>(const EdgeInsets.symmetric(horizontal: 4, vertical: 4) * gsf),
                  minimumSize: WidgetStateProperty.all<Size>(const Size(0, 0)),
                ),
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: 0,
                    height: 44 * gsf,
                    padding: EdgeInsets.only(left: 12.0, right: 12.3),
                    child: Text("Edit meal", style: TextStyle(fontSize: 16 * gsf)),
                  ),
                  PopupMenuItem(
                    value: 1,
                    height: 44 * gsf,
                    padding: EdgeInsets.only(left: 12.0, right: 12.3),
                    child: Text("Edit product", style: TextStyle(fontSize: 16 * gsf)),
                  ),
                  PopupMenuItem(
                    value: 2,
                    height: 44 * gsf,
                    padding: EdgeInsets.only(left: 12.0, right: 12.3),
                    child: Text("Delete meal", style: TextStyle(fontSize: 16 * gsf)),
                  ),
                ],
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
    }
    
    if (meals.isNotEmpty) {
      int daysSince1970 = lastHeader.difference(DateTime(1970)).inDays;
      newKeys[daysSince1970] = children.length + 2;
      children.add(getDateStrip(context, lastHeader));
    }
    
    if (!mapEquals(stripKeys, newKeys)) {
      stripKeys = newKeys;
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

  Widget getDateStrip(BuildContext context, DateTime dateTime) {
    // Convert date to natural string
    String text;
    int relativeDays = dateTime.difference(DateTime.now()).inDays.abs();
    if (relativeDays <= 7) {
      text = "${relativeDaysNatural(dateTime)} (${conditionallyRemoveYear(context, [dateTime], showWeekDay: true)[0]})";
    } else {
      text = conditionallyRemoveYear(context, [dateTime], showWeekDay: true)[0];
    }
    
    var widget = Padding(
      padding: const EdgeInsets.only(top: 3, bottom: 1.5) * gsf,
      // key: key,
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Container(
              color: const Color.fromARGB(255, 200, 200, 200),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 0) * gsf,
                  child: Text(text, style: const TextStyle(fontSize: 15.5 * gsf)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
    return widget;
  }
  
  void _scrollToSelectedDateStrip(DateTime targetDate) {
    // convert date to days since 1970
    int daysSince1970 = targetDate.difference(DateTime(1970)).inDays;
    devtools.log("Trying to scroll to $daysSince1970");
    // find the nearest date in the stripKeys after the target date
    int closestDate = 0;
    for (int date in stripKeys.keys) {
      if (date >= daysSince1970 && date < closestDate) {
        closestDate = date;
        break;
      }
    }
    // if none was found, find the nearest date before the target date
    if (closestDate == 0) {
      for (int date in stripKeys.keys) {
        if (date <= daysSince1970 && date > closestDate) {
          closestDate = date;
          break;
        }
      }
    }
    if (closestDate == 0) return;
    
    // Find the first date after the closest date
    int nextDate = closestDate;
    // for (int date in stripKeys.keys) {
    // reverse order
    for (int i = stripKeys.keys.length - 1; i >= 0; i--) {
      int date = stripKeys.keys.elementAt(i);
      if (date > closestDate) {
        nextDate = date;
        break;
      }
    }
    
    int scrollToIndex = stripKeys[closestDate]!;
    if (nextDate != closestDate) {
      scrollToIndex = stripKeys[nextDate]! + 1;
    }
    
    _scrollController.scrollTo(
      index: scrollToIndex,
      duration: const Duration(milliseconds: 1000),
      curve: Curves.easeOut,
    );
  }
}