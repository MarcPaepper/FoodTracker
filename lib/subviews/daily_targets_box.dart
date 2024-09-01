import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'dart:developer' as devtools show log;

import '../services/data/data_service.dart';
import '../widgets/border_box.dart';
import '../widgets/graph.dart';
import '../widgets/loading_page.dart';

class DailyTargetsBox extends StatefulWidget {
  final DateTime dateTime;
  
  const DailyTargetsBox(
    this.dateTime,
    {super.key}
  );

  @override
  State<DailyTargetsBox> createState() => _DailyTargetsBoxState();
}

class _DailyTargetsBoxState extends State<DailyTargetsBox> {
  final _dataService = DataService.current();
  
  @override
  Widget build(BuildContext context) {
    return BorderBox(
      title: "Daily Targets",
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0, 4, 0, 12),
        child: StreamBuilder(
          stream: _dataService.streamNutritionalValues(),
          builder: (contextN, snapshotN) {
            return StreamBuilder(
              stream: _dataService.streamMeals(),
              builder: (contextM, snapshotM) {
                if (snapshotN.hasError) {
                  devtools.log("Error retrieving nutritional values: ${snapshotN.error}");
                  return Text("Error retrieving nutritional values: ${snapshotN.error}");
                }
                if (snapshotM.hasError) {
                  devtools.log("Error retrieving meals: ${snapshotM.error}");
                  return Text("Error retrieving meals: ${snapshotM.error}");
                }
                if (!snapshotM.hasData || !snapshotN.hasData) {
                  return const LoadingPage();
                }
                var nutritionalValues = snapshotN.data!;
                var meals = snapshotM.data!;
                return Graph(
                  dateTime: widget.dateTime,
                  nutritionalValues: nutritionalValues,
                  meals: meals,
                );
              },
            );
          },
        ),
      ),
    );
  }
}