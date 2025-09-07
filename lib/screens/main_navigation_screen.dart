import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'home_screen.dart';
import 'people_manager_screen.dart';
import 'settings_screen.dart';
import '../widgets/add_transaction_modal.dart';
import '../widgets/add_people_transaction_modal.dart';
import '../services/hive_service.dart';
import '../services/people_hive_service.dart';
import '../widgets/custom_snackbar.dart';

class MainNavigationScreen extends StatefulWidget {
  @override
  _MainNavigationScreenState createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> with TickerProviderStateMixin {
  int _currentIndex = 0;
  late PageController _pageController;
  late AnimationController _fabAnimationController;
  late AnimationController _fabMorphController;
  late Animation<double> _fabScaleAnimation;
  late Animation<double> _fabRotationAnimation;
  late Animation<double> _morphAnimation;
  late Animation<Offset> _positionAnimation;
  
  // Keys for accessing child screen methods
  final GlobalKey<HomeScreenState> _homeScreenKey = GlobalKey<HomeScreenState>();

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    
    // FAB animation controller for show/hide
    _fabAnimationController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    
    // FAB morph animation controller for shape and position changes
    _fabMorphController = AnimationController(
      duration: Duration(milliseconds: 400),
      vsync: this,
    );
    
    _fabScaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fabAnimationController,
      curve: Curves.elasticOut,
    ));
    
    _fabRotationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fabAnimationController,
      curve: Curves.easeInOut,
    ));
    
    _morphAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fabMorphController,
      curve: Curves.easeInOutCubic,
    ));
    
    _positionAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _fabMorphController,
      curve: Curves.easeInOutCubic,
    ));
    
    _fabAnimationController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fabAnimationController.dispose();
    _fabMorphController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    if (index == _currentIndex) return;
    
    final previousIndex = _currentIndex;
    
    setState(() {
      _currentIndex = index;
    });
    
    _pageController.animateToPage(
      index,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeInOutCubic,
    );
    
    // Haptic feedback for better UX
    HapticFeedback.lightImpact();
    
    // Handle FAB animations based on tab changes
    _handleFABTransition(previousIndex, index);
  }

  void _handleFABTransition(int fromIndex, int toIndex) {
    // Show FABs on Home (0) and People (1) tabs, hide on Settings (2)
    if ((fromIndex == 2 && (toIndex == 0 || toIndex == 1)) ||
        (fromIndex == -1 && (toIndex == 0 || toIndex == 1))) {
      // Show FABs
      _fabAnimationController.forward();
    } else if ((fromIndex == 0 || fromIndex == 1) && toIndex == 2) {
      // Hide FABs
      _fabAnimationController.reverse();
    }
    
    // Handle morphing animation between Home and People tabs
    if ((fromIndex == 0 && toIndex == 1) || (fromIndex == 1 && toIndex == 0)) {
      _triggerMorphAnimation();
    }
  }

  void _triggerMorphAnimation() {
    _fabMorphController.forward().then((_) {
      _fabMorphController.reverse();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          final previousIndex = _currentIndex;
          setState(() {
            _currentIndex = index;
          });
          
          _handleFABTransition(previousIndex, index);
        },
        children: [
          HomeScreen(key: _homeScreenKey),
          PeopleManagerScreen(),
          SettingsScreen(),
        ],
      ),
      bottomNavigationBar: _buildModernBottomNavBar(),
      floatingActionButton: _buildAnimatedFAB(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _buildModernBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Container(
          height: 80,
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.home_outlined, Icons.home, 'Home'),
              _buildNavItem(1, Icons.people_outline, Icons.people, 'People'),
              SizedBox(width: 80), // Increased space for FAB area
              _buildNavItem(2, Icons.settings_outlined, Icons.settings, 'Settings'),
              SizedBox(width: 10), // Reduced to balance the layout with FABs shifted right
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData outlinedIcon, IconData filledIcon, String label) {
    final isSelected = _currentIndex == index;
    final color = isSelected 
        ? Theme.of(context).primaryColor 
        : Colors.grey[600];

    return GestureDetector(
      onTap: () => _onTabTapped(index),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected 
              ? Theme.of(context).primaryColor.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: Duration(milliseconds: 200),
              child: Icon(
                isSelected ? filledIcon : outlinedIcon,
                key: ValueKey(isSelected),
                color: color,
                size: 24,
              ),
            ),
            SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: isSelected ? 12 : 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: color,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedFAB() {
    // Only show FABs on Home (0) and People (1) tabs
    if (_currentIndex == 2) {
      return SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: _fabAnimationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _fabScaleAnimation.value,
          child: Transform.rotate(
            angle: _fabRotationAnimation.value * 0.1,
            child: Container(
              // Shift FABs slightly to the right
              margin: EdgeInsets.only(right: 20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).primaryColor.withOpacity(0.3),
                    blurRadius: 15,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: AnimatedBuilder(
                animation: _morphAnimation,
                builder: (context, child) {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildMorphingFAB(
                        isLeft: true,
                        onPressed: _currentIndex == 0 
                            ? _showAddPeopleTransactionModal 
                            : () => _showAddTransactionModal(false),
                        heroTag: "left_fab",
                        backgroundColor: _currentIndex == 0 ? Colors.purple : Theme.of(context).primaryColor,
                        icon: _currentIndex == 0 ? Icons.person_add : Icons.add,
                        iconSize: _currentIndex == 0 ? 20 : 28,
                        isMini: _currentIndex == 0,
                      ),
                      SizedBox(width: 12),
                      _buildMorphingFAB(
                        isLeft: false,
                        onPressed: _currentIndex == 0 
                            ? () => _showAddTransactionModal(false)
                            : _showAddPeopleTransactionModal,
                        heroTag: "right_fab",
                        backgroundColor: _currentIndex == 0 ? Theme.of(context).primaryColor : Colors.purple,
                        icon: _currentIndex == 0 ? Icons.add : Icons.person_add,
                        iconSize: _currentIndex == 0 ? 28 : 20,
                        isMini: _currentIndex == 1,
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMorphingFAB({
    required bool isLeft,
    required VoidCallback onPressed,
    required String heroTag,
    required Color backgroundColor,
    required IconData icon,
    required double iconSize,
    required bool isMini,
  }) {
    // Calculate morph values
    final morphValue = _morphAnimation.value;
    final isHomePage = _currentIndex == 0;
    
    // For smooth morphing, we need to interpolate between the two states
    double fabSize;
    BorderRadius borderRadius;
    
    if (isLeft) {
      // Left FAB: mini circle on home, regular square on people
      if (isHomePage) {
        // Home: mini circle
        fabSize = 40.0;
        borderRadius = BorderRadius.circular(20);
      } else {
        // People: morphing from mini circle to regular square
        fabSize = 40.0 + (16.0 * morphValue); // 40 -> 56
        final radiusValue = 20.0 - (4.0 * morphValue); // 20 -> 16
        borderRadius = BorderRadius.circular(radiusValue);
      }
    } else {
      // Right FAB: regular square on home, mini circle on people
      if (isHomePage) {
        // Home: regular square
        fabSize = 56.0;
        borderRadius = BorderRadius.circular(16);
      } else {
        // People: morphing from regular square to mini circle
        fabSize = 56.0 - (16.0 * morphValue); // 56 -> 40
        final radiusValue = 16.0 + (4.0 * morphValue); // 16 -> 20
        borderRadius = BorderRadius.circular(radiusValue);
      }
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: [
          BoxShadow(
            color: backgroundColor.withOpacity(0.3),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
        width: fabSize,
        height: fabSize,
        child: Material(
          color: backgroundColor,
          borderRadius: borderRadius,
          child: InkWell(
            borderRadius: borderRadius,
            onTap: onPressed,
            onLongPress: (heroTag == "right_fab" && _currentIndex == 0) 
                ? () => _showAddTransactionModal(true) 
                : null,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: borderRadius,
              ),
              child: Center(
                child: AnimatedRotation(
                  duration: Duration(milliseconds: 400),
                  turns: morphValue * 0.5, // Half rotation for smooth effect
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: iconSize,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showAddTransactionModal([bool? forceIncome]) {
    // Show haptic feedback for long press
    if (forceIncome == true) {
      HapticFeedback.mediumImpact();
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddTransactionModal(
        forceIncome: forceIncome,
        onSave: (transaction) async {
          await HiveService.addTransaction(transaction);
          // Refresh home screen data
          _homeScreenKey.currentState?.refreshData();
          CustomSnackBar.show(
              context, 'Transaction added successfully!', SnackBarType.success);
        },
      ),
    );
  }

  void _showAddPeopleTransactionModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddPeopleTransactionModal(
        onSave: (transaction) async {
          await PeopleHiveService.addPeopleTransaction(transaction);
          // Refresh home screen data
          _homeScreenKey.currentState?.refreshData();
          CustomSnackBar.show(context, 'People transaction added successfully!',
              SnackBarType.success);
        },
      ),
    );
  }
}