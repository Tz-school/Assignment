import 'dart:io';
import 'package:path_provider/path_provider.dart';

Future<String> downloadPlannerBackup(String text) async {
  final directory = await getApplicationDocumentsDirectory();
  final file = File(
    '${directory.path}/career_planner_backup_${DateTime.now().microsecondsSinceEpoch}.txt',
  );
  await file.writeAsString(text, flush: true);
  return 'Backup saved in the app documents folder: ${file.path}';
}
