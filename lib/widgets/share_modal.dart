import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/share_service.dart';
import '../services/contact_service.dart';
import '../models/person_summary.dart';
import '../models/people_transaction.dart';
import '../widgets/custom_snackbar.dart';

class ShareModal extends StatefulWidget {
  final PersonSummary person;
  final List<PeopleTransaction> recentTransactions;

  const ShareModal({
    Key? key,
    required this.person,
    required this.recentTransactions,
  }) : super(key: key);

  @override
  _ShareModalState createState() => _ShareModalState();
}

class _ShareModalState extends State<ShareModal> with TickerProviderStateMixin {
  late TextEditingController _phoneController;
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: Duration(milliseconds: 400),
      vsync: this,
    );

    _slideAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    // Load existing phone number if available
    final existingPhone = ContactService.getPersonPhoneNumber(widget.person.name);
    _phoneController = TextEditingController(text: existingPhone ?? '');

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Stack(
          children: [
            // Background overlay
            FadeTransition(
              opacity: _fadeAnimation,
              child: Container(
                color: Colors.black.withOpacity(0.5),
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(),
                ),
              ),
            ),
            // Modal content
            Transform.translate(
              offset: Offset(0, _slideAnimation.value * MediaQuery.of(context).size.height),
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: Offset(0, -5),
                      ),
                    ],
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
                          _buildHeader(),
                          SizedBox(height: 24),
                          _buildPhoneNumberField(),
                          SizedBox(height: 24),
                          _buildPreview(),
                          SizedBox(height: 32),
                          _buildShareOptions(),
                          SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeader() {
    return Column(
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
        SizedBox(height: 20),
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.share,
                color: Theme.of(context).primaryColor,
                size: 24,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Share with ${widget.person.name}',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Send transaction summary',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPhoneNumberField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Phone Number',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              hintText: 'Enter phone number',
              prefixIcon: Icon(Icons.phone_outlined),
              prefixText: '+91 ',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.transparent,
              contentPadding: EdgeInsets.all(20),
            ),
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
            ],
            onChanged: (value) {
              // Auto-save phone number as user types
              if (value.length == 10) {
                ContactService.savePersonContact(widget.person.name, value);
              }
            },
          ),
        ),
        SizedBox(height: 8),
        Text(
          'This number will be saved for future sharing',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildPreview() {
    final shareText = ShareService.generateShareText(widget.person, widget.recentTransactions);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.preview,
              color: Theme.of(context).primaryColor,
              size: 20,
            ),
            SizedBox(width: 8),
            Text(
              'Message Preview',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey.withOpacity(0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                shareText,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildShareOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Share Options',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildShareButton(
                'WhatsApp',
                Icons.chat,
                Colors.green,
                () => _shareViaWhatsApp(),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildShareButton(
                'SMS',
                Icons.sms,
                Colors.blue,
                () => _shareViaSMS(),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildShareButton(
                'More',
                Icons.share,
                Colors.purple,
                () => _shareAsText(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildShareButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: _isLoading ? null : onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(0.3),
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: color,
                size: 20,
              ),
            ),
            SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _shareViaWhatsApp() async {
    if (!_validatePhoneNumber()) return;

    setState(() => _isLoading = true);

    try {
      final phoneNumber = '+91${_phoneController.text.trim()}';
      final message = ShareService.generateShareText(widget.person, widget.recentTransactions);
      
      await ContactService.savePersonContact(widget.person.name, _phoneController.text.trim());
      await ShareService.shareViaWhatsApp(phoneNumber, message);
      
      Navigator.pop(context);
      CustomSnackBar.show(context, 'Shared via WhatsApp successfully!', SnackBarType.success);
    } catch (e) {
      CustomSnackBar.show(context, 'Failed to share via WhatsApp: ${e.toString()}', SnackBarType.error);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _shareViaSMS() async {
    if (!_validatePhoneNumber()) return;

    setState(() => _isLoading = true);

    try {
      final hasPermission = await ShareService.requestSmsPermission();
      if (!hasPermission) {
        CustomSnackBar.show(context, 'SMS permission denied', SnackBarType.error);
        return;
      }

      final phoneNumber = '+91${_phoneController.text.trim()}';
      final message = ShareService.generateShareText(widget.person, widget.recentTransactions);
      
      await ContactService.savePersonContact(widget.person.name, _phoneController.text.trim());
      await ShareService.shareViaSMS(phoneNumber, message);
      
      Navigator.pop(context);
      CustomSnackBar.show(context, 'SMS app opened successfully!', SnackBarType.success);
    } catch (e) {
      CustomSnackBar.show(context, 'Failed to open SMS: ${e.toString()}', SnackBarType.error);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _shareAsText() async {
    setState(() => _isLoading = true);

    try {
      final message = ShareService.generateShareText(widget.person, widget.recentTransactions);
      
      if (_phoneController.text.trim().isNotEmpty) {
        await ContactService.savePersonContact(widget.person.name, _phoneController.text.trim());
      }
      
      await ShareService.shareAsText(message);
      
      Navigator.pop(context);
      CustomSnackBar.show(context, 'Share options opened!', SnackBarType.success);
    } catch (e) {
      CustomSnackBar.show(context, 'Failed to share: ${e.toString()}', SnackBarType.error);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  bool _validatePhoneNumber() {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      CustomSnackBar.show(context, 'Please enter a phone number', SnackBarType.warning);
      return false;
    }
    if (phone.length != 10) {
      CustomSnackBar.show(context, 'Please enter a valid 10-digit phone number', SnackBarType.warning);
      return false;
    }
    return true;
  }
}