import 'package:flutter/material.dart';

class DayDetail extends StatelessWidget {
  final DateTime date;

  const DayDetail({super.key, required this.date});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${date.weekday}, ${date.day} ${date.month} ${date.year}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.breakfast_dining),
                const SizedBox(width: 8),
                const Expanded(
                  child: TextField(
                    decoration: InputDecoration(labelText: 'Breakfast'),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_drop_down),
                  onPressed: () {
                    // Implement meal selection from past entries
                  },
                ),
              ],
            ),
            Row(
              children: [
                const Icon(Icons.lunch_dining),
                const SizedBox(width: 8),
                const Expanded(
                  child: TextField(
                    decoration: InputDecoration(labelText: 'Lunch'),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_drop_down),
                  onPressed: () {
                    // Implement meal selection from past entries
                  },
                ),
              ],
            ),
            Row(
              children: [
                const Icon(Icons.dinner_dining),
                const SizedBox(width: 8),
                const Expanded(
                  child: TextField(
                    decoration: InputDecoration(labelText: 'Dinner'),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_drop_down),
                  onPressed: () {
                    // Implement meal selection from past entries
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Save changes
                Navigator.pop(context);
              },
              child: const Text('Save and Back'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Back without saving'),
            ),
          ],
        ),
      ),
    );
  }
}
