import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'day_detail.dart';

class WeekOverview extends StatefulWidget {
  final DateTime initialStartDate;

  const WeekOverview({super.key, required this.initialStartDate});

  @override
  State<WeekOverview> createState() => _WeekOverviewState();
}

class _WeekOverviewState extends State<WeekOverview> {
  late PageController _pageController;
  late DateTime _currentStartDate;

  @override
  void initState() {
    super.initState();
    _currentStartDate = widget.initialStartDate;
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
            '${DateFormat('MMMM dd').format(_currentStartDate)} - ${DateFormat('dd').format(_currentStartDate.add(const Duration(days: 6)))}'),
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_left),
          onPressed: () {
            _pageController.previousPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut);
          },
        ),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.today),
            onPressed: () {
              final today = DateTime.now();
              final difference =
                  today.difference(widget.initialStartDate).inDays;
              final pageToJump = difference ~/ 7;
              _pageController.jumpToPage(pageToJump);
              setState(() {
                _currentStartDate = DateTime.now()
                    .subtract(Duration(days: DateTime.now().weekday - 1));
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.arrow_right),
            onPressed: () {
              _pageController.nextPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut);
            },
          ),
        ],
      ),
      body: PageView.builder(
        controller: _pageController,
        onPageChanged: (index) {
          // Update the start date based on the page index
          setState(() {
            _currentStartDate =
                widget.initialStartDate.add(Duration(days: 7 * index));
          });
        },
        itemBuilder: (context, pageIndex) {
          // Calculate the start date for the current week page
          final weekStartDate =
              widget.initialStartDate.add(Duration(days: 7 * pageIndex));
          return ListView.builder(
            itemCount: 7,
            itemBuilder: (context, index) {
              final day = weekStartDate.add(Duration(days: index));
              final dayName = DateFormat('EEEE, d').format(day);
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
