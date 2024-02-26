import 'package:flutter/material.dart';
import 'package:food_tracker/services/data/data_objects.dart';

import '../constants/routes.dart';
import '../utility/text_logic.dart';

List<Widget> getProductTiles(BuildContext context, List<Product> products, String search) {
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
    bool dark = (length - index) % 2 == 0;
    var color = dark ? const Color.fromARGB(255, 237, 246, 253) : Colors.white;
    
    return ListTile(
      title: RichText(
        text: TextSpan(
          style: DefaultTextStyle.of(context).style.copyWith(
            color: Colors.black,
            fontSize: 16.5,
          ),
          children: highlightOccurrences(product.name, searchWords),
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
  });
}