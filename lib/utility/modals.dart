import 'package:flutter/material.dart';
import 'package:food_tracker/utility/data_logic.dart';
import 'package:food_tracker/utility/text_logic.dart';

import '../constants/ui.dart';
import '../services/data/data_service.dart';
import '../widgets/search_field.dart';
import '../constants/routes.dart';
import '../services/data/data_objects.dart';
import '../widgets/products_list.dart';
import '../widgets/sort_field.dart';
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
    children.add(const SizedBox(width: 10 * gsf));
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

Future showContinueWithoutSavingDialog(BuildContext context, {Function()? save, String? prodName}) => 
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Unsaved changes'),
      content: const Text('The product has unsaved changes. How do you want to proceed?'),
      surfaceTintColor: Colors.transparent,
      actionsAlignment: MainAxisAlignment.spaceEvenly,
      actions: <Widget>[
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (save != null) ...[
              ElevatedButton.icon(
                style: actionButtonStyle,
                onPressed: () {
                  save();
                  Navigator.of(context).pop(false);
                },
                icon: const Icon(Icons.save, color: Colors.white, size: 24 * gsf),
                label: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 10) * gsf,
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Save',
                        style: TextStyle(fontSize: 16 * gsf, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 2 * gsf),
                       Text(
                        'Save changes and exit',
                        style: TextStyle(fontSize: 14 * gsf),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16 * gsf),
            ],
            ElevatedButton.icon(
              style: actionButtonStyle,
              onPressed: () => Navigator.of(context).pop(true),
              icon: const Icon(Icons.delete, color: Colors.white, size: 24 * gsf),
              label: const Padding(
                padding: EdgeInsets.symmetric(vertical: 0, horizontal: 10 * gsf),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Discard',
                      style: TextStyle(fontSize: 16 * gsf, fontWeight: FontWeight.bold)
                    ),
                    SizedBox(height: 2 * gsf),
                    Text(
                      "Ignore unsaved changes",
                      style: TextStyle(fontSize: 14 * gsf),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16 * gsf),
            ElevatedButton.icon(
              style: actionButtonStyle,
              onPressed: () => Navigator.of(context).pop(false),
              icon: RotatedBox(
                quarterTurns: 2,
                child: Image.asset("assets/geschwungen_arrow.png", width: 24 * gsf, height: 24 * gsf)
              ),
              label: Padding(
                padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 10) * gsf,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Cancel',
                      style: TextStyle(fontSize: 16 * gsf, fontWeight: FontWeight.bold)
                    ),
                    const SizedBox(height: 2 * gsf),
                    Text(
                      'Continue editing ${prodName != null ? "'$prodName'" : "the product"}',
                      style: const TextStyle(fontSize: 14 * gsf)
                    ),
                  ],
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
          padding: const EdgeInsets.fromLTRB(12, 14, 12, 12) * gsf,
          child: Text(
            '"$name" is used as an ingredient in:',
            style: const TextStyle(fontSize: 16 * gsf),
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
            refDate: DateTime.now(),
          )
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Padding(
              padding: const EdgeInsets.all(12) * gsf,
              child: ElevatedButton(
                style: actionButtonStyle,
                onPressed: () {
                  Navigator.of(context).pop(null);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 40) * gsf,
                  child: const Text('Cancel'),
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
  Map<int, double>? relevancies,
  Product? selectedProduct,
  required void Function(Product?) onSelected,
  void Function()? beforeAdd,
  bool autofocus = false,
  bool allowNew = true,
  DateTime? refDate,
}) => showDialog(
    context: context,
    builder: (BuildContext context) {
      var searchController = TextEditingController();
      
      return Dialog(
        insetPadding: const EdgeInsets.all(28) * gsf,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: _MainList(
                productsMap: productsMap,
                relevancies: relevancies,
                onSelected: onSelected,
                onLongPress: (product) {
                  if (allowNew) onAddProduct(context, product.name, true, beforeAdd, onSelected);
                },
                searchController: searchController,
                autofocus: autofocus,
                refDate: refDate,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12) * gsf,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (allowNew) ...[
                    Expanded(
                      child: ElevatedButton(
                        style: actionButtonStyle.copyWith(
                          padding: WidgetStateProperty.all(EdgeInsets.zero),
                        ),
                        onPressed: () {
                          String? name = searchController.text;
                          name = name == '' ? null : name;
                          onAddProduct(context, name, false, beforeAdd, onSelected);
                        },
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 0 * gsf, vertical: 10.0 * gsf),
                          child: Text('Create new'),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16 * gsf),
                  ],
                  Expanded(
                    child: ElevatedButton(
                      style: actionButtonStyle.copyWith(
                        padding: WidgetStateProperty.all(EdgeInsets.zero),
                      ),
                      onPressed: () {
                        onSelected(null);
                        Navigator.of(context).pop();
                      },
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 0 * gsf, vertical: 10.0 * gsf),
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
  builder: (context) {
    var dates = [product.creationDate!, product.lastEditDate!];
    var datesStr = conditionallyRemoveYear(context, dates, showWeekDay: false, removeYear: YearMode.never);
    
    return AlertDialog(
      title: const Text('Product Info'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Created on: ${datesStr[0]}"),
          Text("Last Edit: ${datesStr[1]}"),
          FutureBuilder(
            future: DataService.current().getAllMeals(),
            builder: (context, snapshot) {
              String numberOfMeals = "???";
              String amount = "???";
              
              if (!snapshot.hasError && snapshot.connectionState == ConnectionState.done) {
                Unit defUnit = product.defaultUnit;
                List<Meal> meals = snapshot.data as List<Meal>;
                int count = 0;
                double amountSum = 0;
                for (var meal in meals) {
                  var pQ = meal.productQuantity;
                  if (product.id != pQ.productId) continue;
                  count++;
                  // convert from meal unit to default unit
                  amountSum += convertToUnit(defUnit, pQ.unit, pQ.amount, product.densityConversion, product.quantityConversion, enableTargetQuantity: true);
                }
                numberOfMeals = count.toString();
                amount = "${truncateZeros(roundDouble(amountSum))} ${defUnit == Unit.quantity ? product.quantityName : defUnit.name}";
                List<UnitType> unitTypesUsed = [unitTypes[defUnit]!];
                // if the product has conversions, give the amount in those units as well
                // if (defUnit == Unit.quantity) {
                //   if (product.quantityConversion.enabled) {
                //     // convert to the other unit
                //     var newAmount = convertToUnit(product.quantityConversion.unit2, defUnit, amountSum, product.densityConversion, product.quantityConversion);
                //     amount += "= ${truncateZeros(roundDouble(newAmount))} ${product.quantityConversion.unit2.name}";
                //   }
                // }
                if (product.quantityConversion.enabled) {
                  bool forwards = unitTypesUsed.contains(UnitType.quantity);
                  Unit targetUnit = forwards ? product.quantityConversion.unit2 : product.quantityConversion.unit1;
                  var newAmount = convertToUnit(targetUnit, defUnit, amountSum, product.densityConversion, product.quantityConversion, enableTargetQuantity: true);
                  amount += " = ${truncateZeros(roundDouble(newAmount))} ${forwards ? targetUnit.name : product.quantityName}";
                }
                if (product.densityConversion.enabled) {
                  bool forwards = unitTypesUsed.contains(UnitType.volumetric);
                  Unit targetUnit = forwards ? product.densityConversion.unit2 : product.densityConversion.unit1;
                  var newAmount = convertToUnit(targetUnit, defUnit, amountSum, product.densityConversion, product.quantityConversion);
                  amount += " = ${truncateZeros(roundDouble(newAmount))} ${targetUnit.name}";
                }
              }
              return Text("\nYou've used ${product.name} directly in $numberOfMeals meals, amounting to $amount. (This does not include products which contain ${product.name} as an ingredient)");
            },
          ),
        ],
      ),
      actions: [
        ElevatedButton(
          style: actionButtonStyle,
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
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
  final Map<int, double>? relevancies;
  final Function(Product) onSelected;
  final Function(Product)? onLongPress;
  final bool showSearch;
  final bool colorFromTop;
  final TextEditingController? searchController;
  final bool autofocus;
  final DateTime? refDate;
  
  const _MainList({
    required this.productsMap,
    this.relevancies,
    required this.onSelected,
    this.onLongPress,
    this.showSearch = true,
    this.colorFromTop = false,
    this.searchController,
    this.autofocus = false,
    this.refDate,
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
    if (widget.productsMap.isEmpty) {
      return const Center(
        child: Text(
          'No products found',
          style: TextStyle(
            color: Colors.grey,
            fontStyle: FontStyle.italic,
            fontSize: 16.0 * gsf,
          ),
        ),
      );
    }
    
    return Column(
      children: [
        widget.showSearch ? Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(15 * gsf),
              topRight: Radius.circular(15 * gsf),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0) * gsf,
            child: SearchField(
              textController: _searchController,
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
              sorting: (SortType.relevancy, SortOrder.descending),
              relevancies: widget.relevancies,
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
              },
              refDate: widget.refDate,
            ),
          ),
        ),
      ],
    );
  }
}