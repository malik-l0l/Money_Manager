import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../services/hive_service.dart';
import '../models/transaction.dart';
import '../widgets/balance_card.dart';
import '../widgets/transaction_card.dart';
import '../widgets/add_transaction_modal.dart';
import '../widgets/custom_app_bar.dart';
import 'settings_screen.dart';
import 'monthly_summary_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            CustomAppBar(
              onSettingsPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SettingsScreen()),
                );
              },
              onSummaryPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => MonthlySummaryScreen()),
                );
              },
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ValueListenableBuilder(
                      valueListenable: HiveService.userSettingsBox.listenable(),
                      builder: (context, box, child) {
                        final settings = HiveService.getUserSettings();
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome back,',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                              ),
                            ),
                            Text(
                              settings.name,
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    SizedBox(height: 24),
                    ValueListenableBuilder(
                      valueListenable: HiveService.balanceBox.listenable(),
                      builder: (context, box, child) {
                        final balance = HiveService.getBalance();
                        final settings = HiveService.getUserSettings();
                        return BalanceCard(
                          balance: balance,
                          currency: settings.currency,
                        );
                      },
                    ),
                    SizedBox(height: 32),
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
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => MonthlySummaryScreen()),
                            );
                          },
                          child: Text('View All'),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    ValueListenableBuilder(
                      valueListenable: HiveService.transactionBox.listenable(),
                      builder: (context, box, child) {
                        final transactions = HiveService.getAllTransactions();
                        final settings = HiveService.getUserSettings();
                        
                        if (transactions.isEmpty) {
                          return SizedBox(
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
                                    'Add your first transaction!',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }
                        
                        return ListView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemCount: transactions.length > 5 ? 5 : transactions.length,
                          itemBuilder: (context, index) {
                            final transaction = transactions[index];
                            return TransactionCard(
                              transaction: transaction,
                              currency: settings.currency,
                              onEdit: () => _editTransaction(transaction, index),
                              onDelete: () => _deleteTransaction(index),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTransactionModal(),
        backgroundColor: Theme.of(context).primaryColor,
        child: Icon(Icons.add, color: Colors.white),
      ),
    );
  }
  
  void _showAddTransactionModal({Transaction? transaction, int? index}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddTransactionModal(
        transaction: transaction,
        onSave: (newTransaction) async {
          if (index != null) {
            await HiveService.updateTransaction(index, newTransaction);
          } else {
            await HiveService.addTransaction(newTransaction);
          }
        },
      ),
    );
  }
  
  void _editTransaction(Transaction transaction, int index) {
    _showAddTransactionModal(transaction: transaction, index: index);
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
              await HiveService.deleteTransaction(index);
              Navigator.pop(context);
            },
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
