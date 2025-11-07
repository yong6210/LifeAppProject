import 'package:flutter_riverpod/flutter_riverpod.dart';

final lifestyleSelectionProvider =
    NotifierProvider<LifestyleSelectionController, Set<String>>(
      LifestyleSelectionController.new,
    );

class LifestyleSelectionController extends Notifier<Set<String>> {
  @override
  Set<String> build() => <String>{};

  bool toggle(String id, {int maxSelection = 2}) {
    final current = state;
    if (current.contains(id)) {
      state = Set<String>.from(current)..remove(id);
      return true;
    }
    if (current.length >= maxSelection) {
      return false;
    }
    state = Set<String>.from(current)..add(id);
    return true;
  }

  void setSelections(Iterable<String> ids, {int maxSelection = 2}) {
    state = ids.take(maxSelection).toSet();
  }

  void clear() {
    state = <String>{};
  }
}
