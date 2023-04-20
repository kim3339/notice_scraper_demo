class Notice {
  const Notice(
      {required this.title, required this.datetime, required this.source});
  final String title;
  final DateTime datetime;
  final String source;

  @override
  String toString() =>
      {'title': title, 'datetime': datetime, 'source': source}.toString();
}
