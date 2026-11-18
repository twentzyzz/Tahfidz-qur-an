import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/session.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../l10n/app_strings.dart';
import '../../services/quran_repository.dart';
import '../../widgets/common.dart';
import '../qari/qari_page.dart';

/// App-specific reading leaves, not canonical Madinah mushaf pagination.
/// The group boundary is based on source-text length; no ayah is altered.
List<List<Verse>> mushafReadingLeaves(
  List<Verse> verses, {
  int maxCharacters = 500,
}) {
  if (verses.isEmpty) return [];
  if (maxCharacters <= 0) throw ArgumentError.value(maxCharacters);
  final result = <List<Verse>>[];
  var leaf = <Verse>[];
  var length = 0;
  for (final verse in verses) {
    final nextLength = verse.arabic.runes.length + 6;
    if (leaf.isNotEmpty && length + nextLength > maxCharacters) {
      result.add(leaf);
      leaf = <Verse>[];
      length = 0;
    }
    leaf.add(verse);
    length += nextLength;
  }
  if (leaf.isNotEmpty) result.add(leaf);
  return result;
}

String _arabicDigits(int number) {
  const digits = '٠١٢٣٤٥٦٧٨٩';
  return number
      .toString()
      .split('')
      .map((digit) => digits[int.parse(digit)])
      .join();
}

/// A page-like, Arabic-first reader for the Al-Qur'an tab only.
/// The 30 Juz and memorization readers retain their vertical ayah list.
class MushafReader extends StatefulWidget {
  const MushafReader({
    super.key,
    required this.verses,
    required this.initialVerse,
  });

  final List<Verse> verses;
  final int initialVerse;

  @override
  State<MushafReader> createState() => _MushafReaderState();
}

class _MushafReaderState extends State<MushafReader> {
  late final List<List<Verse>> leaves;
  late final List<TapGestureRecognizer> verseTaps;
  late final PageController pages;
  late int currentLeaf;
  late Verse selectedVerse;

  @override
  void initState() {
    super.initState();
    leaves = mushafReadingLeaves(widget.verses);
    selectedVerse = widget.verses.firstWhere(
      (v) => v.number == widget.initialVerse,
      orElse: () => widget.verses.first,
    );
    currentLeaf = leaves.indexWhere((leaf) => leaf.contains(selectedVerse));
    pages = PageController(initialPage: currentLeaf);
    verseTaps = [
      for (final verse in widget.verses)
        TapGestureRecognizer()
          ..onTap = () {
            _selectVerse(verse);
            _showVerseDetails(verse);
          },
    ];
  }

  @override
  void dispose() {
    for (final tap in verseTaps) {
      tap.dispose();
    }
    pages.dispose();
    super.dispose();
  }

  void _remember(Verse verse) {
    final store = Session.of(context).store;
    perform(
      context,
      () => store.set('last', {'surah': verse.surah, 'verse': verse.number}),
    );
  }

  void _selectVerse(Verse verse) {
    if (!mounted) return;
    setState(() => selectedVerse = verse);
    _remember(verse);
  }

  void _turnLeaf(int page) {
    if (page < 0 || page >= leaves.length) return;
    pages.animateToPage(
      page,
      duration: const Duration(milliseconds: 230),
      curve: Curves.easeInOut,
    );
  }

  void _showVerseDetails(Verse verse) {
    final session = Session.of(context);
    final chapter = session.quran.chapters[verse.surah - 1];
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(sheetContext).height * .76,
          ),
          child: ListenableBuilder(
            listenable: session.store,
            builder: (sheetContext, _) {
              final progress = session.store.map('progress')[verse.ref];
              final saved =
                  session.store.map('bookmarks').containsKey(verse.ref);
              final colors = Theme.of(sheetContext).colorScheme;
              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 2, 20, 28),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${chapter.name} • ${verse.number}',
                          style: Theme.of(sheetContext).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                      IconButton(
                        tooltip: sheetContext.t(
                          'Tutup detail ayat',
                          'Close verse details',
                        ),
                        onPressed: () => Navigator.pop(sheetContext),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SelectableText(
                    verse.arabic,
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.right,
                    style: AppTypography.arabic.copyWith(
                      fontSize: session.store
                          .get<num>('arabicSize', 32)
                          .toDouble(),
                      color: colors.onSurface,
                      height: 2.0,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    sheetContext.t('Makna ayat', 'Verse meaning'),
                    style: Theme.of(sheetContext).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  SelectableText(
                    verse.translation,
                    style: TextStyle(
                      height: 1.7,
                      fontSize: session.store
                          .get<num>('translationSize', 18)
                          .toDouble(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    sheetContext.t(
                      'Terjemahan Indonesia • EQuran.id',
                      'Indonesian translation • EQuran.id',
                    ),
                    style: Theme.of(sheetContext).textTheme.bodySmall
                        ?.copyWith(color: colors.onSurfaceVariant),
                  ),
                  const SizedBox(height: 18),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => perform(
                          sheetContext,
                          () => session.store.bookmark(verse.ref),
                        ),
                        icon: Icon(
                          saved
                              ? Icons.bookmark_rounded
                              : Icons.bookmark_outline_rounded,
                        ),
                        label: Text(sheetContext.t('Bookmark', 'Bookmark')),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => session.player.play(
                          [verse],
                          session.store.get('qari', '05'),
                          1,
                        ),
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: Text(sheetContext.t('Putar ayat', 'Play verse')),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => perform(sheetContext, () async {
                          await Clipboard.setData(
                            ClipboardData(
                              text: '${verse.arabic}\n\n${verse.translation}\n${chapter.name} ${verse.number} · EQuran.id',
                            ),
                          );
                          if (sheetContext.mounted) {
                            ScaffoldMessenger.of(sheetContext).showSnackBar(
                              SnackBar(
                                content: Text(
                                  sheetContext.t('Ayat disalin', 'Verse copied'),
                                ),
                              ),
                            );
                          }
                        }),
                        icon: const Icon(Icons.copy_rounded),
                        label: Text(sheetContext.t('Salin ayat', 'Copy verse')),
                      ),
                      TextButton(
                        onPressed: () => perform(
                          sheetContext,
                          () => session.store.set('last', {
                            'surah': verse.surah,
                            'verse': verse.number,
                          }),
                        ),
                        child: Text(
                          sheetContext.t('Bacaan terakhir', 'Last read'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    sheetContext.t('Status hafalan', 'Memorization status'),
                    style: Theme.of(sheetContext).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final status in ['learning', 'done', 'none'])
                        OutlinedButton.icon(
                          onPressed: () => perform(
                            sheetContext,
                            () => session.store.mark(verse.ref, status),
                          ),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: progress == status
                                ? colors.primaryContainer
                                : null,
                          ),
                          icon: Icon(
                            status == 'done'
                                ? Icons.check_circle_outline_rounded
                                : status == 'learning'
                                    ? Icons.bookmark_border_rounded
                                    : Icons.restart_alt_rounded,
                            size: 18,
                          ),
                          label: Text(
                            status == 'done'
                                ? sheetContext.t('Sudah hafal', 'Memorized')
                                : status == 'learning'
                                    ? sheetContext.t(
                                        'Sedang dihafal',
                                        'Learning',
                                      )
                                    : sheetContext.t('Reset', 'Reset'),
                          ),
                        ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _leaf(BuildContext context, int page) {
    final session = Session.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final chapter = session.quran.chapters[widget.verses.first.surah - 1];
    final arabicSize =
        session.store.get<num>('arabicSize', 32).toDouble();
    final paper = dark ? const Color(0xFF193328) : const Color(0xFFFFFAEC);
    final ink = dark ? const Color(0xFFE9F2E8) : const Color(0xFF244436);

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: paper,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.gold, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: dark ? .17 : .07),
              blurRadius: 17,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(
                color: AppColors.gold.withValues(alpha: .58),
                width: .7,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: SingleChildScrollView(
              key: ValueKey('mushaf-leaf-scroll-$page'),
              padding: const EdgeInsets.fromLTRB(14, 18, 14, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Text(
                      chapter.name,
                      style: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: ink,
                          ),
                    ),
                  ),
                  Center(
                    child: Text(
                      chapter.arabic,
                      textDirection: TextDirection.rtl,
                      style: AppTypography.arabic.copyWith(
                        fontSize: 24,
                        height: 1.65,
                        color: dark ? AppColors.goldLight : AppColors.darkEmerald,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Divider(
                          color: AppColors.gold.withValues(alpha: .65),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: Icon(
                          Icons.auto_awesome_rounded,
                          size: 16,
                          color: AppColors.gold,
                        ),
                      ),
                      Expanded(
                        child: Divider(
                          color: AppColors.gold.withValues(alpha: .65),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SelectableText.rich(
                    TextSpan(
                      children: [
                        for (final verse in leaves[page])
                          TextSpan(
                            text:
                                '${verse.arabic} ۝${_arabicDigits(verse.number)}  ',
                            recognizer: verseTaps[
                              widget.verses.indexOf(verse)
                            ],
                            style: TextStyle(
                              backgroundColor: selectedVerse == verse
                                  ? AppColors.gold.withValues(alpha: .13)
                                  : null,
                            ),
                          ),
                      ],
                    ),
                    key: ValueKey('mushaf-leaf-$page'),
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.justify,
                    style: AppTypography.arabic.copyWith(
                      color: ink,
                      fontSize: arabicSize,
                      height: 2.05,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    context.t(
                      'Ketuk ayat untuk melihat arti dan penanda.',
                      'Tap a verse to view its meaning and actions.',
                    ),
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(
                          color: dark
                              ? const Color(0xFFB8C9BD)
                              : const Color(0xFF687568),
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = Session.of(context);
    final chapter = session.quran.chapters[widget.verses.first.surah - 1];
    final colors = Theme.of(context).colorScheme;
    return Column(
      key: const Key('mushaf-reader'),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 7, 16, 0),
          child: Row(
            children: [
              Icon(Icons.menu_book_rounded, color: colors.primary, size: 19),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  context.t('Baca Mushaf', 'Mushaf reading'),
                  style: Theme.of(context).textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              IconButton(
                tooltip: context.t('Pilih Qari', 'Choose reciter'),
                icon: const Icon(Icons.headphones_rounded),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => const QariPage(),
                  ),
                ),
              ),
              IconButton(
                tooltip: context.t(
                  'Putar seluruh surah',
                  'Play complete surah',
                ),
                icon: const Icon(Icons.play_circle_outline_rounded),
                onPressed: () => session.player.play(
                  widget.verses,
                  session.store.get('qari', '05'),
                  1,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: PageView.builder(
            key: const Key('mushaf-page-view'),
            controller: pages,
            itemCount: leaves.length,
            onPageChanged: (page) {
              setState(() {
                currentLeaf = page;
                selectedVerse = leaves[page].first;
              });
              _remember(selectedVerse);
            },
            itemBuilder: _leaf,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 2, 12, 2),
          child: Row(
            children: [
              IconButton(
                tooltip: context.t('Lembar sebelumnya', 'Previous leaf'),
                onPressed:
                    currentLeaf == 0 ? null : () => _turnLeaf(currentLeaf - 1),
                icon: const Icon(Icons.chevron_left_rounded),
              ),
              Expanded(
                child: Text(
                  context.t(
                    'Lembar ${currentLeaf + 1} / ${leaves.length}',
                    'Leaf ${currentLeaf + 1} / ${leaves.length}',
                  ),
                  key: const Key('mushaf-leaf-count'),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelLarge
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              IconButton(
                tooltip: context.t('Lembar berikutnya', 'Next leaf'),
                onPressed: currentLeaf >= leaves.length - 1
                    ? null
                    : () => _turnLeaf(currentLeaf + 1),
                icon: const Icon(Icons.chevron_right_rounded),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '${chapter.name} • ${selectedVerse.number}',
                  key: const Key('mushaf-selected-ref'),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              ListenableBuilder(
                listenable: session.store,
                builder: (context, _) => IconButton(
                  tooltip: context.t('Bookmark', 'Bookmark'),
                  onPressed: () => perform(
                    context,
                    () => session.store.bookmark(selectedVerse.ref),
                  ),
                  icon: Icon(
                    session.store.map('bookmarks')
                            .containsKey(selectedVerse.ref)
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_outline_rounded,
                  ),
                ),
              ),
              IconButton(
                tooltip: context.t('Putar ayat', 'Play verse'),
                onPressed: () => session.player.play(
                  [selectedVerse],
                  session.store.get('qari', '05'),
                  1,
                ),
                icon: const Icon(Icons.play_arrow_rounded),
              ),
              IconButton.filledTonal(
                tooltip: context.t('Detail ayat', 'Verse details'),
                onPressed: () => _showVerseDetails(selectedVerse),
                icon: const Icon(Icons.translate_rounded),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
