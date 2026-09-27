import 'package:flutter/material.dart';
import 'package:plannedmaintenance/features/home/presentation/widgets/theme_mode_toggle_button.dart';

/// App bar that owns the home tabs and the theme-mode action.
class HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  const HomeAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Text('Maintenance Schedule'),
      actions: const [ThemeModeToggleButton()],
      bottom: const TabBar(
        tabs: <Widget>[
          Tab(icon: Icon(Icons.build_outlined), text: 'Maintenance'),
          Tab(icon: Icon(Icons.help_outline), text: 'Help'),
          Tab(icon: Icon(Icons.info_outline), text: 'Information'),
        ],
      ),
    );
  }

  @override
  Size get preferredSize =>
      const Size.fromHeight(kToolbarHeight + kTextTabBarHeight);
}
