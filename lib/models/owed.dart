import 'package:hive/hive.dart';

part 'owed.g.dart';

@HiveType(typeId: 2)
class Owed {
  @HiveField(0)
  double amount;
  @HiveField(1)
  final String name;

  Owed({required this.name, this.amount = 0});
}