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
import 'package:flutter/rendering.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Transaction> _transactions = [];
  double _balance = 0.0;
  final ScrollController _scrollController = ScrollController();
  bool _showFAB = true;
  int _batchSize = 20;
  int _loadedItems = 0;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _scrollController.addListener(_scrollListener);
  }

  void _loadInitialData() {
    final allTransactions = HiveService.getAllTransactions();
    setState(() {
      _transactions = allTransactions.take(_batchSize).toList();
      _loadedItems = _transactions.length;
      _balance = HiveService.getBalance();
    });
  }

  void _loadMoreTransactions() {
    final allTransactions = HiveService.getAllTransactions();
    if (_loadedItems >= allTransactions.length) return;

    final nextBatch =
        allTransactions.skip(_loadedItems).take(_batchSize).toList();
    setState(() {
      _transactions.addAll(nextBatch);
      _loadedItems = _transactions.length;
    });
  }

  void _scrollListener() {
    if (_scrollController.position.userScrollDirection ==
        ScrollDirection.reverse) {
      if (_showFAB) setState(() => _showFAB = false);
    } else if (_scrollController.position.userScrollDirection ==
        ScrollDirection.forward) {
      if (!_showFAB) setState(() => _showFAB = true);
    }

    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreTransactions();
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = HiveService.getUserSettings();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            CustomAppBar(
              onSettingsPressed: _navigateToSettings,
              onSummaryPressed: _navigateToSummary,
              onPeoplePressed: _navigateToPeopleManager,
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: ListView(
                  controller: _scrollController,
                  children: [
                    SizedBox(height: 16),
                    _buildGreeting(settings.name),
                    SizedBox(height: 24),
                    BalanceCard(
                      balance: _balance,
                      currency: settings.currency,
                    ),
                    SizedBox(height: 32),
                    _buildRecentTransactions(settings.currency),
                    SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: AnimatedOpacity(
        opacity: _showFAB ? 1.0 : 0.0,
        duration: Duration(milliseconds: 300),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            FloatingActionButton(
              heroTag: 'people_fab',
              onPressed: _showAddPeopleTransactionModal,
              backgroundColor: Colors.purple,
              child: Icon(Icons.people_outline, color: Colors.white),
            ),
            SizedBox(width: 16),
            FloatingActionButton.extended(
              heroTag: 'main_fab',
              onPressed: _showAddTransactionModal,
              icon: Icon(Icons.add),
              label: Text('Add Transaction'),
              backgroundColor: Theme.of(context).primaryColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGreeting(String name) {
    final hour = DateTime.now().hour;
    String greeting = (hour < 12)
        ? 'Good Morning'
        : (hour < 17)
            ? 'Good Afternoon'
            : 'Good Evening';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$greeting,',
          style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w300,
              color: Colors.grey[600]),
        ),
        Text(
          name,
          style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildRecentTransactions(String currency) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Transactions',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 16),
        if (_transactions.isEmpty)
          SizedBox(
            height: 200,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long_outlined,
                      size: 64, color: Colors.grey[400]),
                  SizedBox(height: 16),
                  Text('No transactions yet',
                      style: TextStyle(fontSize: 18, color: Colors.grey[600])),
                  SizedBox(height: 8),
                  Text('Tap the + button to add your first transaction',
                      style: TextStyle(fontSize: 14, color: Colors.grey[500])),
                ],
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: _transactions.length,
            itemBuilder: (context, index) {
              final transaction = _transactions[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: TransactionCard(
                  transaction: transaction,
                  currency: currency,
                  onEdit: () => _editTransaction(transaction, index),
                  onDelete: () => _deleteTransaction(index),
                ),
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
      builder: (_) => AddTransactionModal(
        onSave: (transaction) async {
          await HiveService.addTransaction(transaction);
          _loadInitialData();
        },
      ),
    );
  }

  void _showAddPeopleTransactionModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddPeopleTransactionModal(
        onSave: (transaction) async {
          await PeopleHiveService.addPeopleTransaction(transaction);
          _loadInitialData();
        },
      ),
    );
  }

  void _editTransaction(Transaction transaction, int index) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddTransactionModal(
        transaction: transaction,
        onSave: (updatedTransaction) async {
          await HiveService.updateTransaction(index, updatedTransaction);
          _loadInitialData();
        },
      ),
    );
  }

  void _deleteTransaction(int index) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
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
                if (transaction.id.endsWith('_main')) {
                  await PeopleHiveService.deletePeopleTransactionByMainId(
                      transaction.id);
                }
                await HiveService.deleteTransaction(index);
                Navigator.pop(context);
                _loadInitialData();
              }
            },
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _navigateToSettings() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => SettingsScreen()))
        .then((_) => _loadInitialData());
  }

  void _navigateToSummary() {
    Navigator.push(
        context, MaterialPageRoute(builder: (_) => MonthlySummaryScreen()));
  }

  void _navigateToPeopleManager() {
    Navigator.push(
            context, MaterialPageRoute(builder: (_) => PeopleManagerScreen()))
        .then((_) => _loadInitialData());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
