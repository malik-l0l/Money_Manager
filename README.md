# todo

provide you with the complete Flutter project structure and all the Dart code you need for your money manager app! You'll need to create this in your local Flutter development environment.
Add dependencies to your pubspec.yaml:


now please do these modifications :

add a new page to manage transaction between people, make a seperate database and page for that

here the popup should ask 3 things : toggle "give" or "take" amount text field name of the person text field reason text field save button
if i give 30 rs to "sam" it should show "take 30 from sam"
if take 30 rs from "sam" it should show "give 40 back to sam"

store the history by each person


but how can i add people transactions, it is not visible. modify main.dart or files in  screens/


when i give money to someone reduce it from the main balance in the main page. also add an entry in history in main page : give money for "<name>"  for "<reason>"

when i take money from someone add it to the main balance in the main page. also add an entry in history in main page : take money from "<name>"  for "<reason>"



please do these modifications :

remove quick actions section.

place people manager icon in the top, near  settings  and monthly summary icon.

when i give someone money it need to be reduced automatically from the main_balance in the home screen. similarly hen i take money from it need to be added automatically to the main_balance in the home screen.

when i press tick mark from the phone keyboard automatically go to the next text field - to improve user experience,


please fix this bug i saw :

when i add an income "500" current balance = 500
when i give "sam" 30 the current balance is now = 440, which is wrong because 500-30=470
i think it is substracting twice please fix the issue




now please do these modifications :

in the people manager window remove 'Net Balance',

instaed 'total given' and 'total taken' replace it with "You owe" which shows the amount you owe to people, "owes you" which is the amount the peoples owe you

when i lock my phone in people transaction screen, when i unlock the UI just crashes, the text are scattered if this bug is fixable, please fix it too



- fix crash issue


- dlt from main screen to delete from people screen

- place toggle inside transaction to add people transaction 

- auto appear name in Person Name 

- insufficient fund
- automatic cursor go to amount, expense first income second
implement chart
- in setting automatic scroll up add transaction window,


```
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/transaction.dart';
import '../services/hive_service.dart';
import 'add_people_transaction_modal.dart';

class AddTransactionModal extends StatefulWidget {
  final Transaction? transaction;
  final Function(Transaction) onSave;

  const AddTransactionModal({
    Key? key,
    this.transaction,
    required this.onSave,
  }) : super(key: key);

  @override
  _AddTransactionModalState createState() => _AddTransactionModalState();
}

class _AddTransactionModalState extends State<AddTransactionModal>
    with TickerProviderStateMixin {
  late TextEditingController _amountController;
  late TextEditingController _reasonController;
  late DateTime _selectedDate;
  bool _isIncome = true;
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;

  // Focus nodes for better UX
  late FocusNode _amountFocus;
  late FocusNode _reasonFocus;

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

    // Initialize focus nodes
    _amountFocus = FocusNode();
    _reasonFocus = FocusNode();

    if (widget.transaction != null) {
      _amountController = TextEditingController(
        text: widget.transaction!.amount.abs().toStringAsFixed(2),
      );
      _reasonController =
          TextEditingController(text: widget.transaction!.reason);
      _selectedDate = widget.transaction!.date;
      _isIncome = widget.transaction!.amount > 0;
    } else {
      _amountController = TextEditingController();
      _reasonController = TextEditingController();
      _selectedDate = DateTime.now();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _amountController.dispose();
    _reasonController.dispose();
    _amountFocus.dispose();
    _reasonFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = HiveService.getUserSettings();

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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          widget.transaction != null
                              ? 'Edit Transaction'
                              : 'Add Transaction',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        // Toggle button to switch to people transaction
                        if (widget.transaction ==
                            null) // Only show for new transactions
                          GestureDetector(
                            onTap: _switchToPeopleTransaction,
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.purple.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.purple.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.people_outline,
                                    color: Colors.purple,
                                    size: 16,
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    'People',
                                    style: TextStyle(
                                      color: Colors.purple,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
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
                                  _isIncome = true;
                                });
                                HapticFeedback.lightImpact();
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                decoration: BoxDecoration(
                                  color: _isIncome
                                      ? Colors.green
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.add_circle_outline,
                                      color: _isIncome
                                          ? Colors.white
                                          : Colors.green,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Income',
                                      style: TextStyle(
                                        color: _isIncome
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
                          SizedBox(width: 8),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _isIncome = false;
                                });
                                HapticFeedback.lightImpact();
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                decoration: BoxDecoration(
                                  color: !_isIncome
                                      ? Colors.red
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.remove_circle_outline,
                                      color: !_isIncome
                                          ? Colors.white
                                          : Colors.red,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Expense',
                                      style: TextStyle(
                                        color: !_isIncome
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
                        ],
                      ),
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
                      focusNode: _amountFocus,
                      keyboardType:
                          TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        hintText: '0.00',
                        prefixText: settings.currency,
                        prefixStyle: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _isIncome ? Colors.green : Colors.red,
                        ),
                      ),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _isIncome ? Colors.green : Colors.red,
                      ),
                      textInputAction: TextInputAction.next,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'^\d+\.?\d{0,2}')),
                      ],
                      onSubmitted: (_) {
                        FocusScope.of(context).requestFocus(_reasonFocus);
                      },
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

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _saveTransaction,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              _isIncome ? Colors.green : Colors.red,
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

  void _switchToPeopleTransaction() {
    Navigator.pop(context); // Close current modal

    // Show people transaction modal
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddPeopleTransactionModal(
        onSave: (transaction) async {
          // This will be handled by the people service
          Navigator.pop(context); // Close the people modal

          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('People transaction added successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        },
      ),
    );
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
                  primary: _isIncome ? Colors.green : Colors.red,
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

    final transaction = Transaction(
      id: widget.transaction?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      date: _selectedDate,
      amount: _isIncome ? amount : -amount,
      reason: _reasonController.text.trim(),
      timestamp: DateTime.now(),
    );

    widget.onSave(transaction);
    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          widget.transaction != null
              ? 'Transaction updated successfully!'
              : 'Transaction added successfully!',
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

```