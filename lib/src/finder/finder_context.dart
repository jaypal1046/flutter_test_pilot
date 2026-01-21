// finder_context.dart - Context information for finding widgets
/// Context for finding widgets - stores additional metadata
class FinderContext {
  final FindType findType;
  final bool exact;
  final String? parent;
  final String? child;
  final int? index;
  final Position? position;

  const FinderContext({
    this.findType = FindType.smart,
    this.exact = false,
    this.parent,
    this.child,
    this.index,
    this.position,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FinderContext &&
          runtimeType == other.runtimeType &&
          findType == other.findType &&
          exact == other.exact &&
          parent == other.parent &&
          child == other.child &&
          index == other.index &&
          position == other.position;

  @override
  int get hashCode =>
      findType.hashCode ^
      exact.hashCode ^
      parent.hashCode ^
      child.hashCode ^
      index.hashCode ^
      position.hashCode;
}

/// Type of find operation
enum FindType {
  text,
  key,
  semantic,
  type,
  hint,
  label,
  icon,
  tooltip,
  custom,
  descendant,
  ancestor,
  byIndex, // Renamed from 'index' to avoid conflict with enum's index property
  smart,
}

/// Position in list of matches
enum Position { first, last, any }
