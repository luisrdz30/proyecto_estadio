import 'package:flutter/material.dart';
import '../models/event.dart';

class EventDetailScreen extends StatelessWidget {
  final Event event;

  const EventDetailScreen({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(event.title)),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.network(event.image,
                fit: BoxFit.cover, width: double.infinity, height: 220),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(event.title,
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(event.date, style: const TextStyle(color: Colors.grey)),
                  Text(event.place, style: const TextStyle(color: Colors.grey)),
                  const SizedBox(height: 16),
                  Text(event.description),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () {
                      // Aquí luego irá el flujo de compra
                    },
                    icon: const Icon(Icons.shopping_cart),
                    label: Text("Comprar entrada - \$${event.price}"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
