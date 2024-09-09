import 'package:flutter/material.dart';
import 'package:food_tracker/utility/data_logic.dart';

import '../services/data/data_service.dart';
import '../utility/theme.dart';

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
        _buildPortButton(context, true),
        _buildPortButton(context, false),
        _buildReloadButton(),
      ]
    );
  }
  
  Widget _buildPortButton(BuildContext context, bool isExport) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
      child: ElevatedButton(
        style: lightButtonStyle,
        onPressed: () => isExport ? exportData() : importData(context),
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
  
  Widget _buildReloadButton() =>
    Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
      child: ElevatedButton(
        style: lightButtonStyle,
        onPressed: () => DataService.current().reload(),
        child: const Row(
          children: [
            Icon(Icons.refresh),
            SizedBox(width: 20),
            Text("Reload Database"),
          ],
        ),
      ),
    );
}