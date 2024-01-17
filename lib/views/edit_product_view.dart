import 'package:flutter/material.dart';
import 'package:food_tracker/constants/data.dart';
import 'package:food_tracker/services/data/data_objects.dart';
// import "dart:developer" as devtools show log;

import 'package:food_tracker/services/data/data_service.dart';

class EditProductView extends StatefulWidget {
  final int? productId;
  final bool? isEdit;
  
  const EditProductView({Key? key, this.isEdit, this.productId}) : super(key: key);

  @override
  State<EditProductView> createState() => _EditProductViewState();
}

class _EditProductViewState extends State<EditProductView> {
  final _dataService = DataService.current();
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final bool isEdit;
  
  @override
  void initState() {
    if (widget.isEdit == null || (widget.isEdit! && widget.productId == null)) {
      Future(() {
        _showErrorbar("Error: Product not found");
        Navigator.of(context).pop();
      });
    }
    
    isEdit = widget.isEdit ?? false;
    
    _name = TextEditingController();
    _dataService.open(dbName);
    super.initState();
  }
  
  void _showErrorbar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning, color: Colors.white),
            const SizedBox(width: 10),
            Text(msg)
          ]
        ),
        backgroundColor: const Color.fromARGB(255, 77, 22, 0),
      )
    );
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
                        _dataService.deleteProduct(widget.productId!);
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
                  final product = products.firstWhere((prod) => prod.id == widget.productId);
                  _name.text = product.name;
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
                      buildNameField(products),
                      buildAddButton(products),
                    ]
                  ),
                ),
              );
            case ConnectionState.none:
            case ConnectionState.waiting:
            case ConnectionState.active:
            default:
              return Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.all(50.0),
                  child: SizedBox(
                    width: 30,
                    height: 30,
                    child: CircularProgressIndicator(
                      color: Colors.teal.shade500
                    ),
                  ),
                )
              );
          }
        }
      )
    );
  }
  
  Widget buildNameField(Iterable products) => Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextFormField(
        controller: _name,
        decoration: const InputDecoration(
          labelText: "Name"
        ),
        validator: (String? value) {
          for (var prod in products) {
            if (prod.name == value && prod.id != widget.productId) {
              return "Already taken";
            } else if (value == null || value.isEmpty) {
              return "Product must have a name";
            }
          }
          return null;
        },
        autovalidateMode: AutovalidateMode.onUserInteraction,
      ),
    );
  
  Widget buildAddButton(Iterable products) => Padding(
      padding: const EdgeInsets.all(8.0),
      child: TextButton(
        onPressed: () {
          final name = _name.text;
          final isValid = _formKey.currentState!.validate();
          if (isValid) {
            if (isEdit) {
              var product = Product(widget.productId!, name);
              _dataService.updateProduct(product);
            } else {
              _dataService.createProduct(name);
            }
            Navigator.of(context).pop();
          }
        },
        child: Text(isEdit ? "Update" : "Add"),
      ),
    );
}