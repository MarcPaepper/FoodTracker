import 'package:flutter/material.dart';

// modelled after following dialog


//void showEditMealDialog(
//  BuildContext context,
//  DataService dataService,
//  Meal meal,
//  Map<int, Product> productsMap,
//) {
//  showDialog(
//    context: context,
//    builder: (context) => Dialog(
//      insetPadding: const EdgeInsets.all(28),
//      child: Column(
//        mainAxisSize: MainAxisSize.min,
//        crossAxisAlignment: CrossAxisAlignment.stretch,
//        children: [
//          Padding(
//            padding: const EdgeInsets.all(12),
//            child: Text('Edit Meal', style: const TextStyle(fontSize: 18)),
//          ),
//          ListTile(
//            title: const Text('Edit the meal'),
//          ),
//          Row(
//            mainAxisAlignment: MainAxisAlignment.spaceBetween,
//            children: [
//              // Save button
//              Expanded(
//                child: Padding(
//                  padding: const EdgeInsets.all(12),
//                  child: ElevatedButton(
//                    style: actionButtonStyle,
//                    onPressed: () {
                      
//                    },
//                    child: const Text('Save'),
//                  ),
//                ),
//              ),
//              // Cancel button
//              Expanded(
//                child: Padding(
//                  padding: const EdgeInsets.all(12),
//                  child: ElevatedButton(
//                    style: actionButtonStyle,
//                    onPressed: () {
//                      Navigator.of(context).pop();
//                    },
//                    child: const Text('Cancel'),
//                  ),
//                ),
//              ),
//            ],
//          ),
//        ],
//      ),
//    ),
//  );
//}