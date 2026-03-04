import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'providers/recording_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/gameplay_provider.dart';
import 'screens/home_screen.dart';

void main() {
  // Suppress trackpad assertion errors on Flutter Web
  if (kIsWeb) {
    FlutterError.onError = (FlutterErrorDetails details) {
      // Filter out the trackpad assertion error
      if (details.exception.toString().contains('PointerDeviceKind.trackpad') ||
          details.exception.toString().contains('!identical(kind, PointerDeviceKind.trackpad)')) {
        // Silently ignore this specific error
        debugPrint('Suppressed trackpad assertion error (known Flutter Web issue)');
        return;
      }
      // For all other errors, use the default handler
      FlutterError.presentError(details);
    };
  }
  
  runApp(const SpeechToEmailApp());
}

class SpeechToEmailApp extends StatelessWidget {
  const SpeechToEmailApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => RecordingProvider()),
        ChangeNotifierProvider(create: (context) => AuthProvider()),
        ChangeNotifierProvider(create: (context) => GameplayProvider()),
      ],
      child: MaterialApp(
        title: 'HC VfL Speech to Text',
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
        home: const HomeScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}


