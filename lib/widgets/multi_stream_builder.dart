import 'package:flutter/material.dart';

// ignore: unused_import
import 'dart:developer' as devtools show log;

class MultiStreamBuilder extends StatelessWidget {
  const MultiStreamBuilder({
    required this.streams,
    required this.builder,
    super.key,
  });
  
  final List<Stream<Object?>> streams;
  final Widget Function(BuildContext context, List<AsyncSnapshot>) builder;

  @override
  Widget build(BuildContext context) => _buildStreamBuilder(0, [], context);
  
  // recursive streams
  Widget _buildStreamBuilder(
    int index,
    List<AsyncSnapshot> snapshots,
    BuildContext context,
  ) {
    if (index == streams.length) return builder(context, snapshots);
    return StreamBuilder(
      stream: streams[index],
      builder: (context, snapshot) {
        if (index < snapshots.length) {
          snapshots[index] = snapshot as AsyncSnapshot;
        } else {
          snapshots.add(snapshot as AsyncSnapshot);
        }
        return _buildStreamBuilder(index + 1, snapshots, context);
      },
    );
  }
}