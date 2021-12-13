import 'package:d_katalis/blocs/session/session_bloc.dart';
import 'package:d_katalis/main.dart';
import 'package:d_katalis/models/command.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';

const loginCommand = "login";
const depositCommand = "deposit";
const logoutCommand = "logout";
const transferCommand = "transfer";

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FocusNode inputFocus = FocusNode();

  final List<String> availableCommands = [
    loginCommand,
    depositCommand,
    logoutCommand,
    transferCommand,
  ];
  final List<Command> commandsPrinted = [];
  String currentCommand = "";
  final textEditingController = TextEditingController();

  submitCommand(String command) {
    List<String> commandsString = command.split(" ");
    if (commandsString.isEmpty) {
      addErrorCommand("Available command is login, deposit, logout, transfer");
    } else if (!availableCommands.contains(commandsString.first)) {
      addErrorCommand(
          "Invalid command, available command is login, deposit, logout, transfer");
    } else if (commandsString.first == loginCommand) {
      if (commandsString.length < 2) {
        addErrorCommand("You need to specify the name");
      } else {
        context.read<SessionBloc>().add(LogIn(commandsString[1]));
      }
    } else if (commandsString.first == logoutCommand) {
      context.read<SessionBloc>().add(LogOut());
    } else if (commandsString.first == depositCommand) {
      if (commandsString.length < 2) {
        addErrorCommand("You need to specify the amount");
      } else {
        double? balance = double.tryParse(commandsString[1]);
        if (balance == null || balance == 0) {
          addErrorCommand("Invalid balance number (cannot put 0)");
        } else {
          context.read<SessionBloc>().add(AddBalance(balance));
        }
      }
    } else if (commandsString.first == transferCommand) {
      if (commandsString.length < 3) {
        addErrorCommand(
            "You need to specify the amount and name e.g : transfer ivan 50");
      } else {
        double? balance = double.tryParse(commandsString[2]);
        if (balance == null || balance == 0) {
          addErrorCommand("Invalid balance number or zero");
        } else {
          context
              .read<SessionBloc>()
              .add(TransferBalance(balance, commandsString[1]));
        }
      }
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
    inputFocus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SessionBloc, SessionState>(
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
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Hive.deleteBoxFromDisk(userBoxName);
          },
        ),
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
                            child: Text("\$ ${e.command}"),
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
                            children: e.owed.map(
                              (f) {
                                return Text(f);
                              },
                            ).toList(),
                          ),
                        ],
                      ),
                    )),
                TextField(
                  focusNode: inputFocus,
                  controller: textEditingController,
                  cursorWidth: 8,
                  cursorColor: Theme.of(context).textTheme.subtitle2?.color,
                  autofocus: true,
                  decoration: InputDecoration(
                    contentPadding: EdgeInsets.zero,
                    prefix: Text(
                      "\$ ",
                      style: Theme.of(context).textTheme.subtitle2,
                    ),
                    border: InputBorder.none,
                  ),
                  onChanged: (value) {
                    currentCommand = value;
                  },
                  onSubmitted: submitCommand,
                  textInputAction: TextInputAction.send,
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
