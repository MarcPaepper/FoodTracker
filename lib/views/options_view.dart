import 'package:flutter/material.dart';
import 'package:food_tracker/utility/data_logic.dart';

import 'package:flutter/foundation.dart' show kIsWeb;

class OptionsView extends StatefulWidget {
  const OptionsView({super.key});

  @override
  State<OptionsView> createState() => _OptionsViewState();
}

class _OptionsViewState extends State<OptionsView> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        _buildPortButton(true),
        // _buildPortButton(false),
      ]
    );
  }
  
  _buildPortButton(bool isExport) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.teal.shade100.withOpacity(0.6),
          shadowColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: kIsWeb ? 16 : 12),
        ),
        onPressed: () => exportData(),
        child: Row(
          children: [
            Image.asset("assets/${isExport ? "up" : "down"}load.png", width: 24, height: 24),
            const SizedBox(width: 20),
            Text(isExport ? "Export" : "Import"),
          ],
        ),
      ),
    );
  }
}