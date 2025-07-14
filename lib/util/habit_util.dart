// given a habit list of completion days
// is the habit completed today
import 'package:habit_tracker/models/habit.dart';

bool isHabitCompletedToday(List<DateTime> completedDays) {
  final today = DateTime.now();
  return completedDays.any(
    (date) =>
        date.year == today.year &&
        date.month == today.month &&
        date.day == today.day,
  );
}

// prepare heat map dataset
Map<DateTime, int> prepHeatMapDataSet(List<Habit> habits) {
  Map<DateTime, int> dataset = {};

  for (var habit in habits) {
    for (var date in habit.completedDays) {
      // nomalize date to avoid time mismatch
      final nomalizedDate = DateTime(date.year, date.month, date.day);

      // if the date already exists in the dataset, increment its count
      if (dataset.containsKey(nomalizedDate)) {
        dataset[nomalizedDate] = dataset[nomalizedDate]! + 1;
      } else {
        // else initialize it with a count of 1
        dataset[nomalizedDate] = 1;
      }
    }
  }

  return dataset;
}
