import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;
    
    // Adjusted sizes
    const double iconSize = 24.0;  // Reduced from 28
    const double navBarHeight = 70.0;  // Reduced from 80
    
    return Container(
      height: navBarHeight + MediaQuery.of(context).padding.bottom,  // Add padding for safe area
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            blurRadius: 10,
            spreadRadius: 2,
            offset: const Offset(0, -2),
          ),
        ],
        border: Border(
          top: BorderSide(
            color: Colors.grey.withOpacity(0.3),
            width: 1.0,
          ),
        ),
      ),
      child: SafeArea(
        child: SizedBox(  // Added SizedBox to constrain height
          height: navBarHeight,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                context: context,
                icon: Icons.home_outlined,
                activeIcon: Icons.home,
                label: 'Home',
                index: 0,
                primaryColor: primaryColor,
                iconSize: iconSize,
              ),
              _buildNavItem(
                context: context,
                icon: Icons.medical_services_outlined,
                activeIcon: Icons.medical_services,
                label: 'AI Doctor',
                index: 1,
                primaryColor: primaryColor,
                iconSize: iconSize,
              ),
              _buildNavItem(
                context: context,
                icon: Icons.people_outline,
                activeIcon: Icons.people,
                label: 'Connect',
                index: 2,
                primaryColor: primaryColor,
                iconSize: iconSize,
              ),
              _buildNavItem(
                context: context,
                icon: Icons.person_outline,
                activeIcon: Icons.person,
                label: 'Profile',
                index: 3,
                primaryColor: primaryColor,
                iconSize: iconSize,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
    required Color primaryColor,
    required double iconSize,
  }) {
    final isSelected = currentIndex == index;
    final iconColor = isSelected ? primaryColor : Colors.grey[600];
    final textColor = isSelected ? primaryColor : Colors.grey[600];
    final backgroundColor = isSelected ? primaryColor.withOpacity(0.1) : Colors.transparent;
    
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap(index);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 6),  // Reduced padding
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isSelected ? activeIcon : icon,
                  size: iconSize,
                  color: iconColor,
                ),
                const SizedBox(height: 2),  // Reduced spacing
                Text(
                  label,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 12,  // Reduced font size
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                if (isSelected)
                  Container(
                    margin: const EdgeInsets.only(top: 3),  // Reduced margin
                    height: 3,  // Reduced height
                    width: 24,  // Reduced width
                    decoration: BoxDecoration(
                      color: primaryColor,
                      borderRadius: BorderRadius.circular(1.5),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}