import 'package:flutter/material.dart';

/// Dismissible note explaining that web data is stored in this browser.
class PwaDatabaseNotice extends StatefulWidget {
  const PwaDatabaseNotice({super.key});

  @override
  State<PwaDatabaseNotice> createState() => _PwaDatabaseNoticeState();
}

class _PwaDatabaseNoticeState extends State<PwaDatabaseNotice> {
  bool _isVisible = true;

  @override
  Widget build(BuildContext context) {
    if (!_isVisible) {
      return const SizedBox.shrink();
    }

    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: SafeArea(
        top: false,
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  'Your selections and support-form fields are stored in this '
                  'browser. Clearing browser data removes saved values.',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => setState(() => _isVisible = false),
                icon: Icon(
                  Icons.close,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                tooltip: 'Dismiss PWA notice',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
