import 'package:d_katalis/blocs/session/session_bloc.dart';
import 'package:d_katalis/main.dart';
import 'package:d_katalis/models/command.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
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
  ///focus on text field
  final FocusNode inputFocus = FocusNode();

  ///focus on keyboard detector
  final FocusNode keyBoardFocus = FocusNode();

  ///command histories to support arrow up and down
  final List<String> commandHistories = [""];

  ///get the position of current arrow up and down
  int historyPosition = 0;

  final ScrollController scrollController = ScrollController();

  ///supported commands
  final List<String> availableCommands = [
    loginCommand,
    depositCommand,
    logoutCommand,
    transferCommand,
    withdrawCommand,
  ];

  ///commands printed in screen
  final List<Command> commandsPrinted = [];

  ///to handle text changes
  final textEditingController = TextEditingController();

  ///text field submitted
  submitCommand(String command) {
    command = command.trim();
    print("command entered $command");
    if (!commandHistories.contains(command)) {
      commandHistories.insert(1, command);
    }
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
        commandsString[1] = commandsString[1].trim();
        if (commandsString[1].isEmpty) {
          addErrorCommand("Name have space");
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

  ///command input is not valid
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
    scrollToEnd();
  }

  ///detect keyboard arrow up and down
  onRawKeyEvent(RawKeyEvent event) {
    if (event.runtimeType.toString() == 'RawKeyUpEvent') {
      if (event.data.logicalKey == LogicalKeyboardKey.arrowDown) {
        if (historyPosition <= 0) {
          setState(() {
            textEditingController.clear();
          });
          return;
        }
        historyPosition--;
        textEditingController.text = commandHistories[historyPosition];
        textEditingController.selection = TextSelection.fromPosition(
            TextPosition(offset: textEditingController.text.length));
      }
      if (event.data.logicalKey == LogicalKeyboardKey.arrowUp) {
        if (historyPosition >= commandHistories.length - 1) {
          return;
        }
        historyPosition++;
        textEditingController.text = commandHistories[historyPosition];
        textEditingController.selection = TextSelection.fromPosition(
            TextPosition(offset: textEditingController.text.length));
      }
    }
  }

  @override
  void didChangeDependencies() {
    // TODO: implement didChangeDependencies
    super.didChangeDependencies();
  }

  void scrollToEnd() {
    if (scrollController.hasClients) {
      print("dependencies changes has clients");

      scrollController.animateTo(
          scrollController.position.maxScrollExtent + 300,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInCubic);
    }
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
          scrollToEnd();
        },
        child: Scaffold(
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              Hive.deleteBoxFromDisk(userBoxName);
            },
          ),
          body: SafeArea(
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.all(16.0),
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
                  onKey: onRawKeyEvent,
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
                    onSubmitted: submitCommand,
                    textInputAction: TextInputAction.send,
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
