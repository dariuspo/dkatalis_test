import 'package:d_katalis/main.dart';
import 'package:d_katalis/models/user.dart';
import 'package:hive_flutter/hive_flutter.dart';

class UsersRepository {
  final box = Hive.box(userBoxName);

  addNewUser(User user) async{
    await box.put(user.name.toLowerCase(), user);
  }

  User? getUser(String name){
    final User? user = box.get(name.toLowerCase());
    return user;
  }
}
