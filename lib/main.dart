import 'package:d_katalis/app/app.dart';
import 'package:d_katalis/models/user.dart';
import 'package:d_katalis/repositories/users_repository.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

const String userBoxName = "user";

void main() async {
  await Hive.initFlutter();
  Hive.registerAdapter<User>(UserAdapter());
  await Hive.openBox(userBoxName);
  final usersRepository = UsersRepository();
  runApp(App(usersRepository: usersRepository));
}
