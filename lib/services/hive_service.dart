import 'package:hive_flutter/hive_flutter.dart';
import '../models/transaction.dart';
import '../models/user_settings.dart';

class HiveService {
  static late Box<Transaction> _transactionBox;
  static late Box<UserSettings> _userSettingsBox;
  static late Box<double> _balanceBox;
  
  static Box<Transaction> get transactionBox => _transactionBox;
  static Box<UserSettings> get userSettingsBox => _userSettingsBox;
  static Box<double> get balanceBox => _balanceBox;
  
  static Future<void> init() async {
    _transactionBox = await Hive.openBox<Transaction>('transactions');
    _userSettingsBox = await Hive.openBox<UserSettings>('userSettings');
    _balanceBox = await Hive.openBox<double>('balance');
    
    // Initialize user settings if empty
    if (_userSettingsBox.isEmpty) {
      await _userSettingsBox.put('settings', UserSettings());
    }
    
    // Initialize balance if empty
    if (_balanceBox.isEmpty) {
      await _balanceBox.put('balance', 0.0);
    }
  }
  
  static UserSettings getUserSettings() {
    return _userSettingsBox.get('settings', defaultValue: UserSettings())!;
  }
  
  static Future<void> updateUserSettings(UserSettings settings) async {
    await _userSettingsBox.put('settings', settings);
  }
  
  static double getBalance() {
    return _balanceBox.get('balance', defaultValue: 0.0)!;
  }
  
  static Future<void> updateBalance(double balance) async {
    await _balanceBox.put('balance', balance);
  }
  
  static Future<void> addTransaction(Transaction transaction) async {
    await _transactionBox.add(transaction);
    
    // Update balance
    final currentBalance = getBalance();
    final newBalance = currentBalance + transaction.amount;
    await updateBalance(newBalance);
  }
  
  static Future<void> updateTransaction(int index, Transaction transaction) async {
    final oldTransaction = _transactionBox.getAt(index);
    if (oldTransaction != null) {
      // Revert old transaction from balance
      final currentBalance = getBalance();
      final revertedBalance = currentBalance - oldTransaction.amount;
      
      // Apply new transaction to balance
      final newBalance = revertedBalance + transaction.amount;
      
      await _transactionBox.putAt(index, transaction);
      await updateBalance(newBalance);
    }
  }
  
  static Future<void> deleteTransaction(int index) async {
    final transaction = _transactionBox.getAt(index);
    if (transaction != null) {
      // Revert transaction from balance
      final currentBalance = getBalance();
      final newBalance = currentBalance - transaction.amount;
      
      await _transactionBox.deleteAt(index);
      await updateBalance(newBalance);
    }
  }
  
  static List<Transaction> getAllTransactions() {
    return _transactionBox.values.toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }
  
  static List<Transaction> getMonthlyTransactions(DateTime month) {
    final transactions = getAllTransactions();
    return transactions.where((t) => 
      t.date.year == month.year && t.date.month == month.month
    ).toList();
  }
}
