import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:food_tracker/utility/theme.dart';

import '../services/data/data_objects.dart';
import '../services/data/data_service.dart';
import '../utility/data_logic.dart';
import '../widgets/border_box.dart';
import '../widgets/graph.dart';
import '../widgets/loading_page.dart';

import 'dart:developer' as devtools show log;

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
                        List<Meal> newMeals;
                        List<Meal> oldMeals;
                        var targets = snapshotT.data!;
                        
                        if (widget.ingredients == null) {
                          newMeals = snapshotM.data!;
                          oldMeals = [];
                        } else {
                          // convert ProductQuantity to Meal
                          newMeals = widget.ingredients!.map((ingr) => Meal(
                            id: -1,
                            dateTime: widget.dateTime,
                            productQuantity: ingr.$1,
                          )).toList();
                          oldMeals = snapshotM.data!;
                        }
                        
                        Map<int, Product> productsMap = products.asMap().map((key, value) => MapEntry(value.id, value));
                        Map<int, Color> colors = widget.ingredients?.asMap().map((key, value) => MapEntry(value.$1.productId ?? -1, value.$2)) ?? {};
                        List<Product?> newMealProducts = newMeals.map((meal) => productsMap[meal.productQuantity.productId]).toList();
                        newMealProducts.removeWhere((element) => element == null);
                        
                        
                        // a map of all targets and how much of the target was fulfilled by every product
                        var (targetProgress, contributingProducts) = getDailyTargetProgress(widget.dateTime, targets, productsMap, nutritionalValues, newMeals, oldMeals, false);
                        
                        // // sort contributing products by the index map
                        // contributingProducts.sort((a, b) => (ingredientIndices[a.id] ?? 0) - (ingredientIndices[b.id] ?? 0));
                        // sort target progress by the index map
                        
                        if (widget.ingredients != null && widget.ingredients!.isNotEmpty) {
                          var colorChanged = false;
                          DailyTargetsBox.colorsUsed = 0;
                          
                          devtools.log("contrlength: ${contributingProducts.length}, ingredientslength: ${widget.ingredients!.length}");
                          
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
                              widget.ingredients![index] = (productQuantity, grey);
                              colorChanged = true;
                              DailyTargetsBox.colorsUsed++;
                            }
                          }
                          
                          if (colorChanged) widget.onIngredientsChanged(widget.ingredients!);
                        }
                        
                        return Graph(widget.dateTime, targets, products, colors, nutritionalValues, targetProgress); //oldMeals, newMeals);
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