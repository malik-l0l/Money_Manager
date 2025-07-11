import 'package:flutter/material.dart';
import '../models/people_transaction.dart';
import '../utils/date_formatter.dart';

class PeopleTransactionCard extends StatelessWidget {
  final PeopleTransaction transaction;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const PeopleTransactionCard({
    Key? key,
    required this.transaction,
    this.onEdit,
    this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final typeData = _getTransactionTypeData(transaction.transactionType);
    
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: typeData['color'].withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: typeData['color'].withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onEdit,
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: typeData['color'].withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        typeData['icon'],
                        color: typeData['color'],
                        size: 24,
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            transaction.reason,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 4),
                          Text(
                            DateFormatter.formatDateTime(transaction.timestamp),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '₹${transaction.amount.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: typeData['color'],
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          typeData['title'],
                          style: TextStyle(
                            fontSize: 12,
                            color: typeData['color'],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    if (onDelete != null) ...[
                      SizedBox(width: 8),
                      GestureDetector(
                        onTap: onDelete,
                        child: Container(
                          padding: EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(
                            Icons.delete_outline,
                            size: 16,
                            color: Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Map<String, dynamic> _getTransactionTypeData(String type) {
    switch (type) {
      case 'give':
        return {
          'title': 'Given',
          'icon': Icons.arrow_upward,
          'color': Colors.red,
        };
      case 'take':
        return {
          'title': 'Taken',
          'icon': Icons.arrow_downward,
          'color': Colors.green,
        };
      case 'owe':
        return {
          'title': 'They Paid',
          'icon': Icons.credit_card,
          'color': Colors.orange,
        };
      case 'claim':
        return {
          'title': 'Your Money',
          'icon': Icons.account_balance_wallet,
          'color': Colors.blue,
        };
      default:
        // Fallback for legacy data
        return {
          'title': 'Legacy',
          'icon': Icons.help_outline,
          'color': Colors.grey,
        };
    }
  }
}