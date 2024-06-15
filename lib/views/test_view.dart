import 'package:flutter/material.dart';

class TestView extends StatefulWidget {
  const TestView({Key? key}) : super(key: key);

  @override
  State<TestView> createState() => _TestViewState();
}

class _TestViewState extends State<TestView> {
  // List<FocusNode> _focusNodes = [];
  
  @override
  Widget build(BuildContext context) {
    // int number = 10;
    // for (var i = _focusNodes.length; i < number; i++) {
    //   _focusNodes.add(FocusNode());
    // }
    
    // // ListView of TextFields
    // return ListView.builder(
    //   itemCount: number,
    //   itemBuilder: (context, index) {
    //     return TextField(
    //       // focusNode: _focusNodes[index],
    //       decoration: InputDecoration(
    //         labelText: "Field $index",
    //       ),
    //     );
    //   },
    // );
    return Placeholder();
  }
  
  // @override
  // void dispose() {
  //   for (var node in _focusNodes) {
  //     node.dispose();
  //   }
  //   super.dispose();
  // }
}