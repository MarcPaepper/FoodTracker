import 'package:flutter/material.dart';

import '../constants/ui.dart';
import '../utility/data_logic.dart';
import '../utility/theme.dart';
import '../widgets/loading_page.dart';

class ImportExportView extends StatefulWidget {
  const ImportExportView({super.key});

  @override
  State<ImportExportView> createState() => _ImportExportViewState();
}

class _ImportExportViewState extends State<ImportExportView> {
  bool _loading = false;
  
  @override
  Widget build(BuildContext context) {
    return PopScope(
      // onWillPop: () async {
      //   return !_loading; // Prevent popping if loading is true
      // },
      canPop: !_loading,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Import/Export'),
          automaticallyImplyLeading: !_loading, // Disable back button if loading
        ),
        body: _loading
          ? const Column(
              children: [
                SizedBox(height: 180 * gsf),
                LoadingPage(),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8 * gsf),
                _buildPortButton(context, true),
                _buildPortButton(context, false),
              ],
            ),
      ),
    );
  }
  
  Widget _buildPortButton(BuildContext context, bool isExport) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0) * gsf,
      child: ElevatedButton(
        style: lightButtonStyle,
        onPressed: () {
          setState(() {
            _loading = true;
          });
          var future = isExport ? exportData() : importData(context);
          future.then((value) {
            setState(() {
              _loading = false;
              Navigator.pop(context);
            });
          });
        },
        child: Row(
          children: [
            Image.asset("assets/${isExport ? "up" : "down"}load.png", width: 24 * gsf, height: 24 * gsf),
            const SizedBox(width: 20 * gsf),
            Text(isExport ? "Export" : "Import"),
          ],
        ),
      ),
    );
  }
}