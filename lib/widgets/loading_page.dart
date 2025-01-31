import 'package:flutter/material.dart';

import '../constants/ui.dart';

class LoadingPage extends StatelessWidget {
  const LoadingPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => 
    Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.all(50.0 * gsf),
        child: SizedBox(
          width: 30 * gsf,
          height: 30 * gsf,
          child: CircularProgressIndicator(
            color: Colors.teal.shade500
          ),
        ),
      )
    );
}