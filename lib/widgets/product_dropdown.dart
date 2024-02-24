import 'package:flutter/material.dart';

import '../services/data/data_objects.dart';

import 'dart:developer' as devtools show log;

final fillColor = Colors.grey.withAlpha(35);
const fillColorError = Color.fromARGB(34, 255, 111, 0);

const underlineColorEnabled = Colors.grey;
final underlineColorDisabled = Colors.grey.shade300;
final underlineColorFocused = Colors.teal.shade300;
const underlineColorError = Color.fromARGB(210, 193, 46, 27);

class ProductDropdown extends StatefulWidget {
  final List<Product> products;
  final Product selectedProduct;
  final bool? enabled;
  final void Function(Product?)? onChanged;
  
  Color _fillColor = fillColor;
  Color _underlineColor = underlineColorEnabled;

  ProductDropdown({
    required this.products,
    required this.selectedProduct,
    this.enabled,
    this.onChanged,
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
    bool enabled = widget.enabled ?? true;
    
    
    var decoration = enabled
      ? const InputDecoration(
        contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 14),
      ) 
      : InputDecoration(
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
        // no enabled border
        enabledBorder: UnderlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: BorderSide(
            width: 3.5,
            color: Colors.grey.shade300
          )
        ),
      );
    
    var fillColor = widget._fillColor;
    var underlineColor = enabled
      ? widget._underlineColor
      : underlineColorDisabled;
    
    return Column(
      children: [
        DropdownButtonFormField<Product>(
          value: widget.selectedProduct,
          onChanged: widget.onChanged,
          decoration: decoration,
          items: widget.products
            .map<DropdownMenuItem<Product>>(
              (Product product) => DropdownMenuItem<Product>(
                value: product,
                child: Text(product.name),
              ),
            )
            .toList(),
        ),
        const SizedBox(height: 10),
        // button acting the same as above Dropdown
        InkWell(
          borderRadius: BorderRadius.circular(10.0),
          focusNode: _focusNode,
          onTap: () {
            setState(() {
              FocusScope.of(context).requestFocus(_focusNode);
            });
          },
          child: Container(
            // 10px border radius
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10.0),
              color: fillColor,
            ),
            clipBehavior: Clip.antiAlias,
            child: Container(
              padding: const EdgeInsets.all(10),
              // decoration: border only on bottom (like UnderlineInputBorder)
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    width: 2,
                    color: _focusNode.hasFocus
                      ? underlineColorFocused
                      : underlineColor,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    widget.selectedProduct.name,
                    style: TextStyle(
                      color: enabled ? Colors.black : Colors.grey,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.arrow_drop_down,
                    color: enabled ? Colors.black : Colors.grey,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

