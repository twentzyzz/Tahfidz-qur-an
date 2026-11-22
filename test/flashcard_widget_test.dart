import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tahfidz_quran/app/session.dart';
import 'package:tahfidz_quran/features/tahfidz/flashcard_page.dart';
import 'package:tahfidz_quran/services/flashcard_store.dart';

import 'widget_test.dart' show boot;

void main() {
  testWidgets('flashcards are accessible and Arabic stays hidden until reveal', (t) async {
    await boot(t);
    final store = Session.of(t.element(find.byType(Scaffold).first)).store;

    await t.tap(find.byKey(const ValueKey('navigation-3')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('open-flashcards')));
    await t.pumpAndSettle();

    expect(find.byType(FlashcardPage), findsOneWidget);
    await t.tap(find.byKey(const Key('flashcard-start')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('flashcard-card')), findsOneWidget);
    expect(find.byKey(const Key('flashcard-answer')), findsNothing);

    await t.ensureVisible(find.byKey(const Key('flashcard-reveal')));
    await t.tap(find.byKey(const Key('flashcard-reveal')));
    await t.pumpAndSettle();
    expect(find.byKey(const Key('flashcard-answer')), findsOneWidget);

    await t.ensureVisible(find.byKey(const Key('flashcard-again')));
    await t.tap(find.byKey(const Key('flashcard-again')));
    await t.pumpAndSettle();
    expect(store.flashcardRatings.values.single.again, 1);
    expect(store.map('progress'), isEmpty);
    expect(t.takeException(), isNull);
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('flashcard summary is reachable from detailed stats', (t) async {
    await boot(t);
    await t.tap(find.byKey(const ValueKey('navigation-4')));
    await t.pumpAndSettle();
    await t.ensureVisible(find.byKey(const Key('open-detailed-stats')));
    await t.tap(find.byKey(const Key('open-detailed-stats')));
    await t.pumpAndSettle();
    await t.scrollUntilVisible(
      find.byKey(const Key('open-flashcards-from-stats')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.byKey(const Key('open-flashcards-from-stats')), findsOneWidget);
    await t.tap(find.byKey(const Key('open-flashcards-from-stats')));
    await t.pumpAndSettle();
    expect(find.byType(FlashcardPage), findsOneWidget);
    expect(t.takeException(), isNull);
    await t.pumpWidget(const SizedBox());
  });
}
