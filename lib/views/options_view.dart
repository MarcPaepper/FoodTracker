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
            Icon(Icons.import_export),
            SizedBox(width: 20 * gsf),
            Text("Import/Export"),
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
            Icon(Icons.refresh),
            SizedBox(width: 20 * gsf),
            Text("Reload Database"),
          ],
        ),
      ),
    );
}