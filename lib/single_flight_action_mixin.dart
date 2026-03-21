import 'package:flutter/widgets.dart';

/// Prevents the same UI action from being started more than once at a time.
mixin SingleFlightActionMixin<T extends StatefulWidget> on State<T> {
  final Set<String> _inFlightActions = <String>{};

  bool isActionInFlight(String action) => _inFlightActions.contains(action);

  bool isAnyActionInFlight(Iterable<String> actions) {
    for (final action in actions) {
      if (_inFlightActions.contains(action)) {
        return true;
      }
    }
    return false;
  }

  Future<R?> runSingleFlight<R>(
    String action,
    Future<R> Function() operation,
  ) async {
    if (_inFlightActions.contains(action)) {
      return null;
    }

    if (mounted) {
      setState(() {
        _inFlightActions.add(action);
      });
    } else {
      _inFlightActions.add(action);
    }

    try {
      return await operation();
    } finally {
      if (!mounted) {
        _inFlightActions.remove(action);
      } else {
        setState(() {
          _inFlightActions.remove(action);
        });
      }
    }
  }
}
