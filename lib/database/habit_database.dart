import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:habit_tracker/models/app_settings.dart';
import 'package:habit_tracker/models/habit.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

class HabitDatabase extends ChangeNotifier {
  static late Isar isar;

  /*
    S E T U P
  */

  // INITIALIZE - database
  static Future<void> initialize() async {
    final dir = await getApplicationDocumentsDirectory();
    isar = await Isar.open([
      HabitSchema,
      AppSettingsSchema,
    ], directory: dir.path);
  }

  // Save first date of app startup (for heatmap)
  Future<void> saveFirstLaunchDate() async {
    final existingSettings = await isar.appSettings.where().findFirst();
    if (existingSettings == null) {
      final settings = AppSettings()..firstLaunchDate = DateTime.now();
      await isar.writeTxn(() => isar.appSettings.put(settings));
    }
  }

  // Get first date of app startup (for heatmap)
  Future<DateTime?> getFirstLaunchDate() async {
    final settings = await isar.appSettings.where().findFirst();
    return settings?.firstLaunchDate;
  }

  // List of habits
  final List<Habit> currentHabits = [];

  // CREATE - add a new habit
  Future<void> addHabit(String habitName) async {
    // create a new habiit
    final newHabit = Habit()..name = habitName;
    // save to db
    await isar.writeTxn(() => isar.habits.put(newHabit));
    // re-read from db
    readHabits();
  }

  // READ - read saved habits from DB
  Future<void> readHabits() async {
    // fetch all habits from db
    List<Habit> fetchedHabits = await isar.habits.where().findAll();
    // give to current habits
    currentHabits.clear();
    currentHabits.addAll(fetchedHabits);
    // update UI
    notifyListeners();
  }

  // UPDATE - check habit on and off
  Future<void> updateHabitCompletion(int id, bool isCompleted) async {
    // find the habit
    final habit = await isar.habits.get(id);
    // update completion status
    if (habit != null) {
      await isar.writeTxn(() async {
        final today = DateTime.now();
        // if habit is completed -> add the current date to the completedDays list
        if (isCompleted) {
          if (habit.completedDays.contains(DateTime.now())) {
            return;
          }
          habit.completedDays.add(DateTime(today.year, today.month, today.day));
        } else {
          // if habit is NOT completed -> remove the current date from the completedDays list
          habit.completedDays.removeWhere(
            (date) =>
                date.year == today.year &&
                date.month == today.month &&
                date.day == today.day,
          );
        }

        // save the updated habit to DB
        await isar.habits.put(habit);
      });
    }

    // re-read from DB
    readHabits();
  }

  // UPDATE - edit habit name
  Future<void> updateHabitName(int id, String newName) async {
    // find the habit
    final habit = await isar.habits.get(id);

    if (habit != null) {
      await isar.writeTxn(() async {
        habit.name = newName;
        // save updated habit back to the DB
        await isar.habits.put(habit);
      });
    }

    // re-read from DB
    readHabits();
  }

  // DELETE - delete habit
  Future<void> deleteHabit(int id) async {
    // perform the delete
    await isar.writeTxn(() async {
      await isar.habits.delete(id);
    });

    // re-read from DB
    readHabits();
  }
}
