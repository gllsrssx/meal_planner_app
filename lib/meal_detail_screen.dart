import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class MealDetailScreen extends StatefulWidget {
  final String date;

  const MealDetailScreen(this.date, {super.key});

  @override
  // ignore: library_private_types_in_public_api
  _MealDetailScreenState createState() => _MealDetailScreenState();
}

class _MealDetailScreenState extends State<MealDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _ontbijtController = TextEditingController();
  final _lunchController = TextEditingController();
  final _avondetenController = TextEditingController();

  @override
  void dispose() {
    _ontbijtController.dispose();
    _lunchController.dispose();
    _avondetenController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Maaltijd voor ${widget.date}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: <Widget>[
              TextFormField(
                controller: _ontbijtController,
                decoration: const InputDecoration(labelText: 'Ontbijt'),
              ),
              TextFormField(
                controller: _lunchController,
                decoration: const InputDecoration(labelText: 'Lunch'),
              ),
              TextFormField(
                controller: _avondetenController,
                decoration: const InputDecoration(labelText: 'Avondeten'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    FirebaseFirestore.instance
                        .collection('meals')
                        .doc(widget.date)
                        .set({
                      'ontbijt': _ontbijtController.text,
                      'lunch': _lunchController.text,
                      'avondeten': _avondetenController.text,
                    });
                    Navigator.pop(context);
                  }
                },
                child: const Text('Opslaan'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
