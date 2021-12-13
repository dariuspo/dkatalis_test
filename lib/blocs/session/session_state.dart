part of 'session_bloc.dart';

@immutable
abstract class SessionState {
  final User? userSaved;
  final String savedMesssage;
  const SessionState({this.userSaved, required this.savedMesssage});
}

class SessionInitial extends SessionState {
  final String message;
  final bool haveError;

  const SessionInitial({
    required this.message,
    this.haveError = false,
  }) : super(userSaved: null, savedMesssage: message);
}

class SessionLoggedIn extends SessionState {
  final User user;
  final String message;
  final bool haveError;

  const SessionLoggedIn({
    required this.user,
    required this.message,
    this.haveError = false,
  }) : super(userSaved: user, savedMesssage: message);
}
