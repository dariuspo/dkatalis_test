import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:d_katalis/models/user.dart';
import 'package:d_katalis/repositories/users_repository.dart';
import 'package:meta/meta.dart';

part 'session_event.dart';

part 'session_state.dart';

class SessionBloc extends Bloc<SessionEvent, SessionState> {
  final UsersRepository usersRepository;

  SessionBloc(this.usersRepository) : super(const SessionInitial()) {
    on<LogIn>((event, emit) {
      User user = usersRepository.getUser(event.name) ??
          User(name: event.name, balance: 0, owns: []);
      usersRepository.addNewUser(user);
      emit(SessionLoggedIn(user));
    });
    on<LogOut>((event, emit) {
      emit(const SessionInitial());
    });
    on<AddBalance>((event, emit) {
      User? user = state.userSaved;
      if(user == null){
        emit(const SessionInitial());
      }else{
        user.balance = user.balance+event.addBalance;
        usersRepository.addNewUser(user);
        emit(SessionLoggedIn(user));
      }
    });
  }
}
