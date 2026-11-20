
import 'package:flutter_test/flutter_test.dart';
import 'package:codealpha_flashcard_quiz/main.dart';

void main() {
  testWidgets('Flashcard Quiz App loads', (WidgetTester tester) async {
    await tester.pumpWidget(const FlashcardApp());

    expect(find.text('Study Smarter'), findsOneWidget);
  });
}
