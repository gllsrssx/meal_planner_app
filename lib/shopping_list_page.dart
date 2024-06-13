import 'package:flutter/material.dart';

class ShoppingListPage extends StatelessWidget {
  final List<String> ingredients = [
    'Eggs',
    'Milk',
    'Bread',
    'Chicken',
    'Tomatoes',
    'Lettuce',
    'Cheese'
  ];

  ShoppingListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shopping List'),
        backgroundColor: Colors.deepPurple,
      ),
      body: ListView.builder(
        itemCount: ingredients.length,
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: ListTile(
              leading: const Icon(Icons.shopping_cart, color: Colors.green),
              title: Text(ingredients[index],
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          );
        },
      ),
    );
  }
}
