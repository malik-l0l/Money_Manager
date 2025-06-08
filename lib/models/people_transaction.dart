import 'package:hive/hive.dart';

part 'people_transaction.g.dart';

@HiveType(typeId: 2)
class PeopleTransaction extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String personName;

  @HiveField(2)
  double amount;

  @HiveField(3)
  String reason;

  @HiveField(4)
  DateTime date;

  @HiveField(5)
  DateTime timestamp;

  @HiveField(6)
  bool isGiven; // true if you gave money, false if you took money

  PeopleTransaction({
    required this.id,
    required this.personName,
    required this.amount,
    required this.reason,
    required this.date,
    required this.timestamp,
    required this.isGiven,
  });

  // Calculate the balance for this person
  // Positive means they owe you, negative means you owe them
  double get balanceImpact => isGiven ? amount : -amount;

  String get displayText {
    if (isGiven) {
      return "Take ₹${amount.toStringAsFixed(2)} from $personName";
    } else {
      return "Give ₹${amount.toStringAsFixed(2)} back to $personName";
    }
  }
}