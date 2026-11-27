import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mishkat_core/mishkat_core.dart';

/// تمييز الكلمات أثناء التلاوة helix من توقيتات مُتحقَّق منها.
/// يعرض النص العثماني كما هو، ولا يعدّل ترتيبه أو تشكيله.
class WordHighlight extends StatefulWidget {
  const WordHighlight({
    required this.text,
    required this.timings,
    required this.playing,
    super.key,
  });

  final String text;
  final List<WordTiming> timings;
  final bool playing;

  @override
  State<WordHighlight> createState() => _WordHighlightState();
}

class _WordHighlightState extends State<WordHighlight> {
  Timer? _timer;
  int _positionMs = 0;

  @override
  void initState() {
    super.initState();
    _syncTimer();
  }

  @override
  void didUpdateWidget(WordHighlight oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text || oldWidget.timings != widget.timings) {
      _positionMs = 0;
    }
    if (oldWidget.playing != widget.playing) _syncTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _syncTimer() {
    _timer?.cancel();
    if (!widget.playing) return;
    _timer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (!mounted) return;
      setState(() => _positionMs += 100);
    });
  }

  @override
  Widget build(BuildContext context) {
    final tokens = RecitationGrader.words(widget.text);
    final aligned = const WordAligner().align(tokens, widget.timings);
    final active = const WordAligner().activeAt(aligned, _positionMs);
    final colors = Theme.of(context).colorScheme;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        alignment: WrapAlignment.center,
        children: [
          for (var index = 0; index < tokens.length; index++)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: active?.index == index
                    ? colors.primaryContainer
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(tokens[index]),
            ),
        ],
      ),
    );
  }
}
