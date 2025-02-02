// ignore_for_file: curly_braces_in_flow_control_structures

import 'package:flutter/material.dart';
import 'package:food_tracker/services/data/data_objects.dart';
import 'package:food_tracker/utility/modals.dart';
import 'package:food_tracker/widgets/sort_field.dart';

import '../constants/ui.dart';
import '../utility/data_logic.dart';
import '../utility/text_logic.dart';

//  import 'dart:developer' as devtools show log;

List<Widget> getProductTiles({
  required BuildContext context,
  required List<Product> products,
  required String search,
           (SortType sortType, SortOrder sortOrder)? sorting,
           Map<int, double>? relevancies,
  required Function(String, int) onSelected,
           Function(String, int)? onLongPress,
           DateTime? refDate,
  bool colorFromTop = false,
}) {
  var searchWords = search.split(" ");
  products = products.where((product) {
    var name = product.name.toLowerCase();
    return searchWords.every((word) => name.contains(word.toLowerCase()));
  }).toList();
  
  // sorting
  if (sorting != null) {
    try {
      switch (sorting.$1) {
        case SortType.alphabetical:
          products.sort((a, b) => a.name.compareTo(b.name));
          break;
        case SortType.relevancy:
          if (relevancies != null) {
            products.sort((a, b) {
              var relevancyA = relevancies[a.id] ?? 0;
              var relevancyB = relevancies[b.id] ?? 0;
              return relevancyA.compareTo(relevancyB);
            });
            //for (int i = 0; i < products.length && i < 20; i++) {
            //  var product = products[i];
            //  String name = product.name.padRight(30).substring(0, 30);
            //  devtools.log("!!! $name: ${relevancies[product.id]?.toStringAsFixed(2)}");
            //}
            break;
          }
        case SortType.creationDate:
          products.sort((a, b) => a.creationDate!.compareTo(b.creationDate!));
          break;
        case SortType.lastEditDate:
          products.sort((a, b) => a.lastEditDate!.compareTo(b.lastEditDate!));
          break;
      }
      if (sorting.$2 == SortOrder.descending) {
        products = products.reversed.toList();
      }
    } catch (e) {
      showErrorbar(context, "Error sorting products: $e");
    }
  }
  
  var length = products.length;
  return List.generate(length, (index) {
    var product = products[index];
    bool dark = (colorFromTop ? index : (length - index)) % 2 == 0;
    var color = dark ? const Color.fromARGB(255, 237, 246, 253) : Colors.white;
    
    return ProductTile(
      product: product,
      searchWords: searchWords,
      color: color,
      onSelected: onSelected,
      onLongPress: onLongPress,
      refDate: refDate,
      key: ValueKey(product.id),
    );
  });
}

class ProductTile extends StatefulWidget {
  final Product product;
  final List<String> searchWords;
  final Color color;
  final Function(String, int) onSelected;
  final Function(String, int)? onLongPress;
  final DateTime? refDate;
  
  const ProductTile({
    required this.product,
    required this.searchWords,
    required this.color,
    required this.onSelected,
             this.onLongPress,
             this.refDate,
    super.key,
  });

  @override
  State<ProductTile> createState() => _ProductTileState();
}

class _ProductTileState extends State<ProductTile> {
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    var refDate = widget.refDate;
    bool isValid = true;
    bool isTemp = widget.product.isTemporary;
    Widget temporaryIndicator = Container();
    
    if (refDate != null && isTemp) {
      isValid = isDateInsideInterval(refDate, widget.product.temporaryBeginning!, widget.product.temporaryEnd!) == 0;
      temporaryIndicator = Tooltip(
        message: "Temporary product. Date is ${isValid ? "inside" : "outside"} the range.",
        triggerMode: TooltipTriggerMode.longPress,
        textStyle: const TextStyle(
          fontSize: 14 * gsf,
          color: Colors.white,
        ),
        child: Icon(
          isValid ? Icons.event_available : Icons.event_busy,
          color: (isValid ? Colors.blue : Colors.orange).withOpacity(.7),
          size: 20 * gsf,
        ),
      );
    }
    
    List<TextSpan> children = highlightOccurrences(widget.product.name, widget.searchWords);
    List<TextSpan> childrenColored = children.map((child) {
      var style = child.style ?? const TextStyle();
      
      return TextSpan(
        text: child.text,
        style: style.copyWith(
          color: isValid ? style.color : Colors.black.withOpacity(.65)
        ),
      );
    }).toList();
    
    return Material(
      color: widget.color,
      child: InkWell(
        focusNode: _focusNode,
         onTap: () {
           setState(() {
             FocusScope.of(context).requestFocus(_focusNode);
           });
           widget.onSelected(widget.product.name, widget.product.id);
         },
         onLongPress: () {
           setState(() {
             FocusScope.of(context).requestFocus(_focusNode);
           });
           if (widget.onLongPress != null) {
             widget.onLongPress!(widget.product.name, widget.product.id);
           }
         },
        child: ListTile(
          dense: true,
          contentPadding: const EdgeInsets.fromLTRB(16 * gsf, 5 * gsf - 5, 9 * gsf, 5 * gsf - 5),
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: DefaultTextStyle.of(context).style.copyWith(
                      color: Colors.black,
                      fontSize: 16.5 * gsf,
                    ),
                    children: childrenColored,
                  ),
                ),
              ),
              temporaryIndicator,
            ],
          ),
        ),
      ),
    );
  }
}