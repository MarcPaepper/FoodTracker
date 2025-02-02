import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../constants/ui.dart';
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
  final Map<int, Product> productsMap;
  final Product? selectedProduct;
  // final int index;
  final void Function()? beforeTap;
  final void Function(Product?) onChanged;
  final FocusNode? focusNode;
  final bool skipTraversal;
  // final DateTime? autofocus;
  final bool autofocusSearch;
  final bool allowNew;
  final DateTime? refDate;
  
  final Color _fillColor = fillColor;
  final Color _underlineColor = underlineColorEnabled;

  ProductDropdown({
    required this.productsMap,
    required this.selectedProduct,
    // required this.index,
    required this.onChanged,
    this.beforeTap,
    this.focusNode,
    this.skipTraversal = !kIsWeb,
    // this.autofocus,
    this.autofocusSearch = false,
    this.allowNew = true,
    this.refDate,
    Key? key,
  }) : super(key: key);
  
  @override
  State<ProductDropdown> createState() => _ProductDropdownState();
}

class _ProductDropdownState extends State<ProductDropdown> {
  FocusNode? _focusNode;
  bool _hasFocus = false;
  
  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
  }
  
  @override
  void dispose() {
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    var textColor = Theme.of(context).textTheme.bodyMedium!.color ?? Colors.black;
    var fillColor = widget._fillColor;
    var underlineColor = widget._underlineColor;
    
    // // autofocus for 400ms
    // if (widget.autofocus != null) devtools.log("delay ${DateTime.now().difference(widget.autofocus !).inMilliseconds}");
    // if (widget.autofocus != null && DateTime.now().difference(widget.autofocus!).inMilliseconds < 900) {
    //   devtools.log('autofocus the product ${widget.selectedProduct?.name ?? 'null'} at ${widget.autofocus}');
    //   setState(() {
    //     FocusScope.of(context).requestFocus(_focusNode);
    //   });
    //   var times = [50, 100, 150, 200, 250, 300, 350, 400, 450, 500, 550, 600];
    //   for (var time in times) {
    //     Future.delayed(Duration(milliseconds: time), () {
    //       if (mounted) {
    //         setState(() {
    //           FocusScope.of(context).requestFocus(_focusNode);
    //         });
    //       }
    //     });
    //   }
    // }
    
    return ExcludeFocusTraversal(
      excluding: widget.skipTraversal,
      child: InkWell(
        borderRadius: BorderRadius.circular(10.0) * gsf,
        focusNode: _focusNode,
        onFocusChange: (hasFocus) {
          setState(() {
            _hasFocus = hasFocus;
          });
        },
        onTap: () {
          widget.beforeTap?.call();
          setState(() {
            FocusScope.of(context).requestFocus(_focusNode);
          });
          showProductDialog(
            context: context,
            productsMap: widget.productsMap,
            selectedProduct: widget.selectedProduct,
            onSelected:  (newProduct) => widget.onChanged(newProduct),
            autofocus: widget.autofocusSearch,
            allowNew: widget.allowNew,
            refDate: widget.refDate,
          );
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10.0) * gsf,
            color: fillColor,
          ),
          clipBehavior: Clip.antiAlias,
          child: Focus(
            skipTraversal: true,
            child: Container(
              padding: const EdgeInsets.fromLTRB(14, 10, 13, 8) * gsf,
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    width: 1.75 * gsf,
                    color: (_hasFocus)
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
                          fontSize: 16 * gsf,
                        ),
                      )
                    : Text(
                        'Choose a product',
                        style: TextStyle(
                          color: textColor,
                          fontStyle: FontStyle.italic,
                          fontSize: 16 * gsf,
                        ),
                      ),
                  const Spacer(),
                  Icon(
                    Icons.arrow_drop_down,
                    size: 20 * gsf,
                    color: textColor.withAlpha(170),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}