import 'package:collection/collection.dart';
import 'package:collection/collection.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:food_tracker/utility/theme.dart';

import '../services/data/data_objects.dart';
import '../services/data/data_service.dart';
import '../utility/data_logic.dart';
import '../widgets/amount_field.dart';
import '../widgets/border_box.dart';
import '../widgets/color_indicator_strip.dart';
import '../widgets/graph.dart';
import '../widgets/loading_page.dart';

import 'dart:developer' as devtools show log;
import 'dart:math' as math;

import '../widgets/multi_stream_builder.dart';
import '../widgets/multi_value_listenable_builder.dart';
import '../widgets/unit_dropdown.dart';

class DailyTargetsBox extends StatefulWidget {
  final DateTime? dateTime;
  final List<(ProductQuantity, Color)>? ingredients;
  final void Function(List<(ProductQuantity, Color)>) onIngredientsChanged;
  final bool startFolded;
  
  final bool internalList;
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
  
  static final Color pseudoColor = const Color.fromARGB(255, 31, 31, 31);
  
  // ignore: use_key_in_widget_constructors
  DailyTargetsBox(
    this.dateTime,
    this.ingredients,
    this.onIngredientsChanged,
    this.startFolded,
    this.internalList,
    [
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
    ]
  ) {
    assert(internalList == false || name != null);
    assert(internalList == false || defaultUnitNotifier != null);
    assert(internalList == false || nutrientsNotifier != null);
    assert(internalList == false || nutrientAmountNotifier != null);
    assert(internalList == false || nutrientUnitNotifier != null);
    assert(internalList == false || quantityNameController != null);
    assert(internalList == false || ingredientAmountNotifier != null);
    assert(internalList == false || ingredientUnitNotifier != null);
    assert(internalList == false || densityConversionNotifier != null);
    assert(internalList == false || quantityConversionNotifier != null);
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
  
  @override
  void initState() {
    if (!started) {
      started = true;
      foldedIn = widget.startFolded;
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
    
    bool isBig = widget.internalList && foldedIn;
    
    Widget foldButton = InkWell(
      onTap: () {
        setState(() {
          foldedIn = !foldedIn;
        });
      },
      child: Padding(
        padding: EdgeInsets.all(isBig ? 4 : 0),
        child: Row(
          mainAxisSize: foldedIn ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(width: 8),
            const Text(
              "Daily Targets",
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF191919),
              ),
            ),
            SizedBox(width: isBig ? 8 : 0),
            Icon(
              foldedIn ? Icons.arrow_drop_up : Icons.arrow_drop_down,
              size: isBig ? 28 : 22,
            ),
          ],
        ),
      ),
    );
  
  return BorderBox(
    titleWidget: foldedIn ? null : foldButton,
    child: foldedIn ? Padding(
      padding: const EdgeInsets.all(4),
      child: foldButton,
    ) :
      Padding(
        padding: const EdgeInsets.fromLTRB(0, 4, 0, 0),
        child: MultiValueListenableBuilder(
          listenables: widget.internalList ? [
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
                var snapshotM = snapshots[3] as AsyncSnapshot<Object?>;
                
                // loading error handling
                String? errorMsg;
                if (snapshotP.hasError) errorMsg = "Error loading products ${snapshotP.error}";
                if (snapshotN.hasError) errorMsg = "Error loading nutritional values ${snapshotN.error}";
                if (snapshotT.hasError) errorMsg = "Error loading targets ${snapshotT.error}";
                if (snapshotM.hasError) errorMsg = "Error loading meals ${snapshotM.error}";
                if (errorMsg != null) return Text(errorMsg);
                
                // loading page
                if (!snapshots.any((s) => s.hasData) || snapshots.any((s) => s.data == null)) {
                  return const SizedBox(
                    height: 300,
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
                
                // old meal, new meal processing
                if (widget.ingredients == null) {
                  newMeals = snapshotM.data as List<Meal>;
                  oldMeals = [];
                } else {
                  // convert ProductQuantity to Meal
                  newMeals = widget.ingredients!.map((ingr) => Meal(
                    id: -1,
                    dateTime: widget.dateTime ?? DateTime.now(),
                    productQuantity: ingr.$1,
                  )).toList();
                  oldMeals = widget.dateTime == null ? [] : snapshotM.data as List<Meal>;
                }
                
                
                Meal? overrideMeal;
                Product? pseudoProduct;
                if (widget.internalList) {
                  var ingredientAmount = widget.ingredientAmountNotifier!.value;
                  var ingredientUnit = widget.ingredientUnitNotifier!.value;
                  var previewAmount = previewAmountNotifier.value;
                  var previewUnit = previewUnitNotifier.value;
                  
                  var densityConversion = widget.densityConversionNotifier!.value;
                  var quantityConversion = widget.quantityConversionNotifier!.value;
                  
                  var productNutrients = widget.nutrientsNotifier!.value;
                  
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
                  if (!conversionFailed && productNutrients.any((prodN) => prodN.value > 0)) {
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
                      ingredients: widget.ingredients!.map((ingr) => ingr.$1).toList(),
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
                
                List<Meal> convertedMeals = [];
                
                if (conversionFailed || !widget.internalList) {
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
                Map<int, Product> productsMap = products.asMap().map((key, value) => MapEntry(value.id, value));
                Map<int, Color> colors = widget.ingredients?.asMap().map((key, value) => MapEntry(value.$1.productId ?? -1, value.$2)) ?? {};
                List<Product?> newMealProducts = convertedMeals.map((meal) => productsMap[meal.productQuantity.productId]).toList();
                newMealProducts.removeWhere((element) => element == null);
                if (widget.internalList && pseudoProduct != null) {
                  newMealProducts.insert(0, pseudoProduct);
                  productsMap[-1] = pseudoProduct;
                  convertedMeals.insert(0, overrideMeal!);
                }
                
                // a map of all targets and how much of the target was fulfilled by every product
                var (targetProgress, contributingProducts) = getDailyTargetProgress(widget.dateTime, targets, productsMap, nutritionalValues, convertedMeals, oldMeals, true);
                List<Product> contributingColored = List.from(contributingProducts);
                contributingColored.remove(pseudoProduct);
                
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
                if (widget.internalList && pseudoProduct != null) {
                  colors[-1] = DailyTargetsBox.pseudoColor;
                }
                
                bool productOverflow = widget.internalList && targetProgress.entries.any((entry) => entry.value.containsKey(null) && entry.value[null]! > 0);
                
                return Column(
                  children: [
                    if (widget.internalList) ...[
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
                            height: 300,
                            child: Center(
                              child: Text(
                                "Conversion failed",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.red,
                                ),
                              ),
                            ),
                          );
                        }
                        return ScrollConfiguration(
                          behavior: ScrollConfiguration.of(context).copyWith(dragDevices: {PointerDeviceKind.touch, PointerDeviceKind.mouse}),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Graph(constraints.maxWidth, targets, products, colors, nutritionalValues, targetProgress, widget.internalList)
                          ),
                        );
                      }
                    ),
                    if (widget.internalList) ...[
                      const SizedBox(height: 10),
                      _buildProductList(
                        productsMap,
                        widget.ingredients,
                        contributingProducts,
                        productOverflow,
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
            const Padding(
              padding: EdgeInsets.fromLTRB(12, 0, 5, 0),
              child: Text(
                "Nutrients for ",
                maxLines: 3,
                style: TextStyle(
                  fontSize: 16,
                ),
              ),
            ),
            Flexible(
              child: Padding(
                padding: const EdgeInsets.only(right: 12),
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
                fontSize: 16,
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
  ) {
    if (ingredients == null) return Container();
    
    var contributingIngredients = contributingProducts.where((p) => p.id != -1).map((p) {
      return ingredients.firstWhereOrNull((ingr) => ingr.$1.productId == p.id);
    }).toList();
    if (contributingProducts.any((p) => p.id == -1)) {
      contributingIngredients.insert(0, (ProductQuantity(productId: -1, amount: 0, unit: Unit.g), DailyTargetsBox.pseudoColor));
    }
    
    List<Widget> children = [];
    
    int max = contributingIngredients.length + (listOther ? 1 : 0);
    for (int i = 0; i < max; i++) {
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
      
      var product = isProduct ? productsMap[productQuantity!.productId]! : null;
      
      children.add(
        Container(
          color: colorBg,
          child: IntrinsicHeight(
            child: Row(
              children: [
                ColorIndicatorStrip(colorBar, 13, 0.25),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    child: Text(
                      product?.name ?? "Other Products",
                      style: TextStyle(
                        fontSize: 16,
                        color: colorText,
                        fontStyle: isProduct ? FontStyle.normal : FontStyle.italic,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }
}