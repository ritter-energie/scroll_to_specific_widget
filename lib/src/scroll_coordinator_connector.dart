import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:outcome_types/outcome_types.dart';
import 'package:provider/provider.dart';
import 'package:scroll_to_specific_widget/src/active_section_notifier.dart';
import 'package:scroll_to_specific_widget/src/scroll_candidate.dart';
import 'package:scroll_to_specific_widget/src/scroll_candidate_selector_delegate.dart';
import 'package:scroll_to_specific_widget/src/scroll_coordinator.dart';

/// Responsible for connecting the presentation layer of the app
/// to a [ScrollCoordinator]. This involves creating a [ScrollCoordinator]
/// based on a [ScrollCandidateSelectorDelegate], providing that
/// [ScrollCoordinator] to the widget tree using a [Provider], and handling the
/// scroll events received from [ScrollCoordinator.listen] by calling
/// [ScrollController.animateTo], thereby performing the actual scrolling.
///
class ScrollCoordinatorConnector<K> extends StatefulWidget {
  const ScrollCoordinatorConnector({
    required this.scrollController,
    required this.child,
    this.candidateSelectorDelegate,
    this.scrollAnimationCurve,
    this.scrollAnimationDuration,
    this.onSectionChanged,
    this.initialActiveSection,
    this.defaultActiveSectionNotifier,
    super.key,
  });

  final ScrollController scrollController;

  final ScrollCandidateSelectorDelegate<K>? candidateSelectorDelegate;

  final Widget child;

  final Duration? scrollAnimationDuration;
  final Curve? scrollAnimationCurve;

  final void Function(K activeSection)? onSectionChanged;

  final K? initialActiveSection;
  final ActiveSectionNotifier<K>? defaultActiveSectionNotifier;

  @override
  State<ScrollCoordinatorConnector<K>> createState() =>
      _ScrollCoordinatorConnectorState<K>();
}

class _ScrollCoordinatorConnectorState<K>
    extends State<ScrollCoordinatorConnector<K>> {
  static const _defaultScrollAnimationDuration = Duration(milliseconds: 500);
  static const _defaultScrollAnimationCurve = Curves.easeOutCubic;

  /// Create or use the default [ActiveSectionNotifier] if not provided.
  late final ActiveSectionNotifier<K> _defaultNotifier =
      widget.defaultActiveSectionNotifier ??
          ActiveSectionNotifier<K>(widget.initialActiveSection as K);

  /// If the user did not pass a candidateSelectorDelegate, we use the default
  late final ScrollCandidateSelectorDelegate<K> _selectorDelegate =
      widget.candidateSelectorDelegate ?? DefaultScrollCandidateSelector<K>();

  late final _scrollCoordinator = ScrollCoordinator<K>(
    candidateSelectorDelegate: _selectorDelegate,
  );
  ScrollController get _scrollController => widget.scrollController;

  @override
  void initState() {
    super.initState();
    _scrollCoordinator.listen(_scrollCoordinatorListener);
    widget.scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_onScroll);
    _scrollCoordinator.dispose();
    super.dispose();
  }

  void _onScroll() {
    final currentOffset = _scrollController.position.pixels;
    final candidates = _scrollCoordinator.getRegisteredCandidates();
    K? closestCandidate;
    var minDiff = double.infinity;

    candidates.forEach((key, candidateOption) {
      if (candidateOption is Some<ScrollCandidate>) {
        final candidate = candidateOption.value;
        final diff = (candidate.scrollOffset - currentOffset).abs();
        if (diff < minDiff) {
          minDiff = diff;
          closestCandidate = key;
        }
      }
    });

    if (closestCandidate != null) {
      _defaultNotifier.updateActiveSection(closestCandidate!);
      widget.onSectionChanged?.call(closestCandidate!);
    }
  }

  Future<void> _scrollCoordinatorListener(
    ScrollCandidate scrollCandidate,
  ) async {
    var clampedOffset = clampDouble(
      scrollCandidate.scrollOffset,
      _scrollController.position.minScrollExtent,
      _scrollController.position.maxScrollExtent,
    );

    if (clampedOffset > _scrollController.position.pixels) {
      clampedOffset = _scrollController.position.pixels;
    }

    await _scrollController.animateTo(
      scrollCandidate.scrollOffset,
      duration:
          widget.scrollAnimationDuration ?? _defaultScrollAnimationDuration,
      curve: widget.scrollAnimationCurve ?? _defaultScrollAnimationCurve,
    );
    scrollCandidate.onScrollToOffset?.call();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider.value(value: _scrollCoordinator),
        ChangeNotifierProvider<ActiveSectionNotifier<K>>.value(
          value: _defaultNotifier,
        ),
      ],
      child: widget.child,
    );
  }
}
