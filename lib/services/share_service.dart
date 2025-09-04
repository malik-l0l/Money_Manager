import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import '../models/people_transaction.dart';
import '../models/person_summary.dart';
import '../utils/date_formatter.dart';

class ShareService {
  static Future<bool> requestSmsPermission() async {
    final status = await Permission.sms.request();
    return status.isGranted;
  }

  static String generateShareText(PersonSummary person, List<PeopleTransaction> recentTransactions) {
    final StringBuffer buffer = StringBuffer();
    
    // Header with balance summary
    if (person.totalBalance > 0) {
      buffer.writeln('💰 You owe ₹${person.totalBalance.abs().toStringAsFixed(2)} to me');
    } else if (person.totalBalance < 0) {
      buffer.writeln('💰 I owe ₹${person.totalBalance.abs().toStringAsFixed(2)} to you');
    } else {
      buffer.writeln('✅ We\'re all settled up!');
    }
    
    buffer.writeln();
    
    if (recentTransactions.isNotEmpty) {
      buffer.writeln('📋 Last ${recentTransactions.length} transactions:');
      buffer.writeln();
      
      for (int i = 0; i < recentTransactions.length; i++) {
        final transaction = recentTransactions[i];
        final emoji = _getTransactionEmoji(transaction.transactionType);
        final actionText = _getActionText(transaction.transactionType);
        final dateText = DateFormatter.formatDate(transaction.date);
        
        buffer.writeln('${i + 1}. $emoji $actionText ₹${transaction.amount.toStringAsFixed(0)} for ${transaction.reason} [$dateText]');
      }
      
      buffer.writeln();
      buffer.writeln('💡 Balance calculation:');
      
      double runningBalance = 0;
      for (final transaction in recentTransactions.reversed) {
        runningBalance += transaction.balanceImpact;
        final sign = transaction.balanceImpact > 0 ? '+' : '';
        buffer.writeln('   ${sign}₹${transaction.balanceImpact.toStringAsFixed(0)} = ₹${runningBalance.toStringAsFixed(0)}');
      }
    } else {
      buffer.writeln('📋 No recent transactions');
    }
    
    buffer.writeln();
    buffer.writeln('📱 Sent from Money Manager App');
    
    return buffer.toString();
  }

  static String _getTransactionEmoji(String transactionType) {
    switch (transactionType) {
      case 'give':
        return '💸';
      case 'take':
        return '💰';
      case 'owe':
        return '🧾';
      case 'claim':
        return '🏦';
      default:
        return '💳';
    }
  }

  static String _getActionText(String transactionType) {
    switch (transactionType) {
      case 'give':
        return 'I gave you';
      case 'take':
        return 'I took from you';
      case 'owe':
        return 'You paid for me';
      case 'claim':
        return 'You have my money';
      default:
        return 'Transaction';
    }
  }

  static Future<void> shareViaWhatsApp(String phoneNumber, String message) async {
    // Clean phone number (remove spaces, dashes, etc.)
    final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    
    final whatsappUrl = 'https://wa.me/$cleanNumber?text=${Uri.encodeComponent(message)}';
    
    if (await canLaunchUrl(Uri.parse(whatsappUrl))) {
      await launchUrl(Uri.parse(whatsappUrl), mode: LaunchMode.externalApplication);
    } else {
      throw Exception('WhatsApp is not installed');
    }
  }

  static Future<void> shareViaSMS(String phoneNumber, String message) async {
    final smsUrl = 'sms:$phoneNumber?body=${Uri.encodeComponent(message)}';
    
    if (await canLaunchUrl(Uri.parse(smsUrl))) {
      await launchUrl(Uri.parse(smsUrl));
    } else {
      throw Exception('SMS is not available');
    }
  }

  static Future<void> shareAsText(String message) async {
    await Share.share(message, subject: 'Transaction Summary');
  }
}