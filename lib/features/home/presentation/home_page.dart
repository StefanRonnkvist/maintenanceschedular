import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:plannedmaintenance/contact/contact_page.dart';
import 'package:plannedmaintenance/features/help/presentation/help_page.dart';
import 'package:plannedmaintenance/features/home/presentation/widgets/widgets.dart';
import 'package:plannedmaintenance/features/maintenance/presentation/presentation.dart';

/// Hosts the maintenance, help, and contact workflows in a tabbed scaffold.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      initialIndex: 1,
      child: Scaffold(
        appBar: const HomeAppBar(),
        body: Column(
          children: <Widget>[
            if (kIsWeb) const PwaDatabaseNotice(),
            Expanded(
              child: TabBarView(
                children: <Widget>[
                  const CsvDropdowns(),
                  const HelpPage(),
                  ContactPage(
                    serverUri: Uri.parse(
                      'https://stefanronnkvist.com/contact.php',
                    ),
                    showAppBar: false,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
