import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/people_transaction.dart';

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
  _AddPeopleTransactionModalState createState() => _AddPeopleTransactionModalState();
}

class _AddPeopleTransactionModalState extends State<AddPeopleTransactionModal> 
    with TickerProviderStateMixin {
  late TextEditingController _amountController;
  late TextEditingController _reasonController;
  late TextEditingController _personNameController;
  late DateTime _selectedDate;
  bool _isGiven = true; // true = give money, false = take money
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  
  @override
  void initState() {
    super.initState();
    
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
    
    if (widget.transaction != null) {
      _amountController = TextEditingController(
        text: widget.transaction!.amount.toStringAsFixed(2),
      );
      _reasonController = TextEditingController(text: widget.transaction!.reason);
      _personNameController = TextEditingController(text: widget.transaction!.personName);
      _selectedDate = widget.transaction!.date;
      _isGiven = widget.transaction!.isGiven;
    } else {
      _amountController = TextEditingController();
      _reasonController = TextEditingController();
      _personNameController = TextEditingController(text: widget.prefilledPersonName ?? '');
      _selectedDate = DateTime.now();
    }
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    _amountController.dispose();
    _reasonController.dispose();
    _personNameController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _slideAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _slideAnimation.value * MediaQuery.of(context).size.height),
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
                      widget.transaction != null ? 'Edit People Transaction' : 'Add People Transaction',
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
                                      color: _isGiven ? Colors.white : Colors.red,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Give',
                                      style: TextStyle(
                                        color: _isGiven ? Colors.white : Colors.red,
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
                                      color: !_isGiven ? Colors.white : Colors.green,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Take',
                                      style: TextStyle(
                                        color: !_isGiven ? Colors.white : Colors.green,
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
                    
                    // Person Name Field
                    Text(
                      'Person Name',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 8),
                    TextField(
                      controller: _personNameController,
                      decoration: InputDecoration(
                        hintText: 'Enter person name',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      textCapitalization: TextCapitalization.words,
                    ),
                    
                    SizedBox(height: 24),
                    
                    // Amount Field
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
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
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
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
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
                      decoration: InputDecoration(
                        hintText: 'What was this for?',
                        prefixIcon: Icon(Icons.description_outlined),
                      ),
                      textCapitalization: TextCapitalization.sentences,
                      maxLength: 100,
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
                            Icon(Icons.calendar_today, color: Theme.of(context).primaryColor),
                            SizedBox(width: 12),
                            Text(
                              '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Spacer(),
                            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                          ],
                        ),
                      ),
                    ),
                    
                    SizedBox(height: 32),
                    
                    // Preview Text
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: (_isGiven ? Colors.red : Colors.green).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: (_isGiven ? Colors.red : Colors.green).withOpacity(0.3),
                        ),
                      ),
                      child: Row(
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
                          widget.transaction != null ? 'Update Transaction' : 'Save Transaction',
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
    final amount = _amountController.text.isNotEmpty ? _amountController.text : '0';
    final person = _personNameController.text.isNotEmpty ? _personNameController.text : 'Person';
    
    if (_isGiven) {
      return 'You will see: "Take ₹$amount from $person"';
    } else {
      return 'You will see: "Give ₹$amount back to $person"';
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
      id: widget.transaction?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      personName: _personNameController.text.trim(),
      amount: amount,
      reason: _reasonController.text.trim(),
      date: _selectedDate,
      timestamp: DateTime.now(),
      isGiven: _isGiven,
    );
    
    widget.onSave(transaction);
    Navigator.pop(context);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          widget.transaction != null 
              ? 'People transaction updated successfully!'
              : 'People transaction added successfully!',
        ),
        backgroundColor: Colors.green,
      ),
    );
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