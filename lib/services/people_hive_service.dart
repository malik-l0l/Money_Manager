import 'package:hive_flutter/hive_flutter.dart';
import '../models/people_transaction.dart';
import '../models/person_summary.dart';
import '../models/transaction.dart';
import '../utils/constants.dart';
import 'hive_service.dart';

class PeopleHiveService {
  static late Box<PeopleTransaction> _peopleTransactionsBox;

  static Future<void> init() async {
    _peopleTransactionsBox = await Hive.openBox<PeopleTransaction>(AppConstants.peopleTransactionsBox);
  }

  // Add a new people transaction and update main transaction history
  static Future<void> addPeopleTransaction(PeopleTransaction transaction) async {
    await _peopleTransactionsBox.put(transaction.id, transaction);
    
    // Only add to main transaction history (balance will be updated automatically by the transaction)
    await _updateMainTransactionHistory(transaction);
  }

  // Update a people transaction and adjust main transaction history
  static Future<void> updatePeopleTransaction(String id, PeopleTransaction newTransaction) async {
    final oldTransaction = _peopleTransactionsBox.get(id);
    
    if (oldTransaction != null) {
      // Remove the old transaction's effect from main history
      await _removeMainTransactionHistory(oldTransaction);
    }
    
    // Apply the new transaction
    await _peopleTransactionsBox.put(id, newTransaction);
    await _updateMainTransactionHistory(newTransaction);
  }

  // Delete a people transaction and adjust main transaction history
  static Future<void> deletePeopleTransaction(String id) async {
    final transaction = _peopleTransactionsBox.get(id);
    
    if (transaction != null) {
      // Remove the transaction's effect from main history
      await _removeMainTransactionHistory(transaction);
      await _peopleTransactionsBox.delete(id);
    }
  }

  // Delete people transaction by main transaction ID (for bidirectional sync)
  static Future<void> deletePeopleTransactionByMainId(String mainTransactionId) async {
    // Find the people transaction that corresponds to this main transaction
    final peopleTransactionId = mainTransactionId.replaceAll('_main', '');
    final peopleTransaction = _peopleTransactionsBox.get(peopleTransactionId);
    
    if (peopleTransaction != null) {
      await _peopleTransactionsBox.delete(peopleTransactionId);
    }
  }

  // Check if a people transaction exists for a main transaction ID
  static bool peopleTransactionExistsForMainId(String mainTransactionId) {
    final peopleTransactionId = mainTransactionId.replaceAll('_main', '');
    return _peopleTransactionsBox.containsKey(peopleTransactionId);
  }

  // Add entry to main transaction history (balance will be updated automatically)
  static Future<void> _updateMainTransactionHistory(PeopleTransaction peopleTransaction) async {
    // Calculate the amount for main transaction (negative for giving, positive for taking)
    final mainTransactionAmount = peopleTransaction.isGiven 
        ? -peopleTransaction.amount  // Giving money reduces main balance
        : peopleTransaction.amount;  // Taking money increases main balance
    
    // Create a main transaction entry
    final mainTransaction = Transaction(
      id: '${peopleTransaction.id}_main',
      date: peopleTransaction.date,
      amount: mainTransactionAmount,
      reason: peopleTransaction.isGiven 
          ? 'Give money to "${peopleTransaction.personName}" for "${peopleTransaction.reason}"'
          : 'Take money from "${peopleTransaction.personName}" for "${peopleTransaction.reason}"',
      timestamp: peopleTransaction.timestamp,
    );
    
    // Add to main transaction history (this will automatically update the balance)
    await HiveService.addTransaction(mainTransaction);
  }

  // Remove the corresponding main transaction from history
  static Future<void> _removeMainTransactionHistory(PeopleTransaction peopleTransaction) async {
    // Find and remove the corresponding main transaction
    final mainTransactionId = '${peopleTransaction.id}_main';
    await HiveService.deleteTransactionById(mainTransactionId);
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