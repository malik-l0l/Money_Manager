import 'package:hive_flutter/hive_flutter.dart';
import '../models/people_transaction.dart';
import '../models/person_summary.dart';
import '../utils/constants.dart';

class PeopleHiveService {
  static late Box<PeopleTransaction> _peopleTransactionsBox;

  static Future<void> init() async {
    _peopleTransactionsBox = await Hive.openBox<PeopleTransaction>(AppConstants.peopleTransactionsBox);
  }

  // Add a new people transaction
  static Future<void> addPeopleTransaction(PeopleTransaction transaction) async {
    await _peopleTransactionsBox.put(transaction.id, transaction);
  }

  // Get all people transactions
  static List<PeopleTransaction> getAllPeopleTransactions() {
    return _peopleTransactionsBox.values.toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  // Get transactions for a specific person
  static List<PeopleTransaction> getTransactionsForPerson(String personName) {
    return _peopleTransactionsBox.values
        .where((transaction) => transaction.personName.toLowerCase() == personName.toLowerCase())
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  // Get all unique people with their summaries
  static List<PersonSummary> getAllPeopleSummaries() {
    final Map<String, List<PeopleTransaction>> peopleTransactions = {};
    
    // Group transactions by person
    for (final transaction in _peopleTransactionsBox.values) {
      final name = transaction.personName.toLowerCase();
      if (!peopleTransactions.containsKey(name)) {
        peopleTransactions[name] = [];
      }
      peopleTransactions[name]!.add(transaction);
    }

    // Create summaries
    final summaries = <PersonSummary>[];
    for (final entry in peopleTransactions.entries) {
      final transactions = entry.value;
      final totalBalance = transactions.fold<double>(
        0.0, 
        (sum, transaction) => sum + transaction.balanceImpact,
      );
      
      final lastTransaction = transactions
          .reduce((a, b) => a.timestamp.isAfter(b.timestamp) ? a : b);

      summaries.add(PersonSummary(
        name: transactions.first.personName, // Use original case
        totalBalance: totalBalance,
        transactionCount: transactions.length,
        lastTransactionDate: lastTransaction.timestamp,
      ));
    }

    // Sort by last transaction date (most recent first)
    summaries.sort((a, b) => b.lastTransactionDate.compareTo(a.lastTransactionDate));
    return summaries;
  }

  // Update a people transaction
  static Future<void> updatePeopleTransaction(String id, PeopleTransaction transaction) async {
    await _peopleTransactionsBox.put(id, transaction);
  }

  // Delete a people transaction
  static Future<void> deletePeopleTransaction(String id) async {
    await _peopleTransactionsBox.delete(id);
  }

  // Get balance for a specific person
  static double getBalanceForPerson(String personName) {
    final transactions = getTransactionsForPerson(personName);
    return transactions.fold<double>(
      0.0, 
      (sum, transaction) => sum + transaction.balanceImpact,
    );
  }

  // Get total amount you've given to all people
  static double getTotalGiven() {
    return _peopleTransactionsBox.values
        .where((transaction) => transaction.isGiven)
        .fold<double>(0.0, (sum, transaction) => sum + transaction.amount);
  }

  // Get total amount you've taken from all people
  static double getTotalTaken() {
    return _peopleTransactionsBox.values
        .where((transaction) => !transaction.isGiven)
        .fold<double>(0.0, (sum, transaction) => sum + transaction.amount);
  }

  // Get net balance (positive means people owe you, negative means you owe people)
  static double getNetBalance() {
    return _peopleTransactionsBox.values
        .fold<double>(0.0, (sum, transaction) => sum + transaction.balanceImpact);
  }

  // Clear all people transactions (for testing/reset)
  static Future<void> clearAllPeopleTransactions() async {
    await _peopleTransactionsBox.clear();
  }
}