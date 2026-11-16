import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tahfidz_quran/features/audio/offline_audio_page.dart';

import 'widget_test.dart' show boot;

void main() {
  testWidgets('Offline audio manager is reachable from qari selection',
      (tester) async {
    await boot(tester);
    await tester.tap(find.byTooltip('Pengaturan'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Qari & audio'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('Qari & audio'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('manage-offline-audio')));
    await tester.pumpAndSettle();
    expect(find.byType(OfflineAudioPage), findsOneWidget);
    expect(find.text('Audio murottal offline'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
