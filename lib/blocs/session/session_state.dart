part of 'session_bloc.dart';

@immutable
abstract class SessionState {
  final User? userSaved;
  const SessionState({this.userSaved});
}

class SessionInitial extends SessionState {
  const SessionInitial() : super(userSaved: null);
}

class SessionLoggedIn extends SessionState {
  final User user;
  const SessionLoggedIn(this.user) : super(userSaved: user);
}
