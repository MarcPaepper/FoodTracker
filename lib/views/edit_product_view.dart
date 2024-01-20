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
                } catch (e) {
                  return const Text("Error: Product not found");
                }
              }
              _name.text = widget.productName ?? "";
              _defaultUnit = preEditProduct?.defaultUnit ?? Unit.g;
              
              return Padding(
                padding: const EdgeInsets.all(7.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _buildNameField(products),
                      _buildDefaultUnitDropdown(_defaultUnit),
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
  
  Widget _buildDefaultUnitDropdown(Unit currentDefaultUnit) {
    List<Unit> units = Unit.values;
    Map<Unit, Widget> items = {};
    
    for (var unit in units) {
      if (unit == Unit.quantity) {
        // check whether the user has set up a quantity conversion
        if (true) {
          var quantityName = preEditProduct?.quantityUnit ?? "x";
          items[unit] = RichText(
            text: TextSpan(
              text: "$quantityName ",
              children: const [
                TextSpan(
                  text: "(quantity)",
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          );
        }
      } else {
        items[unit] = Text(unitToString(unit));
      }
    }
    
    return StatefulBuilder(
      builder: (BuildContext context, StateSetter setState) {
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                // black text saying "Default Unit:"
                child: Text("  Default Unit:", style: TextStyle(color: Colors.black.withAlpha(200))),
              ),
              Expanded(
                child: DropdownButtonFormField<Unit>(
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                  value: currentDefaultUnit,
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