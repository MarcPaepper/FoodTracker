import 'package:flutter/material.dart';

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
  
  late final bool isEdit;
  
  Unit _defaultUnit = Unit.g;
  int _id = -1;
  Product? preEditProduct;
  
  final _densityConversionNotifier = ValueNotifier<Conversion>(Conversion.defaultDensity());
  final _quantityConversionNotifier = ValueNotifier<Conversion>(Conversion.defaultQuantity());
  
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
          switch (snapshot.connectionState) {
            case ConnectionState.done:
              final products = snapshot.data as List<Product>;
              if (isEdit) {
                try {
                  preEditProduct = products.firstWhere((prod) => prod.name == widget.productName);
                  _id = preEditProduct!.id;
                  _defaultUnit = preEditProduct!.defaultUnit;
                  _densityConversionNotifier.value = preEditProduct!.densityConversion;
                  _quantityConversionNotifier.value = preEditProduct!.quantityConversion;
                } catch (e) {
                  return const Text("Error: Product not found");
                }
              }
              _name.text = widget.productName ?? "";
              
              return Padding(
                padding: const EdgeInsets.all(7.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _buildNameField(products),
                      _buildDefaultUnitDropdown(),
                      _buildConversionField(0),
                      _buildConversionField(1),
                      _buildAddButton(),
                    ]
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
    List<Unit> units = Unit.values;
    Map<Unit, Widget> items = {};
    
    for (var unit in units) {
      if (unit == Unit.quantity) {
        // check whether the user has set up a quantity conversion
        if (true) {
          var quantityName = preEditProduct?.quantityUnit ?? "x";
          items[unit] = RichText(
            text: TextSpan(
              text: quantityName,
              children: const [
                TextSpan(
                  text: "   (quantity)",
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
          ),
        );
      }
    }
    
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
                child: DropdownButtonFormField<Unit>(
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 14),
                  ),
                  value: _defaultUnit,
                  items: items.entries.map((entry) => DropdownMenuItem<Unit>(
                    value: entry.key,
                    child: entry.value,
                  )).toList(),
                  onChanged: (Unit? unit) {
                    if (unit != null) {
                      setState(() {
                        _defaultUnit = unit;
                      });
                    }
                  },
                ),
              ),
            ]
          ),
        );
      }
    );
  }
  
  Widget _buildUnitDropdown(List<Unit> availableUnits,  onChanged) {
    
  }
    
  Widget _buildConversionField(int index) {
    var checkBoxTexts = ["Enable Volumetric Conversion", "Enable Quantity Conversion"];
    var text = checkBoxTexts[index];
    var notifier = index == 0 ? _densityConversionNotifier : _quantityConversionNotifier;
    
    // create a black rounded square as a container
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ValueListenableBuilder(
        valueListenable: notifier,
        builder: (context, value, child) {
          var enabled = value.enabled;
          var textAlpha = enabled ? 255 : 160;
          
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: enabled ? const Color.fromARGB(224, 25, 82, 77) : const Color.fromARGB(151, 158, 158, 158),
                width: 2,
              ),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  value: enabled,
                  controlAffinity: ListTileControlAffinity.leading,
                  onChanged: (bool value) => notifier.value = notifier.value.switched(value),
                  title: Text(
                    text,
                    style: TextStyle(
                      color: Colors.black.withAlpha(textAlpha),
                      fontSize: 16,
                    ),
                  ),
                ),
                Row(
                  children: [
                    // amount field
                    _buildAmountField(notifier, 1),
                  ]
                )
              ],
            ),
          );
        }
      ),
    );
  }
  
  Widget _buildAmountField(ValueNotifier<Conversion> notifier, int index) {
    var amount = index == 0 ? notifier.value.amount1 : notifier.value.amount2;
    
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: TextFormField(
          decoration: const InputDecoration(
            contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 14),
          ),
          initialValue: amount.toString(),
          keyboardType: TextInputType.number,
          validator: (String? value) {
            if (value == null || value.isEmpty) {
              return "Required Field";
            }
            try {
              double.parse(value);
              return null;
            } catch (e) {
              return "Invalid Number";
            }
          },
          autovalidateMode: AutovalidateMode.onUserInteraction,
          onChanged: (String? value) {
            if (value != null && value.isNotEmpty) {
              try {
                var input = double.parse(value);
                if (index == 0) {
                  notifier.value = notifier.value.withAmount1(input);
                } else {
                  notifier.value = notifier.value.withAmount2(input);
                }
                devtools.log("Changed amount$index to $value");
              } catch (e) {
                devtools.log("Error: Invalid number in amount$index field");
              }
            }
          },
        ),
      ),
    );
  }
  
  Widget _buildAddButton() => Padding(
    padding: const EdgeInsets.all(8.0),
    child: TextButton(
      onPressed: () {
        //final name = _name.text;
        final isValid = _formKey.currentState!.validate();
        if (isValid) {
          //if (isEdit) {
          //  var product = Product(_id, name);
          //  _dataService.updateProduct(product);
          //} else {
          //  var product = Product(-1, name);
          //  _dataService.createProduct(product);
          //}
          Navigator.of(context).pop();
        }
      },
      child: Text(isEdit ? "Update" : "Add"),
    ),
  );
}