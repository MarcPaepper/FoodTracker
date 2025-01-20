// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:food_tracker/views/meals_view.dart';
import 'package:food_tracker/views/stats_view.dart';
import '../constants/data.dart';
import '../services/data/data_service.dart';
import 'products_view.dart';
import 'nutvalues_view.dart';
import 'options_view.dart';
import 'targets_view.dart';

// import 'dart:developer' as devtools show log;

class MainView extends StatefulWidget {
  const MainView({super.key});

  @override
  State<MainView> createState() => _MainViewState();
}

class _MainViewState extends State<MainView> {
  late final DataService _dataService;
  final ValueNotifier<DateTime> dateTimeNotifier = ValueNotifier(DateTime.now());
  
  @override
  void initState() {
    _dataService = DataService.current();
    _dataService.open(dbName);
    super.initState();
  }
  
  @override
  void dispose() {
    _dataService.close();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return ScrollConfiguration(
      // clamping scroll physics to avoid overscroll
      behavior: const ScrollBehavior().copyWith(overscroll: false),
      child: DefaultTabController(
        length: 6,
        child: Scaffold(
          appBar: PreferredSize(
            preferredSize: _tabBar.preferredSize,
            child: Material(
              color: Theme.of(context).appBarTheme.backgroundColor,
              child: SafeArea(child: _tabBar),
            )
          ),
          body: TabBarView(
            physics: AlwaysScrollableScrollPhysics(),
            children: [
              MealsView(dateTimeNotifier),
              StatsView(dateTimeNotifier),
              ProductsView(),
              NutritionalValueView(),
              TargetsView(),
              OptionsView(),
            ],
          ),
        )
      ),
    );
  }
  
  TabBar get _tabBar => const TabBar(
    isScrollable: true,
    physics: AlwaysScrollableScrollPhysics(),
    tabAlignment: TabAlignment.center,
    tabs: [
      Tab(text: "Meals"),
      Tab(text: "Stats"),
      Tab(text: "Products"),
      Tab(text: "Nutrition"),
      Tab(text: "Targets"),
      Tab(text: "Options"),
    ],
  );
}
