import 'package:outcome_types/outcome_types.dart';

// imported for docs
import 'package:scroll_to_specific_widget/src/scroll_candidate.dart';

/// Create a subtype of [ScrollCandidateSelectorDelegate] to specify
/// the logic used for selecting the most desirable
/// scrolling target (candidate).
///
// ignore: one_member_abstracts
abstract interface class ScrollCandidateSelectorDelegate<K> {
  Option<ScrollCandidate> selectCandidate(
    Map<K, Option<ScrollCandidate>> registeredCandidates,
  );
}

class DefaultScrollCandidateSelector<K>
    implements ScrollCandidateSelectorDelegate<K> {
  Option<K> targetTab = const None();

  @override
  Option<ScrollCandidate> selectCandidate(
    Map<K, Option<ScrollCandidate>> registeredCandidates,
  ) =>
      switch (targetTab) {
        Some(value: final targetTab) =>
          registeredCandidates[targetTab] ?? const None(),
        None() => const None(),
      };
}
