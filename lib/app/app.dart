import 'package:d_katalis/blocs/session/session_bloc.dart';
import 'package:d_katalis/blocs/users/users_bloc.dart';
import 'package:d_katalis/repositories/users_repository.dart';
import 'package:d_katalis/screens/home_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class App extends StatelessWidget {
  App({
    Key? key,
    required this.usersRepository,
  }) : super(key: key);

  final UsersRepository usersRepository;

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: usersRepository),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<UsersBloc>(
            create: (context) => UsersBloc(usersRepository),
          ),
          BlocProvider<SessionBloc>(
            create: (context) => SessionBloc(usersRepository),
          ),
        ],
        child: MaterialApp(
          theme: ThemeData(),
          darkTheme: ThemeData.dark(),
          themeMode: ThemeMode.dark,
          home: const HomePage(),
        ),
      ),
    );
  }
}
