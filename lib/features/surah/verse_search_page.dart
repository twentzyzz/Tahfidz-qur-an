import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/session.dart';
import '../../core/theme/app_typography.dart';
import '../../l10n/app_strings.dart';
import '../../services/quran_repository.dart';
import 'surah_detail_page.dart';

/// Search Arabic ayat and Indonesian translations in the bundled Quran.
/// Results are limited on screen, while the total count reflects all matches.
class VerseSearchPage extends StatefulWidget {
  const VerseSearchPage({super.key});

  @override
  State<VerseSearchPage> createState() => _VerseSearchPageState();
}

class _VerseSearchPageState extends State<VerseSearchPage> {
  final _controller = TextEditingController();
  Timer? _debounce;
  VerseSearchResults? _results;
  bool _loading = false;
  bool _failed = false;
  int _generation = 0;
  String _resultQuery = '';

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _changed(String text) {
    _debounce?.cancel();
    final generation = ++_generation;
    final query = text.trim();
    if (query.isEmpty) {
      setState(() {
        _results = null;
        _loading = false;
        _failed = false;
      });
      return;
    }
    setState(() {
      _results = null;
      _loading = true;
      _failed = false;
    });
    _debounce = Timer(
      const Duration(milliseconds: 300),
      () => _search(query, generation),
    );
  }

  void _submitted(String text) {
    _debounce?.cancel();
    final generation = ++_generation;
    final query = text.trim();
    if (query.isEmpty) {
      _changed('');
      return;
    }
    setState(() {
      _loading = true;
      _failed = false;
      _results = null;
    });
    _search(query, generation);
  }

  Future<void> _search(String query, int generation) async {
    try {
      final results = await Session.of(context).quran.searchVerses(query);
      if (!mounted || generation != _generation) return;
      setState(() {
        _results = results;
        _resultQuery = query;
        _loading = false;
      });
    } catch (_) {
      if (!mounted || generation != _generation) return;
      setState(() {
        _failed = true;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final quran = Session.of(context).quran;
    final colors = Theme.of(context).colorScheme;
    final matches = _results?.matches ?? const <VerseSearchMatch>[];
    return Scaffold(
      appBar: AppBar(title: Text(context.t('Cari isi ayat', 'Search verses'))),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 850),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                  child: TextField(
                    key: const Key('verse-search-input'),
                    controller: _controller,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      labelText: context.t(
                        'Cari ayat Arab atau terjemahan',
                        'Search Arabic verses or translations',
                      ),
                      hintText: context.t(
                        'Contoh: الحمد atau segala puji',
                        'Example: الحمد or segala puji',
                      ),
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _controller.text.isEmpty
                          ? null
                          : IconButton(
                              tooltip: context.t('Hapus pencarian', 'Clear search'),
                              icon: const Icon(Icons.close_rounded),
                              onPressed: () {
                                _controller.clear();
                                _changed('');
                              },
                            ),
                    ),
                    onChanged: _changed,
                    onSubmitted: _submitted,
                  ),
                ),
                if (_loading)
                  const LinearProgressIndicator(key: Key('verse-search-loading')),
                Expanded(
                  child: _loading
                      ? Center(
                          child: Text(
                            context.t(
                              'Mencari di seluruh Al-Qur’an offline…',
                              'Searching the offline Quran…',
                            ),
                          ),
                        )
                      : _failed
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    context.t(
                                      'Pencarian belum berhasil.',
                                      'Could not complete the search.',
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () => _submitted(_controller.text),
                                    child: Text(context.t('Coba lagi', 'Retry')),
                                  ),
                                ],
                              ),
                            )
                          : _results == null
                              ? Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(24),
                                    child: Text(
                                      context.t(
                                        'Ketik potongan ayat Arab tanpa harakat '
                                        'atau kata dari terjemahan Indonesia. '
                                        'Semua pencarian bisa dilakukan offline.',
                                        'Enter Arabic text without diacritics '
                                        'or words from the Indonesian translation. '
                                        'Search works offline.',
                                      ),
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: colors.onSurfaceVariant,
                                        height: 1.5,
                                      ),
                                    ),
                                  ),
                                )
                              : _results!.total == 0
                                  ? Center(
                                      child: Text(
                                        context.t(
                                          'Ayat tidak ditemukan. Coba kata lain.',
                                          'No verses found. Try another query.',
                                        ),
                                      ),
                                    )
                                  : Column(
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.fromLTRB(
                                            16, 4, 16, 12,
                                          ),
                                          child: Align(
                                            alignment: Alignment.centerLeft,
                                            child: Semantics(
                                              liveRegion: true,
                                              child: Text(
                                                context.t(
                                                  '${matches.length} dari ${_results!.total} hasil ayat',
                                                  '${matches.length} of ${_results!.total} verse matches',
                                                ),
                                                style: TextStyle(
                                                  color: colors.onSurfaceVariant,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: ListView.builder(
                                            key: ValueKey(
                                              'verse-search-results-$_resultQuery',
                                            ),
                                            keyboardDismissBehavior:
                                                ScrollViewKeyboardDismissBehavior.onDrag,
                                            padding: const EdgeInsets.fromLTRB(
                                              16, 0, 16, 24,
                                            ),
                                            itemCount: matches.length,
                                            itemBuilder: (context, index) {
                                              final verse = matches[index].verse;
                                              final chapter =
                                                  quran.chapters[verse.surah - 1];
                                              return Padding(
                                                padding: const EdgeInsets.only(
                                                  bottom: 10,
                                                ),
                                                child: Material(
                                                  color: colors.surface,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(18),
                                                    side: BorderSide(
                                                      color: colors.outlineVariant,
                                                    ),
                                                  ),
                                                  child: InkWell(
                                                    key: ValueKey(
                                                      'verse-result-${verse.ref}',
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(18),
                                                    onTap: () =>
                                                        Navigator.of(context).push(
                                                      MaterialPageRoute<void>(
                                                        builder: (_) =>
                                                            SurahDetailPage(
                                                          number: verse.surah,
                                                          initialVerse:
                                                              verse.number,
                                                        ),
                                                      ),
                                                    ),
                                                    child: Padding(
                                                      padding:
                                                          const EdgeInsets.all(16),
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment.stretch,
                                                        children: [
                                                          Row(
                                                            children: [
                                                              Icon(
                                                                Icons.menu_book_outlined,
                                                                color: colors.primary,
                                                                size: 20,
                                                              ),
                                                              const SizedBox(width: 8),
                                                              Expanded(
                                                                child: Text(
                                                                  '${chapter.name} • ${context.t('Ayat', 'Verse')} ${verse.number}',
                                                                  style: TextStyle(
                                                                    fontWeight:
                                                                        FontWeight.w800,
                                                                    color:
                                                                        colors.primary,
                                                                  ),
                                                                ),
                                                              ),
                                                              const Icon(
                                                                Icons.chevron_right_rounded,
                                                              ),
                                                            ],
                                                          ),
                                                          const SizedBox(height: 8),
                                                          Text(
                                                            verse.arabic,
                                                            textDirection:
                                                                TextDirection.rtl,
                                                            maxLines: 3,
                                                            overflow:
                                                                TextOverflow.ellipsis,
                                                            style: AppTypography.arabic.copyWith(
                                                              fontSize: 23,
                                                              height: 1.8,
                                                              color: colors.onSurface,
                                                            ),
                                                          ),
                                                          const SizedBox(height: 10),
                                                          Text(
                                                            verse.translation,
                                                            maxLines: 3,
                                                            overflow:
                                                                TextOverflow.ellipsis,
                                                            style: TextStyle(
                                                              height: 1.5,
                                                              color: colors.onSurfaceVariant,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
