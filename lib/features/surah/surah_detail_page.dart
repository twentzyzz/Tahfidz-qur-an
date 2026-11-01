import 'package:flutter/material.dart';

import '../../app/session.dart';
import '../../l10n/app_strings.dart';
import '../../services/quran_repository.dart';
import '../../services/player_controller.dart';
import '../../widgets/common.dart';
import '../../widgets/mini_player.dart';

class SurahDetailPage extends StatefulWidget {
  const SurahDetailPage({
    super.key,
    this.number,
    this.juz,
    this.initialVerse = 1,
    this.memorize = false,
  });
  final int? number, juz;
  final int initialVerse;
  final bool memorize;
  @override
  State<SurahDetailPage> createState() => _SurahDetailPageState();
}

class _SurahDetailPageState extends State<SurahDetailPage> {
  Future<List<Verse>>? future;
  PageController? pages;
  int current = 0, start = 1, end = 1, repeat = 1;
  bool hidden = false;
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
    current = (widget.initialVerse - 1).clamp(0, data.length - 1);
    end = data.length;
    pages?.dispose();
    pages = PageController(initialPage: current);
    return data;
  }

  @override
  void dispose() {
    pages?.dispose();
    super.dispose();
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
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Wrap(
                  spacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    DropdownButton<String>(
                      value: s.store.get('qari', '05'),
                      items: qaris.entries
                          .map(
                            (q) => DropdownMenuItem(
                              value: q.key,
                              child: Text(q.value),
                            ),
                          )
                          .toList(),
                      onChanged: (q) => perform(c, () async {
                        await s.store.set('qari', q);
                        if (s.player.current != null) {
                          await s.player.play(
                            s.player.verses,
                            q!,
                            s.player.repeats,
                          );
                        }
                      }),
                    ),
                    DropdownButton<int>(
                      value: repeat,
                      items: [1, 3, 5, 10]
                          .map(
                            (n) =>
                                DropdownMenuItem(value: n, child: Text('$n ×')),
                          )
                          .toList(),
                      onChanged: (n) => setState(() => repeat = n!),
                    ),
                    FilledButton.icon(
                      onPressed: () => s.player.play(
                        verses.sublist(start - 1, end),
                        s.store.get('qari', '05'),
                        repeat,
                      ),
                      icon: const Icon(Icons.play_arrow),
                      label: Text(c.t('Putar rentang', 'Play range')),
                    ),
                  ],
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
                child: PageView.builder(
                  controller: pages,
                  itemCount: verses.length,
                  onPageChanged: (i) {
                    setState(() => current = i);
                    perform(
                      c,
                      () => s.store.set('last', {
                        'surah': verses[i].surah,
                        'verse': verses[i].number,
                      }),
                    );
                  },
                  itemBuilder: (c, i) {
                    final v = verses[i];
                    return ListenableBuilder(
                      listenable: s.player,
                      builder: (c, _) => SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
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
                            const SizedBox(height: 24),
                            if (!hidden)
                              SelectableText(
                                v.arabic,
                                textDirection: TextDirection.rtl,
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                  fontSize: s.store
                                      .get<num>('arabicSize', 32)
                                      .toDouble(),
                                  height: 2,
                                ),
                              ),
                            if (hidden)
                              Text(
                                c.t(
                                  'Teks Arab disembunyikan',
                                  'Arabic text hidden',
                                ),
                                textAlign: TextAlign.center,
                              ),
                            const SizedBox(height: 24),
                            SelectableText(
                              v.translation,
                              style: TextStyle(
                                fontSize: s.store
                                    .get<num>('translationSize', 18)
                                    .toDouble(),
                                height: 1.6,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              c.t(
                                'Terjemahan Indonesia • EQuran.id',
                                'Indonesian translation • EQuran.id',
                              ),
                            ),
                            Wrap(
                              spacing: 8,
                              children: [
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
                                    () => s.store.set('last', {
                                      'surah': v.surah,
                                      'verse': v.number,
                                    }),
                                  ),
                                  child: Text(
                                    c.t('Bacaan terakhir', 'Last read'),
                                  ),
                                ),
                              ],
                            ),
                            Wrap(
                              spacing: 8,
                              children: [
                                for (final status in [
                                  'learning',
                                  'done',
                                  'none',
                                ])
                                  ChoiceChip(
                                    selected:
                                        s.store.map('progress')[v.ref] ==
                                        status,
                                    label: Text(
                                      status == 'done'
                                          ? c.t('Sudah hafal', 'Memorized')
                                          : status == 'learning'
                                          ? c.t('Sedang dihafal', 'Learning')
                                          : c.t('Reset', 'Reset'),
                                    ),
                                    onSelected: (_) => perform(
                                      c,
                                      () => s.store.mark(v.ref, status),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    tooltip: c.t('Ayat sebelumnya', 'Previous verse'),
                    onPressed: current == 0
                        ? null
                        : () => pages!.previousPage(
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeOut,
                          ),
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Text('${current + 1} / ${verses.length}'),
                  IconButton(
                    tooltip: c.t('Ayat berikutnya', 'Next verse'),
                    onPressed: current == verses.length - 1
                        ? null
                        : () => pages!.nextPage(
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeOut,
                          ),
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
