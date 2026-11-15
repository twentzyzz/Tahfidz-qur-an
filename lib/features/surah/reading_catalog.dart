import 'package:flutter/material.dart';

import '../../app/session.dart';
import '../../core/theme/app_typography.dart';
import '../../l10n/app_strings.dart';
import '../../services/quran_repository.dart';
import 'surah_detail_page.dart';

class ReadingCatalog extends StatefulWidget {
  const ReadingCatalog({super.key});

  @override
  State<ReadingCatalog> createState() => _ReadingCatalogState();
}

class _ReadingCatalogState extends State<ReadingCatalog> {
  final search = TextEditingController();

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  void clearSearch() {
    search.clear();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final all = Session.of(context).quran.chapters;
    final query = search.text.trim().toLowerCase();
    final chapters = all.where((chapter) {
      return chapter.name.toLowerCase().contains(query) ||
          chapter.arabic.contains(query) ||
          '${chapter.number}' == query;
    }).toList();
    return CatalogFrame(
      child: CustomScrollView(
        key: const PageStorageKey('reading-catalog'),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CatalogHeading(
                  title: context.t('Daftar surah', 'Surah list'),
                  description: context.t(
                    '${all.length} surah untuk dibaca dan diulang.',
                    '${all.length} surahs to read and revisit.',
                  ),
                ),
                TextField(
                  key: const Key('surah-search'),
                  controller: search,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    labelText: context.t('Cari surah', 'Search surahs'),
                    hintText: context.t('Nama atau nomor', 'Name or number'),
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: search.text.isEmpty
                        ? null
                        : IconButton(
                            tooltip: context.t('Hapus pencarian', 'Clear search'),
                            onPressed: clearSearch,
                            icon: const Icon(Icons.close_rounded),
                          ),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Semantics(
                    liveRegion: true,
                    child: Text(
                      context.t(
                        '${chapters.length} surah',
                        '${chapters.length} surahs',
                      ),
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (chapters.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Column(
                  children: [
                    Text(context.t('Surah tidak ditemukan', 'No surah found')),
                    const SizedBox(height: 8),
                    Text(
                      context.t(
                        'Coba nama Latin, Arab, atau nomor surah.',
                        'Try a Latin or Arabic name, or a surah number.',
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: clearSearch,
                      child: Text(context.t('Tampilkan semua surah', 'Show all surahs')),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _SurahRow(chapter: chapters[index]),
                childCount: chapters.length,
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }
}

class _SurahRow extends StatelessWidget {
  const _SurahRow({required this.chapter});
  final Chapter chapter;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked = constraints.maxWidth < 560 ||
            MediaQuery.textScalerOf(context).scale(16) > 20;
        final arabic = Text(
          chapter.arabic,
          textDirection: TextDirection.rtl,
          style: AppTypography.arabic.copyWith(
            fontSize: 24,
            color: colors.primary,
          ),
        );
        return Material(
          color: colors.surface,
          child: Column(
            children: [
              ListTile(
                key: ValueKey('surah-${chapter.number}'),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                leading: CatalogNumber(chapter.number),
                title: Text(
                  chapter.name,
                  semanticsLabel: '${chapter.number}. ${chapter.name}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text('${chapter.count} ${context.t('ayat', 'verses')}'),
                    if (stacked) arabic,
                  ],
                ),
                trailing: stacked ? null : SizedBox(width: 180, child: arabic),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => SurahDetailPage(number: chapter.number),
                  ),
                ),
              ),
              const Divider(height: 1),
            ],
          ),
        );
      },
    );
  }
}

class CatalogFrame extends StatelessWidget {
  const CatalogFrame({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    bottom: false,
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 850),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: MediaQuery.sizeOf(context).width < 600 ? 16 : 24,
          ),
          child: child,
        ),
      ),
    ),
  );
}

class CatalogHeading extends StatelessWidget {
  const CatalogHeading({super.key, required this.title, required this.description});
  final String title, description;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 16, bottom: 24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text(
          description,
          style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
      ],
    ),
  );
}

class CatalogNumber extends StatelessWidget {
  const CatalogNumber(this.number, {super.key});
  final int number;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Container(
      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$number',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onPrimaryContainer,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  );
}
