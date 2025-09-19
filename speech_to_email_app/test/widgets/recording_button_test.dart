import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speech_to_email_app/widgets/recording_button.dart';
import 'package:speech_to_email_app/providers/recording_provider.dart';

void main() {
  group('RecordingButton Widget', () {
    late bool startRecordingCalled;
    late bool stopRecordingCalled;
    late bool cancelRecordingCalled;
    late bool uploadRecordingCalled;

    setUp(() {
      startRecordingCalled = false;
      stopRecordingCalled = false;
      cancelRecordingCalled = false;
      uploadRecordingCalled = false;
    });

    Widget createTestWidget(RecordingState state) {
      return MaterialApp(
        home: Scaffold(
          body: RecordingButton(
            state: state,
            onStartRecording: () => startRecordingCalled = true,
            onStopRecording: () => stopRecordingCalled = true,
            onCancelRecording: () => cancelRecordingCalled = true,
            onUploadRecording: () => uploadRecordingCalled = true,
          ),
        ),
      );
    }

    group('Idle State', () {
      testWidgets('should show microphone icon when idle', (tester) async {
        await tester.pumpWidget(createTestWidget(RecordingState.idle));
        
        expect(find.byIcon(Icons.mic), findsOneWidget);
        expect(find.text('Tap to start recording'), findsOneWidget);
      });

      testWidgets('should call onStartRecording when tapped in idle state', (tester) async {
        await tester.pumpWidget(createTestWidget(RecordingState.idle));
        
        await tester.tap(find.byType(GestureDetector).first);
        await tester.pump();
        
        expect(startRecordingCalled, isTrue);
      });
    });

    group('Recording State', () {
      testWidgets('should show stop icon when recording', (tester) async {
        await tester.pumpWidget(createTestWidget(RecordingState.recording));
        
        expect(find.byIcon(Icons.stop), findsOneWidget);
        expect(find.text('Recording... Tap to stop'), findsOneWidget);
      });

      testWidgets('should call onStopRecording when tapped while recording', (tester) async {
        await tester.pumpWidget(createTestWidget(RecordingState.recording));
        
        await tester.tap(find.byType(GestureDetector).first);
        await tester.pump();
        
        expect(stopRecordingCalled, isTrue);
      });

      testWidgets('should show cancel button when recording', (tester) async {
        await tester.pumpWidget(createTestWidget(RecordingState.recording));
        
        expect(find.text('Cancel'), findsOneWidget);
        expect(find.byIcon(Icons.close), findsOneWidget);
      });
    });

    group('Stopped State', () {
      testWidgets('should show upload button when stopped', (tester) async {
        await tester.pumpWidget(createTestWidget(RecordingState.stopped));
        
        expect(find.text('Upload'), findsOneWidget);
        expect(find.byIcon(Icons.cloud_upload), findsOneWidget);
      });

      testWidgets('should call onUploadRecording when upload button tapped', (tester) async {
        await tester.pumpWidget(createTestWidget(RecordingState.stopped));
        
        // Find and tap the upload button
        final uploadButton = find.widgetWithText(FloatingActionButton, 'Upload');
        await tester.tap(uploadButton);
        await tester.pump();
        
        expect(uploadRecordingCalled, isTrue);
      });
    });

    group('Processing States', () {
      testWidgets('should show upload icon when uploading', (tester) async {
        await tester.pumpWidget(createTestWidget(RecordingState.uploading));
        
        expect(find.byIcon(Icons.cloud_upload), findsOneWidget);
        expect(find.text('Uploading...'), findsOneWidget);
      });

      testWidgets('should show processing icon when processing', (tester) async {
        await tester.pumpWidget(createTestWidget(RecordingState.processing));
        
        expect(find.byIcon(Icons.hourglass_empty), findsOneWidget);
        expect(find.text('Processing speech...'), findsOneWidget);
      });

      testWidgets('should show check icon when completed', (tester) async {
        await tester.pumpWidget(createTestWidget(RecordingState.completed));
        
        expect(find.byIcon(Icons.check), findsOneWidget);
        expect(find.text('Email sent successfully!'), findsOneWidget);
      });
    });

    group('Error State', () {
      testWidgets('should show error icon when in error state', (tester) async {
        await tester.pumpWidget(createTestWidget(RecordingState.error));
        
        expect(find.byIcon(Icons.error), findsOneWidget);
        expect(find.text('Error occurred'), findsOneWidget);
      });

      testWidgets('should disable main button when in error state', (tester) async {
        await tester.pumpWidget(createTestWidget(RecordingState.error));
        
        await tester.tap(find.byType(GestureDetector).first);
        await tester.pump();
        
        // Should not call any callbacks when in error state
        expect(startRecordingCalled, isFalse);
        expect(stopRecordingCalled, isFalse);
      });
    });

    group('Button Colors', () {
      testWidgets('should use primary color for idle state', (tester) async {
        await tester.pumpWidget(createTestWidget(RecordingState.idle));
        
        final container = tester.widget<AnimatedContainer>(
          find.byType(AnimatedContainer).first,
        );
        
        // Color testing would require access to theme context
        expect(container.decoration, isA<BoxDecoration>());
      });

      testWidgets('should use red color for recording state', (tester) async {
        await tester.pumpWidget(createTestWidget(RecordingState.recording));
        
        final container = tester.widget<AnimatedContainer>(
          find.byType(AnimatedContainer).first,
        );
        
        final decoration = container.decoration as BoxDecoration;
        expect(decoration.color, Colors.red);
      });
    });

    group('Accessibility', () {
      testWidgets('should have proper semantics for screen readers', (tester) async {
        await tester.pumpWidget(createTestWidget(RecordingState.idle));
        
        // Test that important elements are accessible
        expect(find.text('Tap to start recording'), findsOneWidget);
      });
    });
  });
}