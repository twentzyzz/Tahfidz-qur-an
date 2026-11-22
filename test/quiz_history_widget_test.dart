import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tahfidz_quran/app/session.dart';
import 'package:tahfidz_quran/features/tahfidz/quiz_history_page.dart';
import 'package:tahfidz_quran/services/quiz_history_store.dart';

import 'widget_test.dart' show boot;

void main() {
  testWidgets('quiz history is reachable and shows persisted scores', (t) async {
    await boot(t);
    final store = Session.of(t.element(find.byType(Scaffold).first)).store;
    await store.saveQuizAttempt(
      id: 'widget-1',
      surah: 1,
      correct: 4,
      total: 5,
      at: DateTime(2026, 11, 23, 10),
    );

    await t.tap(find.byKey(const ValueKey('navigation-3')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('open-verse-quiz')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('quiz-history-open')));
    await t.pumpAndSettle();

    expect(find.byType(QuizHistoryPage), findsOneWidget);
    expect(find.byKey(const ValueKey('quiz-history-widget-1')), findsOneWidget);
    expect(find.textContaining('Al-Fatihah'), findsWidgets);
    expect(find.textContaining('80%'), findsWidgets);
    expect(t.takeException(), isNull);
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('new users get a helpful empty quiz history state', (t) async {
    await boot(t);
    await t.tap(find.byKey(const ValueKey('navigation-3')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('open-verse-quiz')));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('quiz-history-open')));
    await t.pumpAndSettle();

    expect(find.textContaining('Belum ada hasil kuis'), findsOneWidget);
    expect(t.takeException(), isNull);
    await t.pumpWidget(const SizedBox());
  });
}
