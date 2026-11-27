import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mishkat/core/settings/opt_in_providers.dart';
import 'package:mishkat/l10n/generated/app_localizations.dart';
import 'package:mishkat_core/mishkat_core.dart';

import '../../../app/advanced_providers.dart';
import '../../../app/providers.dart';
import 'quran_providers.dart';
import 'word_highlight.dart';

class QuranScreen extends ConsumerStatefulWidget {
  const QuranScreen({super.key});

  @override
  ConsumerState<QuranScreen> createState() => _QuranScreenState();
}

class _QuranScreenState extends ConsumerState<QuranScreen> {
  final _searchController = TextEditingController();
  final _surahController = TextEditingController();
  final _pageController = TextEditingController(text: '1');
  int? _selectedJuz;
  int? _selectedAyahId;
  int _page = 1;

  @override
  void dispose() {
    _searchController.dispose();
    _surahController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  int? _bounded(String text, int min, int max) {
    final value = int.tryParse(text.trim());
    return value != null && value >= min && value <= max ? value : null;
  }

  void _goToPage(int page) {
    if (page < 1 || page > 604) return;
    setState(() {
      _page = page;
      _pageController.text = '$page';
    });
  }

  void _goToMushaf(int page, {int? ayahId}) {
    _goToPage(page);
    if (ayahId != null) setState(() => _selectedAyahId = ayahId);
    DefaultTabController.of(context).animateTo(0);
  }

  AyahFilter get _localFilter => AyahFilter(
    surahId: _bounded(_surahController.text, 1, 114),
    juz: _selectedJuz,
    page: _bounded(_pageController.text, 1, 604),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final surahs = ref.watch(surahListProvider).value ?? const [];
    final surahNames = {for (final item in surahs) item.id: item.nameAr};

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.navQuran),
          bottom: TabBar(
            tabs: [
              Tab(text: l10n.mushaf),
              Tab(text: l10n.surahs),
              Tab(text: l10n.search),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _mushafTab(l10n, surahNames),
            _surahsTab(l10n),
            _searchTab(l10n),
          ],
        ),
      ),
    );
  }

  Widget _mushafTab(AppLocalizations l10n, Map<int, String> surahNames) {
    final source = ref.watch(mushafSourceProvider);
    final page = ref.watch(activeMushafPageProvider(_page));
    final sourceLabel = switch (source) {
      QuranTextSource.tanzilUthmani => l10n.mushafSourceTanzil,
      QuranTextSource.quranComUthmani => l10n.mushafSourceQuranCom,
    };

    return Column(
      children: [
        ListTile(
          dense: true,
          leading: Icon(
            source.requiresNetwork
                ? Icons.cloud_sync_outlined
                : Icons.menu_book_outlined,
          ),
          title: Text(l10n.mushafSource),
          subtitle: Text(sourceLabel),
          trailing: IconButton(
            tooltip: l10n.mushafSource,
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings'),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Row(
            children: [
              IconButton(
                tooltip: l10n.previousPage,
                icon: const Icon(Icons.chevron_left),
                onPressed: _page > 1 ? () => _goToPage(_page - 1) : null,
              ),
              Expanded(
                child: TextField(
                  controller: _pageController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    labelText: l10n.pageNumber,
                    isDense: true,
                  ),
                  onSubmitted: (value) {
                    final parsed = _bounded(value, 1, 604);
                    if (parsed != null) _goToPage(parsed);
                  },
                ),
              ),
              IconButton(
                tooltip: l10n.nextPage,
                icon: const Icon(Icons.chevron_right),
                onPressed: _page < 604 ? () => _goToPage(_page + 1) : null,
              ),
            ],
          ),
        ),
        Expanded(
          child: page.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.wifi_off_outlined, size: 48),
                    const SizedBox(height: 12),
                    Text(
                      source.requiresNetwork
                          ? l10n.mushafSourceFallback
                          : l10n.errorGeneric,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextButton(
                          onPressed: () =>
                              ref.invalidate(activeMushafPageProvider(_page)),
                          child: Text(l10n.retry),
                        ),
                        TextButton(
                          onPressed: () => context.push('/settings'),
                          child: Text(l10n.mushafSource),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            data: (ayahs) {
              if (ayahs.isEmpty) {
                return Center(child: Text(l10n.noResults));
              }
              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                itemCount: ayahs.length,
                itemBuilder: (context, index) {
                  final ayah = ayahs[index];
                  final newSurah =
                      index == 0 || ayah.surahId != ayahs[index - 1].surahId;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (newSurah)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Directionality(
                            textDirection: TextDirection.rtl,
                            child: Text(
                              surahNames[ayah.surahId] ?? l10n.surah,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                          ),
                        ),
                      Card(
                        color: _selectedAyahId == ayah.id
                            ? Theme.of(context).colorScheme.primaryContainer
                            : null,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Directionality(
                            textDirection: TextDirection.rtl,
                            child: Text(
                              ayah.text,
                              textAlign: TextAlign.right,
                              style: const TextStyle(fontSize: 26, height: 1.7),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _surahsTab(AppLocalizations l10n) {
    final surahs = ref.watch(surahListProvider);
    return surahs.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('$error')),
      data: (rows) => ListView.builder(
        itemCount: rows.length,
        itemBuilder: (context, index) {
          final surah = rows[index];
          return ListTile(
            leading: CircleAvatar(child: Text('${surah.id}')),
            title: Directionality(
              textDirection: TextDirection.rtl,
              child: Text(surah.nameAr),
            ),
            subtitle: Text(
              '${l10n.ayah}: ${surah.ayahCount}  •  '
              '${l10n.page}: ${surah.pageStart}',
            ),
            onTap: () => _goToMushaf(surah.pageStart),
          );
        },
      ),
    );
  }

  Widget _searchTab(AppLocalizations l10n) {
    final term = _searchController.text.trim();
    final results = ref.watch(
      quranFilteredSearchProvider((term: term, filter: _localFilter)),
    );
    final tafsirEnabled = ref.watch(optInProvider(OptInKey.tafsir));
    final wordSyncEnabled = ref.watch(optInProvider(OptInKey.wordSync));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: l10n.searchHint,
              prefixIcon: const Icon(Icons.search),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 110,
                child: TextField(
                  controller: _surahController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: l10n.filterBySurah,
                    isDense: true,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              DropdownButton<int?>(
                value: _selectedJuz,
                hint: Text(l10n.filterByJuz),
                items: [
                  DropdownMenuItem<int?>(value: null, child: Text(l10n.allJuz)),
                  for (var juz = 1; juz <= 30; juz++)
                    DropdownMenuItem<int?>(value: juz, child: Text('$juz')),
                ],
                onChanged: (value) => setState(() => _selectedJuz = value),
              ),
              SizedBox(
                width: 100,
                child: TextField(
                  controller: _pageController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: l10n.filterByPage,
                    isDense: true,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              TextButton(
                onPressed: () => setState(() {
                  _surahController.clear();
                  _pageController.text = '$_page';
                  _selectedJuz = null;
                }),
                child: Text(l10n.clearFilters),
              ),
            ],
          ),
        ),
        if (wordSyncEnabled && !isAiProxyConfigured)
          Padding(
            padding: const EdgeInsets.all(8),
            child: Text(
              l10n.proxyNotConfigured,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        Expanded(
          child: term.isEmpty
              ? Center(child: Text(l10n.searchHint))
              : results.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, stack) => Center(child: Text('$error')),
                  data: (ids) => ids.isEmpty
                      ? Center(child: Text(l10n.noResults))
                      : ListView.builder(
                          itemCount: ids.length,
                          itemBuilder: (context, index) {
                            final id = ids[index];
                            final meta = ref.watch(ayahMetaProvider(id));
                            return meta.when(
                              loading: () => const ListTile(
                                title: LinearProgressIndicator(),
                              ),
                              error: (_, __) => const SizedBox.shrink(),
                              data: (value) {
                                if (value == null) {
                                  return const SizedBox.shrink();
                                }
                                return ListTile(
                                  leading: CircleAvatar(
                                    child: Text('${index + 1}'),
                                  ),
                                  title: Directionality(
                                    textDirection: TextDirection.rtl,
                                    child: Text(value.text),
                                  ),
                                  subtitle: Text(
                                    '${l10n.surah}: ${value.surahId}  •  '
                                    '${l10n.ayah}: ${value.ayahNo}  •  '
                                    '${l10n.page}: ${value.page}',
                                  ),
                                  onTap: () =>
                                      _goToMushaf(value.page, ayahId: id),
                                );
                              },
                            );
                          },
                        ),
                ),
        ),
        if (_selectedAyahId != null && tafsirEnabled)
          _TafsirPanel(ayahId: _selectedAyahId!),
        if (_selectedAyahId != null && wordSyncEnabled && isAiProxyConfigured)
          _WordSyncPanel(ayahId: _selectedAyahId!),
      ],
    );
  }
}

class _TafsirPanel extends ConsumerWidget {
  const _TafsirPanel({required this.ayahId});

  final int ayahId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final tafsir = ref.watch(
      tafsirProvider((ayahId: ayahId, editionId: 'ar.muyassar')),
    );
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: tafsir.when(
          loading: () => const LinearProgressIndicator(),
          error: (error, stack) => Text(l10n.errorNetwork),
          data: (text) => Directionality(
            textDirection: TextDirection.rtl,
            child: Text(text ?? l10n.noTafsirOffline),
          ),
        ),
      ),
    );
  }
}

class _WordSyncPanel extends ConsumerStatefulWidget {
  const _WordSyncPanel({required this.ayahId});

  final int ayahId;

  @override
  ConsumerState<_WordSyncPanel> createState() => _WordSyncPanelState();
}

class _WordSyncPanelState extends ConsumerState<_WordSyncPanel> {
  bool _playing = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final text = ref.watch(ayahTextProvider(widget.ayahId));
    final timings = ref.watch(wordTimingsForAyahProvider(widget.ayahId));
    final ayah = text.value ?? '';
    final words = timings.value ?? const <WordTiming>[];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            if (words.isEmpty)
              Text(l10n.proxyNotConfigured)
            else
              WordHighlight(text: ayah, timings: words, playing: _playing),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton.icon(
                  onPressed: () => setState(() => _playing = true),
                  icon: const Icon(Icons.play_arrow_outlined),
                  label: Text(l10n.play),
                ),
                TextButton.icon(
                  onPressed: () => setState(() => _playing = false),
                  icon: const Icon(Icons.stop_circle_outlined),
                  label: Text(l10n.stop),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
