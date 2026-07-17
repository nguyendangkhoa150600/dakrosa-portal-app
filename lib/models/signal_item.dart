class SignalItem {
  final String id;
  final String label;
  final String source;
  final String tone; // 'success' | 'warning' | 'danger'
  final String status;
  final int? ageSec;
  final String? lastAt;

  SignalItem({
    required this.id,
    required this.label,
    required this.source,
    required this.tone,
    required this.status,
    this.ageSec,
    this.lastAt,
  });
}
