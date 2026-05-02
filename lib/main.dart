import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'bloc/news_bloc.dart';
import 'data/datasources/news_remote_data_source.dart';
import 'data/repositories/news_repository.dart';
import 'presentation/screens/news_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  final repository = NewsRepository(remoteDataSource: NewsRemoteDataSource());

  runApp(NewsApp(repository: repository));
}

class NewsApp extends StatelessWidget {
  final NewsRepository repository;

  const NewsApp({super.key, required this.repository});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => NewsBloc(repository: repository),
      child: MaterialApp(
        title: 'Tech News',
        theme: ThemeData.dark().copyWith(
          primaryColor: Colors.red,
          colorScheme: ColorScheme.fromSwatch(
            primarySwatch: Colors.lime,
            accentColor: Colors.red,
            backgroundColor: Colors.red,
            cardColor: Colors.grey.shade900.withAlpha(128),
          ),
          iconButtonTheme: IconButtonThemeData(
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.all(Colors.grey.shade800),
              foregroundColor: WidgetStateProperty.all(Colors.white),
            ),
          ),
          chipTheme: ChipThemeData(
            labelStyle: TextStyle(color: Colors.white)
          ),
          scaffoldBackgroundColor: const Color.fromARGB(255, 0, 0, 21),
        ),
        home: const NewsScreen(),
      ),
    );
  }
}
