// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:food_tracker/constants/data.dart';
import 'package:food_tracker/services/data/data_service.dart';
import 'package:food_tracker/views/products_view.dart';
import 'package:food_tracker/views/nutvalues_view.dart';

// import 'dart:developer' as devtools show log;

class MainView extends StatefulWidget {
  const MainView({super.key});

  @override
  State<MainView> createState() => _MainViewState();
}

class _MainViewState extends State<MainView> {
  late final DataService _dataService;
  
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
        length: 2,
        child: Scaffold(
          appBar: PreferredSize(
            preferredSize: _tabBar.preferredSize,
            child: Material(
              color: Theme.of(context).appBarTheme.backgroundColor,
              child: SafeArea(child: _tabBar),
            )
          ),
          body: const TabBarView(
            children: [
              ProductsView(),
              NutrionalValueView(),
            ],
          ),
        )
      ),
    );
  }
  
  TabBar get _tabBar => const TabBar(
    tabs: [
      Tab(text: "Products"),
      Tab(text: "Nutrition"),
    ],
  );
}
