import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/recording_provider.dart';
import 'screens/recording_screen.dart';

void main() {
  runApp(const SpeechToEmailApp());
}

class SpeechToEmailApp extends StatelessWidget {
  const SpeechToEmailApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => RecordingProvider(),
      child: MaterialApp(
        title: 'Speech to Email',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            centerTitle: true,
            elevation: 0,
          ),
        ),
        home: const RecordingScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}


