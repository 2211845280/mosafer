/// Formats terminal names for compact UI badges (e.g. gate summary card).
String formatTerminalBadge(String terminal) {
  final value = terminal.trim();
  if (value.isEmpty) return '--';

  final terminalMatch = RegExp(
    r'^terminal\s+(\w+)$',
    caseSensitive: false,
  ).firstMatch(value);
  if (terminalMatch != null) {
    final id = terminalMatch.group(1)!;
    return id.length == 1 ? 'T$id' : id.toUpperCase();
  }

  return value;
}
