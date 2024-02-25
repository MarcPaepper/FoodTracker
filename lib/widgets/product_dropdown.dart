import 'package:flutter/material.dart';

import '../services/data/data_objects.dart';
import '../utility/modals.dart';

// import 'dart:developer' as devtools show log;

final fillColor = Colors.grey.shade400.withAlpha(60);
const fillColorError = Color.fromARGB(34, 255, 111, 0);

const underlineColorEnabled = Colors.grey;
final underlineColorDisabled = Colors.grey.shade300;
final underlineColorFocused = Colors.teal.shade300;
const underlineColorError = Color.fromARGB(210, 193, 46, 27);

class ProductDropdown extends StatefulWidget {
  final List<Product> products;
  final Product? selectedProduct;
  final List<ProductQuantity> ingredients;
  final int index;
  final ValueNotifier<List<ProductQuantity>> ingredientsNotifier;
  final void Function(Product?) onChanged;
  
  final Color _fillColor = fillColor;
  final Color _underlineColor = underlineColorEnabled;

  ProductDropdown({
    required this.products,
    required this.selectedProduct,
    required this.ingredients,
    required this.index,
    required this.ingredientsNotifier,
    required this.onChanged,
    Key? key,
  }) : super(key: key);
  
  @override
  State<ProductDropdown> createState() => _ProductDropdownState();
}

class _ProductDropdownState extends State<ProductDropdown> {
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
    var textColor = Theme.of(context).textTheme.bodyMedium!.color ?? Colors.black;
    var fillColor = widget._fillColor;
    var underlineColor = widget._underlineColor;
    
    return InkWell(
      borderRadius: BorderRadius.circular(10.0),
      focusNode: _focusNode,
      onTap: () {
        setState(() {
          FocusScope.of(context).requestFocus(_focusNode);
        });
        // show dialog to choose product
        showProductDialog(context, widget.products, widget.selectedProduct, (newProduct) => widget.onChanged(newProduct));
      },
      child: Container(
        // 10px border radius
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10.0),
          color: fillColor,
        ),
        clipBehavior: Clip.antiAlias,
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 13, 10),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                width: 1.75,
                color: _focusNode.hasFocus
                  ? underlineColorFocused
                  : underlineColor,
              ),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              widget.selectedProduct != null
                ? Text(
                    widget.selectedProduct!.name,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 16,
                    ),
                  )
                : Text(
                    'Choose a product',
                    style: TextStyle(
                      color: textColor,
                      fontStyle: FontStyle.italic,
                      fontSize: 16,
                    ),
                  ),
              const Spacer(),
              Icon(
                Icons.arrow_drop_down,
                color: textColor.withAlpha(170),
              ),
            ],
          ),
        ),
      ),
    );
  }
}