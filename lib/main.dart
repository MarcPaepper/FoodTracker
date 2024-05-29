// ignore_for_file: unused_import

import 'package:universal_io/io.dart';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:intl/intl_standalone.dart';

import 'utility/theme.dart';
import 'constants/routes.dart';
import 'views/main_view.dart';
import 'views/test_view.dart';

// import "dart:developer" as devtools show log;

void main() {
  initializeDateFormatting(Platform.localeName).then((_) => runApp(
    MaterialApp(
      title: "Food Tracker",
      debugShowCheckedModeBanner: false,
      theme: getTheme(),
      home: const MainView(),
      // home: const TestView(),
      routes: routes,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale("en", "US"),
        Locale("de", "DE"),
      ],
    )
  ));
}