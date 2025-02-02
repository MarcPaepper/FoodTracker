import 'package:flutter/material.dart';

void main() {
  runApp(
    MaterialApp(
      home: const TestView(),
    ),
  );
}

class TestView extends StatelessWidget {
  const TestView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var items = [1, 2, 3, 4, 5];
    
    return Scaffold(
      body:
      DropdownButtonFormField<int>(
        items: items.map<DropdownMenuItem<int>>((int value) {
          return DropdownMenuItem<int>(
            value: value,
            child: Text('Item $value'),
          );
        }).toList(),
        onChanged: (int? newValue) {},
        style: const TextStyle(fontSize: 30),
        selectedItemBuilder: (context) {
          return items.map<Widget>((item) {
            return Text(
              "Item $item",
              style: const TextStyle(fontSize: 30),
            );
          }).toList();
        }
      ),
    );
  }
}
