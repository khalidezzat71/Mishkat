import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mishkat_core/mishkat_core.dart';

final hifzPlanProvider = StateProvider<HifzPlan>((ref) {
  return HifzPlan(
    type: HifzPlanType.page,
    startDate: DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    ),
    dailyNew: 1,
    dailyRecent: 3,
    dailyCumulative: 2,
  );
});

final khatmahPlanProvider = Provider<List<DailyWorkload>>((ref) {
  return const KhatmahPlanner().build(ref.watch(hifzPlanProvider));
});

final todayWorkloadProvider = Provider<DailyWorkload?>((ref) {
  final days = ref.watch(khatmahPlanProvider);
  if (days.isEmpty) return null;
  final now = DateTime.now();
  for (final day in days) {
    if (day.day.year == now.year &&
        day.day.month == now.month &&
        day.day.day == now.day) {
      return day;
    }
  }
  return days.first;
});

final recitationGradeProvider =
    Provider.family<RecitationGrade, ({String expected, String recognized})>(
      (ref, args) =>
          const RecitationGrader().grade(args.expected, args.recognized),
    );
