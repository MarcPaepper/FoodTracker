import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class MultiValueListenableBuilder extends StatelessWidget {
  const MultiValueListenableBuilder ({
    required this.listenables,
    Key? key,
    required this.builder,
    this.child,
  }) : super(key: key);

  final List<ValueListenable> listenables;
  final Widget? child;
  final Widget Function(BuildContext context, List<dynamic> values, Widget? child) builder;

  @override
  Widget build(BuildContext context) => _buildListenableBuilder(0, [], context);
  
  // recursive listenables
  Widget _buildListenableBuilder(
    int index,
    List<dynamic> values,
    BuildContext context,
  ) {
    if (index == listenables.length) return builder(context, values, child);
    return ValueListenableBuilder(
      valueListenable: listenables[index],
      builder: (context, value, childBuilder) {
        values.add(value);
        return _buildListenableBuilder(index + 1, values, context);
      },
    );
  }
}