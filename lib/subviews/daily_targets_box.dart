// ignore_for_file: curly_braces_in_flow_control_structures

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:food_tracker/utility/theme.dart';
import 'package:intl/intl.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../constants/routes.dart';
import '../constants/ui.dart';
import '../services/data/data_objects.dart';
import '../services/data/data_service.dart';
import '../utility/data_logic.dart';
import '../utility/text_logic.dart';
import '../widgets/amount_field.dart';
import '../widgets/border_box.dart';
import '../widgets/color_indicator_strip.dart';
import '../widgets/graph.dart';
import '../widgets/loading_page.dart';
import '../widgets/multi_stream_builder.dart';
import '../widgets/multi_value_listenable_builder.dart';
import '../widgets/unit_dropdown.dart';

import 'dart:developer' as devtools show log;
import 'dart:math' as math;

enum FoldMode {
  startFolded,
  startUnfolded,
  neverFold,
}

enum TimeFormat {
  hours,
  weekdays,
  days,
}

class DailyTargetsBox extends StatefulWidget {
  final DateTime? dateTime;
  final List<(ProductQuantity, Color)>? ingredients;
  final List<Meal>? meals; // ingredients but with timestamps
  final void Function(List<(ProductQuantity, Color)>) onIngredientsChanged;
  final FoldMode startFolded;
  
  final bool ingredientList;
  final bool scrollList;
  
  final TimeFormat? timeFormat;
  
  final String? name;
  final ValueNotifier<Unit>? defaultUnitNotifier;
  final ValueNotifier<List<ProductNutrient>>? nutrientsNotifier;
  final ValueNotifier<double>? nutrientAmountNotifier;
  final ValueNotifier<Unit>? nutrientUnitNotifier;
  final ValueNotifier<double>? ingredientAmountNotifier;
  final ValueNotifier<Unit>? ingredientUnitNotifier;
  final ValueNotifier<Conversion>? densityConversionNotifier;
  final ValueNotifier<Conversion>? quantityConversionNotifier;
  final TextEditingController? quantityNameController;
  
  final Map<Target, Map<Product?, double>>? overrideProgress;
  
  static const Color pseudoColor = Color.fromARGB(255, 31, 31, 31);
  static const Color selfColor = Color.fromARGB(255, 157, 175, 255);
  
  // ignore: use_key_in_widget_constructors
  DailyTargetsBox(
    this.dateTime,
    this.ingredients,
    this.meals,
    this.onIngredientsChanged,
    this.startFolded,
    this.ingredientList,
    this.scrollList,
    [
      this.timeFormat,
      this.name,
      this.defaultUnitNotifier,
      this.nutrientsNotifier,
      this.nutrientAmountNotifier,
      this.nutrientUnitNotifier,
      this.ingredientAmountNotifier,
      this.ingredientUnitNotifier,
      this.densityConversionNotifier,
      this.quantityConversionNotifier,
      this.quantityNameController,
      this.overrideProgress,
    ]
  ) {
    assert(ingredientList == false || name != null);
    assert(ingredientList == false || defaultUnitNotifier != null);
    assert(ingredientList == false || nutrientsNotifier != null);
    assert(ingredientList == false || nutrientAmountNotifier != null);
    assert(ingredientList == false || nutrientUnitNotifier != null);
    assert(ingredientList == false || quantityNameController != null);
    assert(ingredientList == false || ingredientAmountNotifier != null);
    assert(ingredientList == false || ingredientUnitNotifier != null);
    assert(ingredientList == false || densityConversionNotifier != null);
    assert(ingredientList == false || quantityConversionNotifier != null);
  }

  @override
  State<DailyTargetsBox> createState() => _DailyTargetsBoxState();
}

class _DailyTargetsBoxState extends State<DailyTargetsBox> {
  final _dataService = DataService.current();
  bool hidden = false;
  bool started = false;
  bool foldedIn = false;
  
  int colorsUsed = 0;
  
  var previewAmountNotifier = ValueNotifier<double>(0.0);
  var previewAmountController = TextEditingController();
  var previewUnitNotifier = ValueNotifier<Unit>(Unit.g);
  Unit? previousUnit;
  
  ValueNotifier<int?> lowestVisIndexNotifier = ValueNotifier(null);
  ValueNotifier<int?> highestVisIndexNotifier = ValueNotifier(null);
  
  ScrollController productListScrollController = ScrollController();
  
  @override
  void initState() {
    if (!started) {
      started = true;
      foldedIn = widget.startFolded == FoldMode.startFolded;
    }
    super.initState();
  }
  
  @override
  Widget build(BuildContext context) {
    if (hidden) {
      return StreamBuilder(
        stream: _dataService.streamTargets(),
        builder: (context, snapshot) {
          var targets = snapshot.data ?? [];
          if (targets.isNotEmpty) {
            Future(() {
              devtools.log("Unhiding DailyTargetsBox because targets are not empty");
              if (mounted) setState(() => hidden = false);
            });
          }
          return Container();
        }
      );
    }
    
    bool isBig = widget.ingredientList && foldedIn;
    
    Widget foldButton;
    
    if (widget.startFolded == FoldMode.neverFold) {
      foldButton = const Padding(
        padding: EdgeInsets.symmetric(horizontal: 8 * gsf),
        child: Text(
          "Graph",
          style: TextStyle(
            fontSize: 16 * gsf,
            color: Color(0xFF191919),
          ),
        ),
      );
    } else {
      foldButton = InkWell(
        onTap: () {
          setState(() {
            foldedIn = !foldedIn;
          });
        },
        child: Padding(
          padding: EdgeInsets.all(isBig ? 4 : 0) * gsf,
          child: Row(
            mainAxisSize: foldedIn ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(width: 8 * gsf),
              const Text(
                "Daily Targets",
                style: TextStyle(
                  fontSize: 16 * gsf,
                  color: Color(0xFF191919),
                ),
              ),
              SizedBox(width: (isBig ? 8 : 0) * gsf),
              Icon(
                foldedIn ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                size: (isBig ? 28 : 22) * gsf,
              ),
            ],
          ),
        ),
      );
    }
  
  List<Stream> streams = [
    _dataService.streamProducts(),
    _dataService.streamNutritionalValues(),
    _dataService.streamTargets(),
  ];
  if (widget.meals == null) streams.add(_dataService.streamMeals());
  
  return BorderBox(
    titleWidget: foldedIn ? null : foldButton,
    horizontalPadding: 0,
    child: foldedIn ? Padding(
      padding: const EdgeInsets.all(4) * gsf,
      child: foldButton,
    ) :
      Padding(
        padding: const EdgeInsets.fromLTRB(0, 4, 0, 0) * gsf,
        child: MultiValueListenableBuilder(
          listenables: widget.ingredientList ? [
            previewAmountNotifier,
            previewUnitNotifier,
            widget.nutrientsNotifier!,
            widget.nutrientAmountNotifier!,
            widget.nutrientUnitNotifier!,
            widget.ingredientAmountNotifier!,
            widget.ingredientUnitNotifier!,
            widget.densityConversionNotifier!,
            widget.quantityConversionNotifier!,
          ] : [],
          builder: (context, values, child) {
            return MultiStreamBuilder(
              streams: [
                _dataService.streamProducts(),
                _dataService.streamNutritionalValues(),
                _dataService.streamTargets(),
                _dataService.streamMeals(),
              ],
              builder: (context, snapshots) {
                // casting
                var snapshotP = snapshots[0] as AsyncSnapshot<Object?>;
                var snapshotN = snapshots[1] as AsyncSnapshot<Object?>;
                var snapshotT = snapshots[2] as AsyncSnapshot<Object?>;
                var snapshotM = widget.meals == null ? snapshots[3] as AsyncSnapshot<Object?> : null;
                
                // loading error handling
                String? errorMsg;
                if (snapshotP.hasError) errorMsg = "Error loading products ${snapshotP.error}";
                if (snapshotN.hasError) errorMsg = "Error loading nutritional values ${snapshotN.error}";
                if (snapshotT.hasError) errorMsg = "Error loading targets ${snapshotT.error}";
                if (snapshotM != null && snapshotM.hasError) errorMsg = "Error loading meals ${snapshotM.error}";
                if (errorMsg != null) return Text(errorMsg);
                
                // loading page
                if (!snapshots.any((s) => s.hasData) || snapshots.any((s) => s.data == null)) {
                  return const SizedBox(
                    height: 300 * gsf,
                    child: LoadingPage(),
                  );
                }
                
                // data handling
                var products          = snapshotP.data as List<Product>;
                var nutritionalValues = snapshotN.data as List<NutritionalValue>;
                var targets           = snapshotT.data as List<Target>;
                List<Meal> newMeals;
                List<Meal> oldMeals;
                bool conversionFailed = false;
                double factor = 1;
                // sort targets by order id
                targets.sort((a, b) => a.orderId.compareTo(b.orderId));
                
                // Check if there are any targets at all
                bool noTargets = targets.isEmpty;
                if (noTargets != hidden) {
                  Future(() {
                    if (mounted) setState(() => hidden = noTargets);
                  });
                }
                
                // mapping
                Map<int, Product> productsMap = products.asMap().map((key, value) => MapEntry(value.id, value));
                Map<int, Color> colors = widget.ingredients?.asMap().map((key, value) => MapEntry(value.$1.productId ?? -1, value.$2)) ?? {};
                
                // get target progress
                Map<Target, Map<Product?, double>> targetProgress;
                List<Product> contributingProducts;
                if (widget.overrideProgress != null) {
                  targetProgress = widget.overrideProgress!;
                  contributingProducts = widget.ingredients!.map((ingr) => productsMap[ingr.$1.productId]!).toList();
                } else {
                  // old meal, new meal processing
                  if (widget.meals != null) {
                    newMeals = widget.meals!;
                    oldMeals = [];
                  } else {
                    if (widget.ingredients == null) {
                      newMeals = snapshotM!.data as List<Meal>;
                      oldMeals = [];
                    } else {
                   
                      // convert ProductQuantity to Meal
                      newMeals = widget.ingredients!.map((ingr) {
                        return Meal(
                          id: -1,
                          dateTime: widget.dateTime ?? DateTime.now(),
                          productQuantity: ingr.$1,
                        );
                      }).toList();
                      oldMeals = widget.dateTime == null ? [] : snapshotM!.data as List<Meal>;
                    }
                  }
                  
                  Meal? overrideMeal;
                  Product? pseudoProduct;
                  Product? selfProduct;
                  List<ProductNutrient>? productNutrients;
                  if (widget.ingredientList) {
                    var ingredientAmount = widget.ingredientAmountNotifier!.value;
                    var ingredientUnit = widget.ingredientUnitNotifier!.value;
                    var previewAmount = previewAmountNotifier.value;
                    var previewUnit = previewUnitNotifier.value;
                    
                    var densityConversion = widget.densityConversionNotifier!.value;
                    var quantityConversion = widget.quantityConversionNotifier!.value;
                    
                    productNutrients = widget.nutrientsNotifier!.value.map((n) => n.copy()).toList();
                    
                    // set all auto calc nutrients to 0
                    for (var prodN in productNutrients) {
                      if (prodN.autoCalc) prodN.value = 0;
                    }
                    
                    // convert the ingredients from amount given by the ingredients to previewAmountNotifier
                    
                    if (ingredientAmount == 0 || previewAmount == 0) {
                      conversionFailed = true;
                    } else {
                      factor = convertToUnit(ingredientUnit, previewUnit, previewAmount / ingredientAmount, densityConversion, quantityConversion, enableTargetQuantity: true);
                      if (!factor.isFinite) conversionFailed = true;
                    }
                    
                    // check if any auto calculated values are overriden
                    if (!conversionFailed && productNutrients.any((prodN) => prodN.autoCalc)) {
                      // create a pseudo product with the overriden nutrient values
                      pseudoProduct = Product(
                        id: -1,
                        // name: widget.name!,
                        name: "Manually set nutrients",
                        isTemporary: false,
                        defaultUnit: widget.nutrientUnitNotifier!.value,
                        densityConversion: densityConversion,
                        quantityConversion: quantityConversion,
                        quantityName: "",
                        autoCalc: false,
                        amountForIngredients: ingredientAmount,
                        ingredientsUnit: ingredientUnit,
                        amountForNutrients: widget.nutrientAmountNotifier!.value,
                        nutrientsUnit: widget.nutrientUnitNotifier!.value,
                        ingredients: [],
                        nutrients: productNutrients,
                      );
                      
                      // convert from amount given by the nutrients to previewAmountNotifier
                      var pseudoFactor = convertToUnit(pseudoProduct.nutrientsUnit, previewUnit, previewAmount / pseudoProduct.amountForNutrients, densityConversion, quantityConversion, enableTargetQuantity: true);
                      if (!pseudoFactor.isFinite) conversionFailed = true;
                      
                      // create the override meal
                      overrideMeal = Meal(
                        id: -1,
                        dateTime: widget.dateTime ?? DateTime.now(),
                        productQuantity: ProductQuantity(
                          productId: -1,
                          amount: pseudoFactor * pseudoProduct.amountForNutrients,
                          // unit: previewUnit,
                          unit: pseudoProduct.nutrientsUnit,
                        ),
                      );
                    }
                  }
                  
                  // convert meals to the same unit as the previewAmountNotifier
                  List<Meal> convertedMeals = [];
                  
                  if (conversionFailed || !widget.ingredientList) {
                    convertedMeals = List.from(newMeals);
                  } else {
                    // refactor new meals with factor
                    convertedMeals = newMeals.map((meal) {
                      var mealAmount = meal.productQuantity.amount;
                      
                      return Meal(
                        id: meal.id,
                        dateTime: meal.dateTime,
                        productQuantity: ProductQuantity(
                          productId: meal.productQuantity.productId,
                          amount: mealAmount.isFinite && mealAmount > 0 ? mealAmount * factor : mealAmount,
                          unit: meal.productQuantity.unit,
                        ),
                      );
                    }).toList();
                  }
                  
                  // mapping
                  List<Product?> newMealProducts = convertedMeals.map((meal) => productsMap[meal.productQuantity.productId]).toList();
                  newMealProducts.removeWhere((element) => element == null);
                  if (widget.ingredientList && pseudoProduct != null) {
                    newMealProducts.insert(0, pseudoProduct);
                    productsMap[-1] = pseudoProduct;
                    convertedMeals.insert(0, overrideMeal!);
                  }
                  
                  // a map of all targets and how much of the target was fulfilled by every product
                  (targetProgress, contributingProducts) = getDailyTargetProgress(widget.dateTime, targets, productsMap, nutritionalValues, convertedMeals, oldMeals, widget.ingredientList);
                  List<Product> contributingColored = List.from(contributingProducts);
                  contributingColored.remove(pseudoProduct);
                  if (widget.ingredientList && productNutrients!.every((n) => n.value == 0)) {
                    contributingProducts.remove(pseudoProduct);
                  }
                  
                  // Add the product itself, if it is targeted
                  if (targets.any((t) => t.trackedType == Product && productsMap[t.trackedId]?.name == widget.name) && widget.ingredientList) {
                    selfProduct = Product(
                      id: -2,
                      name: widget.name!,
                      isTemporary: false,
                      defaultUnit: widget.nutrientUnitNotifier!.value,
                      densityConversion: widget.densityConversionNotifier!.value,
                      quantityConversion: widget.quantityConversionNotifier!.value,
                      quantityName: "",
                      autoCalc: false,
                      amountForIngredients: widget.ingredientAmountNotifier!.value,
                      ingredientsUnit: widget.ingredientUnitNotifier!.value,
                      amountForNutrients: widget.nutrientAmountNotifier!.value,
                      nutrientsUnit: widget.nutrientUnitNotifier!.value,
                      ingredients: [],
                      nutrients: []
                    );
                    // convert from preview amount to amount set in the target
                    var target = targets.firstWhere((t) => t.trackedType == Product && productsMap[t.trackedId]?.name == widget.name);
                    var targetUnit = target.unit;
                    var targetFactor = convertToUnit(targetUnit!, previewUnitNotifier.value, previewAmountNotifier.value, widget.densityConversionNotifier!.value, widget.quantityConversionNotifier!.value, enableTargetQuantity: true);
                    targetProgress[target] = {selfProduct: targetFactor};
                    productsMap[-2] = selfProduct;
                    contributingProducts.add(selfProduct);
                  }
                  
                  // color verfication
                  if (widget.ingredients != null && widget.ingredients!.isNotEmpty) {
                    var colorChanged = false;
                    colorsUsed = 0;
                    
                    // make sure all contributing products have the right color
                    for (var i = 0; i < contributingColored.length; i++) {
                      int index = widget.ingredients!.indexWhere((element) => element.$1.productId == contributingColored[i].id);
                      var (productQuantity, color) = widget.ingredients![index];
                      var desiredColor = productColors[i % productColors.length];
                      if (color != desiredColor) {
                        // devtools.log("changing color of ${contributingColored[i].name} from $color to $desiredColor");
                        widget.ingredients![index] = (productQuantity, desiredColor);
                        colorChanged = true;
                        colorsUsed++;
                      }
                    }
                    // list of all newMealProducts that did not contribute to any target
                    var nonContributingProducts = newMealProducts.where((p) => !contributingColored.contains(p) && (p?.id ?? 0) > -1).toList();
                    // make sure those are grey
                    const grey = Color.fromARGB(255, 99, 99, 99);
                    for (var p in nonContributingProducts) {
                      var index = widget.ingredients!.indexWhere((element) => element.$1.productId == p!.id);
                      var (productQuantity, color) = widget.ingredients![index];
                      if (color != grey) {
                        // devtools.log("changing color of ${p?.name} from $color to $grey because of non-contribution");
                        widget.ingredients![index] = (productQuantity, grey);
                        colorChanged = true;
                        colorsUsed++;
                      }
                    }
                    
                    if (colorChanged) {
                      Future(() {
                        widget.onIngredientsChanged(widget.ingredients!);
                      });
                    }
                  }
                  if (widget.ingredientList && pseudoProduct != null) {
                    colors[-1] = DailyTargetsBox.pseudoColor;
                  }
                  if (widget.ingredientList && selfProduct != null) {
                    colors[-2] = DailyTargetsBox.selfColor;
                  }
                }
                
                bool productOverflow = false;
                if (widget.ingredientList || widget.scrollList) {
                  productOverflow = targetProgress.entries.any((entry) => entry.value.containsKey(null) && entry.value[null]! > 0);
                }
                
                return Column(
                  children: [
                    if (widget.ingredientList) ...[
                      _buildProductAmountRow(
                        widget.nutrientAmountNotifier!,
                        widget.defaultUnitNotifier!,
                        widget.quantityNameController!,
                      ),
                      const SizedBox(height: 14),
                    ],
                    LayoutBuilder(
                      builder: (context, constraints) {
                        if (conversionFailed) {
                          return const SizedBox(
                            height: 300 * gsf,
                            child: Center(
                              child: Text(
                                "Conversion failed",
                                style: TextStyle(
                                  fontSize: 16 * gsf,
                                  color: Colors.red,
                                ),
                              ),
                            ),
                          );
                        }
                        Widget graph;
                        if (widget.scrollList) { // scrollable graph
                          Map<int, int> contributingProductIndices = {}; // map product id to index in contributingProducts
                          for (var i = 0; i < contributingProducts.length; i++) {
                            contributingProductIndices[contributingProducts[i].id] = i;
                          }
                          
                          return MultiValueListenableBuilder(
                            listenables: [
                              lowestVisIndexNotifier,
                              highestVisIndexNotifier,
                            ],
                            builder: (context, values, child) {
                              int? lowestVisIndex = values[0] as int?;
                              int? highestVisIndex = values[1] as int?;
                              // move all products which are not visible to greyed out dummy products at the top or bottom of the list
                              Map<Target, Map<Product?, double>> newTargetProgress = {};
                              Product? lowNullProduct;
                              Product? highNullProduct;
                              if (lowestVisIndex != null && lowestVisIndex > 0) {
                                lowNullProduct = _getDummyProduct(-4);
                              }
                              if (highestVisIndex != null && highestVisIndex < contributingProducts.length - 1) {
                                highNullProduct = _getDummyProduct(-3);
                              }
                              
                              // Create a new targetProgress to grey out invisible entries with the dummy products
                              for (var entry in targetProgress.entries) {
                                Map<Product?, double> newMap = {};
                                for (var product in entry.value.keys) {
                                  if (product == null) {
                                    newMap[product] = entry.value[product]!;
                                  } else {
                                    var index = contributingProductIndices[product.id];
                                    if (index == null) continue;
                                    Product productToEdit;
                                    if (index < lowestVisIndex!) {
                                      productToEdit = lowNullProduct!;
                                    } else if (index > highestVisIndex!) {
                                      productToEdit = highNullProduct!;
                                    } else {
                                      productToEdit = contributingProducts[index];
                                    }
                                    newMap[productToEdit] = entry.value[product]! + (newMap[productToEdit] ?? 0);
                                  }
                                }
                                // move highNullProduct to the end of the map
                                if (highNullProduct != null && newMap.containsKey(highNullProduct)) {
                                  var highEntry = newMap[highNullProduct];
                                  newMap.remove(highNullProduct);
                                  newMap[highNullProduct] = highEntry!;
                                }
                                newTargetProgress[entry.key] = newMap;
                              }
                              
                              // add the dummy products to the contributing products list
                              List<Product> productsPlus = List.from(contributingProducts);
                              if (lowNullProduct != null) productsPlus.insert(0, lowNullProduct);
                              if (highNullProduct != null) productsPlus.add(highNullProduct);
                              colors[-4] = const Color.fromARGB(255, 99, 99, 99);
                              colors[-3] = const Color.fromARGB(255, 99, 99, 99);
                              
                              return SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Graph(
                                  constraints.maxWidth,
                                  targets,
                                  productsPlus,
                                  colors,
                                  nutritionalValues,
                                  newTargetProgress,
                                  widget.ingredientList,
                                ),
                              );
                            }
                          );
                        } else {
                          graph = SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Graph(constraints.maxWidth, targets, products, colors, nutritionalValues, targetProgress, widget.ingredientList),
                          );
                        }
                        
                        return graph;
                      }
                    ),
                    if (widget.ingredientList || widget.scrollList) ...[
                      const SizedBox(height: 10),
                      _buildProductList(
                        productsMap,
                        widget.ingredients,
                        contributingProducts,
                        productOverflow,
                        widget.scrollList,
                        widget.timeFormat ?? TimeFormat.hours,
                      ),
                    ],
                  ],
                );
              }
            );
          }
        ),
      ),
    );
  }
  
  Widget _buildProductAmountRow(
    ValueNotifier<double> nutrientAmountNotifier,
    ValueNotifier<Unit> defaultUnitNotifier,
    TextEditingController quantityNameController,
  ) {
    return ValueListenableBuilder(
      valueListenable: defaultUnitNotifier,
      builder: (context, defUnit, child) {
        if (defUnit != previousUnit) {
          Future(() {
            previousUnit = defUnit;
            previewUnitNotifier.value = defUnit;
            if (defUnit == Unit.mg) {
              previewAmountNotifier.value = 1000.0;
              previewAmountController.text = "1000";
            } else if (defUnit == Unit.g || defUnit == Unit.ml) {
              previewAmountNotifier.value = 100.0;
              previewAmountController.text = "100";
            } else {
              previewAmountNotifier.value = 1.0;
              previewAmountController.text = "1";
            }
          });
        }
        
        return Row(
          mainAxisSize: MainAxisSize.max,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 5, 0) * gsf,
              child: const Text(
                "Nutrients for ",
                maxLines: 3,
                style: TextStyle(
                  fontSize: 16 * gsf,
                ),
              ),
            ),
            Flexible(
              child: Padding(
                padding: const EdgeInsets.only(right: 12) * gsf,
                child: AmountField(
                  controller: previewAmountController,
                  canBeEmpty: true,
                  onChangedAndParsed: (value) {
                    previewAmountNotifier.value = value;
                  },
                  padding: 0,
                )
              ),
            ),
            Flexible(
              child: MultiValueListenableBuilder(
                listenables: [
                  quantityNameController,
                  previewUnitNotifier,
                ],
                builder: (context, values, child) {
                  var unit = values[1] as Unit;
                  return UnitDropdown(
                    items: buildUnitItems(verbose: true, quantityName: quantityNameController.text), 
                    current: unit,
                    onChanged: (Unit? newUnit) {
                      previewUnitNotifier.value = newUnit!;
                    },
                  );
                }
              ),
            ),
            const Text(
              " :  ",
              maxLines: 3,
              style: TextStyle(
                fontSize: 16 * gsf,
              ),
            ),
          ],
        );
      }
    );
  }
  
  Widget _buildProductList(
    Map<int, Product> productsMap,
    List<(ProductQuantity, Color)>? ingredients,
    List<Product> contributingProducts,
    bool listOther,
    bool showMeals,
    [
      TimeFormat timeFormat = TimeFormat.hours,
    ]
  ) {
    if (ingredients == null) return Container();
    
    // find out height for scroll list
    const lineHeight = 57 * gsf;
    double viewHeight = 0;
    int maxLinesVis = 10000;
    bool showAll = false;
    if (showMeals) {
      double viewportHeight = MediaQuery.of(context).size.height;
      if (kIsWeb) viewportHeight -= 466 * gsf; // subtract the height of the graph
      else viewportHeight -= 466 * gsf;
      int numberOfRows = viewportHeight ~/ lineHeight;
      numberOfRows = math.max(3, math.min(6, numberOfRows)); // clamp between 3 and 7
      maxLinesVis = numberOfRows + 1;
      viewHeight = numberOfRows * lineHeight;
      showAll = numberOfRows + 2 > contributingProducts.length;
      lowestVisIndexNotifier.value ??= 0;
      highestVisIndexNotifier.value ??= maxLinesVis - 1;
    }
    
    var contributingIngredients = contributingProducts.where((p) => p.id >= 0).map((p) {
      return ingredients.firstWhereOrNull((ingr) => ingr.$1.productId == p.id);
    }).toList();
    if (contributingProducts.any((p) => p.id == -1)) {
      contributingIngredients.insert(0, (ProductQuantity(productId: -1, amount: 0, unit: Unit.g), DailyTargetsBox.pseudoColor));
    }
    if (contributingProducts.any((p) => p.id == -2)) {
      contributingIngredients.insert(0, (ProductQuantity(productId: -2, amount: 0, unit: Unit.g), DailyTargetsBox.selfColor));
    }
    
    List<Widget> children = [];
    
    int maxLength = contributingIngredients.length + (listOther ? 1 : 0);
    for (int i = 0; i < maxLength; i++) {
      bool isProduct = i < contributingIngredients.length;
      
      var ingr = isProduct ? contributingIngredients[i] : null;
      var productQuantity = isProduct ? ingr!.$1 : null;
      var colorBar = isProduct ? ingr!.$2 : const Color.fromARGB(255, 90, 90, 90);
      var r = colorBar.red, g = colorBar.green, b = colorBar.blue;
      var avgRGB = (r + g + b) / 3 / 255;
      double scaleFactor = 1;
      if (isProduct && avgRGB != 0) scaleFactor = 0.88 * (0.5 - math.pow(1 - avgRGB, 2) * 0.5) / avgRGB;
      r = (r * scaleFactor).round();
      g = (g * scaleFactor).round();
      b = (b * scaleFactor).round();
      var colorText = Color.fromARGB(255, r, g, b);
      var colorBg = i % 2 == 0 ? const Color.fromARGB(14, 83, 83, 117) : const Color.fromARGB(6, 200, 200, 200);
      
      var product = isProduct ? productsMap[productQuantity!.productId] : null;
      
      children.add(
        Container(
          color: colorBg,
          child: IntrinsicHeight(
            child: Row(
              children: [
                ColorIndicatorStrip(colorBar, 13, 0.25),
                SizedBox(height: showMeals ? (57 * gsf) : 0),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 5, 8, 4) * gsf, // vert 5
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        InkWell(
                          onTap: () {
                            if (isProduct) {
                              // navigate to edit product page
                              var productId = productQuantity!.productId;
                              var product = productsMap[productId]!;
                              
                              Navigator.of(context).pushNamed(
                                editProductRoute,
                                arguments: (product.name, false),
                              );
                            }
                          },
                          child: Text(
                            product?.name ?? "Other Products",
                            style: TextStyle(
                              fontSize: 16 * gsf,
                              fontWeight: showMeals ? FontWeight.w500 : FontWeight.normal,
                              color: colorText,
                              fontStyle: isProduct ? FontStyle.normal : FontStyle.italic,
                            ),
                          ),
                        ),
                        ... (showMeals && isProduct ? [
                          const SizedBox(height: 4 * gsf),
                          Builder(
                            builder: (context) {
                              if (product == null) return Container();
                              var meals = widget.meals!.where((m) => m.productQuantity.productId == product.id).toList();
                              if (meals.isEmpty) return Container();
                              // List<(String, String)> mealStrings = [];
                              List<TableRow> tableRows = [];
                              if (meals.length > 3) {
                                // combine meals
                                // test if all meals use the same product quantity unit
                                var unit = meals[0].productQuantity.unit;
                                var sameUnit = meals.every((m) => m.productQuantity.unit == unit);
                                if (!sameUnit) unit = product.defaultUnit;
                                
                                var totalAmount = 0.0;
                                for (var meal in meals) {
                                  totalAmount += convertToUnit(unit, meal.productQuantity.unit, meal.productQuantity.amount, product.densityConversion, product.quantityConversion, enableTargetQuantity: true);
                                }
                                meals = [Meal(id: -meals.length, dateTime: DateTime.now(), productQuantity: ProductQuantity(productId: product.id, amount: totalAmount, unit: unit))];
                              } else if (meals.length > 1) {
                                // add all meals of the same hour / day together (depending on timeframe)
                                
                                DateTime Function(DateTime) roundFunc = timeFormat == TimeFormat.hours ? roundToHour : roundToDay;
                                List<Meal> newMeals = [];
                                Meal oldMeal = meals[0];
                                DateTime oldDT = roundFunc(oldMeal.dateTime);
                                for (var i = 1; i < meals.length; i++) {
                                  Meal newMeal = meals[i];
                                  DateTime newDT = roundFunc(newMeal.dateTime);
                                  if (oldDT == newDT) {
                                    Unit unit;
                                    if (oldMeal.productQuantity.unit == newMeal.productQuantity.unit) {
                                      unit = oldMeal.productQuantity.unit;
                                    } else {
                                      unit = product.defaultUnit;
                                    }
                                    // convert both to the same unit
                                    double amount1 = convertToUnit(unit, oldMeal.productQuantity.unit, oldMeal.productQuantity.amount, product.densityConversion, product.quantityConversion, enableTargetQuantity: true);
                                    double amount2 = convertToUnit(unit, newMeal.productQuantity.unit, newMeal.productQuantity.amount, product.densityConversion, product.quantityConversion, enableTargetQuantity: true);
                                    oldMeal = oldMeal.copyWith(newProductQuantity: ProductQuantity(productId: product.id, amount: amount1 + amount2, unit: unit));
                                  } else {
                                    newMeals.add(oldMeal);
                                    oldMeal = newMeal;
                                    oldDT = newDT;
                                  }
                                }
                                newMeals.add(oldMeal);
                                if (meals.length != newMeals.length) meals = newMeals;
                              }
                              
                              for (var meal in meals) {
                                String timeString;
                                if (meal.id < 0) {
                                  timeString = "${-meal.id} meals";
                                } else if (timeFormat == TimeFormat.hours) {
                                  timeString = "${meal.dateTime.hour.toString()} h";
                                } else if (timeFormat == TimeFormat.weekdays) {
                                  timeString = DateFormat("EEEE").format(meal.dateTime);
                                } else {
                                  timeString = "${meal.dateTime.day}.${meal.dateTime.month}.";
                                }
                                
                                var amount = meal.productQuantity.amount;
                                var unit = meal.productQuantity.unit;
                                var unitString = unit == Unit.quantity ? product.quantityName : unitToString(unit);
                                tableRows.add(
                                  TableRow(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.only(right: 8) * gsf,
                                        child: Text(
                                          timeString,
                                          style: TextStyle(
                                            fontSize: 14 * gsf,
                                            color: Colors.black.withOpacity(0.66),
                                          ),
                                        ),
                                      ),
                                      Text(
                                        "${truncateZeros(roundDouble(amount))} $unitString",
                                        style: TextStyle(
                                          fontSize: 14 * gsf,
                                          color: Colors.black.withOpacity(0.66),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }
                              double colWidth;
                              if (timeFormat == TimeFormat.weekdays) {
                                colWidth = 100 * gsf;
                              } else {
                                colWidth = 70 * gsf;
                              }
                              return Table(
                                columnWidths: {
                                  0: FixedColumnWidth(colWidth),
                                  1: const IntrinsicColumnWidth(),
                                },
                                children: tableRows,
                              );
                            }
                          ),
                        ] : []),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    
    if (showMeals) {
      if (showAll) {
        lowestVisIndexNotifier.value = 0;
        highestVisIndexNotifier.value = contributingIngredients.length - 1;
        Future.delayed(Duration.zero, () {
          lowestVisIndexNotifier.value = 0;
          highestVisIndexNotifier.value = contributingIngredients.length - 1;
        });
        return Column(
          children: children,
        );
      }
      else {
        // add visibility detector to the children
        children = children.mapIndexed<Widget>((i, child) => VisibilityDetector(
          key: ValueKey("daily targets box scroll list $i"),
          onVisibilityChanged: (info) {
            bool visible = info.visibleFraction > 0;
            if (visible) {
              if (i < (lowestVisIndexNotifier.value ?? 0)) {
                lowestVisIndexNotifier.value = i;
                if ((highestVisIndexNotifier.value ?? contributingIngredients.length - 1) >= i + maxLinesVis) highestVisIndexNotifier.value = i + maxLinesVis;
              } else if (i > (highestVisIndexNotifier.value ?? 0)) {
                highestVisIndexNotifier.value = i;
                if ((lowestVisIndexNotifier.value ?? 0) <= i - maxLinesVis) lowestVisIndexNotifier.value = i - maxLinesVis;
              }
            } else {
              double middle = (lowestVisIndexNotifier.value! + highestVisIndexNotifier.value!) / 2;
              if (i >= (lowestVisIndexNotifier.value ?? 0) && i <= middle && productListScrollController.hasClients && productListScrollController.offset > lineHeight - 1) {
                if (highestVisIndexNotifier.value == contributingProducts.length - 1) return;
                lowestVisIndexNotifier.value = i + 1;
                if ((highestVisIndexNotifier.value ?? contributingProducts.length - 1) >= i + 1 + maxLinesVis) highestVisIndexNotifier.value = i + maxLinesVis;
              }
              if (i <= (highestVisIndexNotifier.value ?? 0) && i >= middle && i >= maxLinesVis) {
                highestVisIndexNotifier.value = i - 1;
                if ((lowestVisIndexNotifier.value ?? 0) <= i - 1 - maxLinesVis) lowestVisIndexNotifier.value = i - maxLinesVis;
              }
            }
          },
          child: child,
        )).toList();
        
        return Column(
          children:  [
            // horizontal black line
            Container(
              height: 1.2,
              color: Colors.black.withOpacity(0.8),
            ),
            // scroll view with meals
            SizedBox(
              height: viewHeight,
              child: ListView(
                controller: productListScrollController,
                children: children,
              ),
            ),
          ],
        );
      }
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      );
    }
  }
}

Product _getDummyProduct(int id) {
  return Product(
    id: id,
    name: "Dummy",
    isTemporary: true,
    defaultUnit: Unit.g,
    densityConversion: Conversion.defaultDensity(),
    quantityConversion: Conversion.defaultQuantity(),
    quantityName: "",
    autoCalc: false,
    amountForIngredients: 0,
    ingredientsUnit: Unit.g,
    amountForNutrients: 0,
    nutrientsUnit: Unit.g,
    ingredients: [],
    nutrients: [],
  );
}