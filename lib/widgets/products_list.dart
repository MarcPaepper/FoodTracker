import 'package:flutter/material.dart';
import 'package:food_tracker/services/data/data_objects.dart';

import '../utility/text_logic.dart';

import 'dart:developer' as devtools show log;

List<Widget> getProductTiles({
  required BuildContext context,
  required List<Product> products,
  required String search,
  required Function(String, int) onSelected,
  Function(String, int)? onLongPress,
  bool colorFromTop = false,
}) {
  var searchWords = search.split(" ");
  
  products = products.where((product) {
    var name = product.name.toLowerCase();
    return searchWords.every((word) => name.contains(word.toLowerCase()));
  }).toList();
  
  // sort products by id
  products.sort((a, b) => a.id.compareTo(b.id));
  
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
  
  const ProductTile({
    required this.product,
    required this.searchWords,
    required this.color,
    required this.onSelected,
    this.onLongPress,
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
          title: RichText(
            text: TextSpan(
              style: DefaultTextStyle.of(context).style.copyWith(
                color: Colors.black,
                fontSize: 16.5,
              ),
              children: highlightOccurrences(widget.product.name, widget.searchWords),
            ),
          ),
        ),
      ),
    );
  }
}