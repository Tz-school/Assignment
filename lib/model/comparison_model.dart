class ComparisonModel {
  final int? id;
  final String title;
  final String state;
  final String sector;
  final double nominalSalary;
  final double netDisposable;
  final double savingsRatio;
  final String status;
  final String notes;

  ComparisonModel({
    this.id,
    required this.title,
    required this.state,
    required this.sector,
    required this.nominalSalary,
    required this.netDisposable,
    required this.savingsRatio,
    required this.status,
    required this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'state': state,
      'sector': sector,
      'nominalSalary': nominalSalary,
      'netDisposable': netDisposable,
      'savingsRatio': savingsRatio,
      'status': status,
      'notes': notes,
    };
  }

  factory ComparisonModel.fromMap(Map<String, dynamic> map) {
    return ComparisonModel(
      id: map['id'] as int?,
      title: map['title'] ?? '',
      state: map['state'] ?? '',
      sector: map['sector'] ?? '',
      nominalSalary: (map['nominalSalary'] as num?)?.toDouble() ?? 0.0,
      netDisposable: (map['netDisposable'] as num?)?.toDouble() ?? 0.0,
      savingsRatio: (map['savingsRatio'] as num?)?.toDouble() ?? 0.0,
      status: map['status'] ?? 'Active',
      notes: map['notes'] ?? '',
    );
  }
}