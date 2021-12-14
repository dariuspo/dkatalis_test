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

class WithdrawBalance extends SessionEvent {
  final double withdrawBalance;
  WithdrawBalance(this.withdrawBalance);
}

class AddBalance extends SessionEvent {
  final double addBalance;
  AddBalance(this.addBalance);
}

class TransferBalance extends SessionEvent {
  final double transferBalance;
  final String toName;
  TransferBalance(this.transferBalance, this.toName);
}