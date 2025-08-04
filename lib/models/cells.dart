enum CellState {
  normal,
  selected,
  matched,
}

class Cell {
  final int value;
  final int row;
  final int col;
  CellState state;

  Cell({
    required this.value,
    required this.row,
    required this.col,
    this.state = CellState.normal,
  });

  // Copy constructor for state updates
  Cell copyWith({
    int? value,
    int? row,
    int? col,
    CellState? state,
  }) {
    return Cell(
      value: value ?? this.value,
      row: row ?? this.row,
      col: col ?? this.col,
      state: state ?? this.state,
    );
  }

  // Check if cell is available for selection
  bool get isSelectable => state != CellState.matched;

  // Check if cell is currently selected
  bool get isSelected => state == CellState.selected;

  // Check if cell is matched (dull)
  bool get isMatched => state == CellState.matched;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Cell &&
        other.row == row &&
        other.col == col;
  }

  @override
  int get hashCode => row.hashCode ^ col.hashCode;

  @override
  String toString() {
    return 'Cell(value: $value, row: $row, col: $col, state: $state)';
  }
}