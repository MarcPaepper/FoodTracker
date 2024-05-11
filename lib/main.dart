// ignore_for_file: unused_import

import 'package:flutter/material.dart';
import 'package:food_tracker/utility/theme.dart';
import 'package:food_tracker/views/main_view.dart';
import 'constants/routes.dart';
import 'views/test_view.dart';

// import "dart:developer" as devtools show log;

void main() {
  runApp(
    MaterialApp(
      title: "Food Tracker",
      debugShowCheckedModeBanner: false,
      theme: getTheme(),
      home: const MainView(),
      // home: const TestView(),
      routes: routes
    )
  );
}