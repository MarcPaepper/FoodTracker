import 'package:flutter/material.dart';
import "dart:developer" as devtools show log;

import '../services/data/data_objects.dart';

class AddMealView extends StatefulWidget {
  const AddMealView({super.key});

  @override
  State<AddMealView> createState() => _AddMealViewState();
}

Future<List<DropdownMenuEntry<Product>>> get dropdownItems async {
  List<DropdownMenuEntry<Product>> menuItems = [];
  // List<Product> products = await DataService.current().products;
  // for (final Product prod in products) {
  //   menuItems.add(DropdownMenuEntry(
  //     value: prod,
  //     label: prod.name
  //   ));
  // }
  return menuItems;
}

class _AddMealViewState extends State<AddMealView> {
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add meal"),
      ),
      body: FutureBuilder(
        future: null,
        builder: (context, snapshot) {
          switch (snapshot.connectionState) {
            
            case ConnectionState.done:
              return Padding(
                padding: const EdgeInsets.all(7.0),
                child: Column(
                  children: [
                    // DropdownMenu<Product>(
                    //   enableSearch: true,
                    //   hintText: "Product Name",
                    //   onSelected: (value) {
                    //     // devtools.log("selected $value");
                    //   },
                    //   // dropdownMenuEntries: await dropdownItems,
                    // ),
                    TextButton(
                      onPressed: () async {
                        devtools.log("User chose ${await showExampleDialog(context)}");
                      },
                      child: const Text("Dialog")
                    )
                  ],
                ),
              );
            case ConnectionState.none:
            case ConnectionState.waiting:
            case ConnectionState.active:
              return Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.all(50.0),
                  child: SizedBox(
                    width: 30,
                    height: 30,
                    child: CircularProgressIndicator(
                      color: Colors.teal.shade500
                    ),
                  ),
                )
              );
          }
        }
      )
    );
  }
}



Future<bool> showExampleDialog(BuildContext context) {
  return showDialog<bool> (
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text("Confirmation"),
        content: const Text("Are you sure?"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(true);
            },
            child: const Text("Yes")
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(false);
            },
            child: const Text("No")
          )
        ]
      );
    }
  ).then((value) => value ?? false);
}