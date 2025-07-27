import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/hive_service.dart';
import '../services/people_hive_service.dart';
import '../models/transaction.dart';
import '../models/daily_transaction_group.dart';
import '../widgets/balance_card.dart';
import '../widgets/transaction_card.dart';
import '../widgets/date_header.dart';
import '../widgets/add_transaction_modal.dart';
import '../widgets/add_people_transaction_modal.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/custom_snackbar.dart';
import 'settings_screen.dart';
import 'monthly_summary_screen.dart';
import 'people_manager_screen.dart';
import 'package:flutter/rendering.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  List<Transaction> _allTransactions = [];
  List<DailyTransactionGroup> _displayedGroups = [];
  List<DailyTransactionGroup> _allGroups = [];
  double _balance = 0.0;
  late ScrollController _scrollController;
  late AnimationController _fabAnimationController;
  late Animation<double> _fabAnimation;
  bool _showFabs = true;
  bool _isLoadingMore = false;
  int _currentPage = 0;
  static const int _itemsPerPage = 10;

  @override
  void initState() {
    super.initState();
    _loadData();

    // Initialize scroll controller and animation
    _scrollController = ScrollController();
    _fabAnimationController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );

    _fabAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fabAnimationController,
      curve: Curves.easeInOut,
    ));

    _fabAnimationController.forward();

    // Add scroll listener for FAB animation and pagination
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _fabAnimationController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // FAB animation logic
    if (_scrollController.position.userScrollDirection ==
        ScrollDirection.reverse) {
      if (_showFabs) {
        setState(() {
          _showFabs = false;
        });
        _fabAnimationController.reverse();
      }
    } else if (_scrollController.position.userScrollDirection ==
        ScrollDirection.forward) {
      if (!_showFabs) {
        setState(() {
          _showFabs = true;
        });
        _fabAnimationController.forward();
      }
    }

    // Pagination logic
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreGroups();
    }
  }

  void _loadData() {
    setState(() {
      _allTransactions = HiveService.getAllTransactions();
      _balance = HiveService.getBalance();
      _allGroups =
          DailyTransactionGroup.groupTransactionsByDate(_allTransactions);
      _currentPage = 0;
      _displayedGroups = [];
      _loadMoreGroups();
    });
  }

  void _loadMoreGroups() {
    if (_isLoadingMore || _displayedGroups.length >= _allGroups.length) return;

    setState(() {
      _isLoadingMore = true;
    });

    // Simulate loading delay for smooth UX
    Future.delayed(Duration(milliseconds: 100), () {
      if (mounted) {
        setState(() {
          final startIndex = _currentPage * _itemsPerPage;
          final endIndex =
              (startIndex + _itemsPerPage).clamp(0, _allGroups.length);

          if (startIndex < _allGroups.length) {
            _displayedGroups.addAll(_allGroups.sublist(startIndex, endIndex));
            _currentPage++;
          }

          _isLoadingMore = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = HiveService.getUserSettings();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            CustomAppBar(
              onSettingsPressed: () => _navigateToSettings(),
              onSummaryPressed: () => _navigateToSummary(),
              onPeoplePressed: () => _navigateToPeopleManager(),
              userName: settings.name,
            ),
            Expanded(
              child: CustomScrollView(
                controller: _scrollController,
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          BalanceCard(
                            balance: _balance,
                            currency: settings.currency,
                          ),
                          SizedBox(height: 5),
                        ],
                      ),
                    ),
                  ),
                  _buildGroupedTransactionsList(settings.currency),
                  if (_isLoadingMore)
                    SliverToBoxAdapter(
                      child: Container(
                        padding: EdgeInsets.all(16),
                        child: Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
                    ),
                  // Add some bottom padding for FABs
                  SliverToBoxAdapter(
                    child: SizedBox(height: 100),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildFloatingActionButtons(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildGroupedTransactionsList(String currency) {
    if (_allTransactions.isEmpty) {
      return SliverToBoxAdapter(
        child: Container(
          height: 300,
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
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, groupIndex) {
          if (groupIndex >= _displayedGroups.length) return null;

          final group = _displayedGroups[groupIndex];
          final List<Widget> children = [];

          // Add date header
          children.add(
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: DateHeader(
                date: group.date,
                totalIncome: group.totalIncome,
                totalExpenses: group.totalExpenses,
              ),
            ),
          );

          // Add transactions for this date
          for (int i = 0; i < group.transactions.length; i++) {
            final transaction = group.transactions[i];
            final transactionIndex = _findTransactionIndex(transaction);

            children.add(
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: TransactionCard(
                  transaction: transaction,
                  currency: currency,
                  onEdit: () => _editTransaction(transaction, transactionIndex),
                  onDelete: () => _deleteTransaction(transactionIndex),
                ),
              ),
            );
          }

          return Column(children: children);
        },
        childCount: _displayedGroups.length,
      ),
    );
  }

  int _findTransactionIndex(Transaction transaction) {
    return _allTransactions.indexWhere((t) => t.id == transaction.id);
  }

  Widget _buildFloatingActionButtons() {
    return AnimatedBuilder(
      animation: _fabAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, (1 - _fabAnimation.value) * 100),
          child: Opacity(
            opacity: _fabAnimation.value,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // People Transaction FAB
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.purple.withOpacity(0.3),
                        blurRadius: 12,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: FloatingActionButton(
                    onPressed: _showAddPeopleTransactionModal,
                    heroTag: "people_fab",
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    child: Icon(Icons.person_add, size: 24),
                  ),
                ),
                SizedBox(width: 16),
                // Main Transaction FAB
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context).primaryColor.withOpacity(0.3),
                        blurRadius: 12,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: GestureDetector(
                    onTap: () => _showAddTransactionModal(
                        false), // false = expense (default)
                    onLongPress: () =>
                        _showAddTransactionModal(true), // true = income
                    child: FloatingActionButton(
                      onPressed: null, // Handled by GestureDetector
                      heroTag: "main_fab",
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      child: Icon(Icons.add, size: 24),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAddTransactionModal([bool? forceIncome]) {
    // Show haptic feedback for long press
    if (forceIncome == true) {
      HapticFeedback.mediumImpact();
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddTransactionModal(
        forceIncome: forceIncome,
        onSave: (transaction) async {
          await HiveService.addTransaction(transaction);
          _loadData();
          CustomSnackBar.show(
              context, 'Transaction added successfully!', SnackBarType.success);
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
          CustomSnackBar.show(context, 'People transaction added successfully!',
              SnackBarType.success);
        },
      ),
    );
  }

  void _editTransaction(Transaction transaction, int index) {
    if (index == -1) return; // Transaction not found

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddTransactionModal(
        transaction: transaction,
        onSave: (updatedTransaction) async {
          await HiveService.updateTransaction(index, updatedTransaction);
          _loadData();
          CustomSnackBar.show(context, 'Transaction updated successfully!',
              SnackBarType.success);
        },
      ),
    );
  }

  void _deleteTransaction(int index) {
    if (index == -1) return; // Transaction not found

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
              final transaction = _allTransactions[index];

              // Check if this is a people transaction (has _main suffix)
              if (transaction.id.endsWith('_main')) {
                // This is a people transaction, delete from people manager too
                await PeopleHiveService.deletePeopleTransactionByMainId(
                    transaction.id);
              }

              // Delete the main transaction
              await HiveService.deleteTransaction(index);
              Navigator.pop(context);
              _loadData();
              CustomSnackBar.show(context, 'Transaction deleted successfully!',
                  SnackBarType.info);
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
    ).then((_) => _loadData());
  }
}
