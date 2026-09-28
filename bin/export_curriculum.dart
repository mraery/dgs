import 'dart:convert';
import 'dart:io';
import '../lib/data/dgs_units.dart';

void main() {
  final dir = Directory('curriculum');
  if (!dir.existsSync()) dir.createSync(recursive: true);

  for (final unit in dgsUnits) {
    final file = File('curriculum/${unit.id}.json');
    file.writeAsStringSync(jsonEncode(unit.toJson()));
  }
  print('Exported ${dgsUnits.length} DGS units to curriculum/*.json');
}
