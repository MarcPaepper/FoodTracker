import 'package:flutter/material.dart';
import 'package:food_tracker/widgets/search_field.dart';

import '../services/data/data_objects.dart';

// import 'dart:developer' as devtools show log;

import '../widgets/products_list.dart';

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

Future showContinueWithoutSavingDialog(BuildContext context) => 
  showDialog(
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
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Choose a product'),
            Expanded(
              child: _ProductList(products: products, onSelected: onChanged),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    onChanged(null);
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancel'),
                ),
              ]
            )
          ]
        )
      );
    }
  );
}

class _ProductList extends StatefulWidget {
  final List<Product> products;
  final Function(Product) onSelected;
  
  const _ProductList({
    required this.products,
    required this.onSelected,
  });

  @override
  State<_ProductList> createState() => __ProductListState();
}

class __ProductListState extends State<_ProductList> {
  final TextEditingController _searchController = TextEditingController();
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: SearchField(
              searchController: _searchController,
              onChanged: (value) => setState(() {}),
            )
          )
        ),
        Expanded(
          child: ListView(
            children: getProductTiles(
              context: context,
              products: widget.products,
              search: _searchController.text,
              onSelected: (name, id) {
                var product = widget.products.firstWhere((element) => element.id == id);
                Navigator.of(context).pop();
                setState(() {
                  _searchController.clear();
                });
                widget.onSelected(product);
              }
            ),
          ),
        ),
      ],
    );
  }
}