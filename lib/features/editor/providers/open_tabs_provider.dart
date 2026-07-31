import 'package:flutter_riverpod/flutter_riverpod.dart';

class OpenNotebookTabsState {
  const OpenNotebookTabsState({this.ids = const [], this.activeId});

  final List<String> ids;
  final String? activeId;

  OpenNotebookTabsState copyWith({
    List<String>? ids,
    String? activeId,
    bool clearActive = false,
  }) {
    return OpenNotebookTabsState(
      ids: ids ?? this.ids,
      activeId: clearActive ? null : (activeId ?? this.activeId),
    );
  }
}

class OpenNotebookTabsNotifier extends StateNotifier<OpenNotebookTabsState> {
  OpenNotebookTabsNotifier() : super(const OpenNotebookTabsState());

  void open(String id) {
    if (state.ids.contains(id)) {
      state = state.copyWith(activeId: id);
      return;
    }
    state = OpenNotebookTabsState(ids: [...state.ids, id], activeId: id);
  }

  void select(String id) {
    if (!state.ids.contains(id)) return;
    state = state.copyWith(activeId: id);
  }

  /// Returns the id to navigate to after close, or null for library.
  String? close(String id) {
    final next = state.ids.where((e) => e != id).toList();
    if (next.isEmpty) {
      state = const OpenNotebookTabsState();
      return null;
    }
    final active = state.activeId == id ? next.last : state.activeId;
    state = OpenNotebookTabsState(ids: next, activeId: active);
    return active;
  }
}

final openNotebookTabsProvider =
    StateNotifierProvider<OpenNotebookTabsNotifier, OpenNotebookTabsState>(
      (ref) => OpenNotebookTabsNotifier(),
    );
