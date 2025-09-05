import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/share_service.dart';
import '../services/contact_service.dart';
import '../models/person_summary.dart';
import '../models/people_transaction.dart';
import '../widgets/custom_snackbar.dart';

class ShareModal extends StatefulWidget {
  final PersonSummary person;
  final List<PeopleTransaction> allTransactions;

  const ShareModal({
    Key? key,
    required this.person,
    required this.allTransactions,
  }) : super(key: key);

  @override
  _ShareModalState createState() => _ShareModalState();
}

class _ShareModalState extends State<ShareModal> with TickerProviderStateMixin {
  late TextEditingController _phoneController;
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late FocusNode _phoneFocus;
  bool _isLoading = false;
  
  // Transaction selection variables
  int _selectedTransactionCount = 5;
  bool _shareAllTransactions = false;
  late int _maxTransactions;

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

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _phoneFocus = FocusNode();
    _maxTransactions = widget.allTransactions.length;
    
    // Set default transaction count (max 10 or total available)
    _selectedTransactionCount = (_maxTransactions < 5) ? _maxTransactions : 5;

    // Load existing phone number if available
    final existingPhone = ContactService.getPersonPhoneNumber(widget.person.name);
    _phoneController = TextEditingController(text: existingPhone ?? '');

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _phoneController.dispose();
    _phoneFocus.dispose();
    super.dispose();
  }

  List<PeopleTransaction> get _selectedTransactions {
    if (_shareAllTransactions) {
      return widget.allTransactions;
    }
    return widget.allTransactions.take(_selectedTransactionCount).toList();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Material(
          color: Colors.transparent,
          child: Stack(
            children: [
              // Background overlay
              FadeTransition(
                opacity: _fadeAnimation,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    color: Colors.black.withOpacity(0.5),
                  ),
                ),
              ),
              // Modal content
              Transform.translate(
                offset: Offset(0, _slideAnimation.value * MediaQuery.of(context).size.height),
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    height: MediaQuery.of(context).size.height * 0.85,
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
                    child: Column(
                      children: [
                        _buildHeader(),
                        Expanded(
                          child: SingleChildScrollView(
                            padding: EdgeInsets.all(24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildPhoneNumberField(),
                                SizedBox(height: 24),
                                _buildTransactionSelector(),
                                SizedBox(height: 24),
                                _buildPreview(),
                                SizedBox(height: 32),
                                _buildShareOptions(),
                                SizedBox(height: 16),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(24),
      child: Column(
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
                        color: Theme.of(context).textTheme.titleLarge?.color,
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
      ),
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
            color: Theme.of(context).textTheme.titleMedium?.color,
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
            focusNode: _phoneFocus,
            keyboardType: TextInputType.phone,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
            decoration: InputDecoration(
              hintText: 'Enter 10-digit phone number',
              hintStyle: TextStyle(
                color: Colors.grey[500],
                fontSize: 16,
              ),
              prefixIcon: Icon(
                Icons.phone_outlined,
                color: Theme.of(context).primaryColor,
              ),
              prefixText: '+91 ',
              prefixStyle: TextStyle(
                color: Theme.of(context).primaryColor,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: Theme.of(context).primaryColor,
                  width: 2,
                ),
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

  Widget _buildTransactionSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Transactions to Share',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).textTheme.titleMedium?.color,
          ),
        ),
        SizedBox(height: 16),
        
        // All transactions toggle
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _shareAllTransactions 
                  ? Theme.of(context).primaryColor.withOpacity(0.3)
                  : Colors.grey.withOpacity(0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.select_all,
                color: _shareAllTransactions 
                    ? Theme.of(context).primaryColor 
                    : Colors.grey[600],
                size: 20,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Share All Transactions',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _shareAllTransactions 
                            ? Theme.of(context).primaryColor 
                            : Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                    Text(
                      'Include all ${_maxTransactions} transactions',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _shareAllTransactions,
                onChanged: (value) {
                  setState(() {
                    _shareAllTransactions = value;
                  });
                },
                activeColor: Theme.of(context).primaryColor,
              ),
            ],
          ),
        ),
        
        if (!_shareAllTransactions) ...[
          SizedBox(height: 16),
          
          // Custom transaction count selector
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.grey.withOpacity(0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.format_list_numbered,
                      color: Theme.of(context).primaryColor,
                      size: 20,
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Number of Transactions',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Spacer(),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$_selectedTransactionCount',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                
                // Slider for transaction count
                if (_maxTransactions > 1)
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: Theme.of(context).primaryColor,
                      inactiveTrackColor: Theme.of(context).primaryColor.withOpacity(0.3),
                      thumbColor: Theme.of(context).primaryColor,
                      overlayColor: Theme.of(context).primaryColor.withOpacity(0.2),
                      valueIndicatorColor: Theme.of(context).primaryColor,
                      trackHeight: 4,
                    ),
                    child: Slider(
                      value: _selectedTransactionCount.toDouble(),
                      min: 1,
                      max: _maxTransactions.toDouble(),
                      divisions: _maxTransactions > 1 ? _maxTransactions - 1 : null,
                      label: '$_selectedTransactionCount transactions',
                      onChanged: (value) {
                        setState(() {
                          _selectedTransactionCount = value.round();
                        });
                      },
                    ),
                  ),
                
                // Quick selection buttons
                SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: [
                    if (_maxTransactions >= 3)
                      _buildQuickSelectButton(3),
                    if (_maxTransactions >= 5)
                      _buildQuickSelectButton(5),
                    if (_maxTransactions >= 10)
                      _buildQuickSelectButton(10),
                    if (_maxTransactions > 10)
                      _buildQuickSelectButton(_maxTransactions, label: 'All'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildQuickSelectButton(int count, {String? label}) {
    final isSelected = !_shareAllTransactions && _selectedTransactionCount == count;
    final displayLabel = label ?? '$count';
    
    return GestureDetector(
      onTap: () {
        setState(() {
          if (label == 'All') {
            _shareAllTransactions = true;
          } else {
            _shareAllTransactions = false;
            _selectedTransactionCount = count;
          }
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected || (label == 'All' && _shareAllTransactions)
              ? Theme.of(context).primaryColor
              : Theme.of(context).primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Theme.of(context).primaryColor.withOpacity(0.3),
          ),
        ),
        child: Text(
          displayLabel,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected || (label == 'All' && _shareAllTransactions)
                ? Colors.white
                : Theme.of(context).primaryColor,
          ),
        ),
      ),
    );
  }

  Widget _buildPreview() {
    final shareText = ShareService.generateShareText(widget.person, _selectedTransactions);

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
                color: Theme.of(context).textTheme.titleMedium?.color,
              ),
            ),
            Spacer(),
            Text(
              '${_selectedTransactions.length} transactions',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        Container(
          height: 200,
          width: double.infinity,
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey.withOpacity(0.3),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Text(
              shareText,
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: Theme.of(context).textTheme.bodyMedium?.color,
                fontFamily: 'monospace',
              ),
            ),
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
            color: Theme.of(context).textTheme.titleMedium?.color,
          ),
        ),
        SizedBox(height: 16),
        
        // WhatsApp - Primary CTA (Full width)
        Container(
          width: double.infinity,
          margin: EdgeInsets.only(bottom: 12),
          child: ElevatedButton(
            onPressed: _isLoading ? null : _shareViaWhatsApp,
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF25D366), // WhatsApp green
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.chat, size: 20),
                SizedBox(width: 12),
                Text(
                  'Send via WhatsApp',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward, size: 16),
              ],
            ),
          ),
        ),
        
        // Secondary options
        Row(
          children: [
            Expanded(
              child: _buildSecondaryShareButton(
                'SMS',
                Icons.sms,
                Colors.blue,
                () => _shareViaSMS(),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildSecondaryShareButton(
                'More Options',
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

  Widget _buildSecondaryShareButton(
      String label, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: _isLoading ? null : onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(0.3),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
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
                size: 18,
              ),
            ),
            SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
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
      final message = ShareService.generateShareText(widget.person, _selectedTransactions);

      await ContactService.savePersonContact(widget.person.name, _phoneController.text.trim());
      await ShareService.shareViaWhatsApp(phoneNumber, message);

      Navigator.pop(context);
      CustomSnackBar.show(context, 'Shared via WhatsApp successfully!', SnackBarType.success);
    } catch (e) {
      CustomSnackBar.show(context, 'Failed to share via WhatsApp: ${e.toString()}', SnackBarType.error);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
      final message = ShareService.generateShareText(widget.person, _selectedTransactions);

      await ContactService.savePersonContact(widget.person.name, _phoneController.text.trim());
      await ShareService.shareViaSMS(phoneNumber, message);

      Navigator.pop(context);
      CustomSnackBar.show(context, 'SMS app opened successfully!', SnackBarType.success);
    } catch (e) {
      CustomSnackBar.show(context, 'Failed to open SMS: ${e.toString()}', SnackBarType.error);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _shareAsText() async {
    setState(() => _isLoading = true);

    try {
      final message = ShareService.generateShareText(widget.person, _selectedTransactions);

      if (_phoneController.text.trim().isNotEmpty) {
        await ContactService.savePersonContact(widget.person.name, _phoneController.text.trim());
      }

      await ShareService.shareAsText(message);

      Navigator.pop(context);
      CustomSnackBar.show(context, 'Share options opened!', SnackBarType.success);
    } catch (e) {
      CustomSnackBar.show(context, 'Failed to share: ${e.toString()}', SnackBarType.error);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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