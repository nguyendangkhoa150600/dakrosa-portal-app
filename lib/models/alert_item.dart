class AlertItem {
  final String tone; // 'warning' | 'info' | 'success'
  final String title;
  final String body;
  final String time;

  AlertItem({
    required this.tone,
    required this.title,
    required this.body,
    required this.time,
  });
}
