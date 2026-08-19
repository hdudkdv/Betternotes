String suggestedNotebookTitle({
  required String untitled,
  String? folderName,
  int? schoolClass,
  String classSpec = '',
}) {
  final folder = folderName?.trim() ?? '';
  if (folder.isEmpty) return untitled;
  if (schoolClass == null) return folder;
  final spec = classSpec.trim();
  final suffix = spec.isEmpty ? '' : (spec.length == 1 ? spec : ' $spec');
  return '$folder $schoolClass$suffix';
}
