/// Response entity for checking if a recipe can be modified (edited/deleted).
/// A recipe can only be modified by its creator AND when it has no child variants or logs.
class RecipeModifiable {
  final bool canModify;
  final bool isOwner;
  final bool hasVariants;
  final bool hasLogs;
  final int variantCount;
  final int logCount;
  final String? reason;

  RecipeModifiable({
    required this.canModify,
    required this.isOwner,
    required this.hasVariants,
    required this.hasLogs,
    required this.variantCount,
    required this.logCount,
    this.reason,
  });
}
