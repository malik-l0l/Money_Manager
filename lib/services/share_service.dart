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

  static String generateShareText(PersonSummary person, List<PeopleTransaction> transactions) {
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
    
    if (transactions.isNotEmpty) {
      buffer.writeln('📋 Last ${transactions.length} transactions:');
      buffer.writeln();
      
      // Calculate running balance from oldest to newest
      double runningBalance = 0;
      final reversedTransactions = transactions.reversed.toList();
      
      for (final transaction in reversedTransactions) {
        runningBalance += transaction.balanceImpact;
      }
      
      // Display transactions from newest to oldest with clean format
      for (final transaction in transactions) {
        final emoji = transaction.balanceImpact > 0 ? '➕' : '➖';
        final actionText = _getCleanActionText(transaction);
        final dateText = DateFormatter.formatDate(transaction.date);
        
        buffer.writeln('$emoji ₹${transaction.amount.toStringAsFixed(0).padLeft(3)}  ($actionText)${' ' * (35 - actionText.length)}[$dateText]');
      }
      
      buffer.writeln('——————————————');
      
      if (person.totalBalance > 0) {
        buffer.writeln('💰 Total: ₹${person.totalBalance.abs().toStringAsFixed(2)} → You owe me');
      } else if (person.totalBalance < 0) {
        buffer.writeln('💰 Total: ₹${person.totalBalance.abs().toStringAsFixed(2)} → I owe you');
      } else {
        buffer.writeln('💰 Total: ₹0.00 → All settled!');
      }
    } else {
      buffer.writeln('📋 No recent transactions');
    }
    
    buffer.writeln();
    buffer.writeln('📱 Sent from Money Manager App');
    
    return buffer.toString();
  }

  static String _getCleanActionText(PeopleTransaction transaction) {
    switch (transaction.transactionType) {
      case 'give':
        return 'I gave you for ${transaction.reason}';
      case 'take':
        return 'I took cash from you for ${transaction.reason}';
      case 'owe':
        return 'You paid for me for ${transaction.reason}';
      case 'claim':
        return 'You hold my money for ${transaction.reason}';
      default:
        return transaction.isGiven 
            ? 'I gave you for ${transaction.reason}'
            : 'I took cash from you for ${transaction.reason}';
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