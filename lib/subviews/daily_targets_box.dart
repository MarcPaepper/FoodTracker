import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:food_tracker/utility/theme.dart';
import 'package:rxdart/rxdart.dart';

import '../services/data/data_objects.dart';
import '../services/data/data_service.dart';
import '../utility/data_logic.dart';
import '../widgets/border_box.dart';
import '../widgets/graph.dart';
import '../widgets/loading_page.dart';

import 'dart:developer' as devtools show log;

import '../widgets/multi_stream_builder.dart';

class DailyTargetsBox extends StatefulWidget {
  final DateTime dateTime;
  final List<(ProductQuantity, Color)>? ingredients;
  final void Function(List<(ProductQuantity, Color)>) onIngredientsChanged;
  static int colorsUsed = 0;
  
  const DailyTargetsBox(
    this.dateTime,
    this.ingredients,
    this.onIngredientsChanged,
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
        padding: const EdgeInsets.fromLTRB(0, 4, 0, 6),
        child: MultiStreamBuilder(
          streams: [
            _dataService.streamProducts(),
            _dataService.streamNutritionalValues(),
            _dataService.streamTargets(),
            _dataService.streamMeals(),
          ],
          builder: (context, snapshots) {
            var snapshotP = snapshots[0] as AsyncSnapshot<Object?>;
            var snapshotN = snapshots[1] as AsyncSnapshot<Object?>;
            var snapshotT = snapshots[2] as AsyncSnapshot<Object?>;
            var snapshotM = snapshots[3] as AsyncSnapshot<Object?>;
            
            String? errorMsg;
            if (snapshotP.hasError) errorMsg = "Error loading products ${snapshotP.error}";
            if (snapshotN.hasError) errorMsg = "Error loading nutritional values ${snapshotN.error}";
            if (snapshotT.hasError) errorMsg = "Error loading targets ${snapshotT.error}";
            if (snapshotM.hasError) errorMsg = "Error loading meals ${snapshotM.error}";
            if (errorMsg != null) return Text(errorMsg);
            
            if (!snapshots.any((s) => s.hasData)) return const LoadingPage();
            
            devtools.log("new data for DailyTargetsBox ${DateTime.now()}");
            
            var products          = snapshotP.data as List<Product>;
            var nutritionalValues = snapshotN.data as List<NutritionalValue>;
            var targets           = snapshotT.data as List<Target>;
            List<Meal> newMeals;
            List<Meal> oldMeals;
            // sort targets by order id
            targets.sort((a, b) => a.orderId.compareTo(b.orderId));
            
            if (widget.ingredients == null) {
              newMeals = snapshotM.data as List<Meal>;
              oldMeals = [];
            } else {
              // convert ProductQuantity to Meal
              newMeals = widget.ingredients!.map((ingr) => Meal(
                id: -1,
                dateTime: widget.dateTime,
                productQuantity: ingr.$1,
              )).toList();
              oldMeals = snapshotM.data as List<Meal>;
            }
            
            Map<int, Product> productsMap = products.asMap().map((key, value) => MapEntry(value.id, value));
            Map<int, Color> colors = widget.ingredients?.asMap().map((key, value) => MapEntry(value.$1.productId ?? -1, value.$2)) ?? {};
            List<Product?> newMealProducts = newMeals.map((meal) => productsMap[meal.productQuantity.productId]).toList();
            newMealProducts.removeWhere((element) => element == null);
            
            // a map of all targets and how much of the target was fulfilled by every product
            var (targetProgress, contributingProducts) = getDailyTargetProgress(widget.dateTime, targets, productsMap, nutritionalValues, newMeals, oldMeals, false);
            
            if (widget.ingredients != null && widget.ingredients!.isNotEmpty) {
              var colorChanged = false;
              DailyTargetsBox.colorsUsed = 0;
              
              // make sure all contributing products have the right color
              for (var i = 0; i < contributingProducts.length; i++) {
                int index = widget.ingredients!.indexWhere((element) => element.$1.productId == contributingProducts[i].id);
                var (productQuantity, color) = widget.ingredients![index];
                var desiredColor = productColors[i % productColors.length];
                if (color != desiredColor) {
                  devtools.log("changing color of ${contributingProducts[i].name} from $color to $desiredColor");
                  widget.ingredients![index] = (productQuantity, desiredColor);
                  colorChanged = true;
                  DailyTargetsBox.colorsUsed++;
                }
              }
              // list of all newMealProducts that did not contribute to any target
              var nonContributingProducts = newMealProducts.where((p) => !contributingProducts.contains(p)).toList();
              // make sure those are grey
              const grey = Color.fromARGB(255, 99, 99, 99);
              for (var p in nonContributingProducts) {
                var index = widget.ingredients!.indexWhere((element) => element.$1.productId == p!.id);
                var (productQuantity, color) = widget.ingredients![index];
                if (color != grey) {
                  devtools.log("changing color of ${p?.name} from $color to $grey because of non-contribution");
                  widget.ingredients![index] = (productQuantity, grey);
                  colorChanged = true;
                  DailyTargetsBox.colorsUsed++;
                }
              }
              
              if (colorChanged) widget.onIngredientsChanged(widget.ingredients!);
            }
            
            return LayoutBuilder(
              builder: (context, constraints) {
                return ScrollConfiguration(
                  behavior: ScrollConfiguration.of(context).copyWith(dragDevices: {PointerDeviceKind.touch, PointerDeviceKind.mouse}),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Graph(constraints.maxWidth, widget.dateTime, targets, products, colors, nutritionalValues, targetProgress)
                  ),
                );
              }
            ); //oldMeals, newMeals);
            // return SingleChildScrollView(
            //   scrollDirection: Axis.horizontal,
            //   child: SizedBox(
            //     width: 1000,
            //     child: Placeholder(),
            //   )
            // );
          }
        ),
      ),
    );
  }
}