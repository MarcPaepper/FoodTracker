// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart' show BuildContext, DefaultTabController, Material, PreferredSize, SafeArea, Scaffold, ScrollBehavior, ScrollConfiguration, State, StatefulWidget, Tab, TabBar, TabBarView, Theme, Widget;
import '../constants/data.dart';
import '../services/data/data_service.dart';
import 'products_view.dart';
import 'nutvalues_view.dart';
import 'options_view.dart';

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
        length: 3,
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
              NutritionalValueView(),
              OptionsView(),
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
      Tab(text: "Options"),
    ],
  );
}
