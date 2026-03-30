import 'dart:io';

void main() async {
  final file = File('lib/screens/business_edit_page.dart');
  var text = await file.readAsString();

  // The extra parenthesis is exactly here:
  text = text.replaceFirst(RegExp(r'\]\s*,\s*\)\s*,\s*\)\s*,\s*if \(_isLoading\)'), '],\n          ),\n          if (_isLoading)');

  // Also verify that the Scaffold closing `);` is there
  if (!text.contains(RegExp(r'\n\s*\]\s*,\s*\)\s*,\s*\)\s*;\s*\}'))) {
     text = text.replaceFirst(RegExp(r'\n\s*\]\s*,\s*\)\s*,\s*\}\s*Widget _buildPremiumHeader'), 
       '\n        ],\n      ),\n    );\n  }\n\n  Widget _buildPremiumHeader');
  }

  await file.writeAsString(text);
}
