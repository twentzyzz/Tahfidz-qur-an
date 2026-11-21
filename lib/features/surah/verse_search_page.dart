import 'package:flutter/material.dart';

import '../../app/session.dart';
import '../../core/theme/app_typography.dart';
import '../../l10n/app_strings.dart';
import '../../services/quran_repository.dart';
import '../../services/verse_search.dart';
import 'surah_detail_page.dart';

class VerseSearchPage extends StatefulWidget {
  const VerseSearchPage({super.key});

  @override
  State<VerseSearchPage> createState() => _VerseSearchPageState();
}

class _VerseSearchPageState extends State<VerseSearchPage> {
  final _controller = TextEditingController();
  final _allVerses = <Verse>[];
  List<Verse> _results = [];
  int _loaded = 0;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Allow the first frame to render before reading the bundled surah files.
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadVerses());
  }

  Future<void> _loadVerses() async {
    final repository = Session.of(context).quran;
    try {
      for (final chapter in repository.chapters) {
        final verses = await repository.surah(chapter.number);
        if (!mounted) return;
        _allVerses.addAll(verses);
        setState(() {
          _loaded++;
          _results = VerseSearch.filter(_allVerses, _controller.text);
        });
      }
      if (mounted) setState(() => _loading = false);
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = context.t(
            'Gagal membaca data ayat offline.',
            'Could not read offline verse data.',
          );
          _loading = false;
        });
      }
    }
  }

  void _search(String value) {
    setState(() => _results = VerseSearch.filter(_allVerses, value));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final quran = Session.of(context).quran;
    final hasQuery = _controller.text.trim().isNotEmpty;
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(context.t('Cari ayat', 'Search verses'))),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 850),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: TextField(
                    key: const Key('verse-search-field'),
                    controller: _controller,
                    autofocus: false,
                    textInputAction: TextInputAction.search,
                    onChanged: _search,
                    decoration: InputDecoration(
                      labelText: context.t(
                        'Cari teks Arab atau Indonesia',
                        'Search Arabic or Indonesian text',
                      ),
                      hintText: context.t(
                        'Contoh: الرحمن atau maha pengasih',
                        'Example: الرحمن or maha pengasih',
                      ),
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: !hasQuery
                          ? null
                          : IconButton(
                              tooltip: context.t('Hapus', 'Clear'),
                              icon: const Icon(Icons.close_rounded),
                              onPressed: () {
                                _controller.clear();
                                _search('');
                              },
                            ),
                    ),
                  ),
                ),
                if (_loading)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        LinearProgressIndicator(
                          value: quran.chapters.isEmpty
                              ? null
                              : _loaded / quran.chapters.length,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          context.t(
                            'Memuat $_loaded dari ${quran.chapters.length} surah offline...',
                            'Loading $_loaded of ${quran.chapters.length} offline surahs...',
                          ),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(_error!, style: TextStyle(color: colors.error)),
                  ),
                if (hasQuery && _error == null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Semantics(
                        liveRegion: true,
                        child: Text(
                          context.t(
                            '${_results.length} ayat ditemukan',
                            '${_results.length} verses found',
                          ),
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                      ),
                    ),
                  ),
                Expanded(
                  child: !hasQuery
                      ? Center(
                          child: Text(
                            context.t(
                              'Ketik kata atau potongan ayat untuk mencari di seluruh Al-Qur’an.',
                              'Type a word or verse fragment to search the Quran.',
                            ),
                            textAlign: TextAlign.center,
                          ),
                        )
                      : _results.isEmpty
                          ? Center(
                              child: Text(
                                _loading
                                    ? context.t(
                                        'Mencari sambil memuat ayat...',
                                        'Searching while loading verses...',
                                      )
                                    : context.t(
                                        'Ayat tidak ditemukan. Coba kata lain.',
                                        'No verses found. Try another word.',
                                      ),
                                textAlign: TextAlign.center,
                              ),
                            )
                          : ListView.builder(
                              key: const Key('verse-search-results'),
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                              itemCount: _results.length,
                              itemBuilder: (context, index) {
                                final verse = _results[index];
                                final chapter = quran.chapters[verse.surah - 1];
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  child: InkWell(
                                    key: ValueKey('verse-result-${verse.ref}'),
                                    borderRadius: BorderRadius.circular(12),
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute<void>(
                                        builder: (_) => SurahDetailPage(
                                          number: verse.surah,
                                          initialVerse: verse.number,
                                        ),
                                      ),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          Text(
                                            '${chapter.name} • ${verse.ref}',
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleSmall
                                                ?.copyWith(
                                                  color: colors.primary,
                                                  fontWeight: FontWeight.w800,
                                                ),
                                          ),
                                          const SizedBox(height: 10),
                                          Text(
                                            verse.arabic,
                                            textDirection: TextDirection.rtl,
                                            textAlign: TextAlign.right,
                                            style: AppTypography.arabic.copyWith(
                                              fontSize: 25,
                                              color: colors.onSurface,
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          Text(
                                            verse.translation,
                                            maxLines: 4,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 6),
                                          Align(
                                            alignment: Alignment.centerRight,
                                            child: Icon(
                                              Icons.chevron_right_rounded,
                                              color: colors.primary,
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
            ),
          ),
        ),
      ),
    );
  }
}
