import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';

import 'scan_stage.dart';

enum ScanProgressPhase { running, done, failed }

/// What the progress popup shows at a given moment.
@immutable
class ScanProgressState {
  final ScanStage stage;
  final ScanProgressPhase phase;

  /// Why it failed; only set when [phase] is [ScanProgressPhase.failed].
  final String? message;

  const ScanProgressState(this.stage, this.phase, {this.message});
}

/// Decides what the progress popup shows while a scan reports its stages.
///
/// Each state is shown for at least [stageDuration], so a stage that finishes
/// quickly can still be read. A stage that takes longer is not stretched: the
/// next one appears as soon as it is reported. A failure is shown right away.
class ScanProgressTimeline extends ChangeNotifier {
  static const defaultStageDuration = Duration(seconds: 1);

  final Duration stageDuration;

  ScanProgressState _state = const ScanProgressState(
    ScanStage.preparing,
    ScanProgressPhase.running,
  );
  final Queue<ScanProgressState> _pending = Queue();
  Timer? _holdTimer;

  /// Whether the state on screen has not been shown long enough to be
  /// replaced yet.
  bool _holding = false;
  Completer<void>? _doneShown;
  bool _closed = false;
  bool _disposed = false;

  ScanProgressTimeline({this.stageDuration = defaultStageDuration}) {
    _startHold();
  }

  ScanProgressState get state => _state;

  ScanProgressState get _last => _pending.isEmpty ? _state : _pending.last;

  /// The scan moved on to [stage]. A repeated stage is ignored.
  void report(ScanStage stage) {
    final last = _last;
    if (_closed ||
        last.phase != ScanProgressPhase.running ||
        last.stage == stage) {
      return;
    }
    _pending.add(ScanProgressState(stage, ScanProgressPhase.running));
    _advance();
  }

  /// The scan succeeded. Completes once "done" has been on screen for a full
  /// [stageDuration], after any stage that was still waiting to be shown.
  Future<void> complete() {
    if (_closed) return Future.value();
    final shown = _doneShown = Completer<void>();
    _pending.add(ScanProgressState(_last.stage, ScanProgressPhase.done));
    _advance();
    return shown.future;
  }

  /// The scan failed in the last stage that was reported. Shown at once; the
  /// stages that were still waiting are dropped.
  void fail(String message) {
    if (_closed) return;
    final stage = _last.stage;
    _closed = true;
    _pending.clear();
    _holdTimer?.cancel();
    _state = ScanProgressState(
      stage,
      ScanProgressPhase.failed,
      message: message,
    );
    notifyListeners();
  }

  void _startHold() {
    _holding = true;
    _holdTimer?.cancel();
    _holdTimer = Timer(stageDuration, _holdElapsed);
  }

  void _holdElapsed() {
    _holding = false;
    if (_state.phase == ScanProgressPhase.done) {
      _doneShown?.complete();
      return;
    }
    _advance();
  }

  void _advance() {
    if (_holding || _pending.isEmpty || _closed) return;
    _state = _pending.removeFirst();
    _startHold();
    notifyListeners();
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _closed = true;
    _holdTimer?.cancel();
    final shown = _doneShown;
    if (shown != null && !shown.isCompleted) shown.complete();
    super.dispose();
  }
}
