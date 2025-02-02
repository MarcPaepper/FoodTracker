import 'package:flutter/material.dart';

import '../constants/routes.dart';
import '../constants/ui.dart';
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
        const SizedBox(height: 8 * gsf),
        _buildPortButton(),
        _buildReloadButton(),
      ]
    );
  }
  
  Widget _buildPortButton() =>
    Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0) * gsf,
      child: ElevatedButton(
        style: lightButtonStyle,
        onPressed: () => Navigator.pushNamed(context, importExportRoute),
        child: const Row(
          children: [
            SizedBox(width: 3),
            Icon(Icons.import_export, size: 24 * gsf),
            SizedBox(width: 17),
            Text("Import/Export", style: TextStyle(fontSize: 16 * gsf)),
          ],
        ),
      ),
    );
  
  Widget _buildReloadButton() =>
    Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0) * gsf,
      child: ElevatedButton(
        style: lightButtonStyle,
        onPressed: () => DataService.current().reload(),
        child: const Row(
          children: [
            Icon(Icons.refresh, size: 24 * gsf),
            SizedBox(width: 20),
            Text("Reload Database", style: TextStyle(fontSize: 16 * gsf)),
          ],
        ),
      ),
    );
}