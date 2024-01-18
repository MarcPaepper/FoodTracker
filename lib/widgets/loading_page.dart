import 'package:flutter/material.dart';

Widget loadingPage() => 
  Align(
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