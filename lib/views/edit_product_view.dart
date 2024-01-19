import 'package:flutter/material.dart';
import 'package:food_tracker/constants/data.dart';
import 'package:food_tracker/services/data/data_objects.dart';
// import "dart:developer" as devtools show log;

import 'package:food_tracker/services/data/data_service.dart';
import 'package:food_tracker/utility/modals.dart';
import 'package:food_tracker/widgets/loading_page.dart';

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
  int _id = -1;
  
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
        // show the delete button if editing
        actions: isEdit ? [
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
          )
        ] : null
      ),
      body: FutureBuilder(
        future: _dataService.getAllProducts(),
        builder: (context, snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.done:
              final products = snapshot.data as List<Product>;
              if (isEdit) {
                try {
                  final product = products.firstWhere((prod) => prod.name == widget.productName);
                  _name.text = product.name;
                  _id = product.id;
                } catch (e) {
                  return const Text("Error: Product not found");
                }
              }
              return Padding(
                padding: const EdgeInsets.all(7.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _buildNameField(products),
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
  
  Widget _buildNameField(Iterable products) => Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextFormField(
        controller: _name,
        decoration: const InputDecoration(
          labelText: "Name"
        ),
        validator: (String? value) {
          for (var prod in products) {
            if (prod.name == value && prod.name != widget.productName) {
              return "Already taken";
            }
          }
          if (value == null || value.isEmpty) {
            return "Required Field";
          }
          return null;
        },
        autovalidateMode: AutovalidateMode.onUserInteraction,
      ),
    );
  
  Widget _buildAddButton() => Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextButton(
        onPressed: () {
          final name = _name.text;
          final isValid = _formKey.currentState!.validate();
          if (isValid) {
            if (isEdit) {
              var product = Product(_id, name);
              _dataService.updateProduct(product);
            } else {
              var product = Product(-1, name);
              _dataService.createProduct(product);
            }
            Navigator.of(context).pop();
          }
        },
        child: Text(isEdit ? "Update" : "Add"),
      ),
    );
}