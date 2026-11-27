import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:mishkat/l10n/generated/app_localizations.dart';

class AthkarItem {
  const AthkarItem({
    required this.id,
    required this.category,
    required this.text,
    required this.repeat,
    required this.source,
  });

  factory AthkarItem.fromJson(Map<String, dynamic> json) => AthkarItem(
    id: json['id'] as int,
    category: json['category'] as String,
    text: json['text'] as String,
    repeat: json['repeat'] as int,
    source: json['source'] as String,
  );

  final int id;
  final String category;
  final String text;
  final int repeat;
  final String source;
}

class AthkarScreen extends ConsumerStatefulWidget {
  const AthkarScreen({super.key});

  @override
  ConsumerState<AthkarScreen> createState() => _AthkarScreenState();
}

class _AthkarScreenState extends ConsumerState<AthkarScreen> {
  final _counts = <int, int>{};

  String _categoryLabel(AppLocalizations l10n, String category) =>
      switch (category) {
        'morning' => l10n.athkarMorning,
        'evening' => l10n.athkarEvening,
        'after_prayer' => l10n.athkarAfterPrayer,
        'sleep' => l10n.athkarSleep,
        _ => l10n.navAthkar,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.navAthkar)),
      body: FutureBuilder<String>(
        future: rootBundle.loadString('assets/data/athkar.json'),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final decoded = jsonDecode(snapshot.data!) as Map<String, dynamic>;
          final items = [
            for (final item in decoded['items'] as List<dynamic>)
              AthkarItem.fromJson(item as Map<String, dynamic>),
          ];
          final seen = <String>{};
          final categories = [
            for (final item in items)
              if (seen.add(item.category)) item.category,
          ];

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    l10n.sunniOnlyDesc,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ),
              for (final category in categories) ...[
                Padding(
                  padding: const EdgeInsets.only(top: 16, bottom: 8),
                  child: Text(
                    _categoryLabel(l10n, category),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                for (final item in items.where((i) => i.category == category))
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Directionality(
                            textDirection: TextDirection.rtl,
                            child: Text(
                              item.text,
                              textAlign: TextAlign.right,
                              style: const TextStyle(fontSize: 20, height: 1.6),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${l10n.messagesCount}: '
                                  '${_counts[item.id] ?? 0}/${item.repeat}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ),
                              Text(
                                item.source,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: OutlinedButton(
                              onPressed: () => setState(() {
                                _counts[item.id] =
                                    (_counts[item.id] ?? 0) + 1;
                              }),
                              child: Text(l10n.tapToCount),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ],
          );
        },
      ),
    );
  }
}
