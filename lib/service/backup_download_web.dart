import 'dart:async';
import 'dart:js_interop';
import 'package:web/web.dart' as web;

Future<String> downloadPlannerBackup(String text) async {
  final filename =
      'career_planner_backup_${DateTime.now().millisecondsSinceEpoch}.txt';
  final blob = web.Blob(
    [text.toJS].toJS,
    web.BlobPropertyBag(type: 'text/plain;charset=utf-8'),
  );
  final url = web.URL.createObjectURL(blob);
  final link = web.HTMLAnchorElement()
    ..href = url
    ..download = filename;
  web.document.body!.appendChild(link);
  try {
    link.click();
  } finally {
    link.remove();
    Timer(const Duration(seconds: 30), () => web.URL.revokeObjectURL(url));
  }
  return 'Download requested: $filename. Check your browser downloads.';
}
