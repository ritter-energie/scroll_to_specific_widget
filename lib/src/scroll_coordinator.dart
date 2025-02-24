import 'dart:async';

import 'package:flutter/rendering.dart';
import 'package:outcome_types/outcome_types.dart';
import 'package:scroll_to_specific_widget/src/scroll_candidate.dart';
import 'package:scroll_to_specific_widget/src/scroll_candidate_selector_delegate.dart';

// imported for docs
// ignore: directives_ordering
import 'package:scroll_to_specific_widget/src/scroll_candidate_callback_registerer.dart';

/// This class receives registrations for scroll candidate callbacks and
/// once scrolling is requested via [triggerScroll], selects the most
/// desirable scrolling candidate using [candidateSelectorDelegate] and
/// emits that candidate through [_streamController];
///
///
/// [ScrollCandidateCallbackRegisterer]s in the widget tree will
/// register [Option<ScrollCandidate> Function]s to this class.
///
/// These callbacks represent a way for to obtain the scroll offset of
/// the [ScrollCandidateCallbackRegisterer]s when [triggerScroll] is
/// called. The return type is [Option<ScrollCandidate>] because there are
/// scenarios when it is not possible to obtain the scroll offset, for instance
/// if a [ScrollCandidateCallbackRegisterer] has incorrectly been placed outside
/// of a [RenderAbstractViewport].
///
/// When [triggerScroll] is called, we pass all the registered scroll
/// candidate callbacks to [ScrollCandidateSelectorDelegate.selectCandidate].
/// If a viable candidate is selected, we emit that candidate through
/// [_streamController].
class ScrollCoordinator<K> {
  ScrollCoordinator({required this.candidateSelectorDelegate});

  final ScrollCandidateSelectorDelegate<K> candidateSelectorDelegate;

  final _scrollCandidateCallbackRegistrations =
      <K, Option<ScrollCandidate> Function()>{};

  final _candidateKeyToRegistrationKey = <K, Object>{};

  late final _streamController = StreamController<ScrollCandidate>.broadcast(
    onCancel: () => _streamActive = false,
    onListen: () => _streamActive = true,
  );

  var _streamActive = false;

  void registerScrollCandidateCallback({
    required K candidateKey,
    required Object registrationKey,
    required Option<ScrollCandidate> Function() candidateCallback,
  }) {
    if (_scrollCandidateCallbackRegistrations.containsKey(candidateKey)) {
      assert(false, 'scroll candidate with $candidateKey already registered');
    }
    _scrollCandidateCallbackRegistrations[candidateKey] = candidateCallback;
    _candidateKeyToRegistrationKey[candidateKey] = registrationKey;
  }

  void unregisterScrollCandidateCallback({
    required K candidateKey,
    required Object registrationKey,
  }) {
    if (_candidateKeyToRegistrationKey[candidateKey] == registrationKey) {
      _scrollCandidateCallbackRegistrations.remove(candidateKey);
    }
  }

  Map<K, Option<ScrollCandidate>> getRegisteredCandidates() {
    return _scrollCandidateCallbackRegistrations.map(
      (key, candidateCallback) => MapEntry(key, candidateCallback()),
    );
  }

  StreamSubscription<ScrollCandidate> listen(
    void Function(ScrollCandidate)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) =>
      _streamController.stream.listen(
        onData,
        onError: onError,
        onDone: onDone,
        cancelOnError: cancelOnError,
      );

  void triggerScroll() {
    if (!_streamActive) return;

    final candidates = _scrollCandidateCallbackRegistrations
        .map((key, eventCallback) => MapEntry(key, eventCallback()));

    if (candidateSelectorDelegate.selectCandidate(candidates)
        case Some(value: final candidate)) {
      _streamController.add(candidate);
    }
  }

  void scrollToCandidate(K candidateKey) {
    final candidateOption =
        _scrollCandidateCallbackRegistrations[candidateKey]?.call();
    if (candidateOption is Some<ScrollCandidate>) {
      _streamController.add(candidateOption.value);
    }
  }

  Future<void> dispose() => _streamController.close();
}
