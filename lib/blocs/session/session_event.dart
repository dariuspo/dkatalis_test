part of 'session_bloc.dart';

@immutable
abstract class SessionEvent {}

class LogIn extends SessionEvent {
  final String name;
  LogIn(this.name);
}

class LogOut extends SessionEvent {
  LogOut();
}

class AddBalance extends SessionEvent {
  final double addBalance;
  AddBalance(this.addBalance);
}