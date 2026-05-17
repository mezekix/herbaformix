class ProgramEditorArgs {
  final String targetUserId;
  final String targetCustomerName;
  final bool isDistributorMode;

  const ProgramEditorArgs({
    required this.targetUserId,
    required this.targetCustomerName,
    this.isDistributorMode = false,
  });
}