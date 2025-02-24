import 'package:flutter/foundation.dart';

/// Generic notifier that keeps the section active.
/// This implementation is the default that consumers of the library
/// can use without having to reimplement the logic.
class ActiveSectionNotifier<K> extends ChangeNotifier {
  ActiveSectionNotifier(this._activeSection);

  K _activeSection;

  K get activeSection => _activeSection;

  /// Updates the active section and notifies listeners only if it changes.
  void updateActiveSection(K section) {
    if (_activeSection != section) {
      _activeSection = section;
      notifyListeners();
    }
  }
}
