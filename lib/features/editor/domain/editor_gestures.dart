/// User-configurable actions for stylus / multi-touch shortcuts.
enum EditorGestureAction {
  none,
  toggleEraser,
  previousTool,
  openToolWheel,
  undo,
  redo,
  nextPage,
  previousPage,
  exportPage,
  cyclePenColor,
  fitZoom,
  goBack,
}

/// Named gesture slots the user can remap in Settings.
enum EditorGestureSlot {
  pencilDoubleTap,
  pencilSqueeze,
  twoFingerTap,
  threeFingerSwipeLeft,
  threeFingerSwipeRight,
}

extension EditorGestureActionX on EditorGestureAction {
  static EditorGestureAction parse(String? name, EditorGestureAction fallback) {
    return EditorGestureAction.values.firstWhere(
      (a) => a.name == name,
      orElse: () => fallback,
    );
  }
}
