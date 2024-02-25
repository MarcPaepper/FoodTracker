import 'package:flutter/material.dart';

import '../services/data/data_objects.dart';

import 'dart:developer' as devtools show log;

void showErrorbar(BuildContext context, String msg) {
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

Future showContinueWithoutSavingDialog(BuildContext context) => showDialog(
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

// a dialog which lets you choose a product
// a textfield on top lets you filter the products
// a listview with the products
// you can exit the dialog by clicking cancel or choosing a product
void showProductDialog(
  BuildContext context,
  List<Product> products,
  Product? selectedProduct,
  void Function(Product?) onChanged
) {
  devtools.log("showProductDialog");
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Choose a product'),
        content: Column(
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: 'Filter products',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) {}
            ),
            ListView.builder(
              itemCount: products.length,
              itemBuilder: (BuildContext context, int index) {
                var product = products[index];
                return ListTile(
                  title: Text(product.name),
                  onTap: () {
                    onChanged(product);
                    Navigator.of(context).pop();
                  },
                  selected: product == selectedProduct,
                );
              }
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              onChanged(null);
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
        ],
      );
    }
  );
}