import 'package:flutter/foundation.dart';

@immutable
class Event {
  final String title;
  final String date;
  final String place;
  final String image;
  final String description;
  final double price;

  const Event({
    required this.title,
    required this.date,
    required this.place,
    required this.image,
    required this.description,
    required this.price,
  });

  @override
  String toString() {
    return "Event(title: $title, date: $date, place: $place, price: $price)";
  }
}
