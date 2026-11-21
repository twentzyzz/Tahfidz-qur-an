import 'package:flutter/material.dart';

import '../../app/session.dart';
import '../../core/theme/app_typography.dart';
import '../../l10n/app_strings.dart';
import '../../services/quran_repository.dart';
import 'surah_detail_page.dart';
import 'verse_search_page.dart';

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
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  key: const Key('open-verse-search'),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => const VerseSearchPage(),
                    ),
                  ),
                  icon: const Icon(Icons.manage_search_rounded),
                  label: Text(
                    context.t(
                      'Cari ayat Arab & Indonesia',
                      'Search Arabic & Indonesian verses',
                    ),
                  ),
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
            fontSize: 25,
            color: colors.primary,
            height: 1.65,
          ),
        );
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Material(
            color: colors.surface,
            elevation: 1,
            shadowColor: const Color(0xFFBFA878).withValues(alpha: .12),
            borderRadius: BorderRadius.circular(18),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: colors.outlineVariant),
              ),
              child: ListTile(
                key: ValueKey('surah-${chapter.number}'),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                leading: CatalogNumber(chapter.number),
                title: Text(
                  chapter.name,
                  semanticsLabel: '${chapter.number}. ${chapter.name}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
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
            ),
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
        Text(
          title,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: Theme.of(context).colorScheme.primary,
            letterSpacing: -.7,
          ),
        ),
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
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final colors = Theme.of(context).colorScheme;
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: 42,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Transform.rotate(
              angle: .785398,
              child: Container(
                width: 31,
                height: 31,
                decoration: BoxDecoration(
                  color: dark ? colors.primaryContainer : const Color(0xFFF9EAC9),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: dark ? colors.primary : const Color(0xFFC5A064),
                    width: 1.5,
                  ),
                ),
              ),
            ),
            Text(
              '$number',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.onSurface,
                fontSize: number >= 100 ? 11 : 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
