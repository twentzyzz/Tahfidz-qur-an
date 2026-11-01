import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

class AppStrings {
  const AppStrings(this.locale);
  final Locale locale;
  String text(String id, String en) => locale.languageCode == 'en' ? en : id;
  static const delegate = _Delegate();
  static AppStrings of(BuildContext context) =>
      Localizations.of<AppStrings>(context, AppStrings)!;
}

class _Delegate extends LocalizationsDelegate<AppStrings> {
  const _Delegate();
  @override
  bool isSupported(Locale locale) => ['id', 'en'].contains(locale.languageCode);
  @override
  Future<AppStrings> load(Locale locale) =>
      SynchronousFuture(AppStrings(locale));
  @override
  bool shouldReload(_Delegate old) => false;
}

extension Translation on BuildContext {
  String t(String id, String en) => AppStrings.of(this).text(id, en);
}
