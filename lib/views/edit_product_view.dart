import 'package:flutter/material.dart';
import 'package:food_tracker/utility/theme.dart';
import 'package:food_tracker/widgets/product_dropdown.dart';
import 'package:food_tracker/utility/text_logic.dart';
import 'package:food_tracker/widgets/border_box.dart';
import 'package:food_tracker/widgets/unit_dropdown.dart';

import 'package:google_fonts/google_fonts.dart';

import 'package:food_tracker/constants/routes.dart';
import 'package:food_tracker/services/data/data_objects.dart';
import 'package:food_tracker/services/data/data_service.dart';
import 'package:food_tracker/utility/modals.dart';
import 'package:food_tracker/widgets/loading_page.dart';
import 'package:food_tracker/widgets/multi_value_listenable_builder.dart';
import 'package:food_tracker/widgets/slidable_list.dart';

import "dart:developer" as devtools show log;

import '../utility/data_logic.dart';

class EditProductView extends StatefulWidget {
  final String? productName;
  final bool? isEdit;
  
  const EditProductView({Key? key, this.isEdit, this.productName}) : super(key: key);

  @override
  State<EditProductView> createState() => _EditProductViewState();
}

class _EditProductViewState extends State<EditProductView> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  
  bool _loaded = false;
  bool _error = false;
  
  final _dataService = DataService.current();
  
  late final GlobalKey<FormState> _formKey;
  late final TextEditingController _productNameController;
  late final TextEditingController _densityAmount1Controller;
  late final TextEditingController _densityAmount2Controller;
  late final TextEditingController _quantityAmount1Controller;
  late final TextEditingController _quantityAmount2Controller;
  late final TextEditingController _quantityNameController;
  late final TextEditingController _resultingAmountController;
  
  final List<TextEditingController> _ingredientAmountControllers = [];
  
  late final bool isEdit;
  
  int _id = -1;
  List<FocusNode> _ingredientFocusNodes = [];
  late Product prevProduct;
  bool interimProduct = false;
  // used to store the product while the user navigates to another page, can contain formal errors
  
  final _densityConversionNotifier = ValueNotifier<Conversion>(Conversion.defaultDensity());
  final _quantityConversionNotifier = ValueNotifier<Conversion>(Conversion.defaultQuantity());
  final _defaultUnitNotifier = ValueNotifier<Unit>(Unit.g);
  
  final _autoCalcAmountNotifier = ValueNotifier<bool>(false);
  final _resultingAmountNotifier = ValueNotifier<double>(0);
  final _ingredientsUnitNotifier = ValueNotifier<Unit>(Unit.g);
  final _ingredientsNotifier = ValueNotifier<List<ProductQuantity>>([]);
  
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
    _resultingAmountController = TextEditingController();
    
    // reload product stream
    Future(() {
      _dataService.reloadProductStream();
    });
    
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
    _resultingAmountController.dispose();
    _densityConversionNotifier.dispose();
    _quantityConversionNotifier.dispose();
    _defaultUnitNotifier.dispose();
    _autoCalcAmountNotifier.dispose();
    _resultingAmountNotifier.dispose();
    _ingredientsUnitNotifier.dispose();
    _ingredientsNotifier.dispose();
    _isDuplicateNotifier.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return PopScope(
      canPop: false,
      onPopInvoked: _onPopInvoked,
      child: Scaffold(
        appBar: AppBar(
          title: Text(isEdit ? "Edit Product" : "Add Product"),
          actions: isEdit ? [_buildDeleteButton()] : null
        ),
        body: ScrollConfiguration(
          // clamping scroll physics to avoid overscroll
          behavior: const ScrollBehavior().copyWith(overscroll: false),
          child: StreamBuilder(
            stream: _dataService.streamProducts(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                _loaded = true;
                final products = snapshot.data as List<Product>;
                if (isEdit) {
                  try {
                    prevProduct = products.firstWhere((prod) => prod.name == widget.productName);
                    _id = prevProduct.id;
                  } catch (e) {
                    _error = true;
                    return const Text("Error: Product not found");
                  }
                } else {
                  prevProduct = Product.defaultValues();
                }
                
                // set initial values
                _productNameController.text = widget.productName ?? prevProduct.name;
                _densityAmount1Controller.text = prevProduct.densityConversion.amount1.toString();
                _densityAmount2Controller.text = prevProduct.densityConversion.amount2.toString();
                _quantityAmount1Controller.text = prevProduct.quantityConversion.amount1.toString();
                _quantityAmount2Controller.text = prevProduct.quantityConversion.amount2.toString();
                _quantityNameController.text = prevProduct.quantityName;
                
                _densityConversionNotifier.value = prevProduct.densityConversion;
                _quantityConversionNotifier.value = prevProduct.quantityConversion;
                _defaultUnitNotifier.value = prevProduct.defaultUnit;
                _autoCalcAmountNotifier.value = prevProduct.autoCalc;
                _ingredientsUnitNotifier.value = prevProduct.ingredientsUnit;
                _ingredientsNotifier.value = prevProduct.ingredients;
                
                _resultingAmountController.text = prevProduct.amountForIngredients.toString();
                _resultingAmountNotifier.value = prevProduct.amountForIngredients;
                
                // populate ingredient amount controllers
                _ingredientAmountControllers.clear();
                for (var ingredient in prevProduct.ingredients) {
                  var controller = TextEditingController();
                  controller.text = ingredient.amount.toString();
                  _ingredientAmountControllers.add(controller);
                }
                
                // remove ".0" from amount fields if it is the end of the string
                var amountFields = [_densityAmount1Controller, _densityAmount2Controller, _quantityAmount1Controller, _quantityAmount2Controller, _resultingAmountController, ..._ingredientAmountControllers];
                for (var field in amountFields) {
                  var text = field.text;
                  if (text.endsWith(".0")) {
                    field.text = text.substring(0, text.length - 2);
                  }
                }
                devtools.log("Product ${isEdit ? prevProduct.name : "/"}: $interimProduct");
                // change state after build complete
                if (!interimProduct) {
                  Future(() {
                    interimProduct = true;
                  });
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
                          _buildIngredientBox(products),
                          const SizedBox(height: 8),
                          _buildAddButton(),
                        ]
                      ),
                    ),
                  ),
                );
              } else {
                return const LoadingPage();
              }
            }
          ),
        )
      ),
    );
  }
  
  Future _onPopInvoked(bool didPop) async {
    if (didPop) return;
    if (!_loaded || _error) {
      // if the data is not loaded yet, pop immediately 
      Navigator.of(context).pop(true);
      return;
    }
    
    final NavigatorState navigator = Navigator.of(context);
    
    // test whether the product has been changed compared to the prevProduct
    var (product, _) = getProductFromForm();
    
    if (product.equals(prevProduct)) {
      Future(() => navigator.pop());
      return;
    }
    
    bool willPop = await showContinueWithoutSavingDialog(context);
    
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
        return ValueListenableBuilder(
          valueListenable: _quantityNameController,
          builder: (context, value, child) {
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
                    child: UnitDropdown(
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
  
  // same as above but with MultiValueListenableBuilder
  Widget _buildConversionFields() {
    return MultiValueListenableBuilder(
      listenables: [
        _defaultUnitNotifier,
        _densityConversionNotifier,
        _quantityConversionNotifier,
      ],
      builder: (context, values, child) {
        var valueUnit = values[0] as Unit;
        var valueConv1 = values[1] as Conversion;
        var valueConv2 = values[2] as Conversion;
        return Column(
          children: [
            _buildConversionField(0, _densityConversionNotifier, valueConv2, valueUnit),
            const SizedBox(height: 10),
            _buildConversionField(1, _quantityConversionNotifier, valueConv1, valueUnit),
          ],
        );
      },
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
        String? validationString = validateConversionBox(index);
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
        var dropdown2 = UnitDropdown(
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
  
  String? validateConversionBox(int index) {
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
  
  /* 
  *  Amount field for the conversion fields
  */
  _buildConversionAmountField({
    required ValueNotifier<Conversion> notifier,
    required TextEditingController controller,
    required int index,
  }) {
    return _buildAmountField(
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
  
  Widget _buildAmountField({
    required TextEditingController controller,
    bool enabled = true,
    Function(double)? onChangedAndParsed,
    double? padding,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: padding ?? 12),
      child: Focus(
        onFocusChange: (bool hasFocus) {
          if (hasFocus) {
            controller.selection = TextSelection(baseOffset: 0, extentOffset: controller.value.text.length);
          }
        },
        child: TextFormField(
          enabled: enabled,
          decoration: const InputDecoration(
            contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 14),
          ),
          controller: controller,
          keyboardType: TextInputType.number,
          validator: (String? value) => enabled ? numberValidator(value) : null,
          autovalidateMode: AutovalidateMode.always,
          onChanged: (String? value) {
            if (value != null && value.isNotEmpty) {
              try {
                value = value.replaceAll(",", ".");
                var cursorPos = controller.selection.baseOffset;
                controller.text = value;
                controller.selection = TextSelection.fromPosition(TextPosition(offset: cursorPos));
                
                var input = double.parse(value);
                if (input.isFinite && onChangedAndParsed != null) {
                  onChangedAndParsed(input);
                }
              } catch (e) {
                devtools.log("Error: Invalid number in amount field");
              }
            }
          },
        ),
      ),
    );
  }
  
  Widget _buildIngredientBox(List<Product> products) {
    return MultiValueListenableBuilder(
      listenables: [
        _productNameController,
        _defaultUnitNotifier,
        _quantityNameController,
        _autoCalcAmountNotifier,
        _ingredientsNotifier,
        _ingredientsUnitNotifier,
        _densityConversionNotifier,
        _quantityConversionNotifier,
        _resultingAmountNotifier
      ],
      builder: (context, values, child) {
        var valueName               = values[0] as TextEditingValue;
        var valueDefUnit            = values[1] as Unit;
        var valueAutoCalc           = values[3] as bool;
        var valueIngredients        = values[4] as List<ProductQuantity>;
        var valueUnit               = values[5] as Unit;
        var valueDensityConversion  = values[6] as Conversion;
        var valueQuantityConversion = values[7] as Conversion;
        var valueResultingAmount    = values[8] as double;
        
        var productName = valueName.text != "" ? "'${valueName.text}'" : "  the product";
        
        // check whether the ingredient unit is compatible with the default unit
        
        var (errorType, errorMsg) = validateResultingAmount(
          valueUnit,
          valueDefUnit,
          valueAutoCalc,
          valueIngredients,
          valueResultingAmount,
          valueDensityConversion,
          valueQuantityConversion,
        );
        
        Widget errorText = 
          errorType == ErrorType.none
            ? const SizedBox()
            : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Text(
                errorMsg!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: errorType == ErrorType.warning ? warningColor : Colors.red,
                  fontSize: 16)
                ),
            );
        
        // calculate the resulting amount
        List<double>? amounts;
        if (valueAutoCalc) {
          amounts = valueIngredients.map((ingr) => convertBetweenProducts(
            targetUnit: valueUnit,
            conversion1: valueDensityConversion,
            conversion2: valueQuantityConversion,
            ingredient: ingr,
            products: products,
          )).toList();
          // sum up all non-NaN amounts to get the resulting amount
          var resultingAmount = amounts.where((amount) => !amount.isNaN).fold(0.0, (prev, amount) => prev + amount);
          
          if (!resultingAmount.isNaN && resultingAmount != valueResultingAmount) {
            // after frame callback to avoid changing the value during build
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _resultingAmountNotifier.value = resultingAmount;
              _resultingAmountController.text = roundDouble(resultingAmount);
            });
          }
        }
        
        return BorderBox(
          title: "Ingredients",
          borderColor: errorType == ErrorType.error ? errorBorderColor : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 0, 8, 8),
                child: Row(
                  children: [
                    Padding( // resulting ingredient amount field
                      padding: EdgeInsets.symmetric(horizontal: valueAutoCalc ? 12 : 12),
                      child: valueAutoCalc ? 
                        Text(
                          valueResultingAmount.isNaN ? "NaN" : roundDouble(valueResultingAmount),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                          )
                        )
                        : SizedBox(
                          width: 70,
                          child:_buildAmountField(
                            controller: _resultingAmountController,
                            enabled: !valueAutoCalc,
                            onChangedAndParsed: (value) => _resultingAmountNotifier.value = value,
                            padding: 0,
                          )
                        ),
                    ),
                    SizedBox( // ingredient unit dropdown
                      width: 95,
                      child: UnitDropdown(
                        items: _buildUnitItems(verbose: true), 
                        current: valueUnit,
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
              ),
              errorText,
              const SizedBox(height: 8),
              _buildIngredientsList(products, valueIngredients, amounts, valueUnit),
              _buildAddIngredientButton(),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildIngredientsList(List<Product> products, List<ProductQuantity> ingredients, List<double>? amounts, Unit targetUnit) {
    // if ingredients is empty, return a single list tile with a message
    if (ingredients.isEmpty) {
      return const ListTile(
        title: Center(
          child: Text(
            "No ingredients yet",
            style: TextStyle(
              fontSize: 16,
              fontStyle: FontStyle.italic,
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
        entries: _getIngredientEntries(products, ingredients, amounts, targetUnit),
        menuWidth: 90,
        onReorder: ((oldIndex, newIndex) {
          if (oldIndex < newIndex) {
            newIndex -= 1;
          }
          var ingredient = ingredients.removeAt(oldIndex);
          ingredients.insert(newIndex, ingredient);
          _ingredientsNotifier.value = List.from(ingredients);
          
          var controller = _ingredientAmountControllers.removeAt(oldIndex);
          _ingredientAmountControllers.insert(newIndex, controller);
        }),
      ),
    );
  }
  
  List<SlidableListEntry> _getIngredientEntries(List<Product> products, List<ProductQuantity> ingredients, List<double>? amounts, Unit targetUnit) {
    var entries = <SlidableListEntry>[];
    _ingredientFocusNodes = <FocusNode>[];
    for (int index = 0; index < ingredients.length; index++) {
      var ingredient = ingredients[index];
      bool conversionPossible = amounts == null || !amounts[index].isNaN;
      bool dark = index % 2 == 0;
      var color = dark ? const Color.fromARGB(12, 0, 0, 255) : const Color.fromARGB(6, 200, 200, 200);
      var focusNode = FocusNode();
      _ingredientFocusNodes.add(focusNode);
      
      var product = ingredient.product != null 
        ? products.firstWhere((prod) => prod.id == ingredient.product!.id)
        : null;
      
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
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ProductDropdown(
                        products: products,
                        selectedProduct: product,
                        ingredients: ingredients,
                        index: index,
                        ingredientsNotifier: _ingredientsNotifier,
                        focusNode: focusNode,
                        onChanged: (Product? newProduct) {
                          if (newProduct != null) {
                            // Check whether the new product supports the current unit
                            late Unit newUnit;
                            if (ingredient.product != null && newProduct.getAvailableUnits().contains(ingredient.product!.defaultUnit)) {
                              newUnit = ingredient.product!.defaultUnit;
                            } else {
                              newUnit = newProduct.defaultUnit;
                            }
                            
                            ingredients[index] = ProductQuantity(
                              product: newProduct,
                              amount: ingredient.amount,
                              unit: newUnit,
                            );
                            _ingredientsNotifier.value = List.from(ingredients);
                            WidgetsBinding.instance.addPostFrameCallback((_) => _requestIngredientFocus(index));
                          }
                        },
                      ),
                      const SizedBox(height: 15),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // amount field
                          Expanded(
                            child: _buildAmountField(
                              controller: _ingredientAmountControllers[index],
                              padding: 0,
                              onChangedAndParsed: (value) {
                                var prev = ingredients[index];
                                ingredients[index] = ProductQuantity(
                                  product: prev.product,
                                  amount: value,
                                  unit: prev.unit,
                                );
                                _ingredientsNotifier.value = List.from(ingredients);
                              }
                            ),
                          ),
                          const SizedBox(width: 12),
                          // unit dropdown
                          Expanded(
                            child: UnitDropdown(
                              items: _buildUnitItems(units: product?.getAvailableUnits() ?? Unit.values),
                              current: ingredient.unit,
                              onChanged: (Unit? unit) {
                                if (unit != null) {
                                  var prev = ingredients[index];
                                  ingredients[index] = ProductQuantity(
                                    product: prev.product,
                                    amount: prev.amount,
                                    unit: unit,
                                  );
                                  _ingredientsNotifier.value = List.from(ingredients);
                                }
                              }
                            ),
                          ),
                        ]
                      ),
                      SizedBox(height: conversionPossible ? 0 : 10),
                      conversionPossible
                        ? const SizedBox()
                        : Text(
                          " ⚠ Conversion to ${unitToLongString(targetUnit)} not possible",
                          style: const TextStyle(
                            color: warningColor,
                            fontSize: 16,
                          ),
                      ),
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
                child: IconButton(
                  color: Colors.white,
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    // navigate to edit the product
                    if (product != null) {
                      Navigator.of(context).pushNamed(
                        editProductRoute,
                        arguments: product.name,
                      );
                    }
                  },
                ),
              ),
            ),
            Container(
              color: Colors.red,
              child: Tooltip(
                message: "Delete Ingredient",
                child: IconButton(
                  color: Colors.white,
                  icon: const Icon(Icons.delete),
                  onPressed: () {
                    ingredients.removeAt(index);
                    _ingredientsNotifier.value = List.from(ingredients);
                    _ingredientAmountControllers.removeAt(index).dispose();
                  },
                ),
              ),
            ),
          ],
        )
      );
    }
    return entries;
  }
  
  Widget _buildAddIngredientButton() {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color.fromARGB(255, 210, 235, 198),
        foregroundColor: Colors.black,
        minimumSize: const Size(double.infinity, 60),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(14),
            bottomRight: Radius.circular(14),
          ),
        ),
        textStyle: Theme.of(context).textTheme.bodyLarge,
      ),
      icon: const Icon(Icons.add),
      label: const Padding(
        padding: EdgeInsets.only(left: 5.0),
        child: Text("Add Ingredient"),
      ),
      onPressed: () {
        
      },
    );
  }
  
  Widget _buildAddButton() => Padding(
    padding: const EdgeInsets.all(8.0),
    child: ElevatedButton(
      style: ButtonStyle(
        backgroundColor: MaterialStateProperty.all(Colors.teal.shade400),
        foregroundColor: MaterialStateProperty.all(Colors.white),
        minimumSize: MaterialStateProperty.all(const Size(double.infinity, 60)),
        textStyle: MaterialStateProperty.all(const TextStyle(fontSize: 16)),
        shape: MaterialStateProperty.all(const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
        )),
      ),
      onPressed: () {
        var (product, isValid) = getProductFromForm();
        
        if (isValid) {
          if (isEdit) {
            _dataService.updateProduct(product);
          } else {
            _dataService.createProduct(product);
          }
          
          Navigator.of(context).pop();
        }
      },
      child: Text(isEdit ? "Update Product" : "Add Product"),
    ),
  );
  
  void _requestIngredientFocus(int index) {
    if (index < _ingredientFocusNodes.length && _ingredientFocusNodes[index].canRequestFocus) {
      _ingredientFocusNodes[index].requestFocus();
    }
  }
  
  (Product, bool) getProductFromForm() {
    final name = _productNameController.text;
    final defUnit = _defaultUnitNotifier.value;
    final densityConversion = _densityConversionNotifier.value;
    final quantityConversion = _quantityConversionNotifier.value;
    final quantityName = _quantityNameController.text;
    final autoCalc = _autoCalcAmountNotifier.value;
    final resultingAmount = _resultingAmountNotifier.value;
    final ingredientsUnit = _ingredientsUnitNotifier.value;
    final ingredients = _ingredientsNotifier.value;
    
    final isValid = _formKey.currentState!.validate()
      && validateConversionBox(0) == null
      && validateConversionBox(1) == null
      && validateResultingAmount(
          ingredientsUnit,
          defUnit,
          autoCalc,
          ingredients,
          resultingAmount,
          densityConversion,
          quantityConversion,
        ).$1 == ErrorType.none;
    
    return (
      Product(
        id:                    isEdit ? _id : -1,
        name:                  name,
        defaultUnit:           defUnit,
        densityConversion:     densityConversion,
        quantityConversion:    quantityConversion,
        quantityName:          quantityName,
        autoCalc:              autoCalc,
        amountForIngredients:  resultingAmount,
        ingredientsUnit:       ingredientsUnit,
        ingredients:           ingredients,
      ),
      isValid,
    );
  }
}