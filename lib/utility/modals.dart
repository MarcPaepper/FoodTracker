import 'dart:math';

import 'package:flutter/material.dart';
import 'package:food_tracker/utility/data_logic.dart';
import 'package:food_tracker/utility/text_logic.dart';

import '../constants/ui.dart';
import '../services/data/data_service.dart';
import '../widgets/amount_field.dart';
import '../widgets/search_field.dart';
import '../constants/routes.dart';
import '../services/data/data_objects.dart';
import '../widgets/products_list.dart';
import '../widgets/sort_field.dart';
import 'theme.dart';

// import 'dart:developer' as devtools show log;

void showErrorbar(BuildContext context, String msg, {double? duration}) => _showSnackbar(
  context: context,
  msg: msg,
  bgColor: const Color.fromARGB(255, 77, 22, 0),
  icon: const Icon(Icons.warning, color: Colors.white),
  duration: duration,
);

void showSnackbar(context, msg, {Color bgColor = Colors.teal, Icon? icon, double? duration}) =>
  _showSnackbar(context: context, msg: msg, bgColor: bgColor, icon: icon, duration: duration);

void _showSnackbar({
  required BuildContext context,
  required String msg,
  required Color bgColor,
  Icon? icon,
  double? duration,
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
      duration: Duration(milliseconds: ((duration ?? 4) * 1000).toInt()),
    ),
  );
}

Future<T?> showOptionDialog<T>({
  required BuildContext context,
  String? title,
  Color? titleBgColor,
  Widget? icon,
  double? iconWidth,
  required Widget content,
  required List<(String?, T Function()?)> options,
  double insetPadding = 28 * gsf,
  double contentPadding = 12 * gsf,
  bool scrollContent = false,
}) {
  Widget? titleWidget;
  if (title != null) {
    var titleColor = Colors.black;
    if (titleBgColor != null) {
      var a = titleBgColor.alpha;
      var r = titleBgColor.red;
      var g = titleBgColor.green;
      var b = titleBgColor.blue;
      // geometric mean
      var avg = pow(r * g * b, 1 / 3);
      avg = a * avg / 255 + 255 - a;
      if (avg < 100) {
        titleColor = Colors.white;
      } else {
        titleColor = Colors.black;
      }
    }
    
    titleWidget = Text(
      title,
      textAlign: TextAlign.center,
      style: TextStyle(fontSize: 18 * gsf, fontWeight: FontWeight.w400, color: titleColor),
    );
    
    if (icon != null) {
      titleWidget = Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          icon,
          const SizedBox(width: 10 * gsf),
          Expanded(child: titleWidget),
          SizedBox(width: 10 * gsf + (iconWidth ?? 0)),
        ],
      );
    }
    
    titleWidget = Container(
      decoration: BoxDecoration(
        color: titleBgColor ?? Colors.transparent,
        borderRadius: const BorderRadius.only(
          topLeft:  Radius.circular(14),
          topRight: Radius.circular(14),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8) * gsf,
      child: titleWidget,
    );
  }
  
  List<Widget> optionButtons = [SizedBox(width: contentPadding)];
  for (int i = 0; i < options.length; i++) {
    optionButtons.add(
      Expanded(
        child: options[i].$1 == null ?
          Container() :
          ElevatedButton(
            style: actionButtonStyle.copyWith(
              padding: WidgetStateProperty.all(EdgeInsets.zero),
            ),
            onPressed: () => Navigator.of(context).pop(options[i].$2 != null ? options[i].$2!() : null),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 0 * gsf, vertical: 10.0 * gsf),
              child: Text(options[i].$1!),
            ),
          ),
      )
    );
    if (i != options.length - 1) {
      optionButtons.add(const SizedBox(width: 16 * gsf));
    }
  }
  optionButtons.add(SizedBox(width: contentPadding));
  
  if (contentPadding != 0) {
    content = Padding(
      padding: EdgeInsets.all(contentPadding),
      child: content,
    );
  }
  
  if (scrollContent) {
    content = Expanded(
      child: SingleChildScrollView(
        child: content,
      ),
    );
  }
  
  return showDialog(
    context: context,
    builder: (context) {
      return Dialog(
        alignment: Alignment.center,
        insetPadding: EdgeInsets.all(insetPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            titleWidget ?? Container(),
            // SizedBox(height: title == null ? 0 : 12 * gsf),
            content,
            const SizedBox(height: 10 * gsf),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: optionButtons,
            ),
            SizedBox(height: contentPadding),
          ],
        ),
      );
    },
  );
}

Future showContinueWithoutSavingDialog(BuildContext context, {Function()? save, String? prodName}) => 
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Unsaved changes'),
      content: Column(
        children: [
          const Text('The product has unsaved changes. How do you want to proceed?'),
          const SizedBox(height: 24 * gsf),
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
      surfaceTintColor: Colors.transparent,
      actionsAlignment: MainAxisAlignment.spaceEvenly,
      scrollable: true,
    ),
  );

void showUsedAsIngredientDialog({
  required String name,
  required BuildContext context,
  required Map<int, Product> usedAsIngredientIn,
  required Function() beforeNavigate,
}) {
  final maxHeight = max(MediaQuery.of(context).size.height * .75 - 350 * gsf, 100 * gsf);
  
  showOptionDialog(
    context: context,
    title: "Can not delete",
    content: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('"$name" is used as an ingredient in:'),
        const SizedBox(height: 10 * gsf),
        ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: maxHeight,
          ),
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
            expand: false,
          ),
        ),
      ],
    ),
    options: [
      ("Close", null),
    ],
  );
}

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
void showProductInfoDialog(BuildContext context, Product product) {
  var dates = [product.creationDate!, product.lastEditDate!];
  var datesStr = conditionallyRemoveYear(context, dates, showWeekDay: false, removeYear: YearMode.never);
  
  showOptionDialog(
    context: context,
    title: "Product Info",
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
            return Text("\nYou've used ${product.name} directly in $numberOfMeals meals, amounting to $amount.\n\n(This does not include products which contain ${product.name} as an ingredient)");
          },
        ),
      ],
    ),
    options: [
      (null, null),
      ("Close", null),
    ],
  );
}

Future<String?> showProductDescriptionDialog(BuildContext context, String currentDescription, String prodName) async {
  final dialogDescriptionController = TextEditingController(text: currentDescription);
  
  final maxHeight = max(MediaQuery.of(context).size.height * .75 - 150 * gsf, 100 * gsf);
  String title = prodName == "" ? "Product Description" : "Description for '$prodName'";
  
  return showOptionDialog<String?>(
    context: context,
    title: title,
    content: ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: maxHeight,
      ),
      child: TextField(
        controller: dialogDescriptionController,
        maxLines: null,
        minLines: 5,
        // expands: true,
        keyboardType: TextInputType.multiline,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(
          hintText: "Description / Notes",
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.all(11) * gsf,
          isDense: true,
        ),
        autofocus: true,
      ),
    ),
    options: [
      ("Save", () => dialogDescriptionController.text.trim()),
      ("Cancel", null),
    ],
  );
}

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

Future<double?> showScaleModal({
  required BuildContext context,
  required Map<int, Product> productsMap,
  required double currentAmount,
  required Unit unit,
  required List<ProductQuantity> ingredients, // List of ingredient names and their current amounts
  required String productName,
  //required Function(double) onScaleConfirmed,
}) async {
  final TextEditingController scaleController = TextEditingController(text: "1.0");
  double scaleFactor = 1.0;
  
  return showOptionDialog<double?>(
    title: "Scale ingredient list",
    context: context,
    titleBgColor: Color.lerp(Colors.teal.shade100, Colors.teal.shade200, 0.9)!,
    icon: Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 7) * gsf,
      child: Image.asset(
        "assets/scale.png",
        width:  30 * gsf,
        height: 30 * gsf,                      
        // primary color of theme
        color: Colors.teal.shade700,
      ),
    ),
    iconWidth: (30 + 10) * gsf,
    scrollContent: true,
    contentPadding: 16 * gsf,
    content: StatefulBuilder(
      builder: (context, setState) {
        int? precision = getPrecision(currentAmount);
        var roundedAmount = double.parse(roundDouble(currentAmount * scaleFactor, precision: precision));
        double scaledResultingAmount = roundedAmount;
        
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text("Enter a scaling factor to multiply all ingredient amounts and the resulting amount by the same value:"),
            const SizedBox(height: 15 * gsf),
            AmountField(
              controller: scaleController,
              padding: 0,
              autofocus: true,
              onChangedAndParsed: (newAmount) {
                setState(() => scaleFactor = newAmount);
              },
            ),
            const SizedBox(height: 20 * gsf),
            const Center(
              child: Text(
                " Preview:",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 10 * gsf),
            const Divider(
              // indent: 4 * gsf,
              thickness: 1.5 * gsf,
              // endIndent:  * gsf,
            ),
            // getTitledDivider("Preview:"),
            const SizedBox(height: 10),
            Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  minVerticalPadding: 0,
                  visualDensity: const VisualDensity(horizontal: 04, vertical: -2),
                  title: Text(productName,
                    style: const TextStyle(fontSize: 16 * gsf),
                  ),
                  trailing: Text(
                    "${truncateZeros(roundDouble(scaledResultingAmount))} ${unitToString(unit)}",
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16 * gsf),
                  ),
                ),
                getTitledDivider("Contains:"),
                ...ingredients.map((ingredient) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      minVerticalPadding: 0,
                      visualDensity: const VisualDensity(horizontal: 0, vertical: -4),
                      title: Text(
                        productsMap[ingredient.productId]?.name ?? "Unknown product", 
                        style: const TextStyle(fontSize: 16 * gsf),
                      ),
                      trailing: Text(
                        "${truncateZeros(roundDouble(ingredient.amount * scaleFactor))} ${unitToString(ingredient.unit)}",
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16 * gsf),
                      ),
                    )),
              ],
            ),
            
          ],
        );
      }
    ),
    
    options: [
      ("Apply", () => double.tryParse(scaleController.text)),
      ("Cancel", null),
    ],
  );
}

Widget getTitledDivider(String title) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8.0),
    child: Row(
      children: [
        const Expanded(
          child: Divider(
            // indent: 4 * gsf,
            thickness: 1.5 * gsf,
            endIndent: 8 * gsf,
          ),
        ),
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16.0 * gsf,
          ),
          textAlign: TextAlign.center,
        ),
        const Expanded(
          child: Divider(
            // endIndent: 8 * gsf,
            thickness: 1.5 * gsf,
            indent: 8 * gsf,
          ),
        ),
      ],
    ),
  );
}

Future<int?> showImportExportDialog(BuildContext context, bool isExport) async {
  return showOptionDialog(
    context: context,
    title: isExport ? "Export" : "Import",
    contentPadding: 16 * gsf,
    content: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton(
          style: actionButtonStyle,
          onPressed: () {
            Navigator.of(context).pop(0);
          },
          child: Text(isExport ? "Export complete backup" : "Import entire backup"),
        )
      ],
    ),
    options: [
      (null, null),
      ("Cancel", null),
    ],
  );
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
  final bool expand;
  
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
    this.expand = true,
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
          'No products yet',
          style: TextStyle(
            color: Colors.grey,
            fontStyle: FontStyle.italic,
            fontSize: 16.0 * gsf,
          ),
        ),
      );
    }
    
    Widget list = ListView(
      shrinkWrap: true,
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
          if (widget.onLongPress != null) {
            var product = widget.productsMap[id]!;
            widget.onLongPress!(product);
          }
        },
        refDate: widget.refDate,
      ),
    );
    
    if (widget.expand) {
      list = Expanded(
        child: list,
      );
    } else {
      list = Flexible(
        child: list,
      );
    }
    
    return Column(
      mainAxisSize: MainAxisSize.min,
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
        list,
      ],
    );
  }
}