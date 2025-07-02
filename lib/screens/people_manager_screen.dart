import 'package:flutter/material.dart';
import '../services/people_hive_service.dart';
import '../models/person_summary.dart';
import '../widgets/add_people_transaction_modal.dart';
import '../widgets/person_summary_card.dart';
import '../widgets/custom_snackbar.dart';
import 'person_detail_screen.dart';

class PeopleManagerScreen extends StatefulWidget {
  @override
  _PeopleManagerScreenState createState() => _PeopleManagerScreenState();
}

class _PeopleManagerScreenState extends State<PeopleManagerScreen> {
  List<PersonSummary> _peopleSummaries = [];
  double _youOwe = 0.0;
  double _owesYou = 0.0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    if (!mounted) return;

    try {
      setState(() {
        _peopleSummaries = PeopleHiveService.getAllPeopleSummaries();

        // Calculate amounts you owe and amounts owed to you
        _youOwe = 0.0;
        _owesYou = 0.0;

        for (final person in _peopleSummaries) {
          if (person.totalBalance > 0) {
            _owesYou += person.totalBalance; // People owe you
          } else if (person.totalBalance < 0) {
            _youOwe += person.totalBalance.abs(); // You owe people
          }
        }
      });
    } catch (e) {
      // Handle any potential errors gracefully
      if (mounted) {
        CustomSnackBar.show(context, 'Error loading data', SnackBarType.error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('People Manager'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _loadData();
        },
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildQuickStats(),
              SizedBox(height: 32),
              _buildPeopleList(),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddTransactionModal,
        icon: Icon(Icons.person_add),
        label: Text('Add Transaction'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
    );
  }

  Widget _buildQuickStats() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'You Owe',
            _youOwe,
            Colors.red,
            Icons.arrow_upward,
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            'Owes You',
            _owesYou,
            Colors.green,
            Icons.arrow_downward,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
      String title, double amount, Color color, IconData icon) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            '₹${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeopleList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'People (${_peopleSummaries.length})',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 16),
        if (_peopleSummaries.isEmpty)
          Container(
            height: 200,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No transactions with people yet',
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
            itemCount: _peopleSummaries.length,
            itemBuilder: (context, index) {
              final person = _peopleSummaries[index];
              return PersonSummaryCard(
                person: person,
                onTap: () => _navigateToPersonDetail(person.name),
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

  void _navigateToPersonDetail(String personName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PersonDetailScreen(personName: personName),
      ),
    ).then((_) => _loadData());
  }
}
