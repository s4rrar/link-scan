class ScanItem {
  final int? id;
  final String barcode;
  final String format;
  final int timestamp;
  final bool sentSuccessfully;

  ScanItem({
    this.id,
    required this.barcode,
    required this.format,
    required this.timestamp,
    required this.sentSuccessfully,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'barcode': barcode,
      'format': format,
      'timestamp': timestamp,
      'sentSuccessfully': sentSuccessfully ? 1 : 0,
    };
  }

  factory ScanItem.fromMap(Map<String, dynamic> map) {
    return ScanItem(
      id: map['id'] as int?,
      barcode: map['barcode'] as String,
      format: map['format'] as String,
      timestamp: map['timestamp'] as int,
      sentSuccessfully: (map['sentSuccessfully'] as int) == 1,
    );
  }
}
