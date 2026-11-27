import 'package:flutter/material.dart';
import 'package:mishkat/l10n/generated/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../../../app/advanced_providers.dart';

/// قائمة القرّاء: المصادر المجانية أولاً، والتنزيل في مساحة خاصة بطلب المستخدم.
class RecitersScreen extends ConsumerStatefulWidget {
  const RecitersScreen({super.key});

  @override
  ConsumerState<RecitersScreen> createState() => _RecitersScreenState();
}

class _RecitersScreenState extends ConsumerState<RecitersScreen> {
  final _player = AudioPlayer();
  final _surah = TextEditingController(text: '1');
  final _ayah = TextEditingController(text: '1');

  @override
  void dispose() {
    _player.dispose();
    _surah.dispose();
    _ayah.dispose();
    super.dispose();
  }

  int get _surahNumber => int.tryParse(_surah.text) ?? 1;
  int get _ayahNumber => int.tryParse(_ayah.text) ?? 1;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final reciters = ref.watch(recitersProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.reciters)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _surah,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: l10n.surah),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _ayah,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: l10n.ayah),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              l10n.downloadsPrivate,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          Expanded(
            child: reciters.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text('$error')),
              data: (rows) => ListView.builder(
                itemCount: rows.length,
                itemBuilder: (context, index) {
                  final reciter = rows[index];
                  return ListTile(
                    title: Text(reciter.nameAr),
                    subtitle: Text(reciter.riwayah ?? ''),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.download_outlined),
                          tooltip: l10n.download,
                          onPressed: () async {
                            final repo = await ref.read(
                              reciterRepositoryProvider.future,
                            );
                            await repo.download(
                              reciter,
                              surah: _surahNumber,
                              ayah: _ayahNumber,
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.play_arrow_outlined),
                          tooltip: l10n.play,
                          onPressed: () async {
                            final repo = await ref.read(
                              reciterRepositoryProvider.future,
                            );
                            await _player.setUrl(
                              repo.resolveUrl(
                                reciter,
                                _surahNumber,
                                _ayahNumber,
                              ),
                            );
                            await _player.play();
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
