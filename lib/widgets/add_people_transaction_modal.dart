import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/people_transaction.dart';
import '../services/people_hive_service.dart';
import '../services/hive_service.dart';

class AddPeopleTransactionModal extends StatefulWidget {
  final PeopleTransaction? transaction;
  final String? prefilledPersonName;
  final Function(PeopleTransaction) onSave;

  const AddPeopleTransactionModal({
    Key? key,
    this.transaction,
    this.prefilledPersonName,
    required this.onSave,
  }) : super(key: key);

  @override
  _AddPeopleTransactionModalState createState() =>
      _AddPeopleTransactionModalState();
}

class _AddPeopleTransactionModalState extends State<AddPeopleTransactionModal>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late TextEditingController _amountController;
  late TextEditingController _reasonController;
  late TextEditingController _personNameController;
  late DateTime _selectedDate;
  String _transactionType = 'owe'; // Default to 'owe' as requested
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;

  // Focus nodes for better UX
  late FocusNode _personNameFocus;
  late FocusNode _amountFocus;
  late FocusNode _reasonFocus;

  // Autocomplete variables
  List<String> _allPeopleNames = [];
  List<String> _filteredNames = [];
  bool _showSuggestions = false;

  // Transaction type definitions in the requested order
  final List<String> _transactionOrder = ['owe', 'give', 'take', 'claim'];

  final Map<String, Map<String, dynamic>> _transactionTypes = {
    'owe': {
      'title': 'Owe',
      'description': 'Someone spent money for you',
      'example': 'Friend paid for your food',
      'icon': Icons.credit_card,
      'color': Colors.orange,
      'balanceText': 'You owe them',
      'mainBalanceChange': 'No change to balance',
    },
    'give': {
      'title': 'Give',
      'description': 'You gave money to someone',
      'example': 'Friend needed money',
      'icon': Icons.arrow_upward,
      'color': Colors.red,
      'balanceText': 'They owe you',
      'mainBalanceChange': 'Reduces your balance',
    },
    'take': {
      'title': 'Take',
      'description': 'You took money from someone',
      'example': 'You needed money',
      'icon': Icons.arrow_downward,
      'color': Colors.green,
      'balanceText': 'You owe them',
      'mainBalanceChange': 'Increases your balance',
    },
    'claim': {
      'title': 'Claim',
      'description': 'Your money is with someone',
      'example': 'Salary sent to friend',
      'icon': Icons.account_balance_wallet,
      'color': Colors.blue,
      'balanceText': 'They owe you',
      'mainBalanceChange': 'No change to balance',
    },
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _animationController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();

    // Initialize focus nodes
    _personNameFocus = FocusNode();
    _amountFocus = FocusNode();
    _reasonFocus = FocusNode();

    // Load existing people names for autocomplete
    _loadPeopleNames();

    if (widget.transaction != null) {
      _amountController = TextEditingController(
        text: widget.transaction!.amount.toStringAsFixed(2),
      );
      _reasonController =
          TextEditingController(text: widget.transaction!.reason);
      _personNameController =
          TextEditingController(text: widget.transaction!.personName);
      _selectedDate = widget.transaction!.date;
      _transactionType = widget.transaction!.transactionType;
    } else {
      _amountController = TextEditingController();
      _reasonController = TextEditingController();
      _personNameController =
          TextEditingController(text: widget.prefilledPersonName ?? '');
      _selectedDate = DateTime.now();
    }

    // Add listener for autocomplete
    _personNameController.addListener(_onPersonNameChanged);

    // Auto focus amount field if setting is enabled
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settings = HiveService.getUserSettings();
      if (settings.autoFocusAmount && widget.transaction == null) {
        FocusScope.of(context).requestFocus(_amountFocus);
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _animationController.dispose();
    _amountController.dispose();
    _reasonController.dispose();
    _personNameController.dispose();
    _personNameFocus.dispose();
    _amountFocus.dispose();
    _reasonFocus.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // Handle app lifecycle changes to prevent crashes
    if (state == AppLifecycleState.paused) {
      // Unfocus all text fields when app goes to background
      _personNameFocus.unfocus();
      _amountFocus.unfocus();
      _reasonFocus.unfocus();
    }
  }

  void _loadPeopleNames() {
    final summaries = PeopleHiveService.getAllPeopleSummaries();
    _allPeopleNames = summaries.map((summary) => summary.name).toList();
  }

  void _onPersonNameChanged() {
    final query = _personNameController.text.toLowerCase();
    if (query.isEmpty) {
      setState(() {
        _showSuggestions = false;
        _filteredNames = [];
      });
      return;
    }

    _filteredNames = _allPeopleNames
        .where((name) => name.toLowerCase().contains(query))
        .take(5) // Limit to 5 suggestions for horizontal scroll
        .toList();

    setState(() {
      _showSuggestions = _filteredNames.isNotEmpty;
    });
  }

  void _selectSuggestion(String name) {
    _personNameController.text = name;
    setState(() {
      _showSuggestions = false;
    });
    // Don't auto focus anywhere, let user decide next action
  }

  FocusNode _getNextFocusNode() {
    final hasPersonName = _personNameController.text.trim().isNotEmpty;

    if (hasPersonName) {
      // If person name exists: amount -> reason -> save
      return _reasonFocus;
    } else {
      // If no person name: amount -> reason -> person -> save
      return _personNameFocus;
    }
  }

  void _handleReasonSubmitted() {
    final hasPersonName = _personNameController.text.trim().isNotEmpty;

    if (hasPersonName) {
      // If person name exists, save directly
      _saveTransaction();
    } else {
      // If no person name, focus on person name
      FocusScope.of(context).requestFocus(_personNameFocus);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _slideAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(
              0, _slideAnimation.value * MediaQuery.of(context).size.height),
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    SizedBox(height: 24),
                    Text(
                      widget.transaction != null
                          ? 'Edit People Transaction'
                          : 'Add People Transaction',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 32),

                    // Transaction Type Selection - 1x4 Grid
                    _buildTransactionTypeSelector(),

                    SizedBox(height: 24),

                    // Combined Info Container (replacing both previous info containers)
                    _buildCombinedInfoCard(),

                    SizedBox(height: 24),

                    // Amount and Date Row
                    Row(
                      children: [
                        // Amount Field - 60% width
                        Expanded(
                          flex: 7,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Amount',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(height: 8),
                              TextField(
                                controller: _amountController,
                                focusNode: _amountFocus,
                                keyboardType: TextInputType.numberWithOptions(
                                    decimal: true),
                                decoration: InputDecoration(
                                  hintText: '0.00',
                                  prefixText: '₹',
                                  prefixStyle: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: _transactionTypes[_transactionType]![
                                        'color'],
                                  ),
                                ),
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: _transactionTypes[_transactionType]![
                                      'color'],
                                ),
                                textInputAction: TextInputAction.next,
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                      RegExp(r'^\d+\.?\d{0,2}')),
                                ],
                                onSubmitted: (_) {
                                  FocusScope.of(context)
                                      .requestFocus(_reasonFocus);
                                },
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 16),
                        // Date Field - 40% width
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Date',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(height: 8),
                              GestureDetector(
                                onTap: _selectDate,
                                child: Container(
                                  padding: EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).cardColor,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: Colors.grey.withOpacity(0.3),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.calendar_today,
                                        color: Theme.of(context).primaryColor,
                                        size: 18,
                                      ),
                                      SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 24),

                    // Reason Field - Now placed before person name
                    Text(
                      'Reason',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 8),
                    TextField(
                      controller: _reasonController,
                      focusNode: _reasonFocus,
                      decoration: InputDecoration(
                        hintText:
                            _transactionTypes[_transactionType]!['example'],
                        prefixIcon: Icon(Icons.description_outlined),
                      ),
                      textCapitalization: TextCapitalization.sentences,
                      textInputAction: TextInputAction.next,
                      maxLength: 100,
                      onSubmitted: (_) {
                        _handleReasonSubmitted();
                      },
                    ),

                    SizedBox(height: 24),

                    // Person Name Field with Horizontal Autocomplete
                    Text(
                      'Person Name',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 8),
                    Column(
                      children: [
                        TextField(
                          controller: _personNameController,
                          focusNode: _personNameFocus,
                          decoration: InputDecoration(
                            hintText: 'Enter person name',
                            prefixIcon: Icon(Icons.person_outline),
                            suffixIcon: _showSuggestions
                                ? IconButton(
                                    icon: Icon(Icons.clear),
                                    onPressed: () {
                                      _personNameController.clear();
                                      setState(() {
                                        _showSuggestions = false;
                                      });
                                    },
                                  )
                                : null,
                          ),
                          textCapitalization: TextCapitalization.words,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) {
                            _saveTransaction();
                          },
                        ),
                        if (_showSuggestions) ...[
                          SizedBox(height: 12),
                          Container(
                            height: 50,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: _filteredNames.length,
                              itemBuilder: (context, index) {
                                final name = _filteredNames[index];
                                final isLast =
                                    index == _filteredNames.length - 1;

                                return Container(
                                  margin: EdgeInsets.only(
                                    right: isLast ? 0 : 8,
                                  ),
                                  child: GestureDetector(
                                    onTap: () => _selectSuggestion(name),
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context)
                                            .primaryColor
                                            .withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(25),
                                        border: Border.all(
                                          color: Theme.of(context)
                                              .primaryColor
                                              .withOpacity(0.3),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.person,
                                            color:
                                                Theme.of(context).primaryColor,
                                            size: 16,
                                          ),
                                          SizedBox(width: 6),
                                          Text(
                                            name,
                                            style: TextStyle(
                                              color: Theme.of(context)
                                                  .primaryColor,
                                              fontWeight: FontWeight.w500,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ],
                    ),

                    SizedBox(height: 28),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _saveTransaction,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              _transactionTypes[_transactionType]!['color'],
                          foregroundColor: Colors.white,
                        ),
                        child: Text(
                          widget.transaction != null
                              ? 'Update Transaction'
                              : 'Save Transaction',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTransactionTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Transaction Type',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 12),
        // 1x4 Grid - Single row with 4 columns
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: _transactionOrder.map((type) {
              final isLast = type == _transactionOrder.last;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: isLast ? 0 : 4),
                  child: _buildTransactionTypeOption(type),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionTypeOption(String type) {
    final typeData = _transactionTypes[type]!;
    final isSelected = _transactionType == type;

    return GestureDetector(
      onTap: () {
        setState(() {
          _transactionType = type;
        });
        HapticFeedback.lightImpact();
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: BoxDecoration(
          color: isSelected ? typeData['color'] : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(
              typeData['icon'],
              color: isSelected ? Colors.white : typeData['color'],
              size: 20,
            ),
            SizedBox(height: 4),
            Text(
              typeData['title'],
              style: TextStyle(
                color: isSelected ? Colors.white : typeData['color'],
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCombinedInfoCard() {
    final typeData = _transactionTypes[_transactionType]!;
    final amount =
        _amountController.text.isNotEmpty ? _amountController.text : '0';
    final person = _personNameController.text.isNotEmpty
        ? _personNameController.text
        : 'Person';
    final reason =
        _reasonController.text.isNotEmpty ? _reasonController.text : 'reason';

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: typeData['color'].withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: typeData['color'].withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main description
          Row(
            children: [
              Icon(
                typeData['icon'],
                color: typeData['color'],
                size: 16,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  typeData['description'],
                  style: TextStyle(
                    color: typeData['color'],
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 8),

          // Example
          Text(
            'Example: ${typeData['example']}',
            style: TextStyle(
              color: typeData['color'].withOpacity(0.8),
              fontSize: 12,
            ),
          ),

          SizedBox(height: 12),
          Divider(color: typeData['color'].withOpacity(0.3), height: 1),
          SizedBox(height: 12),

          // People Balance Impact
          Row(
            children: [
              Icon(
                Icons.people,
                color: typeData['color'],
                size: 14,
              ),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  _getPeopleBalanceText(amount, person),
                  style: TextStyle(
                    color: typeData['color'],
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 8),

          // Main Balance Impact
          Row(
            children: [
              Icon(
                Icons.account_balance_wallet,
                color: Colors.grey[600],
                size: 14,
              ),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  _getMainBalanceText(amount, person, reason),
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getPeopleBalanceText(String amount, String person) {
    switch (_transactionType) {
      case 'give':
      case 'claim':
        return '$person owes you ₹$amount';
      case 'take':
      case 'owe':
        return 'You owe $person ₹$amount';
      default:
        return '';
    }
  }

  String _getMainBalanceText(String amount, String person, String reason) {
    switch (_transactionType) {
      case 'give':
        return 'Main balance: -₹$amount | Give money to $person for $reason';
      case 'take':
        return 'Main balance: +₹$amount | Take money from $person for $reason';
      case 'owe':
        return 'Main balance: No change | $person spent ₹$amount for you for $reason';
      case 'claim':
        return 'Main balance: No change | $person has ₹$amount of your money for $reason';
      default:
        return '';
    }
  }

  void _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: _transactionTypes[_transactionType]!['color'],
                ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _saveTransaction() {
    if (_personNameController.text.trim().isEmpty) {
      _showError('Please enter person name');
      return;
    }

    if (_amountController.text.trim().isEmpty) {
      _showError('Please enter an amount');
      return;
    }

    if (_reasonController.text.trim().isEmpty) {
      _showError('Please enter a reason');
      return;
    }

    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      _showError('Please enter a valid amount');
      return;
    }

    final transaction = PeopleTransaction(
      id: widget.transaction?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      personName: _personNameController.text.trim(),
      amount: amount,
      reason: _reasonController.text.trim(),
      date: _selectedDate,
      timestamp: DateTime.now(),
      transactionType: _transactionType,
    );

    widget.onSave(transaction);
    Navigator.pop(context);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}
