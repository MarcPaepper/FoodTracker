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
          stream: _dataService.streamProducts(),
          builder: (contextP, snapshotP) {
            return StreamBuilder(
              stream: _dataService.streamNutritionalValues(),
              builder: (contextN, snapshotN) {
                return StreamBuilder(
                  stream: _dataService.streamTargets(),
                  builder: (contextT, snapshotT) {
                    return StreamBuilder(
                      stream: _dataService.streamMeals(),
                      builder: (contextM, snapshotM) {
                        String? errorMsg;
                        if (snapshotP.hasError) errorMsg = "products";
                        if (snapshotN.hasError) errorMsg = "nutritional values";
                        if (snapshotT.hasError) errorMsg = "daily targets";
                        if (snapshotM.hasError) errorMsg = "meals";
                        if (errorMsg != null) return Text("Error loading $errorMsg");
                        
                        if (!snapshotP.hasData || !snapshotN.hasData || !snapshotT.hasData || !snapshotM.hasData) {
                          return const LoadingPage();
                        }
                        
                        var products = snapshotP.data!;
                        var nutritionalValues = snapshotN.data!;
                        var meals = snapshotM.data!;
                        var targets = snapshotT.data!;
                        
                        return Graph(widget.dateTime, targets, products, nutritionalValues, const [], meals);
                      },
                    );
                  }
                );
              },
            );
          }
        ),
      ),
    );
  }
}