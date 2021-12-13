import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:d_katalis/models/owed.dart';
import 'package:d_katalis/models/user.dart';
import 'package:d_katalis/repositories/users_repository.dart';
import 'package:meta/meta.dart';
import 'package:collection/collection.dart';

part 'session_event.dart';

part 'session_state.dart';

class SessionBloc extends Bloc<SessionEvent, SessionState> {
  final UsersRepository usersRepository;

  SessionBloc(this.usersRepository) : super(const SessionInitial(message: "")) {
    on<LogIn>((event, emit) {
      mapLoginEvent(emit, event);
    });
    on<LogOut>((event, emit) {
      bool isValid = checkIsLoggedIn(emit);
      if (!isValid) return;
      emit(
        SessionInitial(message: "Goodbye, ${state.userSaved!.name}"),
      );
    });
    on<AddBalance>((event, emit) {
      mapAddBalance(emit, event);
    });
    on<TransferBalance>((event, emit) {
      mapTransferBalance(emit, event);
    });
  }

  void mapTransferBalance(Emitter<SessionState> emit, TransferBalance event) {
    bool isValid = checkIsLoggedIn(emit);
    if (!isValid) return;
    User user = usersRepository.getUser(state.userSaved!.name)!;
    User? transferTo = usersRepository.getUser(event.toName);
    if (transferTo == null) {
      emit(
        SessionLoggedIn(
          user: user,
          message: "Cannot find that name",
        ),
      );
      return;
    }
    Owed? userOwed = user.owns
        .firstWhereOrNull((element) => element.name == transferTo.name);
    Owed? transferToOwed = transferTo.owns
        .firstWhereOrNull((element) => element.name == user.name);
    double amountPaid = 0;
    if (userOwed != null) {
      double finalOwed = userOwed.amount - event.transferBalance;
      if (finalOwed == 0) {
        user.owns.removeWhere((element) => element.name == transferTo.name);
        transferTo.owns.removeWhere((element) => element.name == user.name);
      } else {
        userOwed.amount = finalOwed;
        transferToOwed!.amount = -finalOwed;
        transferTo.owns[transferTo.owns
                .indexWhere((element) => element.name == user.name)] =
            transferToOwed;
        user.owns[user.owns
                .indexWhere((element) => element.name == transferTo.name)] =
            userOwed;
      }
    } else if (user.balance < event.transferBalance) {
      double amountOwed = event.transferBalance - user.balance;
      amountPaid = user.balance;
      user.balance = 0;
      transferTo.owns.add(Owed(name: user.name, amount: amountOwed));
      user.owns.add(Owed(name: transferTo.name, amount: -amountOwed));
      transferTo.balance = transferTo.balance + amountPaid;
    } else {
      user.balance = user.balance - event.transferBalance;
      transferTo.balance = transferTo.balance + event.transferBalance;
      amountPaid = event.transferBalance;
    }
    usersRepository.addNewUser(user);
    usersRepository.addNewUser(transferTo);
    emit(
      SessionLoggedIn(
        user: user,
        message: amountPaid == 0
            ? ""
            : "Transferred \$$amountPaid to ${transferTo.name}",
      ),
    );
  }

  void mapAddBalance(Emitter<SessionState> emit, AddBalance event) {
    bool isValid = checkIsLoggedIn(emit);
    if (!isValid) return;
    User user = usersRepository.getUser(state.userSaved!.name)!;
    double balanceAdded = event.addBalance;
    for (var element in user.owns) {
      User transferToUser = usersRepository.getUser(element.name)!;

      if(balanceAdded <= 0) break;
    }
    user.balance = user.balance + event.addBalance;
    usersRepository.addNewUser(user);
    emit(
      SessionLoggedIn(
        user: user,
        message: "\$${event.addBalance} added to your account",
      ),
    );
  }

  void mapLoginEvent(Emitter<SessionState> emit, LogIn event) {
    if (state is SessionLoggedIn) {
      emit(SessionLoggedIn(
        user: state.userSaved!,
        message:
            "You already logged in as ${state.userSaved!.name}, logout first",
      ));
    } else {
      User user = usersRepository.getUser(event.name) ??
          User(name: event.name, balance: 0, owns: []);
      usersRepository.addNewUser(user);
      emit(SessionLoggedIn(
        user: user,
        message: "Hello, ${user.name}",
      ));
    }
  }

  bool checkIsLoggedIn(Emitter<SessionState> emit) {
    if (state is SessionInitial) {
      emit(
        const SessionInitial(
            message: "You need to login first", haveError: true),
      );
      return false;
    }
    return true;
  }
}
