import 'package:flutter/material.dart';

import 'package:google_fonts/google_fonts.dart';

import 'package:food_tracker/constants/data.dart';
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
  
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _densityAmount1;
  late final TextEditingController _densityAmount2;
  late final TextEditingController _quantityAmount1;
  late final TextEditingController _quantityAmount2;
  late final TextEditingController _quantityName;
  
  late final bool isEdit;
  
  int _id = -1;
  Product? preEditProduct;
  
  final _densityConversionNotifier = ValueNotifier<Conversion>(Conversion.defaultDensity());
  final _quantityConversionNotifier = ValueNotifier<Conversion>(Conversion.defaultQuantity());
  final _defaultUnitNotifier = ValueNotifier<Unit>(Unit.g);
  
  var isDuplicate = ValueNotifier<bool>(false);
  
  @override
  void initState() {
    if (widget.isEdit == null || (widget.isEdit! && widget.productName == null)) {
      Future(() {
        showErrorbar(context, "Error: Product not found");
        Navigator.of(context).pop();
      });
    }
    
    isEdit = widget.isEdit ?? false;
    
    _name = TextEditingController();
    _densityAmount1 = TextEditingController();
    _densityAmount2 = TextEditingController();
    _quantityAmount1 = TextEditingController();
    _quantityAmount2 = TextEditingController();
    _quantityName = TextEditingController();
    
    _dataService.open(dbName);
    super.initState();
  }
  
  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                  preEditProduct = products.firstWhere((prod) => prod.name == widget.productName);
                  _id = preEditProduct!.id;
                  _defaultUnitNotifier.value = preEditProduct!.defaultUnit;
                  _densityConversionNotifier.value = preEditProduct!.densityConversion;
                  _quantityConversionNotifier.value = preEditProduct!.quantityConversion;
                } catch (e) {
                  return const Text("Error: Product not found");
                }
              }
              _name.text = widget.productName ?? "";
              _densityAmount1.text = preEditProduct?.densityConversion.amount1.toString() ?? Conversion.defaultDensity().amount1.toString();
              _densityAmount2.text = preEditProduct?.densityConversion.amount2.toString() ?? Conversion.defaultDensity().amount2.toString();
              _quantityAmount1.text = preEditProduct?.quantityConversion.amount1.toString() ?? Conversion.defaultQuantity().amount1.toString();
              _quantityAmount2.text = preEditProduct?.quantityConversion.amount2.toString() ?? Conversion.defaultQuantity().amount2.toString();
              _quantityName.text = preEditProduct?.quantityUnit ?? "x";
              
              return SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(7.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      
                      children: [
                        _buildNameField(products),
                        const SizedBox(height: 5),
                        _buildDefaultUnitDropdown(),
                        const SizedBox(height: 10),
                        _buildConversionFields(),
                        const SizedBox(height: 5),
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
    );
  }
  
  Widget _buildDeleteButton() => 
    IconButton(
      onPressed: () {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Delete Product"),
            content: const Text("If you delete this product, all associated data will be lost."),
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
        controller: _name,
        decoration: const InputDecoration(
          labelText: "Name"
        ),
        validator: (String? value) {
          for (var prod in products) {
            if (prod.name == value && prod.name != widget.productName) {
              // change notifier after build complete
              if (!isDuplicate.value) {
                Future(() {
                  isDuplicate.value = true;
                });
              }
              return "Already taken";
            }
          }
          if (isDuplicate.value) {
            Future(() {
              isDuplicate.value = false;
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
      valueListenable: isDuplicate,
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
          final name = _name.text;
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
  
  Map<Unit, Widget> _buildUnitItems({List<Unit>? units}) {
    var items = <Unit, Widget>{};
    units ??= Unit.values;
    
    for (var unit in units) {
      if (unit == Unit.quantity) {
        // TODO: check whether the user has set up a quantity conversion
        if (true) {
          var quantityName = preEditProduct?.quantityUnit ?? "x";
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
        }
      } else {
        items[unit] = RichText(
          text: TextSpan(
            text: unitToString(unit),
            style: TextStyle(
              fontFamily: GoogleFonts.nunitoSans().fontFamily,
              fontSize: 16,
              color: Colors.black,
            ),
          ),
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
    var conversion = notifier.value;
    
    var checkBoxTexts = ["Enable Volumetric Conversion", "Enable Quantity Conversion"];
    var text = checkBoxTexts[index];
    var controller1 = index == 0 ? _densityAmount1 : _quantityAmount1;
    var controller2 = index == 0 ? _densityAmount2 : _quantityAmount2;
    var units1 = index == 0 ? volumetricUnits : null;
    var units2 = index == 0 ? weightUnits : Unit.values.where((unit) => unit != Unit.quantity).toList();

    var enabled = conversion.enabled;
    var textAlpha = enabled ? 255 : 100;
    String? validationString = validateConversion(index);
    Color borderColor;
    if (enabled) {
      if (validationString != null) {
        borderColor = const Color.fromARGB(255, 230, 0, 0);
      } else {
        borderColor = const Color.fromARGB(200, 25, 82, 77);
      }
    } else {
      borderColor = const Color.fromARGB(130, 158, 158, 158);
    }
    
    // create unit dropdowns
    Widget dropdown1;
    if (units1 != null) {
      dropdown1 = Expanded(
        child: _buildUnitDropdown(
          items: _buildUnitItems(units: units1),
          enabled: conversion.enabled,
          current: conversion.unit1,
          onChanged: (Unit? unit) {
            if (unit != null) {
              notifier.value = notifier.value.withUnit1(unit);
            }
          }
        ),
      );
    } else {
      // quantity name field instead of dropdown
      dropdown1 = Expanded(
        child: TextFormField(
          enabled: conversion.enabled,
          controller: _quantityName,
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
        ),
      );
    }
    var dropdown2 = Expanded(
      child: _buildUnitDropdown(
        items: _buildUnitItems(units: units2),
        enabled: conversion.enabled,
        current: conversion.unit2,
        onChanged: (Unit? unit) {
          if (unit != null) {
            notifier.value = notifier.value.withUnit2(unit);
          }
        }
      ),
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
    
    bool isWide = MediaQuery.of(context).size.width > 450;
    devtools.log("width = ${MediaQuery.of(context).size.width}");
    
    Widget inputFields = isWide
      ? Row(
        children: [
          _buildAmountField(notifier, controller1, 1),
          dropdown1,
          equalSign,
          _buildAmountField(notifier, controller2, 2),
          dropdown2,
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
    
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: borderColor,
            width: 2,
          ),
        ),
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
      )
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
            return "Cannot convert quantity (${_quantityName.text}) to default unit (${unitToString(defUnit)}) without density conversion.";
          }
        }
      } else {
        if (defUnit == Unit.quantity && !otherConvNotifier.value.enabled) {
          return "If the default unit is quantity (${_quantityName.text}), the quantity conversion must be enabled.";
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
      return null;
    }
    
    return Expanded(
      child: Padding(
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
        ),
      ),
    );
  }
  
  Widget _buildIngredientList() {
    return const Text("Ingredients");
  }
  
  Widget _buildAddButton() => Padding(
    padding: const EdgeInsets.all(8.0),
    child: TextButton(
      onPressed: () {
        final name = _name.text;
        final defUnit = _defaultUnitNotifier.value;
        final densityConversion = _densityConversionNotifier.value;
        final quantityConversion = _quantityConversionNotifier.value;
        final quantityName = _quantityName.text;
        final isValid = _formKey.currentState!.validate() && validateConversion(0) == null && validateConversion(1) == null;
        if (isValid) {
          if (isEdit) {
            var product = Product(_id, name, defUnit, densityConversion, quantityConversion, quantityName);
            _dataService.updateProduct(product);
          } else {
            var product = Product(-1, name, defUnit, densityConversion, quantityConversion, quantityName);
            _dataService.createProduct(product);
          }
          Navigator.of(context).pop();
        }
      },
      child: Text(isEdit ? "Update" : "Add"),
    ),
  );
}