import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'day_detail.dart';

class WeekOverview extends StatelessWidget {
  final DateTime startDate;

  const WeekOverview({super.key, required this.startDate});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Week Overview'),
      ),
      body: ListView.builder(
        itemCount: 7,
        itemBuilder: (context, index) {
          final day = startDate.add(Duration(days: index));
          final dayName = DateFormat('EEEE').format(day); // Get the day name
          return ListTile(
            title: Text(dayName),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Breakfast: ${getMeal(day, 'breakfast')}'),
                Text('Lunch: ${getMeal(day, 'lunch')}'),
                Text('Dinner: ${getMeal(day, 'dinner')}'),
              ],
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DayDetail(date: day),
                ),
              );
            },
          );
        },
      ),
    );
  }

  String getMeal(DateTime day, String mealType) {
    // Mock data for demonstration
    return 'Example meal';
  }
}
