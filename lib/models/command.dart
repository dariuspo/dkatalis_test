import 'package:d_katalis/models/owed.dart';

class Command {
  final String command;
  final String message;
  final String balance;
  final List<String> owed;

  Command({
    required this.command,
    required this.message,
    required this.balance,
    this.owed = const [],
  });
}

List<String> convertOwedToString(List<Owed> owns) {
  final List<String> strings = [];
  for (var element in owns) {
    strings.add(
        "Owed \$${element.amount.abs()} ${element.amount.isNegative ? "to " : "from "}${element.name}");
  }
  return strings;
}
