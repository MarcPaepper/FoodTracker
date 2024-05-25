import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../widgets/search_field.dart';
import '../constants/routes.dart';
import '../services/data/data_objects.dart';
import '../widgets/products_list.dart';
import 'theme.dart';

// import 'dart:developer' as devtools show log;


void showErrorbar(BuildContext context, String msg) =>
  _showSnackbar(context: context, msg: msg, bgColor: const Color.fromARGB(255, 77, 22, 0), icon: const Icon(Icons.warning, color: Colors.white));

void showSnackbar(context, msg, {Color bgColor = Colors.teal, Icon? icon}) =>
  _showSnackbar(context: context, msg: msg, bgColor: bgColor, icon: icon);

void _showSnackbar({
  required BuildContext context,
  required String msg,
  required Color bgColor,
  Icon? icon,
}) {
  var children = <Widget>[];
  if (icon != null) {
    children.add(icon);
    children.add(const SizedBox(width: 10));
  }
  children.add(Text(msg));
  
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: children,
      ),
      backgroundColor: bgColor,
    )
  );
}

Future showContinueWithoutSavingDialog(BuildContext context, {Function()? save}) => 
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Discard changes?'),
      content: const Text('If you continue, you lose your changes.'),
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
            if (save != null) ...[
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  style: actionButtonStyle,
                  onPressed: () {
                    save();
                    Navigator.of(context).pop(true);
                  },
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                    child: Text('Save'),
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    ),
  );

void showUsedAsIngredientDialog({
  required String name,
  required BuildContext context,
  required Map<int, Product> usedAsIngredientIn,
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
          child: _MainList(
            onSelected: (product) {
              beforeNavigate();
              Navigator.of(context).pushNamed(
                editProductRoute,
                arguments: (product.name, false),
              );
            },
            productsMap: usedAsIngredientIn,
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
                  Navigator.of(context).pop(null);
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
  required Map<int, Product> productsMap,
  Product? selectedProduct,
  required void Function(Product?) onSelected,
  void Function()? beforeAdd,
  bool autofocus = false,
}) => showDialog(
    context: context,
    builder: (BuildContext context) {
      var searchController = TextEditingController();
      
      return Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _MainList(
                productsMap: productsMap,
                onSelected: onSelected,
                onLongPress: (product) =>
                  onAddProduct(context, product.name, true, beforeAdd, onSelected),
                searchController: searchController,
                autofocus: autofocus,
              ),
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
                        String? name = searchController.text;
                        name = name == '' ? null : name;
                        onAddProduct(context, name, false, beforeAdd, onSelected);
                      },
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 0, vertical: 10.0),
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

// show a dialog which lets you see the creation date and the last edit date of a product
void showProductInfoDialog(BuildContext context, Product product) => showDialog(
  context: context,
  builder: (context) => AlertDialog(
    title: const Text('Product Info'),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Created on: ${DateFormat.yMd(Platform.localeName).format(product.creationDate!)}"),
        Text("Last Edit: ${DateFormat.yMd(Platform.localeName).format(product.lastEditDate!)}"),
      ],
    ),
    actions: [
      ElevatedButton(
        style: actionButtonStyle,
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Close'),
      ),
    ],
  ),
);

void onAddProduct(
  BuildContext context,
  String? name,
  bool isCopy,
  void Function()? beforeAdd,
  void Function(Product?) onSelected,
) {
  beforeAdd?.call();
  // navigate to the product creation screen
  // and wait for the result
  Navigator.of(context).pushNamed(
    addProductRoute,
    arguments: (name, isCopy),
  ).then((value) {
    Navigator.of(context).pop();
    if (value == null) {
      onSelected(null);
    } else {
      onSelected(value as Product);
    }
  });
}

class _MainList extends StatefulWidget {
  final Map<int, Product> productsMap;
  final Function(Product) onSelected;
  final Function(Product)? onLongPress;
  final bool showSearch;
  final bool colorFromTop;
  final TextEditingController? searchController;
  final bool autofocus;
  
  const _MainList({
    required this.productsMap,
    required this.onSelected,
    this.onLongPress,
    this.showSearch = true,
    this.colorFromTop = false,
    this.searchController,
    this.autofocus = false,
  });

  @override
  State<_MainList> createState() => _MainListState();
}

class _MainListState extends State<_MainList> {
  late TextEditingController _searchController;
  
  @override
  void initState() {
    _searchController = widget.searchController ?? TextEditingController();
    super.initState();
  }
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        widget.showSearch ? Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(15),
              topRight: Radius.circular(15),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SearchField(
              searchController: _searchController,
              onChanged: (value) => setState(() {}),
              autofocus: widget.autofocus,
            )
          )
        ) : const SizedBox(),
        Expanded(
          child: ListView(
            children: getProductTiles(
              context: context,
              products: widget.productsMap.values.toList(),
              search: _searchController.text,
              colorFromTop: widget.colorFromTop,
              onSelected: (name, id) {
                var product = widget.productsMap[id]!;
                Navigator.of(context).pop();
                setState(() {
                  _searchController.clear();
                });
                widget.onSelected(product);
              },
              onLongPress: (name, id) {
                var product = widget.productsMap[id]!;
                if (widget.onLongPress != null) {
                  widget.onLongPress!(product);
                } else {
                  widget.onSelected(product);
                }
              }
            ),
          ),
        ),
      ],
    );
  }
}