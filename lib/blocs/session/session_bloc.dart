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
    ///handle login event
    on<LogIn>((event, emit) {
      mapLoginEvent(emit, event);
    });
    ///handle logout event
    on<LogOut>((event, emit) {
      bool isValid = checkIsLoggedIn(emit);
      if (!isValid) return;
      emit(
        SessionInitial(message: "Goodbye, ${state.userSaved!.name}!"),
      );
    });
    ///handle add balance event
    on<AddBalance>((event, emit) {
      mapAddBalance(emit, event);
    });
    ///handle transfer balance event
    on<TransferBalance>((event, emit) {
      mapTransferBalance(emit, event);
    });
    ///handle withdraw balance event
    on<WithdrawBalance>((event, emit) {
      mapWithdrawBalance(emit, event);
    });
  }

  void mapTransferBalance(Emitter<SessionState> emit, TransferBalance event) {
    ///check user login or not
    bool isValid = checkIsLoggedIn(emit);
    if (!isValid) return;
    User user = usersRepository.getUser(state.userSaved!.name)!;
    User? transferTo = usersRepository.getUser(event.toName);

    ///check the target user is already register or not
    if (transferTo == null) {
      emit(
        SessionLoggedIn(
          user: user,
          message: "Cannot find that name",
        ),
      );
      return;
    }

    ///cannot send to own name
    if (transferTo.name.toLowerCase() == user.name.toLowerCase()) {
      emit(
        SessionLoggedIn(
          user: user,
          message: "Cannot transfer to yourself",
        ),
      );
      return;
    }
    Owed? userOwed = user.owns
        .firstWhereOrNull((element) => element.name == transferTo.name);
    double amountPaid = 0;

    ///check if user have owe
    if (userOwed != null) {
      double finalOwed = userOwed.amount - event.transferBalance;

      ///if the transfer is settled the owe, no balance transferred
      if (finalOwed == 0) {
        clearOwnBetweenUsers(user, transferTo);
      } else {
        ///transfer larger the owe, and have balance that could be transferred
        if (finalOwed.isNegative && user.balance > 0) {
          finalOwed = finalOwed + user.balance;

          ///the balance is not enough
          if (finalOwed.isNegative) {
            transferTo.balance = transferTo.balance + user.balance;
            amountPaid = user.balance;
            user.balance = 0;
            updateUsersOwed(user, transferTo, finalOwed);
          }

          ///balance is enough the owe is settled
          ///remaining balance saved
          else {
            ///paid the user balance reduced by balance left
            transferTo.balance = transferTo.balance + user.balance - finalOwed;
            amountPaid = user.balance - finalOwed;
            user.balance = finalOwed;
            clearOwnBetweenUsers(user, transferTo);
          }
        } else {
          ///the owe still larger than transferred or no balance available
          ///in this case only calculate the owe
          updateUsersOwed(user, transferTo, finalOwed);
        }
      }
    }

    ///user balance is not enough owe created
    else if (user.balance < event.transferBalance) {
      double amountOwed = event.transferBalance - user.balance;
      amountPaid = user.balance;
      user.balance = 0;
      transferTo.owns.add(Owed(name: user.name, amount: amountOwed));
      user.owns.add(Owed(name: transferTo.name, amount: -amountOwed));
      transferTo.balance = transferTo.balance + amountPaid;
    }

    ///the user balance is enough money transferred
    else {
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
    ///check user login or not
    bool isValid = checkIsLoggedIn(emit);
    if (!isValid) return;
    User user = usersRepository.getUser(state.userSaved!.name)!;
    double balanceAdded = event.addBalance;
    List<String> toRemoveName = [];
    String message = "";

    ///have owe that need to be paid first
    for (var element in user.owns) {
      ///check if owe is negative, and deposited still larger than 0
      if (element.amount.isNegative && balanceAdded > 0) {
        User transferToUser = usersRepository.getUser(element.name)!;
        balanceAdded = element.amount + balanceAdded;

        ///there is some balance left after pays own
        ///this indicate that all owns is paid
        if (balanceAdded >= 0) {
          transferToUser.owns
              .removeWhere((element) => element.name == user.name);
          transferToUser.balance =
              transferToUser.balance + element.amount.abs();
          usersRepository.addNewUser(transferToUser);
          toRemoveName.add(transferToUser.name);
          message = message +
              "${message.isNotEmpty ? "\n" : ""}Transferred \$${element.amount.abs()} to ${transferToUser.name}";
        }

        ///no balance deposited left
        ///cannot pay anymore break the loop
        else {
          transferToUser.balance =
              transferToUser.balance + (balanceAdded - element.amount).abs();
          usersRepository.addNewUser(transferToUser);
          message = message +
              "${message.isNotEmpty ? "\n" : ""}Transferred \$${(balanceAdded - element.amount).abs()} to ${transferToUser.name}";
          updateUsersOwed(user, transferToUser, balanceAdded);
          break;
        }
      }
    }

    ///toRemove used to avoid error editing iterable while looping
    user.owns.removeWhere((e) => toRemoveName.contains(e.name));
    user.balance = user.balance + (balanceAdded < 0 ? 0 : balanceAdded);
    usersRepository.addNewUser(user);
    if (balanceAdded > 0) {
      message = message +
          "${message.isNotEmpty ? "\n" : ""}\$$balanceAdded added to your account";
    }
    emit(
      SessionLoggedIn(
        user: user,
        message: message,
      ),
    );
  }

  void mapLoginEvent(Emitter<SessionState> emit, LogIn event) {
    ///already login, cannot login again
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
        message: "Hello, ${user.name}!",
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

  void mapWithdrawBalance(Emitter<SessionState> emit, WithdrawBalance event) {
    bool isValid = checkIsLoggedIn(emit);
    if (!isValid) return;
    User user = usersRepository.getUser(state.userSaved!.name)!;
    ///withdraw larger than current balance
    if (event.withdrawBalance > user.balance) {
      emit(
        SessionLoggedIn(
          user: user,
          message: "You cannot withdraw more than your balance",
        ),
      );
      return;
    }
    user.balance = user.balance - event.withdrawBalance;
    usersRepository.addNewUser(user);
    emit(
      SessionLoggedIn(
        user: user,
        message: "You withdrew ${event.withdrawBalance} from your account",
      ),
    );
  }

  clearOwnBetweenUsers(User user1, User user2) {
    user1.owns.removeWhere((element) => element.name == user2.name);
    user2.owns.removeWhere((element) => element.name == user1.name);
    usersRepository.addNewUser(user1);
    usersRepository.addNewUser(user2);
  }

  updateUsersOwed(User user1, User user2, double finalAmount) {
    Owed? user1Owed =
        user1.owns.firstWhereOrNull((element) => element.name == user2.name);
    Owed? user2Owed =
        user2.owns.firstWhereOrNull((element) => element.name == user1.name);
    user1Owed!.amount = finalAmount;
    user2Owed!.amount = -finalAmount;
    user1.owns[user1.owns.indexWhere((element) => element.name == user2.name)] =
        user1Owed;
    user2.owns[user2.owns.indexWhere((element) => element.name == user1.name)] =
        user2Owed;
    usersRepository.addNewUser(user1);
    usersRepository.addNewUser(user2);
  }
}
