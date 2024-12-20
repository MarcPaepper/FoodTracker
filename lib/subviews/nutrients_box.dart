import 'package:flutter/material.dart';

import '../services/data/data_objects.dart';
import '../utility/data_logic.dart';
import '../utility/text_logic.dart';
import '../utility/theme.dart';
import '../widgets/amount_field.dart';
import '../widgets/border_box.dart';
import '../widgets/multi_value_listenable_builder.dart';
import '../widgets/unit_dropdown.dart';

// import 'dart:developer' as devtools show log;

class NutrientsBox extends StatelessWidget {
  final List<NutritionalValue> nutValues;
  final Map<int, Product> productsMap;
  
  final ValueNotifier<double> nutrientAmountNotifier;
  final ValueNotifier<Unit> nutrientsUnitNotifier;
  final ValueNotifier<List<ProductNutrient>> nutrientsNotifier;
  final ValueNotifier<Unit> defaultUnitNotifier;
  final ValueNotifier<Conversion> densityConversionNotifier;
  final ValueNotifier<Conversion> quantityConversionNotifier;
  final ValueNotifier<List<(ProductQuantity, Color)>> ingredientsNotifier;
  final ValueNotifier<Unit> ingredientsUnitNotifier;
  final ValueNotifier<double> resultingAmountNotifier;
  
  final TextEditingController quantityNameController;
  final TextEditingController nutrientAmountController;
  final List<TextEditingController> nutrientAmountControllers;
  
  final Function(Unit) onUnitChanged;
  final Function() intermediateSave;
  
  const NutrientsBox({
    required this.nutValues,
    required this.productsMap,
    required this.nutrientAmountNotifier,
    required this.nutrientsUnitNotifier,
    required this.nutrientsNotifier,
    required this.defaultUnitNotifier,
    required this.densityConversionNotifier,
    required this.quantityConversionNotifier,
    required this.ingredientsNotifier,
    required this.ingredientsUnitNotifier,
    required this.resultingAmountNotifier,
    required this.quantityNameController,
    required this.nutrientAmountController,
    required this.nutrientAmountControllers,
    required this.onUnitChanged,
    required this.intermediateSave,
    super.key
  });

  @override
  Widget build(BuildContext context) {
    return MultiValueListenableBuilder(
      listenables: [
        nutrientAmountNotifier,
        nutrientsUnitNotifier,
        nutrientsNotifier,
        defaultUnitNotifier,
        densityConversionNotifier,
        quantityConversionNotifier,
        ingredientsNotifier,
        ingredientsUnitNotifier,
        resultingAmountNotifier,
        quantityNameController
      ],
      builder: (context, values, child) {
        var valueAmount             = values[0] as double;
        var valueNutrientsUnit      = values[1] as Unit;
        var valueNutrients          = values[2] as List<ProductNutrient>;
        var valueDefUnit            = values[3] as Unit;
        var valueDensityConversion  = values[4] as Conversion;
        var valueQuantityConversion = values[5] as Conversion;
        var valueIngredients        = values[6] as List<(ProductQuantity, Color)>;
        var valueIngredientsUnit    = values[7] as Unit;
        var valueResultingAmount    = values[8] as double;
        
        var anyAutoCalc = valueNutrients.any((nutrient) => nutrient.autoCalc);
        var isEmpty = !(anyAutoCalc || valueNutrients.any((nutrient) => nutrient.value != 0));
        
        // calculate the nutrient values
        var updatedNutrients = calcNutrients(
          nutrients: valueNutrients,
          ingredients: valueIngredients.map((pair) => pair.$1).toList(),
          productsMap: productsMap,
          ingredientsUnit: valueIngredientsUnit,
          nutrientsUnit: valueNutrientsUnit,
          densityConversion: valueDensityConversion,
          quantityConversion: valueQuantityConversion,
          amountForIngredients: valueResultingAmount,
          amountForNutrients: valueAmount,
        ).$1;
        
        // if any value differs, update the nutrient values
        for (var i = 0; i < valueNutrients.length; i++) {
          if (valueNutrients[i].value != updatedNutrients[i].value) {
            nutrientsNotifier.value = updatedNutrients;
            break;
          }
        }
        
        // check whether the ingredient unit is compatible with the default unit
        var (errorType, errorMsg) = validateAmount(
          valueNutrientsUnit,
          valueDefUnit,
          anyAutoCalc,
          isEmpty,
          valueAmount,
          valueDensityConversion,
          valueQuantityConversion,
        );
        
        Widget errorText = 
          errorMsg == null
            ? const SizedBox()
            : Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Text(
                errorMsg,
                textAlign: TextAlign.left,
                style: TextStyle(
                  color: errorType == ErrorType.warning ? warningColor : Colors.red,
                  fontSize: 16)
                ),
            );
        
        return BorderBox(
          title: "Nutrients",
          borderColor: errorType == ErrorType.error ? errorBorderColor : null,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 6, 14, 0),
                child: Row(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    const Text(
                      "Nutrients for ",
                      maxLines: 3,
                      style: TextStyle(
                        fontSize: 16,
                      ),
                    ),
                    Flexible(
                      child: Padding( // resulting ingredient amount field
                        padding: const EdgeInsets.only(right: 12),
                        child: AmountField(
                          controller: nutrientAmountController,
                          onChangedAndParsed: (value) {
                            nutrientAmountNotifier.value = value;
                            intermediateSave();
                          },
                          padding: 0,
                        )
                      ),
                    ),
                    Flexible(
                      child: UnitDropdown(
                        items: buildUnitItems(verbose: true, quantityName: quantityNameController.text), 
                        current: valueNutrientsUnit,
                        onChanged: (Unit? unit) => onUnitChanged(unit?? Unit.g),
                      ),
                    ),
                    const Text(
                      " :  ",
                      maxLines: 3,
                      style: TextStyle(
                        fontSize: 16,
                      ),
                    ),
                    const Column(
                      children: [
                       Tooltip(
                          message: "Fields left empty are calculated automatically from ingredients and are shown as blue.",
                          child: Icon(
                            Icons.info_outline,
                            size: 22.0,
                            color: Colors.blue,
                          ),
                        ),
                        SizedBox(height: 14),
                      ],
                    ),
                  ],
                ),
              ),
              errorText,
              const SizedBox(height: 12),
              _buildNutrientsList(valueNutrients, nutValues),
            ],
          ),
        );
      }
    );
  }
  
  Widget _buildNutrientsList(
    List<ProductNutrient> nutrients,
    List<NutritionalValue> nutValues,
  ) {
    // sort nutValues by order id
    nutValues.sort((a, b) => a.orderId - b.orderId);
    
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: nutValues.length,
      itemBuilder: (context, index) {
        var nutValue = nutValues[index];
        var nutrient = nutrients.firstWhere((nut) => nut.nutritionalValueId == nutValue.id);
        
        bool dark = index % 2 == 0;
        var color = dark ? const Color.fromARGB(11, 83, 83, 117) : const Color.fromARGB(6, 200, 200, 200);
        
        return ListTile(
          tileColor: color,
          key: Key("tile for the nutrient ${nutrient.nutritionalValueId}"),
          contentPadding: EdgeInsets.zero,
          minVerticalPadding: 0,
          visualDensity: const VisualDensity(horizontal: 0, vertical: -4),
          title: Row(
            children: [
              // Text field for the nutrient amount
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
                child: SizedBox(
                  width: 140,
                  child: AmountField(
                    controller: nutrientAmountControllers[index],
                    canBeEmpty: true,
                    hintText: roundDouble(nutrient.value),
                    onChangedAndParsed: (value) {
                      nutrient.value = value;
                      nutrient.autoCalc = false;
                      nutrientsNotifier.value = List.from(nutrients);
                      intermediateSave();
                    },
                    onEmptied: () {
                      nutrient.autoCalc = true;
                      nutrientsNotifier.value = List.from(nutrients);
                      intermediateSave();
                    },
                    padding: 0,
                    borderColor: nutrient.autoCalc ? const Color.fromARGB(181,  56, 141, 211) : null,//Color.fromARGB(197, 76, 129, 124),
                    fillColor: nutrient.autoCalc   ? const Color.fromARGB( 44, 155, 186, 245) : null,
                    hintColor: nutrient.autoCalc   ? const Color.fromARGB(174,  18,  83, 136)  : null,
                  ),
                ),
              ),
              // Text for the nutrient name
              Text(
                "${nutValue.unit} ${nutValue.showFullName ? nutValue.name : ""}",
                style: const TextStyle(
                  fontSize: 16,
                ),
              )
            ],
          ),
        );
      },
    );
  }
}