import 'package:flutter/material.dart';
import 'package:food_tracker/widgets/border_box.dart';

import 'package:google_fonts/google_fonts.dart';

import 'package:food_tracker/constants/routes.dart';
import 'package:food_tracker/services/data/data_objects.dart';
import 'package:food_tracker/services/data/data_service.dart';
import 'package:food_tracker/utility/modals.dart';
import 'package:food_tracker/widgets/loading_page.dart';

import "dart:developer" as devtools show log;

class EditProductView extends StatefulWidget {
  final String? productName;
  final bool? isEdit;
  
  const EditProductView({Key? key, this.isEdit, this.productName}) : super(key: key);

  @override
  State<EditProductView> createState() => _EditProductViewState();
}

class _EditProductViewState extends State<EditProductView> {
  final _dataService = DataService.current();
  
  late final GlobalKey<FormState> _formKey;
  late final TextEditingController _productNameController;
  late final TextEditingController _densityAmount1Controller;
  late final TextEditingController _densityAmount2Controller;
  late final TextEditingController _quantityAmount1Controller;
  late final TextEditingController _quantityAmount2Controller;
  late final TextEditingController _quantityNameController;
  late final TextEditingController _amountForIngredientsController;
  
  late final bool isEdit;
  
  int _id = -1;
  late Product prevProduct;
  
  final _densityConversionNotifier = ValueNotifier<Conversion>(Conversion.defaultDensity());
  final _quantityConversionNotifier = ValueNotifier<Conversion>(Conversion.defaultQuantity());
  final _defaultUnitNotifier = ValueNotifier<Unit>(Unit.g);
  
  final _autoCalcAmountNotifier = ValueNotifier<bool>(false);
  final _ingredientsUnitNotifier = ValueNotifier<Unit>(Unit.g);
  
  final _isDuplicateNotifier = ValueNotifier<bool>(false);
  
  @override
  void initState() {
    if (widget.isEdit == null || (widget.isEdit! && widget.productName == null)) {
      Future(() {
        showErrorbar(context, "Error: Product not found");
        Navigator.of(context).pop();
      });
    }
    
    _formKey = GlobalKey<FormState>();
    
    isEdit = widget.isEdit ?? false;
    
    _productNameController = TextEditingController();
    _densityAmount1Controller = TextEditingController();
    _densityAmount2Controller = TextEditingController();
    _quantityAmount1Controller = TextEditingController();
    _quantityAmount2Controller = TextEditingController();
    _quantityNameController = TextEditingController();
    _amountForIngredientsController = TextEditingController();
    
    super.initState();
  }
  
  @override
  void dispose() {
    _productNameController.dispose();
    _densityAmount1Controller.dispose();
    _densityAmount2Controller.dispose();
    _quantityAmount1Controller.dispose();
    _quantityAmount2Controller.dispose();
    _quantityNameController.dispose();
    _amountForIngredientsController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: _onPopInvoked,
      child: Scaffold(
        appBar: AppBar(
          title: Text(isEdit ? "Edit Product" : "Add Product"),
          actions: isEdit ? [_buildDeleteButton()] : null
        ),
        body: FutureBuilder(
          future: _dataService.getAllProducts(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              devtools.log("Error: ${snapshot.error}");
              return const Text("Error");
            }
            switch (snapshot.connectionState) {
              case ConnectionState.done:
                final products = snapshot.data as List<Product>;
                if (isEdit) {
                  try {
                    prevProduct = products.firstWhere((prod) => prod.name == widget.productName);
                    _id = prevProduct.id;
                  } catch (e) {
                    return const Text("Error: Product not found");
                  }
                } else {
                  prevProduct = Product.defaultValues();
                }
                
                _productNameController.text = widget.productName ?? prevProduct.name;
                _densityAmount1Controller.text = prevProduct.densityConversion.amount1.toString();
                _densityAmount2Controller.text = prevProduct.densityConversion.amount2.toString();
                _quantityAmount1Controller.text = prevProduct.quantityConversion.amount1.toString();
                _quantityAmount2Controller.text = prevProduct.quantityConversion.amount2.toString();
                _quantityNameController.text = prevProduct.quantityName;
                _amountForIngredientsController.text = prevProduct.amountForIngredients.toString();
                
                // remove ".0" from amount fields if it is the end of the string
                var amountFields = [_densityAmount1Controller, _densityAmount2Controller, _quantityAmount1Controller, _quantityAmount2Controller, _amountForIngredientsController];
                for (var field in amountFields) {
                  var text = field.text;
                  if (text.endsWith(".0")) {
                    field.text = text.substring(0, text.length - 2);
                  }
                }
                
                return SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(6.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        
                        children: [
                          _buildNameField(products),
                          const SizedBox(height: 5),
                          _buildDefaultUnitDropdown(),
                          const SizedBox(height: 8),
                          _buildConversionFields(),
                          const SizedBox(height: 14),
                          _buildIngredientList(),
                          _buildAddButton(),
                        ]
                      ),
                    ),
                  ),
                );
              case ConnectionState.none:
              case ConnectionState.waiting:
              case ConnectionState.active:
              default:
                return loadingPage();
            }
          }
        )
      ),
    );
  }
  
  Future _onPopInvoked(bool didPop) async {
    devtools.log("pop invoked");
    
    if (didPop) return;
    
    final NavigatorState navigator = Navigator.of(context);
    
    // test whether the product has been changed compared to the prevProduct
    var product = getProductFromForm();
    
    if (product != null && product.equals(prevProduct)) {
      Future(() => navigator.pop());
      return;
    }
    
    
    bool willPop = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Are you sure?'),
        content: const Text('Unsaved changes will be lost.'),
        surfaceTintColor: Colors.transparent,
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Yes'),
          ),
        ],
      ),
    );
    
    if (willPop) {
      Future(() => navigator.pop());
    }
  }
  
  Widget _buildDeleteButton() => 
    IconButton(
      onPressed: () {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Delete Product"),
            content: const Text("If you delete this product, all associated data will be lost."),
            surfaceTintColor: Colors.transparent,
            actions: [
              TextButton(
                onPressed: () {
                  _dataService.deleteProductWithName(widget.productName!);
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                },
                child: const Text("Delete"),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text("Cancel"),
              )
            ],
          )
        );
      },
      icon: const Icon(Icons.delete),
    );
  
  Widget _buildNameField(List<Product> products) {
    var textField = Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextFormField(
        controller: _productNameController,
        decoration: const InputDecoration(
          labelText: "Name"
        ),
        validator: (String? value) {
          for (var prod in products) {
            if (prod.name == value && prod.name != widget.productName) {
              // change notifier after build complete
              if (!_isDuplicateNotifier.value) {
                Future(() {
                  _isDuplicateNotifier.value = true;
                });
              }
              return "Already taken";
            }
          }
          if (_isDuplicateNotifier.value) {
            Future(() {
              _isDuplicateNotifier.value = false;
            });
          }
          if (value == null || value.isEmpty) {
            return "Required Field";
          }
          return null;
        },
        autovalidateMode: AutovalidateMode.onUserInteraction,
      ),
    );
    
    return ValueListenableBuilder<bool>(
      valueListenable: _isDuplicateNotifier,
      builder: (context, value, child) {
        return Column(
          children: [
            textField,
            if (value) _buildShowDuplicateButton(products),
          ],
        );
      }
    );
  }
  
  // Make a stateful name field widget which changes its state and shows a button if the name is a duplicate
  
  Widget _buildShowDuplicateButton(List<Product> products) => Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextButton(
        onPressed: () {
          final name = _productNameController.text;
          // navigate to edit view of duplicate product
          try {
            final product = products.firstWhere((prod) => prod.name == name);
            Navigator.of(context).pushNamed(
              editProductRoute,
              arguments: product.name,
            );
          } catch (e) {
            devtools.log("Error: Product not found");
          }
        },
        child: const Text(
          "Show Duplicate",
          style: TextStyle(
            color: Colors.red,
          ),
        ),
      ),
    );
  
  Widget _buildDefaultUnitDropdown() {
    return StatefulBuilder(
      builder: (BuildContext context, StateSetter setState) {
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    "Default Unit:",
                    style: TextStyle(
                      color: Colors.black.withAlpha(200),
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: _buildUnitDropdown(
                  items: _buildUnitItems(),
                  current: _defaultUnitNotifier.value,
                  onChanged: (Unit? unit) {
                    if (unit != null) {
                      setState(() {
                        _defaultUnitNotifier.value = unit;
                      });
                    }
                  }
                )
              ),
            ]
          ),
        );
      }
    );
  }
  
  Map<Unit, Widget> _buildUnitItems({List<Unit>? units, bool verbose = true, int? maxWidth}) {
    var items = <Unit, Widget>{};
    units ??= Unit.values;
    
    for (var unit in units) {
      if (unit == Unit.quantity && verbose) {
        var quantityName = _quantityNameController.text;
        items[unit] = RichText(
          text: TextSpan(
            style: TextStyle(
              fontFamily: GoogleFonts.nunitoSans().fontFamily,
              fontSize: 16,
              color: Colors.black,
            ),
            text: quantityName,
            children: const [
              TextSpan(
                text: "  (quantity)",
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
        );
      } else {
        items[unit] = RichText(
          text: TextSpan(
            text: unit == Unit.quantity ? _quantityNameController.text : unitToString(unit),
            style: TextStyle(
              fontFamily: GoogleFonts.nunitoSans().fontFamily,
              fontSize: 16,
              color: Colors.black,
            ),
          ),
        );
      }
      
      // limit width of items if maxWidth is set
      if (maxWidth != null) {
        items[unit] = SizedBox(
          width: maxWidth.toDouble(),
          child: items[unit],
        );
      }
    }
    
    return items;
  }
  
  Widget _buildUnitDropdown({
    required Map<Unit, Widget> items,
    required Unit current,
    bool enabled = true,
    Function(Unit? unit)? onChanged,
  }) {
    var decoration = enabled
      ? const InputDecoration(
        contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 14),
      ) 
      : InputDecoration(
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
        // no enabled border
        enabledBorder: UnderlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: BorderSide(
            width: 3.5,
            color: Colors.grey.shade300
          )
        ),
      );
    
    if (!enabled) {
      // reduce opacity of items
      items = items.map((key, value) => MapEntry(key, Opacity(
        opacity: 0.4,
        child: value,
      )));
    }
    
    return DropdownButtonFormField<Unit>(
      decoration: decoration,
      isExpanded: true,
      value: current,
      items: items.entries.map((entry) => DropdownMenuItem<Unit>(
        value: entry.key,
        child: entry.value,
      )).toList(),
      onChanged: enabled ? onChanged : null,
    );
  }
  
  Widget _buildConversionFields() {
    return ValueListenableBuilder(
        valueListenable: _defaultUnitNotifier,
        builder: (contextUnit, valueUnit, childUnit) {
          return ValueListenableBuilder(
            valueListenable: _densityConversionNotifier,
            builder: (contextConv1, valueConv1, childConv1) {
               return ValueListenableBuilder(
                valueListenable: _quantityConversionNotifier,
                builder: (contextConv2, valueConv2, childConv2) {
                  return Column(
                    children: [
                      _buildConversionField(0, _densityConversionNotifier, valueConv2, valueUnit),
                      const SizedBox(height: 10),
                      _buildConversionField(1, _quantityConversionNotifier, valueConv1, valueUnit),
                    ],
                  );
                }
               );
            }
          );
        }
    );
  }
  
  Widget _buildConversionField(int index, ValueNotifier<Conversion> notifier, Conversion otherConversion, Unit defUnit) {
    return LayoutBuilder(
      builder: (context, constraints) {
        var conversion = notifier.value;
        
        var checkBoxTexts = ["Enable Volumetric Conversion", "Enable Quantity Conversion"];
        var text = checkBoxTexts[index];
        var controller1 = index == 0 ? _densityAmount1Controller : _quantityAmount1Controller;
        var controller2 = index == 0 ? _densityAmount2Controller : _quantityAmount2Controller;
        var units1 = index == 0 ? volumetricUnits : null;
        var units2 = index == 0 ? weightUnits : Unit.values.where((unit) => unit != Unit.quantity).toList();

        var enabled = conversion.enabled;
        var textAlpha = enabled ? 255 : 100;
        String? validationString = validateConversion(index);
        Color? borderColor;
        if (enabled) {
          if (validationString != null) {
            borderColor = const Color.fromARGB(255, 230, 0, 0);
          } else {
            borderColor = null; // default
          }
        } else {
          borderColor = const Color.fromARGB(130, 158, 158, 158);
        }
        
        // create unit dropdowns
        Widget dropdown1;
        if (units1 != null) {
          dropdown1 = _buildUnitDropdown(
            items: _buildUnitItems(units: units1),
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
            controller: _quantityNameController,
            decoration: const InputDecoration(
              labelText: "Designation",
            ),
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
        var dropdown2 = _buildUnitDropdown(
          items: _buildUnitItems(units: units2),
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
              Expanded(child: _buildAmountField(notifier, controller1, 1)),
              Expanded(child: dropdown1),
              equalSign,
              Expanded(child: _buildAmountField(notifier, controller2, 2)),
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
                  _buildAmountField(notifier, controller1, 1),
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
                  _buildAmountField(notifier, controller2, 2),
                  dropdown2,
                ]
              ),
            ],
          );
        
        return BorderBox(
          borderColor: borderColor,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(0, 8, 12, 16),
            child: Column(
              children: [
                SwitchListTile(
                  value: enabled,
                  controlAffinity: ListTileControlAffinity.leading,
                  onChanged: (bool value) {
                    // validate form after future build
                    if (!value) {
                      Future(() {
                        _formKey.currentState!.validate();
                      });
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
  
  String? validateConversion(int index) {
    // check whether all children of the conversion field are valid
    var defUnit = _defaultUnitNotifier.value;
    var convNotifier = index == 0 ? _densityConversionNotifier : _quantityConversionNotifier;
    var otherConvNotifier = index == 0 ? _quantityConversionNotifier : _densityConversionNotifier;
    
    // Check if conversion is active
    if (convNotifier.value.enabled) {
      // Check whether a conversion to the default unit is possible
      if (index == 1) {
        if (defUnit != Unit.quantity) {
          bool different = volumetricUnits.contains(defUnit) ^ volumetricUnits.contains(convNotifier.value.unit2);
          if (different && !otherConvNotifier.value.enabled) {
            return "Cannot convert quantity (${_quantityNameController.text}) to default unit (${unitToString(defUnit)}) without density conversion.";
          }
        }
      } else {
        if (defUnit == Unit.quantity && !otherConvNotifier.value.enabled) {
          return "If the default unit is quantity (${_quantityNameController.text}), the quantity conversion must be enabled.";
        }
      }
    }
    
    return null;
  }
  
  Widget _buildAmountField(
    ValueNotifier<Conversion> notifier,
    TextEditingController controller,
    int index,
  ) {
    validator(String? value) {
      if (!notifier.value.enabled) {
        return null;
      }
      if (value == null || value.isEmpty) {
        return "Required Field";
      }
      try {
        double.parse(value);
      } catch (e) {
        return "Invalid Number";
      }
      return null;
    }
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: TextFormField(
        enabled: notifier.value.enabled,
        decoration: const InputDecoration(
          contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 14),
        ),
        controller: controller,
        keyboardType: TextInputType.number,
        validator: notifier.value.enabled ? validator : null,
        autovalidateMode: AutovalidateMode.always,
        onChanged: (String? value) {
          if (value != null && value.isNotEmpty) {
            try {
              value = value.replaceAll(",", ".");
              var cursorPos = controller.selection.baseOffset;
              controller.text = value;
              controller.selection = TextSelection.fromPosition(TextPosition(offset: cursorPos));
              
              var input = double.parse(value);
              if (index == 1) {
                notifier.value = notifier.value.withAmount1(input);
              } else {
                notifier.value = notifier.value.withAmount2(input);
              }
            } catch (e) {
              devtools.log("Error: Invalid number in amount$index field");
            }
          }
        },
        onTap: () => controller.selection = TextSelection(baseOffset: 0, extentOffset: controller.value.text.length),
      ),
    );
  }
  
  Widget _buildIngredientList() {
    
    return ValueListenableBuilder(
      valueListenable: _productNameController,
      builder: (contextName, valueName, childName) {
        return ValueListenableBuilder(
          valueListenable: _defaultUnitNotifier,
            builder: (contextUnit, valueUnit, childUnit) {
            return ValueListenableBuilder(
              valueListenable: _quantityNameController,
              builder: (contextQuantityName, valueQuantityName, childQuantityName) {
                return ValueListenableBuilder(
                  valueListenable: _autoCalcAmountNotifier,
                  builder: (contextAutoCalc, valueAutoCalc, childAutoCalc) {
                    var productName = valueName.text != "" ? "'${valueName.text}'" : "the product";
                    
                    return BorderBox(
                      title: "Ingredients",
                      child: Padding(
                        padding: const EdgeInsets.all(0),
                        child: Column(
                          children: [
                            SwitchListTile(
                              value: valueAutoCalc,
                              controlAffinity: ListTileControlAffinity.leading,
                              onChanged: (bool value) {
                                _autoCalcAmountNotifier.value = value;
                              },
                              title: const Padding(
                                padding: EdgeInsets.only(top: 2),
                                child: Text(
                                  "Auto calculate the resulting amount",
                                  style: TextStyle(
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(4, 0, 8, 8),
                              child: Row(
                                children: [
                                  Padding(
                                    padding: EdgeInsets.symmetric(horizontal: valueAutoCalc ? 12 : 12),
                                    child: valueAutoCalc ? 
                                      Text(
                                        _amountForIngredientsController.text,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontSize: 16,
                                        )
                                      )
                                      : SizedBox(
                                        width: 70,
                                        child: TextFormField(
                                          enabled: !valueAutoCalc,
                                          controller: _amountForIngredientsController,
                                          keyboardType: TextInputType.number,
                                          decoration: const InputDecoration(
                                            contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 14),
                                          ),
                                          validator: (String? value) {
                                            if (valueAutoCalc) {
                                              return null;
                                            }
                                            if (value == null || value.isEmpty) {
                                              return "Required Field";
                                            }
                                            try {
                                              double.parse(value);
                                            } catch (e) {
                                              return "Invalid Number";
                                            }
                                            return null;
                                          },
                                          autovalidateMode: AutovalidateMode.onUserInteraction,
                                        )
                                      ),
                                  ),
                                  SizedBox(
                                    width: 95,
                                    child: _buildUnitDropdown(
                                      items: _buildUnitItems(verbose: true), 
                                      current: _ingredientsUnitNotifier.value,
                                      onChanged: (Unit? unit) => _ingredientsUnitNotifier.value = unit ?? Unit.g,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      "of $productName contains:",
                                      maxLines: 3,
                                      style: const TextStyle(
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          ],
                        ),
                      ),
                    );
                  }
                );
              }
            );
          }
        );
      }
    );
  }
  
  Widget _buildAddButton() => Padding(
    padding: const EdgeInsets.all(8.0),
    child: TextButton(
      onPressed: () {
        var product = getProductFromForm();
        
        if (product != null) {
          if (isEdit) {
            devtools.log("Updating product");
            _dataService.updateProduct(product);
          } else {
            _dataService.createProduct(product);
          }
          
          Navigator.of(context).pop();
        }
      },
      child: Text(isEdit ? "Update" : "Add"),
    ),
  );
  
  Product? getProductFromForm() {
    final name = _productNameController.text;
    final defUnit = _defaultUnitNotifier.value;
    final densityConversion = _densityConversionNotifier.value;
    final quantityConversion = _quantityConversionNotifier.value;
    final quantityName = _quantityNameController.text;
    final autoCalcAmount = _autoCalcAmountNotifier.value;
    final amountForIngredients = double.parse(_amountForIngredientsController.text);
    final ingredientsUnit = _ingredientsUnitNotifier.value;
    
    final isValid = _formKey.currentState!.validate() && validateConversion(0) == null && validateConversion(1) == null;
    if (isValid) {
      return Product(
        id:                    isEdit ? _id : -1,
        name:                  name,
        defaultUnit:           defUnit,
        densityConversion:     densityConversion,
        quantityConversion:    quantityConversion,
        quantityName:          quantityName,
        autoCalcAmount:        autoCalcAmount,
        amountForIngredients:  amountForIngredients,
        ingredientsUnit:       ingredientsUnit,
      );
    } else {
      return null;
    }
  }
}