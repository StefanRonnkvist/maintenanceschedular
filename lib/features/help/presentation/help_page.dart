import 'package:flutter/material.dart';

/// Provides expandable guidance for the maintenance and contact workflows.
class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const <Widget>[
        Text(
          'Help Center',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
        ),
        SizedBox(height: 8),
        Text('Choose a category to learn how to use the maintenance guide.'),
        SizedBox(height: 16),
        _HelpCategory(
          icon: Icons.play_circle_outline,
          title: 'Getting started',
          children: <Widget>[
            _HelpItem(
              title: 'Find a maintenance task',
              body:
                  'Open Maintenance and choose a Group, then continue through '
                  'the fields that appear. Each choice filters the next field '
                  'until the matching maintenance details are shown.',
            ),
            _HelpItem(
              title: 'Automatic values',
              body:
                  'When only one value matches your choices, the app fills it '
                  'in automatically. Read-only fields are part of the selected '
                  'schedule and do not need input.',
            ),
            _HelpItem(
              title: 'Change an earlier selection',
              body:
                  'Select a different value in any earlier field. Later fields '
                  'are cleared automatically so that only matching maintenance '
                  'information is shown.',
            ),
          ],
        ),
        _HelpCategory(
          icon: Icons.event_note_outlined,
          title: 'Schedule fields',
          children: <Widget>[
            _HelpItem(
              title: 'Description and estimated time',
              body:
                  'Description identifies the maintenance task. Estimated time '
                  'is the planned task duration and may not include preparation '
                  'or return-to-service checks.',
            ),
            _HelpItem(
              title: 'Level and out of service',
              body:
                  'Level identifies the required personnel qualification. Out '
                  'of Service indicates whether the equipment is expected to '
                  'be unavailable while the task is performed.',
            ),
            _HelpItem(
              title: 'Maintenance intervals',
              body:
                  'Schedule, Time in service, Checking, Replacement, and When '
                  'necessary describe when a task should be considered. Follow '
                  'the maintenance sheet for the authoritative procedure.',
            ),
            _HelpItem(
              title: 'Maintenance sheet',
              body:
                  'Use the displayed sheet reference to locate the detailed '
                  'service procedure and required precautions.',
            ),
          ],
        ),
        _HelpCategory(
          icon: Icons.settings_outlined,
          title: 'App settings and data',
          children: <Widget>[
            _HelpItem(
              title: 'Offline maintenance data',
              body:
                  'Maintenance schedules and level descriptions are included '
                  'with the app, so browsing them does not require an internet '
                  'connection.',
            ),
            _HelpItem(
              title: 'Change the theme',
              body:
                  'Use the brightness icon in the top bar to cycle through '
                  'system, light, and dark theme modes.',
            ),
          ],
        ),
        _HelpCategory(
          icon: Icons.engineering_outlined,
          title: 'Skill levels and safety',
          children: <Widget>[
            _HelpItem(
              title: 'L1 - Operator',
              body:
                  'A person with specific knowledge of operating the machine.',
            ),
            _HelpItem(
              title: 'L2 - Maintenance Technician',
              body:
                  'A trained professional qualified to work on the mechanical '
                  'parts of the machine and its installations.',
            ),
            _HelpItem(
              title: 'L3 - Authorized Service Technician',
              body:
                  'Prima Industrie Technical Assistance personnel or a person '
                  'with specific authorization from Technical Assistance.',
            ),
            _HelpItem(
              title: 'Work safely',
              body:
                  'This app is a schedule reference, not a replacement for the '
                  'machine manual, maintenance sheet, training, lockout '
                  'procedures, or site safety requirements.',
            ),
          ],
        ),
        _HelpCategory(
          icon: Icons.support_agent_outlined,
          title: 'Troubleshooting and contact',
          children: <Widget>[
            _HelpItem(
              title: 'No options are displayed',
              body:
                  'Return to the first field and choose a machine group. Each '
                  'later field appears only after the previous selection has '
                  'matching data.',
            ),
            _HelpItem(
              title: 'Ask a question',
              body:
                  'Open Information, enter your contact details and question, '
                  'then select Send Question. The app sends your name, email, '
                  'question, app version, and basic platform and layout details '
                  'to the support service. An internet connection is required.',
            ),
            _HelpItem(
              title: 'A question could not be sent',
              body:
                  'Check your internet connection and correct any highlighted '
                  'fields. If package detection failed, select Retry before '
                  'sending again. The server response appears below the form.',
            ),
          ],
        ),
      ],
    );
  }
}

/// Groups related help items in an expandable category.
class _HelpCategory extends StatelessWidget {
  const _HelpCategory({
    required this.icon,
    required this.title,
    required this.children,
  });

  final IconData icon;
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: Icon(icon),
        title: Text(title),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: children,
      ),
    );
  }
}

/// Renders a titled piece of guidance inside a help category.
class _HelpItem extends StatelessWidget {
  const _HelpItem({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 4),
          Align(alignment: Alignment.centerLeft, child: Text(body)),
        ],
      ),
    );
  }
}
