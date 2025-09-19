import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_email_app/main.dart';
import 'package:speech_to_email_app/providers/recording_provider.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('End-to-End Tests', () {
    testWidgets('Complete recording workflow', (tester) async {
      // Launch the app
      await tester.pumpWidget(const SpeechToEmailApp());
      await tester.pumpAndSettle();

      // Verify initial state
      expect(find.text('Speech to Email'), findsOneWidget);
      expect(find.text('Ready to Record'), findsOneWidget);
      expect(find.text('Tap to start recording'), findsOneWidget);

      // Test recording button interaction
      final recordButton = find.byType(GestureDetector).first;
      expect(recordButton, findsOneWidget);

      // Tap to start recording (this would require mocking in real tests)
      await tester.tap(recordButton);
      await tester.pumpAndSettle();

      // In a real integration test, we would:
      // 1. Verify recording state changes
      // 2. Wait for recording to complete
      // 3. Test upload functionality
      // 4. Verify status updates
      // 5. Check completion state

      // For now, just verify the UI responds
      expect(find.byType(GestureDetector), findsWidgets);
    });

    testWidgets('Error handling workflow', (tester) async {
      await tester.pumpWidget(const SpeechToEmailApp());
      await tester.pumpAndSettle();

      // Test error scenarios (would require mocking)
      // 1. Permission denied
      // 2. Network errors
      // 3. Upload failures
      // 4. Processing errors

      expect(find.text('Speech to Email'), findsOneWidget);
    });

    testWidgets('Cross-platform compatibility', (tester) async {
      await tester.pumpWidget(const SpeechToEmailApp());
      await tester.pumpAndSettle();

      // Test that the app works across different screen sizes
      await tester.binding.setSurfaceSize(const Size(800, 600)); // Tablet
      await tester.pumpAndSettle();
      expect(find.text('Speech to Email'), findsOneWidget);

      await tester.binding.setSurfaceSize(const Size(400, 800)); // Phone
      await tester.pumpAndSettle();
      expect(find.text('Speech to Email'), findsOneWidget);
    });

    testWidgets('Performance test', (tester) async {
      final stopwatch = Stopwatch()..start();
      
      await tester.pumpWidget(const SpeechToEmailApp());
      await tester.pumpAndSettle();
      
      stopwatch.stop();
      
      // App should load within reasonable time
      expect(stopwatch.elapsedMilliseconds, lessThan(3000));
    });
  });
}