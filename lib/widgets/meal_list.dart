import "dart:async";

import "package:flutter/material.dart";
import "package:flutter/rendering.dart";
import "package:flutter_sticky_header/flutter_sticky_header.dart";
import "package:food_tracker/services/data/async_provider.dart";

import "../constants/routes.dart";
import "../services/data/data_objects.dart";
import "../services/data/data_service.dart";
import "../utility/text_logic.dart";
import "add_meal_box.dart";

import "dart:developer" as devtools show log;

import "datetime_selectors.dart";
import "loading_page.dart";

class MealList extends StatefulWidget {
  final Map<int, Product>? productsMap;
  final List<Meal> meals;
  final bool loaded;
  
  const MealList({
    required this.productsMap,
    required this.meals,
    required this.loaded,
    super.key,
  });

  @override
  State<MealList> createState() => _MealListState();
}

class _MealListState extends State<MealList> {
  final DataService dataService = DataService.current();
  final ScrollController _scrollController = ScrollController();
  // Timer? _stickyHeaderTimer;
  // bool _showStickyHeader = false;
  
  bool hasScrolled = false;
  
  // @override
  // void initState() {
  //   super.initState();
  //   _scrollController.addListener(_onScroll);
  // }
  
  @override
  void dispose() {
    // _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    // _stickyHeaderTimer?.cancel();
    super.dispose();
  }
  
  // void _onScroll() {
  //   if (_scrollController.position.userScrollDirection != ScrollDirection.forward) return;
  //   if (!_showStickyHeader) {
  //     _showStickyHeader = true;
  //     _stickyHeaderTimer = Timer(const Duration(milliseconds: 2000), () {
  //       if (_showStickyHeader) {
  //         setState(() {
  //           _showStickyHeader = false;
  //         });
  //       }
  //     });
  //   }
  // }
  
  @override
  Widget build(BuildContext context) {
    if (!hasScrolled) {
      hasScrolled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(const Duration(milliseconds: 0), () {
          // _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
          _scrollController.jumpTo(100000);
          devtools.log("Jumped to max scroll extent ${_scrollController.position.maxScrollExtent}");
          Future.delayed(const Duration(milliseconds: 10000), () {
            devtools.log("Current scroll position: ${_scrollController.position.pixels}");
          });
        });
      });
    }
    
    return LayoutBuilder(
      builder: (context, constraints) {
        var underHeight = constraints.maxHeight - 605 - widget.meals.length * 55;
        if (underHeight < 0) underHeight = 0;
        
        return CustomScrollView(
          controller: _scrollController,
          // physics: const ClampingScrollPhysics(),
          // physics: const BouncingScrollPhysics(),
          // physics: const AlwaysScrollableScrollPhysics(),
          // physics: const
          scrollBehavior: MouseDragScrollBehavior().copyWith(scrollbars: false),
          cacheExtent: 999999999999999,
          slivers: [
             SliverToBoxAdapter(
              child: SizedBox(height: underHeight)
            ),
            ...getMealTiles(context, dataService, widget.productsMap, widget.meals, widget.loaded),
            const SliverToBoxAdapter(
              child: SizedBox(height: 5)
            ),
            SliverToBoxAdapter(
              child: AddMealBox(
                copyDateTime: DateTime.now(),
                onDateTimeChanged: (newDateTime) => Future.delayed(const Duration(milliseconds: 100), () => AsyncProvider.changeCompDT(newDateTime)),
                productsMap: widget.productsMap ?? {},
              ),
            ),
          ],
        );
      }
    );
  }

  List<Widget> getMealTiles(BuildContext context, DataService dataService, Map<int, Product>? productsMap, List<Meal> meals, bool loaded) {
    if (!loaded) return const [SliverToBoxAdapter(child: LoadingPage())];
    
    List<Widget> children = [];
    List<Widget> currentSliverChildren = [];                                                                                                       
    DateTime lastHeader = DateTime(0);
    if (meals.isNotEmpty) {
      var lastMeal = meals[meals.length - 1];
      var lastDate = lastMeal.dateTime;
      lastHeader = DateTime(lastDate.year, lastDate.month, lastDate.day);
    }
    for (int i = meals.length - 1; i >= 0; i--) {
      final meal = meals[i];
      final product = productsMap?[meal.productQuantity.productId];
      final mealDate = DateTime(meal.dateTime.year, meal.dateTime.month, meal.dateTime.day);
      
      if (lastHeader.isBefore(mealDate)) {
        devtools.log('MealList: meals are not sorted by date');
      } else if (lastHeader.isAfter(mealDate)) {
        var copyDate = lastHeader.copyWith();
        children.add(
          SliverStickyHeader.builder(
            builder: (context, SliverStickyHeaderState state) => getDateStrip(context, copyDate, state),
            sliver: SliverList(delegate: SliverChildListDelegate(List.from(currentSliverChildren.reversed))),
          ),
        );
        currentSliverChildren = [];
        lastHeader = mealDate;
      } else if (i < meals.length - 1) {
        currentSliverChildren.add(_buildHorizontalLine());
      }
      
      var unitName = unitToString(meal.productQuantity.unit);
      var productName = product?.name ?? 'Unknown';
      var amountText = '${truncateZeros(meal.productQuantity.amount)}\u2009$unitName';
      var hourText = '${meal.dateTime.hour}h';
      
      currentSliverChildren.add(
        ListTile(
          title: Row(
            children: [
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 2.5),
                    Text(productName, style: const TextStyle(fontSize: 16.5)),
                    Padding(
                      padding: const EdgeInsets.only(left: 0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(amountText, style: const TextStyle(fontSize: 14, color: Color.fromARGB(255, 0, 85, 255))),
                          Text(hourText, style: const TextStyle(fontSize: 14)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 2),
                  ],
                ),
              ),
              PopupMenuButton(
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: 0,
                    child: Text('Edit'),
                  ),
                  PopupMenuItem(
                    value: 1,
                    child: Text('Delete'),
                  ),
                ],
                onSelected: (int value) {
                  if (value == 0) {
                    // edit
                    // navigate to edit meal view
                    Navigator.pushNamed(context, editMealRoute, arguments: meal.id);
                  } else if (value == 1) {
                    // delete
                    dataService.deleteMeal(meal.id);
                  }
                },
              ),
            ],
          ),
          minVerticalPadding: 0,
          visualDensity: const VisualDensity(vertical: -4, horizontal: 0),
          contentPadding: EdgeInsets.zero,
        ),
      );
    }
    
    if (meals.isNotEmpty) {
      children.add(
        SliverStickyHeader.builder(
          builder: (context, SliverStickyHeaderState state) => getDateStrip(context, lastHeader, state),
          sliver: SliverList(delegate: SliverChildListDelegate(List.from(currentSliverChildren))),
        ),
      );
    }
    
    return children.reversed.toList();
    // return children;
  }

  Widget _buildHorizontalLine() =>
    const Divider(
      indent: 7,
      endIndent: 10,
      height: 1,
    );

  Widget getDateStrip(BuildContext context, DateTime dateTime, SliverStickyHeaderState state) {
    // Convert date to natural string
    String text;
    int relativeDays = dateTime.difference(DateTime.now()).inDays.abs();
    if (relativeDays <= 7) {
      text = "${relativeDaysNatural(dateTime)} (${conditionallyRemoveYear(context, [dateTime], showWeekDay: true)[0]})";
    } else {
      text = conditionallyRemoveYear(context, [dateTime], showWeekDay: true)[0];
    }
    
    var widget = Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 2),
      child: Row(
        children: [
          // SizedBox(width: state.isPinned ? 20 : 0),
          state.isPinned ? Spacer() : SizedBox(width: 0),
          Expanded(
            flex: 5,
            child: Container(
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 200, 200, 200),
                borderRadius: BorderRadius.circular(state.isPinned ? 7 : 0),
              ),
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 0),
                  child: Text(text, style: const TextStyle(fontSize: 15.5)),
                ),
              ),
            ),
          ),
          // SizedBox(width: state.isPinned ? 20 : 0),
          state.isPinned ? Spacer() : SizedBox(width: 0),
        ],
      ),
    );
    
    // if (!state.isPinned) return widget;
    
    // return AnimatedOpacity(
    //   opacity: _showStickyHeader ? 1 : 0.2,
    //   duration: const Duration(milliseconds: 3000),
    //   child: widget,
    // );
    return widget;
  }
}