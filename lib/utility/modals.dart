import 'package:flutter/material.dart';
import 'package:food_tracker/widgets/search_field.dart';

import '../constants/routes.dart';
import '../services/data/data_objects.dart';

// import 'dart:developer' as devtools show log;

import '../widgets/products_list.dart';
import 'theme.dart';

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
      title: const Text('Discard changes?'),
      content: const Text('You have made changes which will be lost unless you save them.'),
      surfaceTintColor: Colors.transparent,
      actionsAlignment: MainAxisAlignment.spaceEvenly,
      actions: <Widget>[
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                style: actionButtonStyle,
                onPressed: () => Navigator.of(context).pop(true),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                  child: Text('Yes'),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                style: actionButtonStyle,
                onPressed: () => Navigator.of(context).pop(false),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                  child: Text('No'),
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );

void showUsedAsIngredientDialog({
  required String name,
  required BuildContext context,
  required List<Product> usedAsIngredient,
  required Function() beforeNavigate,
}) => showDialog(
  context: context,
  builder: (context) => Dialog(
    // surfaceTintColor: Colors.transparent,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
          child: Text(
            '"$name" is used as an ingredient in:',
            style: const TextStyle(fontSize: 16),
          ),
        ),
        Expanded(
          child: _ProductList(
            onSelected: (product) {
              beforeNavigate();
              Navigator.of(context).pushNamed(
                editProductRoute,
                arguments: product.name,
              );
            },
            products: usedAsIngredient,
            showSearch: false,
            colorFromTop: true,
          )
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: ElevatedButton(
                style: actionButtonStyle,
                onPressed: () {
                  Navigator.of(context).pop([true, "Hallo7"]);
                },
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10, horizontal: 40),
                  child: Text('Cancel'),
                ),
              ),
            ),
          ],
        )
      ],
    ),
  )
);

// a dialog which lets you choose a product
// a textfield on top lets you filter the products
// a listview with the products
// you can exit the dialog by clicking cancel or choosing a product
void showProductDialog({
  required BuildContext context,
  required List<Product> products,
  Product? selectedProduct,
  required void Function(Product?) onSelected,
  void Function()? beforeAdd,
}) => showDialog(
    context: context,
    builder: (BuildContext context) {
      return Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                'Choose a product',
                style: TextStyle(fontSize: 17),
              ),
            ),
            Expanded(
              child: _ProductList(products: products, onSelected: onSelected),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: actionButtonStyle,
                      onPressed: () {
                        beforeAdd?.call();
                        // navigate to the product creation screen
                        // and wait for the result
                        
                      },
                      child: const Padding(
                        padding: EdgeInsets.all(10.0),
                        child: Text('Create new'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      style: actionButtonStyle,
                      onPressed: () {
                        onSelected(null);
                        Navigator.of(context).pop();
                      },
                      child: const Padding(
                        padding: EdgeInsets.all(10.0),
                        child: Text('Cancel'),
                      ),
                    ),
                  ),
                ]
              )
            ),
          ]
        )
      );
    }
  );

class _ProductList extends StatefulWidget {
  final List<Product> products;
  final Function(Product) onSelected;
  final bool showSearch;
  final bool colorFromTop;
  
  const _ProductList({
    required this.products,
    required this.onSelected,
    this.showSearch = true,
    this.colorFromTop = false,
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
        widget.showSearch ? Container(
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: SearchField(
              searchController: _searchController,
              onChanged: (value) => setState(() {}),
            )
          )
        ) : const SizedBox(),
        Expanded(
          child: ListView(
            children: getProductTiles(
              context: context,
              products: widget.products,
              search: _searchController.text,
              colorFromTop: widget.colorFromTop,
              onSelected: (name, id) {
                var product = widget.products.firstWhere((element) => element.id == id);
                Navigator.of(context).pop();
                setState(() {
                  _searchController.clear();
                });
                widget.onSelected(product);
              },
            ),
          ),
        ),
      ],
    );
  }
}