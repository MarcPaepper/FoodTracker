// ignore_for_file: curly_braces_in_flow_control_structures

import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:food_tracker/utility/theme.dart";

import "../constants/routes.dart";
import "../services/data/async_provider.dart";
import '../services/data/data_objects.dart';
import "../utility/data_logic.dart";
import "../utility/modals.dart";
import "../utility/text_logic.dart";
import "amount_field.dart";
import "border_box.dart";
import "product_dropdown.dart";
import "slidable_list.dart";
import "unit_dropdown.dart";

 import "dart:developer" as devtools show log;

class FoodBox extends StatefulWidget {
  final Map<int, Product> productsMap;
  final int? focusIndex;
  final DateTime? autofocusTime;
  
  final ValueNotifier<List<(ProductQuantity, Color)>> ingredientsNotifier;
  final List<TextEditingController> ingredientAmountControllers;
  final List<FocusNode>? ingredientDropdownFocusNodes;
  
  final bool? canChangeProducts;
  
  // final Function() intermediateSave;
  // final Function(List<ProductQuantity>) onChanged;
  final Function(int, int) requestIngredientFocus;
  
  const FoodBox({
    required this.productsMap,
             this.focusIndex,
             this.autofocusTime,
    required this.ingredientsNotifier,
    required this.ingredientAmountControllers,
             this.ingredientDropdownFocusNodes,
             this.canChangeProducts,
    // required this.intermediateSave,
    // required this.onChanged,
    required this.requestIngredientFocus,
    super.key,
  });

  @override
  State<FoodBox> createState() => _FoodBoxState();
}

class _FoodBoxState extends State<FoodBox> {
  bool hasFocusNodes = false;
  late final bool canChange;
  
  @override
  void initState() {
    hasFocusNodes = widget.ingredientDropdownFocusNodes != null;
    canChange = widget.canChangeProducts ?? true;
    super.initState();
  }
  
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: widget.ingredientsNotifier,
      builder: (context, List<(ProductQuantity, Color)> ingredients, _) {
        devtools.log("ingredients change detected");
        return BorderBox(
          child: Container(
            clipBehavior: Clip.antiAlias,
            // rounded corners
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildIngredientsList(context, ingredients, widget.canChangeProducts ?? true),
                canChange ? _buildAddButton(context, ingredients.isEmpty, ingredients) : const SizedBox(height: 0),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildIngredientsList(
    BuildContext context,
    List<(ProductQuantity, Color)> ingredients,
    bool canDelete,
  ) {
    List<SlidableListEntry> entries;
    bool valid;
    (entries, valid) = _getIngredientEntries(context, widget.productsMap, ingredients);
    
    return FormField(
      validator: (value) {
        if (!valid) {
          return "Please fill out all ingredients";
        }
        return null;
      },
      autovalidateMode: AutovalidateMode.always,
      builder: (state) {
        return SlidableList(
          entries: entries,
          menuWidth: canChange ? 90 : 50,
        );
      },
    );
  }
  
  (List<SlidableListEntry>, bool) _getIngredientEntries(
    BuildContext context,
    Map<int, Product> productsMap,
    List<(ProductQuantity, Color)> ingredients,
  ) {
    // remove all products from product list
    var prodQuantities = ingredients.map((e) => e.$1).toList();
    var reducedProducts = reduceProducts(productsMap, prodQuantities, null);
    
    var entries = <SlidableListEntry>[];
    
    // check whether there are the correct number of focus nodes
    if (hasFocusNodes) {
      for (int i = widget.ingredientDropdownFocusNodes!.length; i < ingredients.length; i++) {
        widget.ingredientDropdownFocusNodes!.add(FocusNode());
      }
      for (int i = widget.ingredientDropdownFocusNodes!.length; i > ingredients.length; i--) {
        widget.ingredientDropdownFocusNodes!.removeLast();
      }
    }
    
    bool valid = true;
    
    // build the list of ingredients
    for (int index = 0; index < ingredients.length; index++) {
      var ingredient = ingredients[index];
      var productQuantity = ingredient.$1;
      bool dark = index % 2 == 0;
      var color = dark ? const Color.fromARGB(11, 83, 83, 117) : const Color.fromARGB(6, 200, 200, 200);
      var focusNode1 = hasFocusNodes ? widget.ingredientDropdownFocusNodes![index] : null;
      
      var product = productQuantity.productId != null 
        ? productsMap[productQuantity.productId]
        : null;
      
      var availableProducts = <int, Product>{};
      availableProducts.addAll(reducedProducts);
      if (product != null) availableProducts[product.id] = product;
      
      // check whether selected unit is compatible with the product
      var unit = productQuantity.unit;
      if (product != null && !product.getAvailableUnits().contains(unit)) {
        unit = product.defaultUnit;
        ingredients[index] = (
          ProductQuantity(
            productId: productQuantity.productId,
            amount: productQuantity.amount,
            unit: unit,
          ),
          ingredient.$2,
        );
        // update after build
        WidgetsBinding.instance.addPostFrameCallback((_) {
          widget.ingredientsNotifier.value = List.from(ingredients);
        });
      }
      
      var errorType = ErrorType.none;
      var errorMsg = "";
      
      if (product == null) {
        errorType = ErrorType.error;
        errorMsg = "Must select a product";
        valid = false;
      }
      
      var errorBox = errorType == ErrorType.none
        ? const SizedBox()
        : Text(
          " ⚠ $errorMsg",
          style: TextStyle(
            color: errorType == ErrorType.error ? Colors.red : warningColor,
            fontSize: 16,
          ),
        );
      
      devtools.log("Ingredient $index: ${product?.name ?? "null"} has color ${ingredient.$2}");
      
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
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: kIsWeb ? 16: 18), // TODO: Should mobile also have 16 padding?
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ProductDropdown(
                        productsMap: availableProducts,
                        selectedProduct: product,
                        // index: index,
                        focusNode: focusNode1,
                        // autofocus: index == widget.focusIndex ? widget.autofocusTime : null,
                        autofocusSearch: true,
                        beforeTap: () => {},//widget.intermediateSave(),
                        onChanged: (Product? newProduct) {
                          if (newProduct != null) {
                            // Check whether the new product supports the current unit
                            late Unit newUnit;
                            var currentUnit = unit;
                            newUnit = (newProduct.getAvailableUnits().contains(currentUnit)) ? currentUnit : newProduct.defaultUnit;
                            
                            ingredients[index] = (
                              ProductQuantity(
                                productId: newProduct.id,
                                amount:    productQuantity.amount,
                                unit:      newUnit,
                              ),
                              ingredient.$2,
                            );
                            // widget.onChanged(widget.ingredientsUnitNotifier.value, ingredients, index);
                            widget.ingredientsNotifier.value = List.from(ingredients);
                            widget.requestIngredientFocus(index, 0);
                          }
                        },
                      ),
                      const SizedBox(height: 14),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // color indicator as rounded rectangle
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: ingredient.$2,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
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
                              }
                            ),
                          ),
                          const SizedBox(width: 12),
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
                                }
                              }
                            ),
                          ),
                        ]
                      ),
                      SizedBox(height: errorType == ErrorType.none ? 0 : 10),
                      errorBox,
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
                child: ExcludeFocusTraversal(
                  child: IconButton(
                    color: Colors.white,
                    icon: const Icon(Icons.edit),
                    onPressed: () {
                      // navigate to edit the product
                      if (product != null) {
                        // widget.intermediateSave();
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
            ...canChange ? [
              Container(
                color: Colors.red,
                child: Tooltip(
                  message: "Delete Ingredient",
                  child: ExcludeFocusTraversal(
                    child: IconButton(
                      color: Colors.white,
                      icon: const Icon(Icons.delete),
                      onPressed: () {
                        ingredients.removeAt(index);
                        widget.ingredientAmountControllers.removeAt(index);
                        widget.ingredientsNotifier.value = List.from(ingredients);
                      },
                    ),
                  ),
                ),
              ),
            ] : [],
          ],
        )
      );
    }
    
    return (entries, valid);
  }
  
  Widget _buildAddButton(BuildContext context, bool roundedTop, List<(ProductQuantity, Color)> ingredients) {
    return ElevatedButton.icon(
      style: addButtonStyle.copyWith(
        shape: WidgetStateProperty.all<RoundedRectangleBorder>(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
              bottomLeft: const Radius.circular(14),
              bottomRight: const Radius.circular(14),
              topRight: Radius.circular(roundedTop ? 14 : 0),
              topLeft: Radius.circular(roundedTop ? 14 : 0),
            ),
          ),
        ),
        minimumSize: WidgetStateProperty.all<Size>(const Size(0, 50)),
      ),
      onPressed: () async {
        Map<int, double>? relevancies;
        try {
          relevancies = await AsyncProvider.getRelevancies();
        } finally {}
        
        // remove ingredient products from products map
        var prodQuantities = ingredients.map((e) => e.$1).toList();
        var reducedProducts = reduceProducts(widget.productsMap, prodQuantities, null);
        
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
                  unit: defUnit,
                ),
                color,
              ));
              var newController = TextEditingController();
              newController.text = truncateZeros(amount);
              widget.ingredientAmountControllers.add(newController);
              widget.ingredientsNotifier.value = List.from(ingredients);
              // widget.onChanged(widget.ingredientsUnitNotifier.value, ingredients, null);
              Future.delayed(const Duration(milliseconds: 50), () => widget.requestIngredientFocus(ingredients.length - 1, 1));
            }
          },
          beforeAdd: () => {},//widget.intermediateSave(),
        );
      },
      label: const Text("Add Ingredient"),
      icon: const Icon(Icons.add),
    );
  }
}