import 'package:flutter/material.dart';
import 'package:mishkat/l10n/generated/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mishkat/core/settings/opt_in_providers.dart';
import 'package:mishkat_core/mishkat_core.dart';

import '../../../app/advanced_providers.dart';
import 'quran_providers.dart';
import 'word_highlight.dart';

class QuranScreen extends ConsumerStatefulWidget {
  const QuranScreen({super.key});

  @override
  ConsumerState<QuranScreen> createState() => _QuranScreenState();
}

class _QuranScreenState extends ConsumerState<QuranScreen> {
  final _controller = TextEditingController();
  final _surahController = TextEditingController();
  final _pageController = TextEditingController();
  int? _selectedJuz;
  int? _selectedAyahId;

  @override
  void dispose() {
    _controller.dispose();
    _surahController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  int? _bounded(String text, int min, int max) {
    final value = int.tryParse(text.trim());
    return value != null && value >= min && value <= max ? value : null;
  }

  AyahFilter get _localFilter => AyahFilter(
    surahId: _bounded(_surahController.text, 1, 114),
    juz: _selectedJuz,
    page: _bounded(_pageController.text, 1, 604),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final results = ref.watch(
      quranFilteredSearchProvider((
        term: _controller.text.trim(),
        filter: _localFilter,
      )),
    );
    final tafsirEnabled = ref.watch(optInProvider(OptInKey.tafsir));
    final wordSyncEnabled = ref.watch(optInProvider(OptInKey.wordSync));
    final selected = _selectedAyahId;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.navQuran)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: l10n.searchHint,
                prefixIcon: const Icon(Icons.search),
              ),
              onChanged: (_) => setState(() {}),
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: 120,
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
                    DropdownMenuItem<int?>(
                      value: null,
                      child: Text(l10n.allJuz),
                    ),
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
                    _pageController.clear();
                    _selectedJuz = null;
                  }),
                  child: Text(l10n.clearFilters),
                ),
              ],
            ),
            if (ref.watch(optInProvider(OptInKey.wordSync)) &&
                !isAiProxyConfigured)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  l10n.proxyNotConfigured,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            const SizedBox(height: 16),
            Expanded(
              child: results.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(child: Text('$error')),
                data: (ids) => ids.isEmpty
                    ? const SizedBox.shrink()
                    : ListView.builder(
                        itemCount: ids.length,
                        itemBuilder: (context, index) {
                          final id = ids[index];
                          return FutureBuilder<String?>(
                            future: ref.watch(ayahTextProvider(id).future),
                            builder: (context, snapshot) => ListTile(
                              selected: selected == id,
                              leading: CircleAvatar(
                                child: Text('${index + 1}'),
                              ),
                              title: Directionality(
                                textDirection: TextDirection.rtl,
                                child: Text(snapshot.data ?? ''),
                              ),
                              onTap: () => setState(() => _selectedAyahId = id),
                            ),
                          );
                        },
                      ),
              ),
            ),
            if (selected != null && tafsirEnabled)
              _TafsirPanel(ayahId: selected),
            if (selected != null && wordSyncEnabled && isAiProxyConfigured)
              _WordSyncPanel(ayahId: selected),
          ],
        ),
      ),
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
