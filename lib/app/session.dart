import 'package:flutter/widgets.dart';

import '../services/app_store.dart';
import '../services/quran_repository.dart';
import '../services/player_controller.dart';
import '../services/prayer_service.dart';

class Session extends InheritedWidget {
  const Session({
    super.key,
    required this.store,
    required this.quran,
    required this.player,
    required this.prayer,
    required super.child,
  });
  final AppStore store;
  final QuranRepository quran;
  final PlayerController player;
  final PrayerService prayer;
  static Session of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<Session>()!;
  @override
  bool updateShouldNotify(Session old) => true;
}
