import 'dart:io';

void main() {
  final file = File('lib/core/database/collections.dart');
  var content = file.readAsStringSync();

  final regex = RegExp(r'(@collection\s+class\s+(\w+)\s+\{[\s\S]*?)(^\})', multiLine: true);

  content = content.replaceAllMapped(regex, (match) {
    final className = match.group(2);
    // Ignore objects that are solely embedded links and do not need independent syncing
    if (className == 'JournalLine' || className == 'InvoiceLine' || className == 'BOMIngredient') return match.group(0)!;
    
    // Ignore if already added
    if (match.group(1)!.contains('lastModified')) return match.group(0)!;

    return '${match.group(1)}  @Index()\n  DateTime lastModified = DateTime.now();\n  @Index()\n  bool isSynced = false;\n${match.group(3)}';
  });

  if (!content.contains('class SecurityAudit')) {
    content += '''

@collection
class SecurityAudit {
  Id id = Isar.autoIncrement;
  late DateTime timestamp;
  late String action; // CREATE, UPDATE, DELETE, LOGIN
  late String module; // POS, HR, Accounting
  String? details;
  String? userId;

  @Index()
  DateTime lastModified = DateTime.now();
  @Index()
  bool isSynced = false;
}
''';
  }

  file.writeAsStringSync(content);
  print('Added sync fields and SecurityAudit schema successfully.');
}
