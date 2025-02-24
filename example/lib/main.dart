import 'package:flutter/material.dart';
import 'package:outcome_types/outcome_types.dart';
import 'package:provider/provider.dart';
import 'package:scroll_to_specific_widget/scroll_to_specific_widget.dart';

enum Category { A, B, C, D }

enum ValidationStatus { valid, invalid }

class _CategoryA extends StatelessWidget {
  const _CategoryA();

  @override
  Widget build(BuildContext context) {
    return ScrollCandidateCallbackRegisterer(
      scrollCandidateKey: Category.A,
      child: Container(
        height: 400,
        color: Colors.red,
      ),
    );
  }
}

class _CategoryB extends StatelessWidget {
  const _CategoryB();

  @override
  Widget build(BuildContext context) {
    return ScrollCandidateCallbackRegisterer(
      scrollCandidateKey: Category.B,
      child: Container(
        height: 600,
        color: Colors.green,
      ),
    );
  }
}

class _CategoryC extends StatelessWidget {
  const _CategoryC();

  @override
  Widget build(BuildContext context) {
    return ScrollCandidateCallbackRegisterer(
      scrollCandidateKey: Category.C,
      child: Container(
        height: 800,
        color: Colors.blue,
      ),
    );
  }
}

class _CategoryD extends StatelessWidget {
  const _CategoryD();

  @override
  Widget build(BuildContext context) {
    return ScrollCandidateCallbackRegisterer(
      scrollCandidateKey: Category.D,
      child: Container(
        height: 1000,
        color: Colors.purple,
      ),
    );
  }
}

class _CandidateSelectorDelegate
    implements ScrollCandidateSelectorDelegate<Category> {
  final _categoriesByStatus = <ValidationStatus, List<Category>>{};

  void updateValidationStatus(
    Map<Category, ValidationStatus> categoryToValidationStatus,
  ) {
    _categoriesByStatus.clear();
    for (final MapEntry(key: key, value: value)
        in categoryToValidationStatus.entries) {
      (_categoriesByStatus[value] ??= []).add(key);
    }
  }

  // Selects the upmost invalid category (aka. with smallest scroll offset)
  @override
  Option<ScrollCandidate> selectCandidate(
    Map<Category, Option<ScrollCandidate>> registeredCandidates,
  ) {
    final invalidCategories =
        _categoriesByStatus[ValidationStatus.invalid] ?? [];

    Option<ScrollCandidate> topmostScrollCandidate = const None();

    for (final MapEntry(key: category, value: scrollCandidate)
        in registeredCandidates.entries) {
      if (invalidCategories.contains(category)) {
        if (scrollCandidate case Some(value: final event)) {
          if (topmostScrollCandidate case Some(value: final topmost)) {
            if (event.scrollOffset < topmost.scrollOffset) {
              topmostScrollCandidate = Some(event);
            }
          } else {
            topmostScrollCandidate = Some(event);
          }
        } else {
          assert(false, 'scroll event callback returned None()');
        }
      }
    }

    return topmostScrollCandidate;
  }
}

class Example extends StatefulWidget {
  const Example({super.key});

  @override
  State<Example> createState() => _ExampleState();
}

class _ExampleState extends State<Example> {
  // In a real app, this would not be static and instead be updated
  // accordingly whenever the user input changes.
  static const categoryToValidationStatus = <Category, ValidationStatus>{
    Category.A: ValidationStatus.valid,
    Category.B: ValidationStatus.invalid,
    Category.C: ValidationStatus.invalid,
    Category.D: ValidationStatus.valid,
  };

  final _scrollController = ScrollController();
  final _candidateSelectorDelegate = _CandidateSelectorDelegate();

  @override
  void initState() {
    super.initState();
    _candidateSelectorDelegate
        .updateValidationStatus(categoryToValidationStatus);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      builder: (_, __) => Builder(
        builder: (context) {
          return ChangeNotifierProvider(
            create: (_) => ActiveSectionNotifier<Category>(Category.A),
            child: Scaffold(
              appBar: AppBar(
                title: const Text('Scroll to Specific Widget Example'),
              ),
              // Dentro del Scaffold:
              body: Builder(
                builder: (context) {
                  return ScrollCoordinatorConnector<Category>(
                    scrollController: _scrollController,
                    candidateSelectorDelegate: _candidateSelectorDelegate,
                    onSectionChanged: (activeSection) {
                      context
                          .read<ActiveSectionNotifier<Category>>()
                          .updateActiveSection(activeSection);
                    },
                    child: Row(
                      children: [
                        SizedBox(
                          width: 100,
                          child: Consumer<ActiveSectionNotifier<Category>>(
                            builder: (context, activeTabNotifier, _) {
                              return ListView(
                                children: Category.values.map((category) {
                                  return ListTile(
                                    title: Text(
                                      category.toString().split('.').last,
                                    ),
                                    tileColor:
                                        activeTabNotifier.activeSection ==
                                                category
                                            ? Colors.green
                                            : Colors.blue,
                                    onTap: () {
                                      activeTabNotifier
                                          .updateActiveSection(category);
                                      // context
                                      //     .read<ScrollCoordinator<Category>>()
                                      //     .triggerScroll();
                                      context
                                          .read<ScrollCoordinator<Category>>()
                                          .scrollToCandidate(category);
                                    },
                                  );
                                }).toList(),
                              );
                            },
                          ),
                        ),
                        // Contenido scrollable
                        Expanded(
                          child: ListView(
                            controller: _scrollController,
                            children: [
                              const _CategoryA(),
                              const SizedBox(height: 8),
                              const _CategoryB(),
                              const SizedBox(height: 8),
                              const _CategoryC(),
                              const SizedBox(height: 8),
                              const _CategoryD(),
                              const SizedBox(height: 8),
                              ElevatedButton(
                                onPressed: () => context
                                    .read<ScrollCoordinator<Category>>()
                                    .triggerScroll(),
                                child: const Text('What did I miss?'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

void main() {
  runApp(const Example());
}
