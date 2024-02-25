import 'package:flutter/material.dart';
import 'package:food_tracker/services/data/data_objects.dart';

import '../constants/routes.dart';
import '../utility/text_logic.dart';

class ProductList extends StatefulWidget {
  final List<Product> products;
  final String search;
  final ScrollController? scrollController;
  
  const ProductList({
    required this.products,
    required this.search,
    this.scrollController,
    super.key
  });

  @override
  State<ProductList> createState() => _ProductListState();
}

class _ProductListState extends State<ProductList> {
  @override
  Widget build(BuildContext context) {
    var products = widget.products;
    var search = widget.search.split(" ");
    
    products = products.where((product) {
      var name = product.name.toLowerCase();
      return search.every((word) => name.contains(word.toLowerCase()));
    }).toList();
    
    // sort products by id
    products.sort((a, b) => a.id.compareTo(b.id));
    
    var length = products.length;
    return ListView.builder(
      physics: const ClampingScrollPhysics(),
      controller: widget.scrollController,
      itemCount: length,
      itemBuilder: (context, index) {
        var product = products[index];
        bool dark = (length - index) % 2 == 0;
        var color = dark ? const Color.fromARGB(255, 237, 246, 253) : Colors.white;
        
        return ListTile(
          title: RichText(
            text: TextSpan(
              style: DefaultTextStyle.of(context).style.copyWith(
                color: Colors.black,
                fontSize: 16.5,
              ),
              children: highlightOccurrences(product.name, search),
            ),
          ),
          tileColor: color,
          onTap: () {
            Navigator.pushNamed (
              context,
              editProductRoute,
              arguments: product.name,
            );
          }
        );
      }
    );
  }
}