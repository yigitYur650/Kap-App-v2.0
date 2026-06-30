enum StockStatus {
  inStock,
  low,
  outOfStock;

  /// Map string representation in PostgreSQL to StockStatus enum
  static StockStatus fromString(String status) {
    switch (status) {
      case 'var':
        return StockStatus.inStock;
      case 'azaldı':
        return StockStatus.low;
      case 'yok':
        return StockStatus.outOfStock;
      default:
        return StockStatus.inStock; // Fallback default
    }
  }

  /// Map StockStatus enum back to PostgreSQL string representation
  String toDbString() {
    switch (this) {
      case StockStatus.inStock:
        return 'var';
      case StockStatus.low:
        return 'azaldı';
      case StockStatus.outOfStock:
        return 'yok';
    }
  }
}
