import 'package:flutter/services.dart';

import '../../core/theme/app_typography.dart';
import '../../core/constants/app_colors.dart';

import 'package:flutter/material.dart';

import '../../app/session.dart';
import '../../l10n/app_strings.dart';
import '../../services/quran_repository.dart';
import '../../widgets/common.dart';
import '../../widgets/mini_player.dart';
import '../qari/qari_page.dart';
import '../tahfidz/practice_page.dart';
import '../offline_recitation/offline_recitation_page.dart';
import 'mushaf_reader.dart';

class SurahDetailPage extends StatefulWidget {
  const SurahDetailPage({
    super.key,
    this.number,
    this.juz,
    this.initialVerse = 1,
    this.resumeSurah,
    this.memorize = false,
  });
  final int? number, juz;
  /// Surah number paired with initialVerse when resuming inside a juz.
  final int? resumeSurah;
  final int initialVerse;
  final bool memorize;
  @override
  State<SurahDetailPage> createState() => _SurahDetailPageState();
}

class _SurahDetailPageState extends State<SurahDetailPage> {
  Future<List<Verse>>? future;
  int current = 0, start = 1, end = 1, repeat = 1;
  int _anchor = 0;
  bool hidden = false;
  bool _visibilityCheckQueued = false;
  bool _persistOnNextCheck = false;
  int? _lastSavedIndex;
  GlobalKey _readerCenterKey = GlobalKey();
  final GlobalKey _readerViewportKey = GlobalKey();
  List<GlobalKey> _verseKeys = [];
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    future ??= load();
  }

  Future<List<Verse>> load() async {
    final q = Session.of(context).quran;
    final data = widget.juz != null
        ? await q.juzVerses(widget.juz!)
        : await q.surah(widget.number!);
    if (widget.juz != null && widget.resumeSurah != null) {
      final match = data.indexWhere(
        (verse) =>
            verse.surah == widget.resumeSurah &&
            verse.number == widget.initialVerse,
      );
      current = match >= 0 ? match : 0;
    } else {
      current = (widget.initialVerse - 1).clamp(0, data.length - 1);
    }
    _anchor = current;
    _readerCenterKey = GlobalKey();
    _verseKeys = List.generate(data.length, (_) => GlobalKey());
    _lastSavedIndex = widget.memorize ? current : null;
    end = data.length;
    if (mounted && widget.memorize) {
      await Session.of(context).store.set('lastMemorization', {
        'surah': data[current].surah,
        'verse': data[current].number,
      });
    } else if (mounted) {
      // Opening a reader also establishes the correct mode for Resume,
      // even when the user closes the page without scrolling.
      await Session.of(context).store.rememberReadingPosition(
        surah: data[current].surah,
        verse: data[current].number,
        juz: widget.juz,
      );
    }
    return data;
  }

  void _savePosition(Session s, List<Verse> verses, int index) {
    if (_lastSavedIndex == index || !mounted) return;
    _lastSavedIndex = index;
    final verse = verses[index];
    perform(
      context,
      () => widget.memorize
          ? s.store.set('lastMemorization', {
              'surah': verse.surah,
              'verse': verse.number,
            })
          : s.store.rememberReadingPosition(
              surah: verse.surah,
              verse: verse.number,
              juz: widget.juz,
            ),
    );
  }

  // A sliver list builds only visible ayat. Read the top-most visible item
  // after layout so the bookmark is updated when vertical scrolling stops.
  void _queueVisibleVerseUpdate(
    Session s,
    List<Verse> verses, {
    required bool persist,
  }) {
    _persistOnNextCheck |= persist;
    if (_visibilityCheckQueued) return;
    _visibilityCheckQueued = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _visibilityCheckQueued = false;
      final save = _persistOnNextCheck;
      _persistOnNextCheck = false;
      if (!mounted) return;
      final viewport = _readerViewportKey.currentContext?.findRenderObject();
      if (viewport is! RenderBox || !viewport.hasSize) return;
      final viewportTop = viewport.localToGlobal(Offset.zero).dy;
      int? visible;
      var nearest = double.infinity;
      for (var i = 0; i < _verseKeys.length; i++) {
        final box = _verseKeys[i].currentContext?.findRenderObject();
        if (box is! RenderBox || !box.attached || !box.hasSize) continue;
        final top = box.localToGlobal(Offset.zero).dy - viewportTop;
        final bottom = top + box.size.height;
        if (bottom <= 0 || top >= viewport.size.height) continue;
        final distance = top <= 10 && bottom > 10 ? 0.0 : top.abs();
        if (distance < nearest) {
          nearest = distance;
          visible = i;
        }
      }
      if (visible == null) return;
      if (current != visible) setState(() => current = visible!);
      if (save) _savePosition(s, verses, visible);
    });
  }

  void _jumpToVerse(Session s, List<Verse> verses, int index) {
    if (index < 0 || index >= verses.length) return;
    setState(() {
      current = index;
      _anchor = index;
      _readerCenterKey = GlobalKey();
    });
    _savePosition(s, verses, index);
  }

  Widget _juzToolbar(BuildContext c, Session s, List<Verse> verses) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: Wrap(
        key: const Key('juz-compact-toolbar'),
        spacing: 9,
        runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          OutlinedButton.icon(
            onPressed: () => Navigator.push(
              c,
              MaterialPageRoute<void>(
                builder: (_) => const QariPage(),
              ),
            ),
            icon: const Icon(Icons.headphones_rounded, size: 18),
            label: Text(c.t('Pilih Qari', 'Choose reciter')),
          ),
          DropdownButton<int>(
            value: repeat,
            underline: const SizedBox.shrink(),
            items: [1, 3, 5, 10]
                .map((n) => DropdownMenuItem(
                      value: n,
                      child: Text('$n ×'),
                    ))
                .toList(),
            onChanged: (n) => setState(() => repeat = n!),
          ),
          FilledButton.tonalIcon(
            onPressed: () => s.player.play(
              verses,
              s.store.get('qari', '05'),
              repeat,
            ),
            icon: const Icon(Icons.play_arrow_rounded, size: 19),
            label: Text(c.t('Putar Juz', 'Play juz')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext c) {
    final s = Session.of(c);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.juz != null
              ? 'Juz ${widget.juz}'
              : s.quran.chapters[widget.number! - 1].name,
        ),
      ),
      bottomNavigationBar: const SafeArea(top: false, child: MiniPlayer()),
      body: FutureBuilder<List<Verse>>(
        future: future,
        builder: (c, snapshot) {
          if (snapshot.hasError) {
            return failure(c, () => setState(() => future = load()));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final verses = snapshot.data!;
          // The Al-Qur'an tab reads like a multi-ayah mushaf leaf.
          // Juz and memorization keep the continuous vertical ayah reader.
          if (widget.juz == null && !widget.memorize) {
            return MushafReader(
              verses: verses,
              initialVerse: widget.initialVerse,
            );
          }
          return Column(
            children: [
              if (widget.juz != null)
                _juzToolbar(c, s, verses)
              else
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(c).colorScheme.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: Theme.of(c).colorScheme.outlineVariant,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () => Navigator.push(
                              c,
                              MaterialPageRoute<void>(
                                builder: (_) => const QariPage(),
                              ),
                            ),
                            icon: const Icon(Icons.headphones_rounded),
                            label: Text(c.t('Pilih Qari', 'Choose reciter')),
                          ),
                          DropdownButton<int>(
                            value: repeat,
                            underline: const SizedBox.shrink(),
                            items: [1, 3, 5, 10]
                                .map((n) => DropdownMenuItem(
                                      value: n,
                                      child: Text('$n ×'),
                                    ))
                                .toList(),
                            onChanged: (n) => setState(() => repeat = n!),
                          ),
                          if (widget.memorize)
                            OutlinedButton.icon(
                              onPressed: () => Navigator.push(
                                c,
                                MaterialPageRoute<void>(
                                  builder: (_) => PracticePage(
                                    verses: verses.sublist(start - 1, end),
                                  ),
                                ),
                              ),
                              icon: const Icon(Icons.quiz_outlined),
                              label: Text(c.t('Ujian rentang', 'Test this range')),
                            ),
                          if (widget.memorize)
                            OutlinedButton.icon(
                              onPressed: () => Navigator.push(
                                c,
                                MaterialPageRoute<void>(
                                  builder: (_) => OfflineRecitationPage(
                                    verses: verses.sublist(start - 1, end),
                                  ),
                                ),
                              ),
                              icon: const Icon(Icons.mic_none),
                              label: Text(
                                c.t('Latihan dengan AI Offline', 'Practice with offline AI'),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      FilledButton.icon(
                        onPressed: () => s.player.play(
                          verses.sublist(start - 1, end),
                          s.store.get('qari', '05'),
                          repeat,
                        ),
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: Text(c.t('Putar rentang', 'Play range')),
                      ),
                    ],
                  ),
                ),
              ),
              if (widget.memorize)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          initialValue: start,
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: c.t('Ayat awal', 'Start verse'),
                          ),
                          items: List.generate(
                            verses.length,
                            (i) => DropdownMenuItem(
                              value: i + 1,
                              child: Text('${i + 1}'),
                            ),
                          ),
                          onChanged: (n) => setState(() {
                            start = n!;
                            if (end < start) end = start;
                          }),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          key: ValueKey(end),
                          initialValue: end,
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: c.t('Ayat akhir', 'End verse'),
                          ),
                          items: List.generate(
                            verses.length - start + 1,
                            (i) => DropdownMenuItem(
                              value: i + start,
                              child: Text('${i + start}'),
                            ),
                          ),
                          onChanged: (n) => setState(() => end = n!),
                        ),
                      ),
                      IconButton(
                        tooltip: c.t(
                          'Sembunyikan / tampilkan Arab',
                          'Hide / show Arabic',
                        ),
                        onPressed: () => setState(() => hidden = !hidden),
                        icon: Icon(
                          hidden ? Icons.visibility_off : Icons.visibility,
                        ),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: SizedBox.expand(
                  key: _readerViewportKey,
                  child: NotificationListener<ScrollNotification>(
                    onNotification: (notification) {
                      if (notification.depth != 0) return false;
                      if (notification is ScrollUpdateNotification ||
                          notification is ScrollEndNotification) {
                        _queueVisibleVerseUpdate(
                          s,
                          verses,
                          persist: notification is ScrollEndNotification,
                        );
                      }
                      return false;
                    },
                    child: CustomScrollView(
                      key: ValueKey('vertical-reader-$_anchor'),
                      center: _readerCenterKey,
                      slivers: [
                        SliverList.builder(
                          itemCount: _anchor,
                          itemBuilder: (context, index) {
                            final i = _anchor - index - 1;
                            return _verseTile(context, s, verses[i], i);
                          },
                        ),
                        SliverList.builder(
                          key: _readerCenterKey,
                          itemCount: verses.length - _anchor,
                          itemBuilder: (context, index) {
                            final i = _anchor + index;
                            return _verseTile(context, s, verses[i], i);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Theme.of(c).colorScheme.surface,
                  border: Border(
                    top: BorderSide(
                      color: Theme.of(c).colorScheme.outlineVariant,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton.filledTonal(
                    tooltip: c.t('Ayat sebelumnya', 'Previous verse'),
                    onPressed: current == 0
                        ? null
                        : () => _jumpToVerse(s, verses, current - 1),
                    icon: const Icon(Icons.chevron_left),
                  ),
                    Text(
                      '${current + 1} / ${verses.length}',
                      style: Theme.of(c).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    IconButton.filledTonal(
                    tooltip: c.t('Ayat berikutnya', 'Next verse'),
                    onPressed: current == verses.length - 1
                        ? null
                        : () => _jumpToVerse(s, verses, current + 1),
                    icon: const Icon(Icons.chevron_right),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
  Widget _verseTile(BuildContext c, Session s, Verse v, int i) {
    return KeyedSubtree(
      key: ValueKey('verse-${v.ref}'),
      child: ListenableBuilder(
      listenable: Listenable.merge([s.player, s.store]),
      builder: (c, _) => Container(
        key: _verseKeys[i],
        padding: EdgeInsets.fromLTRB(
          widget.juz != null ? 18 : 20,
          widget.juz != null ? 14 : 20,
          widget.juz != null ? 18 : 20,
          widget.juz != null ? 18 : 32,
        ),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Theme.of(c).colorScheme.outlineVariant,
              width: .75,
            ),
          ),
        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (widget.juz != null && (v.number == 1 || i == 0)) ...[
                              Container(
                                key: ValueKey('juz-chapter-${v.surah}'),
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(c).brightness == Brightness.dark
                                      ? Theme.of(c).colorScheme.primaryContainer
                                          .withValues(alpha: .28)
                                      : const Color(0xFFF8F1E0),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Theme.of(c).brightness == Brightness.dark
                                        ? Theme.of(c).colorScheme.outlineVariant
                                        : AppColors.goldBorder,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      s.quran.chapters[v.surah - 1].name,
                                      style: Theme.of(c).textTheme.titleSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.w800,
                                            color: Theme.of(c).colorScheme.primary,
                                          ),
                                    ),
                                    Text(
                                      s.quran.chapters[v.surah - 1].arabic,
                                      textDirection: TextDirection.rtl,
                                      style: AppTypography.arabic.copyWith(
                                        fontSize: 22,
                                        height: 1.4,
                                        color: Theme.of(c).colorScheme.onSurface,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 18),
                            ],
                            if (widget.juz != null)
                              Row(
                                children: [
                                  SizedBox.square(
                                    dimension: 45,
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        Transform.rotate(
                                          angle: .7853981634,
                                          child: Container(
                                            width: 31,
                                            height: 31,
                                            decoration: BoxDecoration(
                                              color: Theme.of(c).brightness ==
                                                      Brightness.dark
                                                  ? Theme.of(c)
                                                      .colorScheme
                                                      .primaryContainer
                                                      .withValues(alpha: .35)
                                                  : const Color(0xFFFFF7E8),
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(
                                                color: Theme.of(c).brightness ==
                                                        Brightness.dark
                                                    ? AppColors.goldLight
                                                    : AppColors.gold,
                                                width: 1.2,
                                              ),
                                            ),
                                          ),
                                        ),
                                        Text(
                                          '${v.number}',
                                          style: Theme.of(c)
                                              .textTheme
                                              .labelMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.w800,
                                                color: Theme.of(c)
                                                    .colorScheme.onSurface,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 9),
                                  Expanded(
                                    child: Text(
                                      '${s.quran.chapters[v.surah - 1].name} • ${v.number}',
                                      style: Theme.of(c)
                                          .textTheme
                                          .labelMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                            color: Theme.of(c)
                                                .colorScheme.onSurfaceVariant,
                                          ),
                                    ),
                                  ),
                                ],
                              )
                            else
                              Text(
                                '${s.quran.chapters[v.surah - 1].name} • ${v.number}',
                                style: Theme.of(c).textTheme.titleMedium,
                              ),
                            if (s.player.current?.ref == v.ref)
                              Text(
                                c.t('Audio ayat ini', 'Audio for this verse'),
                                style: TextStyle(
                                  color: Theme.of(c).colorScheme.primary,
                                ),
                              ),
                            if (widget.juz == null) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      '${s.quran.chapters[v.surah - 1].count} ${c.t('ayat', 'verses')}',
                                      style: Theme.of(c).textTheme.bodySmall,
                                    ),
                                  ),
                                  Flexible(
                                    child: Text(
                                      s.quran.chapters[v.surah - 1].arabic,
                                      textDirection: TextDirection.rtl,
                                      textAlign: TextAlign.end,
                                      style: AppTypography.arabic.copyWith(
                                        fontSize: 22,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            SizedBox(height: widget.juz != null ? 14 : 22),
                            Container(
                              key: widget.juz != null
                                  ? ValueKey('juz-arabic-${v.ref}')
                                  : null,
                              width: double.infinity,
                              padding: EdgeInsets.symmetric(
                                horizontal: widget.juz != null ? 0 : 22,
                                vertical: widget.juz != null ? 4 : 34,
                              ),
                              decoration: widget.juz != null
                                  ? null
                                  : BoxDecoration(
                                color: Theme.of(c).brightness == Brightness.dark
                                    ? Theme.of(c).colorScheme.surface
                                    : const Color(0xFFFFF9EC),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: Theme.of(c).brightness == Brightness.dark
                                      ? Theme.of(c).colorScheme.outlineVariant
                                      : const Color(0xFFD1B77C),
                                  width: 1.3,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFBFA878).withValues(alpha: .10),
                                    blurRadius: 14,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: !hidden
                                  ? SelectableText(
                                      v.arabic,
                                      textDirection: TextDirection.rtl,
                                      textAlign: TextAlign.right,
                                      style: AppTypography.arabic.copyWith(
                                        color: Theme.of(c).colorScheme.onSurface,
                                        fontSize: s.store
                                            .get<num>('arabicSize', 32)
                                            .toDouble(),
                                        height: widget.juz != null ? 2.15 : 2.35,
                                      ),
                                    )
                                  : Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 35,
                                      ),
                                      child: Text(
                                        c.t(
                                          'Teks Arab disembunyikan',
                                          'Arabic text hidden',
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                            ),
                            SizedBox(height: widget.juz != null ? 18 : 26),
                            if (widget.juz != null)
                              Row(
                                children: [
                                  Container(
                                    height: 2,
                                    width: 24,
                                    decoration: BoxDecoration(
                                      color: AppColors.gold,
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Divider(
                                      height: 1,
                                      thickness: .7,
                                      color: Theme.of(c).colorScheme.outlineVariant,
                                    ),
                                  ),
                                ],
                              )
                            else
                              Row(
                                children: [
                                  Icon(Icons.translate_rounded,
                                    color: Theme.of(c).colorScheme.primary,
                                    size: 18),
                                  const SizedBox(width: 8),
                                  Text(
                                    c.t('Makna ayat', 'Verse meaning'),
                                    style: Theme.of(c).textTheme.titleSmall
                                        ?.copyWith(fontWeight: FontWeight.w800),
                                  ),
                                ],
                              ),
                            const SizedBox(height: 12),
                            SelectableText(
                              v.translation,
                              style: TextStyle(
                                fontSize: s.store
                                    .get<num>('translationSize', 18)
                                    .toDouble(),
                                height: 1.8,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              c.t(
                                'Terjemahan Indonesia • EQuran.id',
                                'Indonesian translation • EQuran.id',
                              ),
                              style: widget.juz != null
                                  ? Theme.of(c).textTheme.labelSmall?.copyWith(
                                      color: Theme.of(c)
                                          .colorScheme.onSurfaceVariant,
                                      fontSize: 11,
                                    )
                                  : null,
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                IconButton(
                                  tooltip: c.t('Salin ayat', 'Copy verse'),
                                  icon: const Icon(Icons.copy_outlined),
                                  onPressed: () => perform(c, () async {
                                    await Clipboard.setData(
                                      ClipboardData(
                                        text:
                                            '${v.arabic}\n\n${v.translation}\n${s.quran.chapters[v.surah - 1].name} ${v.number} · EQuran.id',
                                      ),
                                    );
                                    if (c.mounted) {
                                      ScaffoldMessenger.of(c).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            c.t('Ayat disalin', 'Verse copied'),
                                          ),
                                        ),
                                      );
                                    }
                                  }),
                                ),
                                IconButton(
                                  tooltip: c.t('Bookmark', 'Bookmark'),
                                  onPressed: () =>
                                      perform(c, () => s.store.bookmark(v.ref)),
                                  icon: Icon(
                                    s.store.map('bookmarks').containsKey(v.ref)
                                        ? Icons.bookmark
                                        : Icons.bookmark_outline,
                                  ),
                                ),
                                IconButton(
                                  tooltip: c.t('Putar ayat', 'Play verse'),
                                  onPressed: () => s.player.play(
                                    [v],
                                    s.store.get('qari', '05'),
                                    repeat,
                                  ),
                                  icon: const Icon(Icons.play_circle),
                                ),
                                TextButton(
                                  onPressed: () => perform(
                                    c,
                                    () => s.store.rememberReadingPosition(
                                      surah: v.surah,
                                      verse: v.number,
                                      juz: widget.juz,
                                    ),
                                  ),
                                  child: Text(
                                    c.t('Bacaan terakhir', 'Last read'),
                                  ),
                                ),
                              ],
                            ),
                            if (widget.juz != null) ...[
                              const SizedBox(height: 8),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: PopupMenuButton<String>(
                                  key: ValueKey('juz-mark-${v.ref}'),
                                  tooltip: c.t(
                                    'Status hafalan',
                                    'Memorization status',
                                  ),
                                  onSelected: (value) => perform(
                                    c,
                                    () => s.store.mark(v.ref, value),
                                  ),
                                  itemBuilder: (context) => [
                                    PopupMenuItem(
                                      value: 'learning',
                                      child: Text(c.t('Sedang dihafal', 'Learning')),
                                    ),
                                    PopupMenuItem(
                                      value: 'done',
                                      child: Text(c.t('Sudah hafal', 'Memorized')),
                                    ),
                                    PopupMenuItem(
                                      value: 'none',
                                      child: Text(c.t('Reset', 'Reset')),
                                    ),
                                  ],
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 10,
                                      horizontal: 6,
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          s.store.map('progress')[v.ref] == 'done'
                                              ? Icons.check_circle_rounded
                                              : s.store.map('progress')[v.ref] ==
                                                      'learning'
                                                  ? Icons.bookmark_added_outlined
                                                  : Icons.flag_outlined,
                                          size: 18,
                                          color: Theme.of(c).colorScheme.primary,
                                        ),
                                        const SizedBox(width: 7),
                                        Text(
                                          s.store.map('progress')[v.ref] == 'done'
                                              ? c.t('Sudah hafal', 'Memorized')
                                              : s.store.map('progress')[v.ref] ==
                                                      'learning'
                                                  ? c.t('Sedang dihafal', 'Learning')
                                                  : c.t('Tandai hafalan', 'Mark memorization'),
                                          style: Theme.of(c).textTheme.labelMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.w700,
                                                color: Theme.of(c)
                                                    .colorScheme.onSurfaceVariant,
                                              ),
                                        ),
                                        const SizedBox(width: 4),
                                        const Icon(Icons.expand_more_rounded, size: 17),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ] else ...[
                            const SizedBox(height: 16),
                            Text(
                              c.t('Status hafalan', 'Memorization status'),
                              style: Theme.of(c).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 10),
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final compact = constraints.maxWidth < 350 ||
                                    MediaQuery.textScalerOf(context).scale(16) > 22;
                                final buttonWidth = compact
                                    ? (constraints.maxWidth - 8) / 2
                                    : (constraints.maxWidth - 16) / 3;
                                return Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    for (final status in ['learning', 'done', 'none'])
                                      SizedBox(
                                        width: buttonWidth,
                                        child: Builder(
                                        builder: (context) {
                                          final colors = Theme.of(context).colorScheme;
                                          final selected =
                                              s.store.map('progress')[v.ref] == status;
                                          final label = status == 'done'
                                              ? c.t('Sudah hafal', 'Memorized')
                                              : status == 'learning'
                                                  ? c.t('Sedang dihafal', 'Learning')
                                                  : c.t('Reset', 'Reset');
                                          return Material(
                                            color: selected
                                                ? colors.primaryContainer
                                                : colors.surface,
                                            borderRadius: BorderRadius.circular(14),
                                            child: InkWell(
                                              onTap: () => perform(
                                                c,
                                                () => s.store.mark(v.ref, status),
                                              ),
                                              borderRadius: BorderRadius.circular(14),
                                              child: Container(
                                                constraints: const BoxConstraints(minHeight: 66),
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 12,
                                                ),
                                                decoration: BoxDecoration(
                                                  borderRadius: BorderRadius.circular(14),
                                                  border: Border.all(
                                                    color: selected
                                                        ? colors.primary
                                                        : colors.outlineVariant,
                                                  ),
                                                ),
                                                child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Icon(
                                                      status == 'done'
                                                          ? Icons.check_circle_outline
                                                          : status == 'learning'
                                                              ? Icons.bookmark_border_rounded
                                                              : Icons.restart_alt_rounded,
                                                      color: selected
                                                          ? colors.primary
                                                          : colors.onSurfaceVariant,
                                                      size: 20,
                                                    ),
                                                    const SizedBox(height: 6),
                                                    Text(
                                                      label,
                                                      textAlign: TextAlign.center,
                                                      softWrap: true,
                                                      style: Theme.of(c)
                                                          .textTheme
                                                          .labelSmall
                                                          ?.copyWith(
                                                            color: selected
                                                                ? colors.primary
                                                                : colors.onSurface,
                                                            fontWeight: selected
                                                                ? FontWeight.w800
                                                                : FontWeight.w600,
                                                          ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                        ),
                                      ),
                                  ],
                                );
                              },
                            ),
                            ],
                          ],

        ),
      ),
      ),
    );
  }

}
