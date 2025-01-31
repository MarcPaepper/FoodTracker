import 'package:flutter/material.dart';

class TestView extends StatelessWidget {
  const TestView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    List<DropdownMenuItem<int>> debugItems = [
      DropdownMenuItem(
        value: 1,
        child: Text("Option 1"),
      ),
      DropdownMenuItem(
        value: 2,
        child: Text("Option 2"),
      ),
    ];
    
    return Scaffold(
      body: SizedBox(
        height: 200,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: DropdownButton<int> ( // rendered correctly
                isExpanded: true,
                value: 1,
                items: debugItems,
                onChanged: (int? value) {},
              ),
            ),
            Expanded(
              child: DropdownButtonFormField<int>( // looks weird
                isExpanded: true,
                value: 1,
                items: debugItems,
                onChanged: (int? value) {},
              ),
            ),
          ],
        ),
      ),
    );
  }
}