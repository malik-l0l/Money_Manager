import 'package:flutter/material.dart';
import '../services/hive_service.dart';
import '../services/people_hive_service.dart';
import '../models/transaction.dart';
import '../widgets/balance_card.dart';
import '../widgets/transaction_card.dart';
import '../widgets/add_transaction_modal.dart';
import '../widgets/add_people_transaction_modal.dart';
import '../widgets/custom_app_bar.dart';
import 'settings_screen.dart';
import 'monthly_summary_screen.dart';
import 'people_manager_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Transaction> _transactions = [];
  double _balance = 0.0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      _transactions = HiveService.getAllTransactions();
      _balance = HiveService.getBalance();
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = HiveService.getUserSettings();
    final recentTransactions = _transactions.take(5).toList();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            CustomAppBar(
              onSettingsPressed: () => _navigateToSettings(),
              onSummaryPressed: () => _navigateToSummary(),
              onPeoplePressed: () => _navigateToPeopleManager(),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildGreeting(settings.name),
                    SizedBox(height: 24),
                    BalanceCard(
                      balance: _balance,
                      currency: settings.currency,
                    ),
                    SizedBox(height: 32),
                    _buildRecentTransactions(recentTransactions, settings.currency),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // People Transaction Button
          Container(
            margin: EdgeInsets.only(bottom: 16),
            child: FloatingActionButton(
              onPressed: _showAddPeopleTransactionModal,
              heroTag: "people_fab",
              backgroundColor: Colors.purple,
              child: Icon(Icons.people_outline, color: Colors.white),
            ),
          ),
          // Main Transaction Button
          FloatingActionButton.extended(
            onPressed: _showAddTransactionModal,
            heroTag: "main_fab",
            icon: Icon(Icons.add),
            label: Text('Add Transaction'),
            backgroundColor: Theme.of(context).primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildGreeting(String name) {
    final hour = DateTime.now().hour;
    String greeting;
    
    if (hour < 12) {
      greeting = 'Good Morning';
    } else if (hour < 17) {
      greeting = 'Good Afternoon';
    } else {
      greeting = 'Good Evening';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$greeting,',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w300,
            color: Colors.grey[600],
          ),
        ),
        Text(
          name,
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildRecentTransactions(List<Transaction> transactions, String currency) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Transactions',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (transactions.length > 5)
              TextButton(
                onPressed: () => _navigateToSummary(),
                child: Text('View All'),
              ),
          ],
        ),
        SizedBox(height: 16),
        if (transactions.isEmpty)
          Container(
            height: 200,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No transactions yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Tap the + button to add your first transaction',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: transactions.length,
            itemBuilder: (context, index) {
              final transaction = transactions[index];
              return TransactionCard(
                transaction: transaction,
                currency: currency,
                onEdit: () => _editTransaction(transaction, index),
                onDelete: () => _deleteTransaction(index),
              );
            },
          ),
      ],
    );
  }

  void _showAddTransactionModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddTransactionModal(
        onSave: (transaction) async {
          await HiveService.addTransaction(transaction);
          _loadData();
        },
      ),
    );
  }

  void _showAddPeopleTransactionModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddPeopleTransactionModal(
        onSave: (transaction) async {
          await PeopleHiveService.addPeopleTransaction(transaction);
          _loadData();
        },
      ),
    );
  }

  void _editTransaction(Transaction transaction, int index) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddTransactionModal(
        transaction: transaction,
        onSave: (updatedTransaction) async {
          await HiveService.updateTransaction(index, updatedTransaction);
          _loadData();
        },
      ),
    );
  }

  void _deleteTransaction(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Transaction'),
        content: Text('Are you sure you want to delete this transaction?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final allTransactions = HiveService.getAllTransactions();
              if (index >= 0 && index < allTransactions.length) {
                final transaction = allTransactions[index];
                
                // Check if this is a people transaction (has _main suffix)
                if (transaction.id.endsWith('_main')) {
                  // This is a people transaction, delete from people manager too
                  await PeopleHiveService.deletePeopleTransactionByMainId(transaction.id);
                }
                
                // Delete the main transaction
                await HiveService.deleteTransaction(index);
                Navigator.pop(context);
                _loadData();
              }
            },
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _navigateToSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SettingsScreen()),
    ).then((_) => _loadData());
  }

  void _navigateToSummary() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => MonthlySummaryScreen()),
    );
  }

  void _navigateToPeopleManager() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PeopleManagerScreen()),
    ).then((_) => _loadData()); // Reload data when returning from people manager
  }
}