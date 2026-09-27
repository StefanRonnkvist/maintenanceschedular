import 'package:flutter/material.dart';

/// Dismissible warning about storage limitations in the web build.
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
      color: Theme.of(context).colorScheme.error,
      child: SafeArea(
        top: false,
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  'PWA notice: database functions are not available on web '
                  'builds. Data is temporary for this browser session only.',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onError,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => setState(() => _isVisible = false),
                icon: Icon(
                  Icons.close,
                  color: Theme.of(context).colorScheme.onError,
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
