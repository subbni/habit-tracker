import 'package:flutter/material.dart';
import 'package:habit_tracker/components/my_drawer.dart';
import 'package:habit_tracker/components/my_habit_tile.dart';
import 'package:habit_tracker/components/my_heat_map.dart';
import 'package:habit_tracker/database/habit_database.dart';
import 'package:habit_tracker/models/habit.dart';
import 'package:habit_tracker/util/habit_util.dart';
import 'package:habit_tracker/util/strings.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    // read existing habits on app startup
    Provider.of<HabitDatabase>(context, listen: false).readHabits();

    super.initState();
  }

  // text controller
  final TextEditingController textController = TextEditingController();

  // create new habit
  void createNewHabit() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: TextField(
          controller: textController,
          decoration: const InputDecoration(
            hintText: AppString.habitNameTextField,
          ),
        ),
        actions: [
          // save button
          MaterialButton(
            onPressed: () {
              // get the new habit name
              String newHabitName = textController.text;
              // save to db
              context.read<HabitDatabase>().addHabit(newHabitName);
              // pop box
              Navigator.pop(context);
              // clear controller
              textController.clear();
            },
            child: const Text(AppString.saveString),
          ),

          // cancel button
          MaterialButton(
            onPressed: () {
              // pop box
              Navigator.pop(context);
              // clear controller
              textController.clear();
            },
            child: const Text(AppString.cancelString),
          ),
        ],
      ),
    );
  }

  // check habit on & off
  void checkHabitOnOff(bool? value, Habit habit) {
    // update habit completion status
    if (value != null) {
      context.read<HabitDatabase>().updateHabitCompletion(habit.id, value);
    }
  }

  // edit habit box
  void editHabitBox(Habit habit) {
    // set the controller's text to the habit's current name
    textController.text = habit.name;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: TextField(controller: textController),
        actions: [
          // save button
          MaterialButton(
            onPressed: () {
              // get the habit name
              String newHabitName = textController.text;
              // save to db
              context.read<HabitDatabase>().updateHabitName(
                habit.id,
                newHabitName,
              );
              // pop box
              Navigator.pop(context);
              // clear controller
              textController.clear();
            },
            child: const Text(AppString.saveString),
          ),

          // cancel button
          MaterialButton(
            onPressed: () {
              // pop box
              Navigator.pop(context);
              // clear controller
              textController.clear();
            },
            child: const Text(AppString.cancelString),
          ),
        ],
      ),
    );
  }

  // delete habit box
  void deleteHabitBox(Habit habit) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppString.deleteHabitAlert),
        actions: [
          // delete button
          MaterialButton(
            onPressed: () {
              // save to db
              context.read<HabitDatabase>().deleteHabit(habit.id);
              // pop box
              Navigator.pop(context);
            },
            child: const Text(AppString.deleteString),
          ),

          // cancel button
          MaterialButton(
            onPressed: () {
              // pop box
              Navigator.pop(context);
            },
            child: const Text(AppString.cancelString),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      drawer: const MyDrawer(),
      floatingActionButton: FloatingActionButton(
        onPressed: createNewHabit,
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.tertiary,
        child: Icon(
          Icons.add,
          color: Theme.of(context).colorScheme.inversePrimary,
        ),
      ),
      body: ListView(
        children: [
          // heat map
          _buildHeatMap(),
          // habit list
          _buildHabitList(),
        ],
      ),
    );
  }

  Widget _buildHeatMap() {
    // habit database
    final habitDatabase = context.watch<HabitDatabase>();
    // current habits
    List<Habit> currentHabits = habitDatabase.currentHabits;
    // return heat map UI
    return FutureBuilder<DateTime?>(
      future: habitDatabase.getFirstLaunchDate(),
      builder: (context, snapshot) {
        // once the data is available -> build heat map
        if (snapshot.hasData) {
          return MyHeatMap(
            startDate: snapshot.data!,
            datasets: prepHeatMapDataSet(currentHabits),
          );
        } else {
          return Container();
        }
      },
    );
  }

  Widget _buildHabitList() {
    // habit db
    final habitDatabase = context.watch<HabitDatabase>();

    // current habits
    List<Habit> currentHabits = habitDatabase.currentHabits;

    // return list of habits UI
    return currentHabits.isEmpty
        ? Padding(
            padding: const EdgeInsets.symmetric(vertical: 30),
            child: Center(
              child: Text(
                AppString.createHabitString,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          )
        : ListView.builder(
            itemCount: currentHabits.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemBuilder: (context, index) {
              // get each individual habit
              final habit = currentHabits[index];
              // check if the habit is completed today
              bool isCompletedToday = isHabitCompletedToday(
                habit.completedDays,
              );
              // return habit title UI
              return MyHabitTile(
                isCompleted: isCompletedToday,
                text: habit.name,
                onChanged: (value) => checkHabitOnOff(value, habit),
                editHabit: (context) => editHabitBox(habit),
                deleteHabit: (context) => deleteHabitBox(habit),
              );
            },
          );
  }
}
