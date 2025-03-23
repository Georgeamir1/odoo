import 'package:lingo_hunter/lingo_hunter.dart';

void main() async {
  await LingoHunter.extractAndCreateTranslationFiles(
    baseLang: 'en',
    langs: ['ar', 'fr', 'es'],
  );
  print("✅ تم إنشاء ملفات الترجمة بنجاح في جذر المشروع.");
}
