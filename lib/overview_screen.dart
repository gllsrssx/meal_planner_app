import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'day_detail.dart';

class OverviewScreen extends StatefulWidget {
  final DateTime initialStartDate;

  const OverviewScreen({super.key, required this.initialStartDate});

  @override
  State<OverviewScreen> createState() => _OverviewScreenState();
}

class _OverviewScreenState extends State<OverviewScreen> {
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
        backgroundColor: Theme.of(context).canvasColor,
        elevation: 4.0,
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
              // No need to calculate difference from Monday, as the week starts from 'today'
              final startOfWeek = today; // The week starts from today
              final difference =
                  startOfWeek.difference(widget.initialStartDate).inDays;
              final pageToJump = difference ~/ 7;
              _pageController.jumpToPage(pageToJump);
              setState(() {
                _currentStartDate = startOfWeek;
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
          setState(() {
            _currentStartDate =
                widget.initialStartDate.add(Duration(days: 7 * index));
          });
        },
        itemBuilder: (context, pageIndex) {
          final weekStartDate =
              widget.initialStartDate.add(Duration(days: 7 * pageIndex));
          return ListView.builder(
            itemCount: 7,
            itemBuilder: (context, index) {
              final day = weekStartDate.add(Duration(days: index));
              final dayName = DateFormat('EEEE d').format(day);
              return Padding(
                padding:
                    const EdgeInsets.all(3.0), // Adds outer padding to each row
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                        10.0), // Rounds the corners of the card
                  ),
                  child: ListTile(
                    contentPadding: EdgeInsets.symmetric(
                        vertical: 3.0,
                        horizontal: 6.0), // Adjusts ListTile padding
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          dayName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold, // Makes text bold
                            fontSize: 16, // Increases font size
                          ),
                        ),
                        FutureBuilder<Map<String, bool>>(
                          future: getMealsForDay(day),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const SizedBox(
                                width: 24,
                                height: 24,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              );
                            }
                            if (snapshot.hasData) {
                              final meals = snapshot.data!;
                              return Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (meals['breakfast'] == true)
                                    CircleAvatar(
                                      // Adds background to icons
                                      radius: 12,
                                      backgroundColor: Colors.blue[200],
                                      child: const Icon(Icons.free_breakfast,
                                          size: 16),
                                    ),
                                  if (meals['lunch'] == true)
                                    CircleAvatar(
                                      radius: 12,
                                      backgroundColor: Colors.green[200],
                                      child: const Icon(Icons.lunch_dining,
                                          size: 16),
                                    ),
                                  if (meals['dinner'] == true)
                                    CircleAvatar(
                                      radius: 12,
                                      backgroundColor: Colors.red[200],
                                      child: const Icon(Icons.dinner_dining,
                                          size: 16),
                                    ),
                                  if (meals['snack'] == true)
                                    CircleAvatar(
                                      radius: 12,
                                      backgroundColor: Colors.orange[200],
                                      child: const Icon(Icons.cookie, size: 16),
                                    ),
                                ],
                              );
                            }
                            return const SizedBox
                                .shrink(); // or any other placeholder
                          },
                        ),
                      ],
                    ),
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DayDetail(date: day),
                        ),
                      );
                      if (result == true) {
                        setState(() {
                          // Refresh the list
                        });
                      }
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<Map<String, bool>> getMealsForDay(DateTime day) async {
    final String? uid = FirebaseAuth.instance.currentUser?.uid;
    Map<String, bool> meals = {
      'breakfast': false,
      'lunch': false,
      'dinner': false,
      'snack': false
    };
    if (uid == null) {
      Fluttertoast.showToast(msg: 'User not logged in');
      return meals;
    }
    final String formattedDate = DateFormat('yyyy-MM-dd').format(day);
    try {
      final dateRef = FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('dates')
          .where('date', isEqualTo: formattedDate)
          .limit(1);
      final dateSnapshot = await dateRef.get();
      if (dateSnapshot.docs.isNotEmpty) {
        final String dateId = dateSnapshot.docs.first.id;
        final metadataRef = FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('metadata')
            .doc(dateId);
        final metadataSnapshot = await metadataRef.get();
        if (metadataSnapshot.exists) {
          final data = metadataSnapshot.data()!;
          meals['breakfast'] = data.containsKey('breakfast');
          meals['lunch'] = data.containsKey('lunch');
          meals['dinner'] = data.containsKey('dinner');
          meals['snack'] = data.containsKey('snack');
        }
      }
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error fetching meals for day: $e');
    }
    return meals;
  }
}
