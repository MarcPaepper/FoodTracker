import 'package:flutter/material.dart';
import 'package:food_tracker/data_manager.dart';
import "dart:developer" as devtools show log;

class AddMealView extends StatefulWidget {
  const AddMealView({super.key});

  @override
  State<AddMealView> createState() => _AddMealViewState();
}

List<DropdownMenuEntry<Product>> get dropdownItems{
  List<DropdownMenuEntry<Product>> menuItems = [];
  for (final Product prod in getProducts()) {
    menuItems.add(DropdownMenuEntry(
      value: prod,
      label: prod.name
    ));
  }
  return menuItems;
}

class _AddMealViewState extends State<AddMealView> {
  @override
  Widget build(BuildContext context) {
    devtools.log("test");
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add meal"),
      ),
      body: Column(
        children: [
          DropdownMenu<Product>(
            enableSearch: true,
            hintText: "Product Name",
            onSelected: (value) {
              devtools.log("selected $value");
            },
            dropdownMenuEntries: dropdownItems,
          ),
          TextButton(
            onPressed: () async {
              devtools.log("User chose ${await showExampleDialog(context)}");
            },
            child: const Text("Dialog")
          )
        ],
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