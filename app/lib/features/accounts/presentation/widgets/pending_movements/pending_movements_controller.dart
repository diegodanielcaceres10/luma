import 'package:flutter/material.dart';

import 'pending_movement.dart';

/// Holds the [PendingMovement]s accumulated by a [PendingMovementsSection]
/// so the owning screen can read them (and their [total]) when it is time to
/// persist or discard them. The screen owns the controller's lifecycle and
/// must call [dispose] once it is done with it.
class PendingMovementsController extends ChangeNotifier {
  final List<PendingMovement> _movements = [];

  List<PendingMovement> get movements => List.unmodifiable(_movements);

  bool get isEmpty => _movements.isEmpty;
  bool get isNotEmpty => _movements.isNotEmpty;

  /// Sum of every accumulated movement's signed amount, rounded to cents so
  /// repeated double addition doesn't leave remainders.
  double get total {
    final cents = _movements.fold<int>(
      0,
      (sum, movement) => sum + (movement.amount * 100).round(),
    );
    return cents / 100;
  }

  void add(PendingMovement movement) {
    _movements.add(movement);
    notifyListeners();
  }

  void remove(PendingMovement movement) {
    _movements.remove(movement);
    notifyListeners();
  }

  /// Swaps [old] for [updated] keeping its position in the list, so editing
  /// a movement doesn't send it to the bottom. Does nothing if [old] is no
  /// longer queued.
  void replace(PendingMovement old, PendingMovement updated) {
    final index = _movements.indexOf(old);
    if (index == -1) return;
    _movements[index] = updated;
    notifyListeners();
  }

  void removeWhere(bool Function(PendingMovement movement) test) {
    _movements.removeWhere(test);
    notifyListeners();
  }

  void clear() {
    _movements.clear();
    notifyListeners();
  }
}
