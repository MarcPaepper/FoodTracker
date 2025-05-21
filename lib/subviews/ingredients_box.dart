// ignore_for_file: curly_braces_in_flow_control_structures

import 'package:flutter/material.dart';

import '../constants/routes.dart';
import '../constants/ui.dart';
import '../services/data/async_provider.dart';
import '../services/data/data_objects.dart';
import '../utility/data_logic.dart';
import '../utility/modals.dart';
import '../utility/text_logic.dart';
import '../utility/theme.dart';
import '../widgets/amount_field.dart';
import '../widgets/border_box.dart';
import '../widgets/multi_value_listenable_builder.dart';
import '../widgets/product_dropdown.dart';
import '../widgets/slidable_list.dart';
import '../widgets/unit_dropdown.dart';

import 'dart:developer' as devtools show log;

class IngredientsBox extends StatefulWidget {
  final int id;
  final Product prevProduct;
  final Map<int, Product> productsMap;
  final int? focusIndex;
  final DateTime? autofocusTime;
  
  final ValueNotifier<Unit>                           defaultUnitNotifier;
  final TextEditingController                         quantityNameController;
  final ValueNotifier<bool>                           autoCalcAmountNotifier;
  // final ValueNotifier<List<ProductQuantity>>       ingredientsNotifier;
  final ValueNotifier<List<(ProductQuantity, Color)>> ingredientsNotifier;
  final ValueNotifier<Unit>                           ingredientsUnitNotifier;
  final ValueNotifier<Conversion>                     densityConversionNotifier;
  final ValueNotifier<Conversion>                     quantityConversionNotifier;
  final ValueNotifier<double>                         resultingAmountNotifier;
  final ValueNotifier<bool>                           validNotifier;
  final TextEditingController                         productNameController;
  final TextEditingController                         resultingAmountController;
  final List<TextEditingController>                   ingredientAmountControllers;
  final List<FocusNode>                               ingredientDropdownFocusNodes;
  
  final Function() intermediateSave;
  final Function(Unit, List<(ProductQuantity, Color)>, int?) onChanged;
  final Function(int, int) requestIngredientFocus;
  
  const IngredientsBox({
    required this.id,
    required this.prevProduct,
    required this.productsMap,
             this.focusIndex,
             this.autofocusTime,
    required this.defaultUnitNotifier,
    required this.quantityNameController,
    required this.autoCalcAmountNotifier,
    required this.ingredientsNotifier,
    required this.ingredientsUnitNotifier,
    required this.densityConversionNotifier,
    required this.quantityConversionNotifier,
    required this.resultingAmountNotifier,
    required this.validNotifier,
    required this.productNameController,
    required this.resultingAmountController,
    required this.ingredientAmountControllers,
    required this.ingredientDropdownFocusNodes,
    required this.intermediateSave,
    required this.onChanged,
    required this.requestIngredientFocus,
    super.key,
  });

  @override
  State<IngredientsBox> createState() => _IngredientsBoxState();
}

class _IngredientsBoxState extends State<IngredientsBox> {
  @override
  Widget build(BuildContext context) {
    return MultiValueListenableBuilder(
      listenables: [
        widget.productNameController,
        widget.defaultUnitNotifier,
        widget.quantityNameController,
        widget.autoCalcAmountNotifier,
        widget.ingredientsNotifier,
        widget.ingredientsUnitNotifier,
        widget.densityConversionNotifier,
        widget.quantityConversionNotifier,
        widget.resultingAmountNotifier,
      ],
      builder: (context, values, child) {
        var valueName               = values[0] as TextEditingValue;
        var valueDefUnit            = values[1] as Unit;
        var valueAutoCalc           = values[3] as bool;
        var valueIngredients        = values[4] as List<(ProductQuantity, Color)>;
        var valueUnit               = values[5] as Unit;
        var valueDensityConversion  = values[6] as Conversion;
        var valueQuantityConversion = values[7] as Conversion;
        var valueResultingAmount    = values[8] as double;
        
        var productName = valueName.text.trim() != "" ? "'${valueName.text.trim()}'" : " the product";
        List<(ProductQuantity, Product?)> ingredientsWithProducts = [];
        for (var ingredient in valueIngredients) {
          ingredientsWithProducts.add((ingredient.$1, widget.productsMap[ingredient.$1.productId]));
        }
        // check whether the ingredient unit is compatible with the default unit
        var (errorType, errorMsg) = validateAmount(
          valueUnit,
          valueDefUnit,
          valueAutoCalc,
          valueIngredients.isEmpty,
          valueResultingAmount,
          valueDensityConversion,
          valueQuantityConversion,
        );
        
        Widget errorText = 
          errorMsg == null
            ? const SizedBox()
            : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15 * gsf),
              child: Text(
                errorMsg,
                textAlign: TextAlign.left,
                style: TextStyle(
                  color: errorType == ErrorType.warning ? warningColor : Colors.red,
                  fontSize: 16 * gsf)
                ),
            );
        
        // calculate the resulting amount
        List<double>? amounts;
        if (valueAutoCalc) {
          double resultingAmount;
          (resultingAmount, amounts) = calcResultingAmount(
            ingredientsWithProducts,
            valueUnit,
            valueDensityConversion,
            valueQuantityConversion,
          );
          String roundedAmount = roundDouble(resultingAmount);
          resultingAmount = double.parse(roundedAmount);
          
          if (!resultingAmount.isNaN && resultingAmount != valueResultingAmount) {
            // // after frame callback to avoid changing the value during build
            WidgetsBinding.instance.addPostFrameCallback((_) {
              widget.resultingAmountNotifier.value = resultingAmount;
              widget.resultingAmountController.text = roundedAmount;
            });
          }
        }
        
        // same as above but using ingredientsWithProducts
        
        List<List<String>> errors = ingredientsWithProducts.map((pair) => validateIngredient(
          products: widget.productsMap,
          ingrProd: pair.$2,
          product:  widget.prevProduct,
        )).toList();
        
        var circRefs = errors.map((list) => list.contains("Circular Reference")).toList();
        var outsideTempRange = errors.map((list) => list.contains("Outside temporary range")).toList();
        
        var hasError = circRefs.any((element) => element) || outsideTempRange.any((element) => element);
        
        if (hasError == widget.validNotifier.value) {
          widget.validNotifier.value = !hasError;
        }
        
        if (hasError) {
          errorType = ErrorType.error;
        }
        
        bool scaleBtnEnabled = errorType != ErrorType.error && valueIngredients.isNotEmpty;
        if (scaleBtnEnabled && valueIngredients.any((pair) => pair.$1.productId == null)) scaleBtnEnabled = false;
        
        var scaleBtnStyle = lightButtonStyle.copyWith(
          padding: WidgetStateProperty.all(const EdgeInsets.symmetric(horizontal: 13, vertical: 10) * gsf),
          shape: WidgetStateProperty.all(const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(9 * gsf)),
          )),
          minimumSize: WidgetStateProperty.all(null),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          backgroundColor: WidgetStateProperty.all(scaleBtnEnabled ? areaButtonColor : Colors.grey.withOpacity(0.12)), // const Color.fromARGB(255, 225, 248, 242)
        );
        
        if (!scaleBtnEnabled) {
          scaleBtnStyle = scaleBtnStyle.copyWith(
          splashFactory: NoSplash.splashFactory,
          );
        }
        
        return BorderBox(
          title: "Ingredients",
          borderColor: errorType == ErrorType.error ? errorBorderColor : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: SwitchListTile(
                      value: valueAutoCalc,
                      controlAffinity: ListTileControlAffinity.leading,
                      visualDensity: VisualDensity.compact,
                      onChanged: (bool value) {
                        widget.autoCalcAmountNotifier.value = value;
                        widget.intermediateSave();
                      },
                      title: Padding(
                        padding: const EdgeInsets.only(top: 2) * gsf,
                        child: const Text(
                          "Autocalc amount",
                          style: TextStyle(
                            fontSize: 16 * gsf,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 5 * gsf),
                    child: IconButton(
                      style: scaleBtnStyle,
                      // custom icon 
                      icon: Image.asset(
                        "assets/scale.png",
                        width: 21 * gsf,
                        height: 21 * gsf,                      
                        // primary color of theme
                        color: scaleBtnEnabled ? const Color.fromARGB(255, 0, 141, 122) : Colors.grey.withOpacity(0.65),
                      ),
                      onPressed: () async {
                        if (!scaleBtnEnabled) return;
                          
                        double? scaleFactor = await showScaleModal(
                          context: context,
                          productsMap: widget.productsMap,
                          currentAmount: valueResultingAmount,
                          unit: valueUnit,
                          ingredients: valueIngredients.map((pair) => pair.$1).toList(),
                          productName: productName,
                        );
                        
                        if (scaleFactor == null) return;
                        if (scaleFactor.isInfinite || scaleFactor.isNaN || scaleFactor <= 0) {
                          if (context.mounted) {
                            showErrorbar(
                              context,
                              "Invalid scale factor",
                              duration: 2.5,
                            );
                          }
                          return;
                        }
                        
                        for (int i = 0; i < valueIngredients.length; i++) {
                          var ingredient = valueIngredients[i];
                          valueIngredients[i] = (
                            ProductQuantity(
                              productId: ingredient.$1.productId,
                              amount: ingredient.$1.amount * scaleFactor,
                              unit: ingredient.$1.unit,
                            ),
                            ingredient.$2,
                          );
                          widget.ingredientAmountControllers[i].text = truncateZeros(ingredient.$1.amount * scaleFactor);
                        }
                        widget.resultingAmountNotifier.value = valueResultingAmount * scaleFactor;
                        widget.resultingAmountController.text = truncateZeros(valueResultingAmount * scaleFactor);
                        widget.ingredientsNotifier.value = List.from(valueIngredients);
                        widget.intermediateSave();
                      }
                    ),
                  ),
                  const SizedBox(width: 14 * gsf),
                ],
              ),
              const SizedBox(height: 7 * gsf),
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 0, 8, 8) * gsf,
                child: Row(
                  children: [
                    Padding( // resulting ingredient amount field
                      padding: EdgeInsets.symmetric(horizontal: valueAutoCalc ? 12 : 10) * gsf,
                      child: valueAutoCalc ? 
                        Text(
                          valueResultingAmount.isNaN ? "NaN" : roundDouble(valueResultingAmount),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16 * gsf,
                          )
                        )
                        : SizedBox(
                          width: 80 * gsf,
                          child: AmountField(
                            controller: widget.resultingAmountController,
                            enabled: !valueAutoCalc,
                            onChangedAndParsed: (value) {
                              widget.resultingAmountNotifier.value = value;
                              widget.intermediateSave();
                            },
                            padding: 0,
                          )
                        ),
                    ),
                    SizedBox( // ingredient unit dropdown
                      width: 95 * gsf,
                      child: UnitDropdown(
                        items: buildUnitItems(verbose: true, quantityName: widget.quantityNameController.text), 
                        current: valueUnit,
                        intermediateSave: widget.intermediateSave,
                        onChanged: (Unit? unit) {
                          var newUnit = unit ?? Unit.g;
                          widget.onChanged(newUnit, valueIngredients, null);
                        },
                      ),
                    ),
                    const SizedBox(width: 8 * gsf),
                    Flexible(
                      child: Text(
                        "of $productName contains:",
                        maxLines: 3,
                        style: const TextStyle(
                          fontSize: 16 * gsf,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              errorText,
              const SizedBox(height: 8 * gsf),
              _buildIngredientsList(context, widget.productsMap, valueIngredients, amounts, errors, valueUnit, widget.quantityNameController.text),
              _buildAddIngredientButton(context, widget.productsMap, valueIngredients, widget.id),
            ],
          ),
        );
      },
    );
  }

  Widget _buildIngredientsList(
    BuildContext context,
    Map<int, Product> productsMap,
    List<(ProductQuantity, Color)> ingredients,
    List<double>? amounts,
    List<List<String>> errors,
    Unit targetUnit,
    String quantityName,
  ) {
    // if ingredients is empty, return a single list tile with a message
    if (ingredients.isEmpty) {
      return const ListTile(
        contentPadding: EdgeInsets.zero,
        minVerticalPadding: 0,
        visualDensity: VisualDensity(horizontal: 0, vertical: -2),
        title: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 14 * gsf - 14),
            child: Text(
              "No ingredients yet",
              style: TextStyle(
                fontSize: 16 * gsf,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ),
        titleAlignment: ListTileTitleAlignment.center,
        tileColor: Color.fromARGB(14, 0, 0, 255),
      );
    }
    
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(),
      child: SlidableReorderableList(
        key: Key("slidable reorderable list of ingredients of length ${ingredients.length}"),
        buildDefaultDragHandles: false,
        
        entries: _getIngredientEntries(context, productsMap, ingredients, amounts, errors, targetUnit, widget.id),
        menuWidth: 90 * gsf,
        onReorder: ((oldIndex, newIndex) {
          if (oldIndex < newIndex) {
            newIndex -= 1;
          }
          var ingredient = ingredients.removeAt(oldIndex);
          ingredients.insert(newIndex, ingredient);
          widget.ingredientsNotifier.value = List.from(ingredients);
          
          var controller = widget.ingredientAmountControllers.removeAt(oldIndex);
          widget.ingredientAmountControllers.insert(newIndex, controller);
        }),
      ),
    );
  }

  List<SlidableListEntry> _getIngredientEntries(
    BuildContext context,
    Map<int, Product> productsMap,
    List<(ProductQuantity, Color)> ingredients,
    List<double>? amounts,
    List<List<String>> errors,
    Unit targetUnit,
    int id,
  ) {
    // remove all ingredient products from products list
    var reducedProducts = reduceProducts(productsMap, ingredients.map((pair) => pair.$1).toList(), id);
    
    var entries = <SlidableListEntry>[];
    
    // check whether there are the correct number of focus nodes
    for (int i = widget.ingredientDropdownFocusNodes.length; i < ingredients.length; i++) {
      widget.ingredientDropdownFocusNodes.add(FocusNode());
    }
    for (int i = widget.ingredientDropdownFocusNodes.length; i > ingredients.length; i--) {
      widget.ingredientDropdownFocusNodes.removeLast();
    }
    
    for (int index = 0; index < ingredients.length; index++) {
      var ingredient = ingredients[index].$1;
      bool dark = index % 2 == 0;
      var color = dark ? const Color.fromARGB(11, 83, 83, 117) : const Color.fromARGB(6, 200, 200, 200);
      var focusNode1 = widget.ingredientDropdownFocusNodes[index];
      
      var product = ingredient.productId != null 
        ? productsMap[ingredient.productId]
        : null;
      
      var availableProducts = <int, Product>{};
      availableProducts.addAll(reducedProducts);
      if (product != null) availableProducts[product.id] = product;
      
      // check whether selected unit is compatible with the product
      var unit = ingredient.unit;
      if (product != null && !product.getAvailableUnits().contains(unit)) {
        unit = product.defaultUnit;
        ingredients[index] = (
          ProductQuantity(
            productId: ingredient.productId,
            amount: ingredient.amount,
            unit: unit,
          ),
          ingredients[index].$2,
        );
        // update after build
        WidgetsBinding.instance.addPostFrameCallback((_) {
          widget.ingredientsNotifier.value = List.from(ingredients);
        });
      }
      
      var errorType = ErrorType.none;
      var errorMsg = "";
      if (errors[index].contains("Circular Reference")) {
        errorType = ErrorType.error;
        errorMsg += "Circular Reference";
      }
      if (errors[index].contains("Outside temporary range")) {
        errorType = ErrorType.error;
        if (errorMsg != "") errorMsg += ",\n";
        errorMsg += "Outside temporary range";
      }
      
      if (product == null) {
        errorType = ErrorType.error;
        errorMsg = "Must select a product";
      } else if (errorType == ErrorType.none && amounts != null && amounts[index].isNaN) {
        errorType = ErrorType.warning;
        errorMsg = "Conversion to ${unitToLongString(targetUnit)} not possible";
      }
      
      var errorBox = errorType == ErrorType.none
        ? const SizedBox()
        : Text(
          " ⚠ $errorMsg",
          style: TextStyle(
            color: errorType == ErrorType.error ? Colors.red : warningColor,
            fontSize: 16 * gsf,
          ),
        );
      
      entries.add(
        SlidableListEntry(
          key: Key("${product == null ? "unnamed " : ""}ingredient ${product?.name} at $index of ${ingredients.length}"),
          child: ReorderableDelayedDragStartListener(
            index: index,
            child: ListTile(
              key: Key("tile for the ${product == null ? "unnamed " : ""} ingredient ${product?.name} at $index of ${ingredients.length}"),
              contentPadding: EdgeInsets.zero,
              minVerticalPadding: 0,
              visualDensity: const VisualDensity(horizontal: 0, vertical: -4),
              title: Container(
                color: color,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14) * gsf,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FormField(
                        builder: (context) => ProductDropdown(
                          productsMap: availableProducts,
                          selectedProduct: product,
                          // index: index,
                          focusNode: focusNode1,
                          // autofocus: index == widget.focusIndex ? widget.autofocusTime : null,
                          autofocusSearch: true,
                          beforeTap: () => widget.intermediateSave(),
                          onChanged: (Product? newProduct) {
                            if (newProduct != null) {
                              // Check whether the new product supports the current unit
                              late Unit newUnit;
                              var currentUnit = unit;
                              newUnit = (newProduct.getAvailableUnits().contains(currentUnit)) ? currentUnit : newProduct.defaultUnit;
                              
                              ingredients[index] = (
                                ProductQuantity(
                                  productId: newProduct.id,
                                  amount:    ingredient.amount,
                                  unit:      newUnit,
                                ),
                                ingredients[index].$2,
                              );
                              widget.onChanged(widget.ingredientsUnitNotifier.value, ingredients, index);
                              widget.ingredientsNotifier.value = List.from(ingredients);
                              // WidgetsBinding.instance.addPostFrameCallback((_) => _requestIngredientFocus(index, 0));
                              // // request after 200 ms
                              // Future.delayed(const Duration(milliseconds: 200), () => _requestIngredientFocus(index, 0));
                            }
                          },
                        ),
                        validator: (value) => errorType != ErrorType.error ? null : errorMsg,
                      ),
                      const SizedBox(height: 12 * gsf),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // amount field
                          Expanded(
                            child: AmountField(
                              controller: widget.ingredientAmountControllers[index],
                              padding: 0,
                              onChangedAndParsed: (value) {
                                var prev = ingredients[index];
                                ingredients[index] = (
                                  ProductQuantity(
                                    productId: prev.$1.productId,
                                    amount: value,
                                    unit: prev.$1.unit,
                                  ),
                                  prev.$2,
                                );
                                widget.ingredientsNotifier.value = List.from(ingredients);
                                widget.onChanged(widget.ingredientsUnitNotifier.value, ingredients, null);
                              }
                            ),
                          ),
                          const SizedBox(width: 9 * gsf),
                          // unit dropdown
                          Expanded(
                            child: UnitDropdown(
                              items: buildUnitItems(units: product?.getAvailableUnits() ?? Unit.values, quantityName: product?.quantityName ?? "x"),
                              current: unit,
                              onChanged: (Unit? unit) {
                                if (unit != null) {
                                  var prev = ingredients[index];
                                  ingredients[index] = (
                                    ProductQuantity(
                                      productId: prev.$1.productId,
                                      amount: prev.$1.amount,
                                      unit: unit,
                                    ),
                                    prev.$2,
                                  );
                                  widget.ingredientsNotifier.value = List.from(ingredients);
                                  widget.onChanged(widget.ingredientsUnitNotifier.value, ingredients, null);
                                }
                              }
                            ),
                          ),
                        ]
                      ),
                      SizedBox(height: errorType == ErrorType.none ? 0 : 10),
                      errorBox
                    ],
                  ),
                ),
              ),
            ),
          ),
          menuItems: [
            Container(
              color: const Color.fromARGB(255, 90, 150, 255),
              child: Tooltip(
                message: "Edit Product",
                textStyle: const TextStyle(
                  fontSize: 14 * gsf,
                  color: Colors.white,
                ),
                child: ExcludeFocusTraversal(
                  child: IconButton(
                    color: Colors.white,
                    icon: const Icon(Icons.edit),
                    iconSize: 24 * gsf,
                    onPressed: () {
                      // navigate to edit the product
                      if (product != null) {
                        widget.intermediateSave();
                        Navigator.of(context).pushNamed(
                          editProductRoute,
                          arguments: (product.name, false),
                        );
                      }
                    },
                  ),
                ),
              ),
            ),
            Container(
              color: Colors.red,
              child: Tooltip(
                message: "Delete Ingredient",
                textStyle: const TextStyle(
                  fontSize: 14 * gsf,
                  color: Colors.white,
                ),
                child: ExcludeFocusTraversal(
                  child: IconButton(
                    color: Colors.white,
                    icon: const Icon(Icons.delete),
                    iconSize: 24 * gsf,
                    onPressed: () {
                      ingredients.removeAt(index);
                      widget.ingredientAmountControllers.removeAt(index);
                      widget.ingredientsNotifier.value = List.from(ingredients);
                      widget.onChanged(widget.ingredientsUnitNotifier.value, ingredients, null);
                    },
                  ),
                ),
              ),
            ),
          ],
        )
      );
    }
    
    return entries;
  }

  Widget _buildAddIngredientButton(BuildContext context, Map<int, Product> productsMap, List<(ProductQuantity, Color)> ingredients, int id) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color.fromARGB(255, 210, 235, 198),
        foregroundColor: Colors.black,
        minimumSize: const Size(double.infinity, 50 * gsf),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 16 * gsf),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(14 * gsf),
            bottomRight: Radius.circular(14 * gsf),
          ),
        ),
        textStyle: Theme.of(context).textTheme.bodyLarge,
      ),
      icon: const Icon(Icons.add, size: 20 * gsf),
      label: const Padding(
        padding: EdgeInsets.only(left: 5.0 * gsf),
        child: Text("Add Ingredient"),
      ),
      onPressed: () async {// remove all ingredient products from products list
        var reducedProducts = reduceProducts(productsMap, ingredients.map((pair) => pair.$1).toList(), id);
        Map<int, double>? relevancies;
        try {
          relevancies = await AsyncProvider.getRelevancies(useCached: CacheMode.cached);
        } finally {}
        
        // show product dialog
        widget.intermediateSave();
        if (context.mounted) showProductDialog(
          context: context,
          productsMap: reducedProducts,
          relevancies: relevancies,
          selectedProduct: null,
          autofocus: true,
          onSelected: (Product? product) {
            if (product != null) {
              var defUnit = product.defaultUnit;
              double amount;
              if (defUnit == Unit.quantity || defUnit == Unit.l || defUnit == Unit.kg) {
                amount = 1.0;
              } else {
                amount = 100.0;
              }
              // list of all colors used in the ingredients
              var colorsUsed = ingredients.map((e) => e.$2).toSet();
              var color = productColors.firstWhere((c) => !colorsUsed.contains(c), orElse: () => productColors[colorsUsed.length % productColors.length]);
              devtools.log("adding ${product.name} with color $color");
              
              ingredients.add((
                ProductQuantity(
                  productId: product.id,
                  amount: amount,
                  unit: product.defaultUnit,
                ),
                color,
              ));
              var newController = TextEditingController();
              newController.text = truncateZeros(amount);
              widget.ingredientAmountControllers.add(newController);
              widget.ingredientsNotifier.value = List.from(ingredients);
              widget.onChanged(widget.ingredientsUnitNotifier.value, ingredients, null);
              Future.delayed(const Duration(milliseconds: 50), () => widget.requestIngredientFocus(ingredients.length - 1, 1));
            }
          },
          beforeAdd: () => widget.intermediateSave(),
        );
      },
    );
  }


}