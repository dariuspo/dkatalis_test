import 'package:d_katalis/models/owed.dart';
import 'package:hive/hive.dart';

part 'user.g.dart';

@HiveType(typeId: 1)
class User {
  @HiveField(0)
  final String name;
  @HiveField(1)
  double balance;
  @HiveField(2)
  List<Owed> owns;

  User({
    required this.name,
    this.balance = 0,
    this.owns = const [],
  });
}
