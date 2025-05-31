import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class MainScaffold extends StatefulWidget {
  final Widget body;
  final int currentIndex;
  final String? title;
  final List<Widget>? actions;
  final Widget? leading;

  const MainScaffold({
    super.key, 
    required this.body,
    required this.currentIndex,
    this.title,
    this.actions,
    this.leading,
  });

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  void _onTap(BuildContext context, int index) {
    if (index == widget.currentIndex) return;
    switch (index) {
      case 0:
        context.go('/homepage');
        break;
      case 1:
        context.go('/jadwal-perkuliahan');
        break;
      case 2:
        context.go('/jadwal-kerja-kelompok');
        break;
      case 3:
        context.go('/settings');
        break;
    }
  }

  Widget _buildNavItem(int index, IconData icon, IconData activeIcon) {
    final isActive = index == widget.currentIndex;
    return IconButton(
      icon: FaIcon(
        isActive ? activeIcon : icon,
        size: 20,
      ),
      color: isActive ? Color(0xFFFBBF24) : Colors.grey[600],
      onPressed: () => _onTap(context, index),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.title != null
          ? AppBar(
              title: Text(widget.title!),
              actions: widget.actions,
              leading: widget.leading,
              backgroundColor: Colors.white,
              foregroundColor: Theme.of(context).primaryColor,
              elevation: 0,
              centerTitle: true,
            )
          : null,
      body: Column(
        children: [
          Expanded(
            child: widget.body,
          ),
          SizedBox(height: 80), // Add padding for bottom navigation bar
        ],
      ),
      extendBody: true,
      bottomNavigationBar: Container(
        margin: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Color(0xFF2E2E2E),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: Offset(0, -5),
            ),
          ],
        ),
        height: 56,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(0, FontAwesomeIcons.home, FontAwesomeIcons.home),
            _buildNavItem(1, FontAwesomeIcons.calendarAlt, FontAwesomeIcons.calendarAlt),
            _buildNavItem(2, FontAwesomeIcons.stream, FontAwesomeIcons.stream),
            _buildNavItem(3, FontAwesomeIcons.user, FontAwesomeIcons.user),
          ],
        ),
      ),
      backgroundColor: Colors.white, // Change back to white background
    );
  }
}
