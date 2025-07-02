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
  bool _isGiven = true; // true = give money, false = take money
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
      _isGiven = widget.transaction!.isGiven;
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
    FocusScope.of(context).requestFocus(_reasonFocus);
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

                    // Transaction Type Toggle
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _isGiven = true;
                                });
                                HapticFeedback.lightImpact();
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                decoration: BoxDecoration(
                                  color: _isGiven
                                      ? Colors.red
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.arrow_upward,
                                      color:
                                          _isGiven ? Colors.white : Colors.red,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Give',
                                      style: TextStyle(
                                        color: _isGiven
                                            ? Colors.white
                                            : Colors.red,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _isGiven = false;
                                });
                                HapticFeedback.lightImpact();
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                decoration: BoxDecoration(
                                  color: !_isGiven
                                      ? Colors.green
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.arrow_downward,
                                      color: !_isGiven
                                          ? Colors.white
                                          : Colors.green,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Take',
                                      style: TextStyle(
                                        color: !_isGiven
                                            ? Colors.white
                                            : Colors.green,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 24),

                    // Amount Field - Moved to top
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
                      keyboardType:
                          TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        hintText: '0.00',
                        prefixText: '₹',
                        prefixStyle: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _isGiven ? Colors.red : Colors.green,
                        ),
                      ),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _isGiven ? Colors.red : Colors.green,
                      ),
                      textInputAction: TextInputAction.next,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'^\d+\.?\d{0,2}')),
                      ],
                      onSubmitted: (_) {
                        FocusScope.of(context).requestFocus(_personNameFocus);
                      },
                    ),

                    SizedBox(height: 24),

                    // Person Name Field with Autocomplete - Moved under amount
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
                          textInputAction: TextInputAction.next,
                          onSubmitted: (_) {
                            FocusScope.of(context).requestFocus(_reasonFocus);
                          },
                        ),
                        if (_showSuggestions) ...[
                          SizedBox(height: 8),
                          Container(
                            constraints: BoxConstraints(maxHeight: 150),
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.grey.withOpacity(0.3),
                              ),
                            ),
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: _filteredNames.length,
                              itemBuilder: (context, index) {
                                final name = _filteredNames[index];
                                return ListTile(
                                  dense: true,
                                  leading: Icon(
                                    Icons.person,
                                    color: Theme.of(context).primaryColor,
                                    size: 20,
                                  ),
                                  title: Text(
                                    name,
                                    style: TextStyle(fontSize: 14),
                                  ),
                                  onTap: () => _selectSuggestion(name),
                                );
                              },
                            ),
                          ),
                        ],
                      ],
                    ),

                    SizedBox(height: 24),

                    // Reason Field
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
                        hintText: 'What was this for?',
                        prefixIcon: Icon(Icons.description_outlined),
                      ),
                      textCapitalization: TextCapitalization.sentences,
                      textInputAction: TextInputAction.done,
                      maxLength: 100,
                      onSubmitted: (_) {
                        _saveTransaction();
                      },
                    ),

                    SizedBox(height: 16),

                    // Date Selector
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
                          children: [
                            Icon(Icons.calendar_today,
                                color: Theme.of(context).primaryColor),
                            SizedBox(width: 12),
                            Text(
                              '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Spacer(),
                            Icon(Icons.arrow_forward_ios,
                                size: 16, color: Colors.grey),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: 32),

                    // Preview Text
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: (_isGiven ? Colors.red : Colors.green)
                            .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: (_isGiven ? Colors.red : Colors.green)
                              .withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: _isGiven ? Colors.red : Colors.green,
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _getPreviewText(),
                                  style: TextStyle(
                                    color: _isGiven ? Colors.red : Colors.green,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Text(
                            _getMainBalanceImpact(),
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 24),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _saveTransaction,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isGiven ? Colors.red : Colors.green,
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

  String _getPreviewText() {
    final amount =
        _amountController.text.isNotEmpty ? _amountController.text : '0';
    final person = _personNameController.text.isNotEmpty
        ? _personNameController.text
        : 'Person';

    if (_isGiven) {
      return 'You will see: "Take ₹$amount from $person"';
    } else {
      return 'You will see: "Give ₹$amount back to $person"';
    }
  }

  String _getMainBalanceImpact() {
    final amount =
        _amountController.text.isNotEmpty ? _amountController.text : '0';
    final person = _personNameController.text.isNotEmpty
        ? _personNameController.text
        : 'Person';
    final reason =
        _reasonController.text.isNotEmpty ? _reasonController.text : 'reason';

    if (_isGiven) {
      return 'Main balance: -₹$amount | History: "Give money to "$person" for "$reason""';
    } else {
      return 'Main balance: +₹$amount | History: "Take money from "$person" for "$reason""';
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
                  primary: _isGiven ? Colors.red : Colors.green,
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
      isGiven: _isGiven,
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