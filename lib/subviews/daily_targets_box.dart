import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import '../services/data/data_objects.dart';
import '../services/data/data_service.dart';
import '../widgets/border_box.dart';
import '../widgets/graph.dart';
import '../widgets/loading_page.dart';

// import 'dart:developer' as devtools show log;

class DailyTargetsBox extends StatefulWidget {
  final DateTime dateTime;
  final List<ProductQuantity>? ingredients;
  
  const DailyTargetsBox(
    this.dateTime,
    this.ingredients,
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
                        List<Meal> newMeals;// = widget.ingredients == null ? snapshotM.data! : widget.ingredients!;
                        List<Meal> oldMeals;// = widget.ingredients == null ? [] : snapshotM.data!;
                        var targets = snapshotT.data!;
                        
                        if (widget.ingredients == null) {
                          newMeals = snapshotM.data!;
                          oldMeals = [];
                        } else {
                          // convert ProductQuantity to Meal
                          newMeals = widget.ingredients!.map((ingr) => Meal(
                            id: -1,
                            dateTime: widget.dateTime,
                            productQuantity: ingr,
                          )).toList();
                          oldMeals = snapshotM.data!;
                        }
                        
                        return Graph(widget.dateTime, targets, products, nutritionalValues, oldMeals, newMeals);
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