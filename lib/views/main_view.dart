// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:food_tracker/constants/data.dart';
import 'package:food_tracker/services/data/data_service.dart';
import 'package:food_tracker/views/products_view.dart';

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
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: _tabBar.preferredSize,
          child: Material(
            color: Theme.of(context).appBarTheme.backgroundColor,
            child: _tabBar,
          )
        ),
        body: const TabBarView(
          children: [
            Icon(Icons.directions_car, size: 350),
            ProductsView(),
            Icon(Icons.directions_transit, size: 350),
          ],
        ),
      )
    );
  }
  
  TabBar get _tabBar => const TabBar(
    tabs: [
      Tab(text: "Hey"),
      Tab(text: "Products"),
      Tab(text: "Meals"),
    ],
  );
}
