import 'package:flutter/material.dart';

import '../services/data/data_objects.dart';
import '../utility/theme.dart';
import '../widgets/amount_field.dart';
import '../widgets/border_box.dart';
import '../widgets/multi_value_listenable_builder.dart';
import '../widgets/unit_dropdown.dart';

class ConversionBoxes extends StatelessWidget {
  final ValueNotifier<Unit> defaultUnitNotifier;
  final ValueNotifier<Conversion> densityConversionNotifier;
  final ValueNotifier<Conversion> quantityConversionNotifier;
  final TextEditingController densityAmount1Controller;
  final TextEditingController densityAmount2Controller;
  final TextEditingController quantityAmount1Controller;
  final TextEditingController quantityAmount2Controller;
  final TextEditingController quantityNameController;
  final Function() onValidate;
  
  const ConversionBoxes({
    required this.defaultUnitNotifier,
    required this.densityConversionNotifier,
    required this.quantityConversionNotifier,
    required this.densityAmount1Controller,
    required this.densityAmount2Controller,
    required this.quantityAmount1Controller,
    required this.quantityAmount2Controller,
    required this.quantityNameController,
    required this.onValidate,
    Key? key
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return MultiValueListenableBuilder(
      listenables: [
        defaultUnitNotifier,
        densityConversionNotifier,
        quantityConversionNotifier,
      ],
      builder: (context, values, child) {
        var valueUnit = values[0] as Unit;
        var valueConv1 = values[1] as Conversion;
        var valueConv2 = values[2] as Conversion;
        return Column(
          children: [
            _buildConversionBox(0, densityConversionNotifier, valueConv2, valueUnit),
            const SizedBox(height: 10),
            _buildConversionBox(1, quantityConversionNotifier, valueConv1, valueUnit),
          ],
        );
      },
    );
  }
  
  Widget _buildConversionBox(int index, ValueNotifier<Conversion> notifier, Conversion otherConversion, Unit defUnit) {
    return LayoutBuilder(
      builder: (context, constraints) {
        var conversion = notifier.value;
        
        var checkBoxTexts = ["Volumetric Conversion", "Quantity Conversion"];
        var text = checkBoxTexts[index];
        var controller1 = index == 0 ? densityAmount1Controller : quantityAmount1Controller;
        var controller2 = index == 0 ? densityAmount2Controller : quantityAmount2Controller;
        var units1 = index == 0 ? volumetricUnits : null;
        var units2 = index == 0 ? weightUnits : Unit.values.where((unit) => unit != Unit.quantity).toList();

        var enabled = conversion.enabled;
        var textAlpha = enabled ? 255 : 100;
        String? validationString = validateConversionBox(index, defUnit, densityConversionNotifier.value, quantityConversionNotifier.value, quantityNameController.text);
        Color? borderColor;
        if (enabled) {
          borderColor = validationString == null ? null : errorBorderColor;
        } else {
          borderColor = disabledBorderColor;
        }
        
        // create unit dropdowns
        Widget dropdown1;
        if (units1 != null) {
          dropdown1 = UnitDropdown(
            items: buildUnitItems(units: units1, quantityName: quantityNameController.text),
            enabled: conversion.enabled,
            current: conversion.unit1,
            onChanged: (Unit? unit) {
              if (unit != null) {
                notifier.value = notifier.value.withUnit1(unit);
              }
            }
          );
        } else {
          // quantity name field instead of dropdown
          dropdown1 = TextFormField(
            enabled: conversion.enabled,
            controller: quantityNameController,
            decoration: const InputDecoration(
              labelText: "Designation",
            ),
            textInputAction: TextInputAction.next,
            validator: (String? value) {
              if (!conversion.enabled) {
                return null;
              }
              if (value == null || value.isEmpty) {
                return "Required Field";
              }
              return null;
            },
            autovalidateMode: AutovalidateMode.onUserInteraction,
          );
        }
        var dropdown2 = UnitDropdown(
          items: buildUnitItems(units: units2, quantityName: quantityNameController.text),
          enabled: conversion.enabled,
          current: conversion.unit2,
          onChanged: (Unit? unit) {
            if (unit != null) {
              notifier.value = notifier.value.withUnit2(unit);
            }
          }
        );
        
        var equalSign = Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Text(
            "=",
            style: TextStyle(
              color: Colors.black.withAlpha(textAlpha),
              fontSize: 16,
            ),
          ),
        );
        
        bool isWide = constraints.maxWidth > 450;
        
        Widget inputFields = isWide
          ? Row(
            children: [
              Expanded(child: _buildConversionAmountField(notifier: notifier, controller: controller1, index: 1)),
              Expanded(child: dropdown1),
              equalSign,
              Expanded(child: _buildConversionAmountField(notifier: notifier, controller: controller2, index: 2)),
              Expanded(child: dropdown2),
            ]
          )
          : Table(
            columnWidths: const {
              0: IntrinsicColumnWidth(),
              1: FlexColumnWidth(1),
              2: FlexColumnWidth(1),
            },
            children: [
              TableRow(
                children: [
                  const SizedBox.shrink(),
                  _buildConversionAmountField(notifier: notifier, controller: controller1, index: 1),
                  dropdown1,
                ]
              ),
              // spacing
              const TableRow(
                children: [
                  SizedBox(height: 15),
                  SizedBox(height: 15),
                  SizedBox(height: 15),
                ]
              ),
              TableRow(
                children: [
                  TableCell(
                    verticalAlignment: TableCellVerticalAlignment.middle,
                    child: equalSign,
                  ),
                  _buildConversionAmountField(notifier: notifier, controller: controller2, index: 2),
                  dropdown2,
                ]
              ),
            ],
          );
        
        if (!conversion.enabled) inputFields = const SizedBox();
        
        return BorderBox(
          borderColor: borderColor,
          child: Padding(
            padding: EdgeInsets.fromLTRB(0, 8, 12, conversion.enabled ? 16 : 0),
            child: Column(
              children: [
                SwitchListTile(
                  value: enabled,
                  controlAffinity: ListTileControlAffinity.leading,
                  onChanged: (bool value) {
                    // validate form after future build
                    if (!value) {
                      Future(() => onValidate());
                    }
                    notifier.value = notifier.value.switched(value);
                  },
                  title: Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      text,
                      style: TextStyle(
                        color: Colors.black.withAlpha(((textAlpha + 255) / 2).round()),
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                inputFields,
                // Text for validation message
                if (validationString != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                    child: 
                    Text(
                      validationString,
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 15,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      }
    );
  }
  
  /* 
  *  Amount field for the conversion fields
  */
  _buildConversionAmountField({
    required ValueNotifier<Conversion> notifier,
    required TextEditingController controller,
    required int index,
  }) {
    return AmountField(
      controller: controller,
      enabled: notifier.value.enabled,
      onChangedAndParsed: (value) {
        if (index == 1) {
          notifier.value = notifier.value.withAmount1(value);
        } else {
          notifier.value = notifier.value.withAmount2(value);
        }
      }
    );
  }
}
  
String? validateConversionBox(int index, Unit defUnit, Conversion densityConversion, Conversion quantityConversion, String quantityName) {
  // check whether all children of the conversion field are valid
  var conv = index == 0 ? densityConversion : quantityConversion;
  var otherConv = index == 0 ? quantityConversion : densityConversion;
  
  // Check if conversion is active
  if (conv.enabled) {
    // Check whether one of the amount fields is 0
    if (conv.amount1 == 0 || conv.amount2 == 0) {
      return "Both amounts must be >0";
    }
    // Check whether a conversion to the default unit is possible
    if (index == 1) {
      if (defUnit != Unit.quantity) {
        bool different = volumetricUnits.contains(defUnit) ^ volumetricUnits.contains(conv.unit2);
        if (different && !otherConv.enabled) {
          return "Cannot convert quantity ($quantityName) to default unit (${unitToString(defUnit)}) without density conversion.";
        }
      }
    } else {
      if (defUnit == Unit.quantity && !otherConv.enabled) {
        return "If the default unit is quantity ($quantityName), the quantity conversion must be enabled.";
      }
    }
  }
  
  return null;
}