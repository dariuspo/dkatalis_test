import 'package:d_katalis/blocs/session/session_bloc.dart';
import 'package:d_katalis/models/command.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:universal_html/html.dart' as universal;

const loginCommand = "login";
const depositCommand = "deposit";
const logoutCommand = "logout";
const transferCommand = "transfer";
const withdrawCommand = "withdraw";

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FocusNode inputFocus = FocusNode();
  final FocusNode keyBoardFocus = FocusNode();
  final List<String> commandHistories = [""];
  int historyPosition = 0;
  final List<String> availableCommands = [
    loginCommand,
    depositCommand,
    logoutCommand,
    transferCommand,
    withdrawCommand,
  ];
  final List<Command> commandsPrinted = [];
  String currentCommand = "";
  final textEditingController = TextEditingController();

  submitCommand(String command) {
    commandHistories.insert(1, command);
    historyPosition = 0;
    List<String> commandsString = command.split(" ");
    if (commandsString.isEmpty) {
      addErrorCommand(
          "Available command is login, withdraw, deposit, logout, transfer");
      return;
    }
    switch (commandsString.first) {
      case loginCommand:
        if (commandsString.length < 2) {
          addErrorCommand("You need to specify the name");
          return;
        }
        context.read<SessionBloc>().add(LogIn(commandsString[1]));
        break;
      case depositCommand:
        if (commandsString.length < 2) {
          addErrorCommand("You need to specify the amount");
          return;
        }
        double? balance = double.tryParse(commandsString[1]);
        if (balance == null || balance == 0) {
          addErrorCommand("Invalid balance number (cannot put 0)");
          return;
        }
        context.read<SessionBloc>().add(AddBalance(balance));
        break;
      case logoutCommand:
        context.read<SessionBloc>().add(LogOut());
        break;
      case transferCommand:
        if (commandsString.length < 3) {
          addErrorCommand(
              "You need to specify the amount and name e.g : transfer ivan 50");
          return;
        }
        double? balance = double.tryParse(commandsString[2]);
        if (balance == null || balance == 0) {
          addErrorCommand(
              "Invalid balance number or zero, e.g : transfer ivan 50");
          return;
        }
        context
            .read<SessionBloc>()
            .add(TransferBalance(balance, commandsString[1]));
        break;
      case withdrawCommand:
        if (commandsString.length < 2) {
          addErrorCommand("You need to specify the amount");
          return;
        }
        double? balance = double.tryParse(commandsString[1]);
        if (balance == null || balance == 0) {
          addErrorCommand("Invalid balance number (cannot put 0)");
          return;
        }
        context.read<SessionBloc>().add(WithdrawBalance(balance));
        break;
      default:
        addErrorCommand(
            "Invalid command, available command is login, withdraw, deposit, logout, transfer");
    }
  }

  addErrorCommand(String message) {
    setState(() {
      commandsPrinted.add(
        Command(
          message: message,
          command: textEditingController.text,
          balance: "",
        ),
      );
    });
    textEditingController.clear();
  }

  @override
  void didChangeDependencies() {
    // TODO: implement didChangeDependencies
    super.didChangeDependencies();
  }

  @override
  void initState() {
    super.initState();
    final loader = universal.document.getElementsByClassName('loading');
    if (loader.isNotEmpty) {
      loader.first.remove();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        inputFocus.requestFocus();
      },
      child: BlocListener<SessionBloc, SessionState>(
        listener: (context, state) {
          if (state is SessionLoggedIn) {
            setState(() {
              commandsPrinted.add(
                Command(
                  message: state.message,
                  command: textEditingController.text,
                  balance: "Your balance is \$${state.user.balance}",
                  owed: convertOwedToString(state.user.owns),
                ),
              );
            });
          }
          if (state is SessionInitial) {
            setState(() {
              commandsPrinted.add(
                Command(
                  message: state.message,
                  command: textEditingController.text,
                  balance: "",
                ),
              );
            });
          }
          textEditingController.clear();
        },
        child: Scaffold(
          /*floatingActionButton: FloatingActionButton(
            onPressed: () {
              Hive.deleteBoxFromDisk(userBoxName);
            },
          ),*/
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SafeArea(
              child: ListView(
                children: [
                  ...commandsPrinted.map((e) => Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(bottom: 4.0),
                              child: Text(
                                "\$ ${e.command}",
                                style: Theme.of(context).textTheme.bodyText2,
                              ),
                            ),
                            Visibility(
                              visible: e.message.isNotEmpty,
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 4.0),
                                child: Text(e.message),
                              ),
                            ),
                            Visibility(
                              visible: e.balance.isNotEmpty,
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 4.0),
                                child: Text(e.balance),
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: e.owed.map(
                                (f) {
                                  return Text(f);
                                },
                              ).toList(),
                            ),
                          ],
                        ),
                      )),
                  RawKeyboardListener(
                    focusNode: keyBoardFocus,
                    onKey: (RawKeyEvent event) {
                      if (event.runtimeType.toString() == 'RawKeyUpEvent') {
                        if (event.data.logicalKey ==
                            LogicalKeyboardKey.arrowDown) {
                          if (historyPosition <= 0) {
                            setState(() {
                              textEditingController.clear();
                            });
                            return;
                          }
                          historyPosition--;
                          textEditingController.text =
                              commandHistories[historyPosition];
                          textEditingController.selection =
                              TextSelection.fromPosition(TextPosition(
                                  offset: textEditingController.text.length));
                        }
                        if (event.data.logicalKey ==
                            LogicalKeyboardKey.arrowUp) {
                          if (historyPosition >= commandHistories.length - 1) {
                            return;
                          }
                          historyPosition++;
                          textEditingController.text =
                              commandHistories[historyPosition];
                          textEditingController.selection =
                              TextSelection.fromPosition(TextPosition(
                                  offset: textEditingController.text.length));
                        }
                      }
                    },
                    child: TextField(
                      focusNode: inputFocus,
                      autofocus: true,
                      controller: textEditingController,
                      cursorWidth: 5,
                      cursorHeight: 16,
                      cursorColor: Theme.of(context).textTheme.subtitle2?.color,
                      style: Theme.of(context).textTheme.bodyText2,
                      expands: false,
                      decoration: InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                          prefix: Text(
                            "\$ ",
                            style: Theme.of(context).textTheme.subtitle2,
                          ),
                          border: InputBorder.none),
                      onChanged: (value) {
                        currentCommand = value;
                      },
                      onSubmitted: submitCommand,
                      textInputAction: TextInputAction.send,
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
