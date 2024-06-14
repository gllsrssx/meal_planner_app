import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';

class DayDetail extends StatefulWidget {
  final DateTime date;

  const DayDetail({super.key, required this.date});

  @override
  _DayDetailState createState() => _DayDetailState();
}

class _DayDetailState extends State<DayDetail> {
  final TextEditingController _breakfastController = TextEditingController();
  final TextEditingController _lunchController = TextEditingController();
  final TextEditingController _dinnerController = TextEditingController();
  final TextEditingController _snackController =
      TextEditingController(); // Snack controller
  bool _isLoading = false; // To track loading state

  @override
  void initState() {
    super.initState();
    fetchAndSetLastMeals();
  }

  Future<void> fetchAndSetLastMeals() async {
    final breakfastMeals = await _fetchPastMeals('breakfast');
    if (breakfastMeals.isNotEmpty) {
      _breakfastController.text = breakfastMeals.last;
    }

    final lunchMeals = await _fetchPastMeals('lunch');
    if (lunchMeals.isNotEmpty) {
      _lunchController.text = lunchMeals.last;
    }

    final dinnerMeals = await _fetchPastMeals('dinner');
    if (dinnerMeals.isNotEmpty) {
      _dinnerController.text = dinnerMeals.last;
    }

    final snackMeals = await _fetchPastMeals('snack');
    if (snackMeals.isNotEmpty) {
      _snackController.text = snackMeals.last;
    }
  }

  Future<void> _saveMealData() async {
    setState(() {
      _isLoading = true;
    });
    try {
      await Future.wait([
        if (_breakfastController.text.isNotEmpty)
          saveMealIfNotExists('breakfast', _breakfastController),
        if (_lunchController.text.isNotEmpty)
          saveMealIfNotExists('lunch', _lunchController),
        if (_dinnerController.text.isNotEmpty)
          saveMealIfNotExists('dinner', _dinnerController),
        if (_snackController.text.isNotEmpty) // Save snack if not empty
          saveMealIfNotExists('snack', _snackController),
      ]);
      Fluttertoast.showToast(msg: "Meals saved successfully!");
      Navigator.pop(context); // Navigate back after saving
    } catch (e) {
      Fluttertoast.showToast(msg: "Error saving meals: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> saveMealIfNotExists(
      String mealType, TextEditingController controller) async {
    final String formattedDate = DateFormat('yyyy-MM-dd').format(widget.date);
    final String? uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final querySnapshot = await FirebaseFirestore.instance
        .collection('meals')
        .where('date', isEqualTo: formattedDate)
        .where('mealType', isEqualTo: mealType)
        .where('name', isEqualTo: controller.text)
        .where('uid', isEqualTo: uid)
        .get();

    if (querySnapshot.docs.isEmpty) {
      await FirebaseFirestore.instance.collection('meals').add({
        'name': controller.text,
        'date': formattedDate,
        'mealType': mealType,
        'uid': uid,
      });
    }
  }

  Future<List<String>> _fetchPastMeals(String? mealType) async {
    final String formattedDate = DateFormat('yyyy-MM-dd').format(widget.date);
    final String? uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return [];

    final querySnapshot = await FirebaseFirestore.instance
        .collection('meals')
        .where('date', isEqualTo: formattedDate)
        .where('mealType', isEqualTo: mealType)
        .where('uid', isEqualTo: uid)
        .get();

    List<String> mealNames = [];
    for (var doc in querySnapshot.docs) {
      mealNames.add(doc.data()['name'] as String);
    }
    return mealNames;
  }

  Future<void> _showMealSelectionDialog(
      TextEditingController controller, String mealType) async {
    final List<String> pastMeals = await _fetchPastMeals(mealType);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Select a $mealType'),
          content: SingleChildScrollView(
            child: ListBody(
              children: pastMeals.map((String meal) {
                return GestureDetector(
                  child: Text(meal),
                  onTap: () {
                    controller.text = meal;
                    Navigator.of(context).pop();
                  },
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMealInputRow(String label, IconData icon,
      TextEditingController controller, String mealType) {
    return Row(
      children: [
        Icon(icon),
        const SizedBox(width: 8),
        Expanded(
          child: TextField(
            controller: controller,
            decoration: InputDecoration(labelText: label),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.arrow_drop_down),
          onPressed: () => _showMealSelectionDialog(controller, mealType),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(DateFormat('EEEE, d MMM y').format(widget.date)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildMealInputRow('Breakfast', Icons.breakfast_dining,
                _breakfastController, 'breakfast'),
            _buildMealInputRow(
                'Lunch', Icons.lunch_dining, _lunchController, 'lunch'),
            _buildMealInputRow(
                'Dinner', Icons.dinner_dining, _dinnerController, 'dinner'),
            _buildMealInputRow('Snack', Icons.cookie, _snackController,
                'snack'), // Snack input row
            const SizedBox(height: 20),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _saveMealData,
                    child: const Text('Save and Back'),
                  ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Back without saving'),
            ),
          ],
        ),
      ),
    );
  }
}
