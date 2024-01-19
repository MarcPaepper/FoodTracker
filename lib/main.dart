import 'package:flutter/material.dart';
import 'package:food_tracker/utility/theme.dart';
import 'package:food_tracker/views/main_view.dart';
import 'constants/routes.dart';

// import "dart:developer" as devtools show log;

void main() {
  runApp(
    MaterialApp(
      title: "Food Tracker",
      debugShowCheckedModeBanner: false,
      theme: getTheme(),
      home: const MainView(),
      routes: routes
    )
  );
}