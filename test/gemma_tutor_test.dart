import 'package:flutter_test/flutter_test.dart';

import 'package:betternotes/features/tools/assistant/gemma_tutor.dart';

void main() {
  test('does not reveal a linear solution', () {
    final tutor = GemmaTutor(german: true);
    final reply = tutor.respond('2x+3=11');
    expect(tutor.replyLeaks(reply.text), isFalse);
    expect(reply.text.toLowerCase(), contains('taschenrechner'));
    expect(reply.solved, isFalse);
  });

  test('refuses to state the answer when asked', () {
    final tutor = GemmaTutor(german: true);
    tutor.respond('2x+3=11');
    final reply = tutor.respond('sag mir die Lösung');
    expect(tutor.replyLeaks(reply.text), isFalse);
    expect(reply.solved, isFalse);
  });

  test('walks through intermediate then confirms without repeating the number', () {
    final tutor = GemmaTutor(german: true);
    tutor.respond('2x+3=11');
    final mid = tutor.respond('8');
    expect(mid.solved, isFalse);
    expect(tutor.replyLeaks(mid.text), isFalse);
    final done = tutor.respond('4');
    expect(done.solved, isTrue);
    expect(tutor.replyLeaks(done.text), isFalse);
  });

  test('does not compute a plain expression', () {
    final tutor = GemmaTutor(german: true);
    final reply = tutor.respond('2+3*4');
    expect(tutor.replyLeaks(reply.text), isFalse);
    expect(reply.text.contains('14'), isFalse);
  });

  test('derivative asks for the rule, not 2x', () {
    final tutor = GemmaTutor(german: true);
    final reply = tutor.respond('ableitung von x^2');
    expect(reply.text.toLowerCase(), contains('tafelwerk'));
    expect(reply.text.toLowerCase().contains('2x'), isFalse);
    final done = tutor.respond('2x');
    expect(done.solved, isTrue);
  });

  test('trig tells the student to type it themselves', () {
    final tutor = GemmaTutor(german: true);
    final reply = tutor.respond('sin(90)');
    expect(tutor.replyLeaks(reply.text), isFalse);
    expect(reply.text.toLowerCase(), contains('grad'));
  });

  test('explains a history connection without writing the exam sentence', () {
    final tutor = GemmaTutor(german: true);
    final reply = tutor.respond(
      'Ich verstehe den Zusammenhang zwischen Versailles und Hitler nicht',
    );
    expect(reply.text.toLowerCase(), contains('versailles'));
    expect(reply.text.toLowerCase(), contains('weimar'));
    expect(reply.text.toLowerCase(), contains('aufgabe'));
  });

  test('starts caricature analysis with description first', () {
    final tutor = GemmaTutor(german: true);
    final reply = tutor.respond('Karikatur');
    expect(reply.text.toLowerCase(), contains('beschreib'));
    expect(reply.text.toLowerCase(), contains('symbol'));
  });

  test('explains a math why-question without leaking the result', () {
    final tutor = GemmaTutor(german: true);
    tutor.respond('2x+3=11');
    final reply = tutor.respond('warum muss ich das auf beiden Seiten tun?');
    expect(reply.text.toLowerCase(), contains('beiden seiten'));
    expect(tutor.replyLeaks(reply.text), isFalse);
  });

  test('opens the calculator for a linear equation', () {
    final tutor = GemmaTutor(german: true);
    final reply = tutor.respond('2x+3=11');
    expect(reply.toolAction, GemmaToolAction.calculator);
    expect(reply.chips, contains('Taschenrechner'));
  });

  test('opens the formula book for a derivative', () {
    final tutor = GemmaTutor(german: true);
    final reply = tutor.respond('ableitung von x^2');
    expect(reply.toolAction, GemmaToolAction.formulaBook);
    expect(reply.formulaChapterId, 'analysis');
    expect(reply.chips, contains('Tafelwerk'));
  });

  test('explains a named caricature symbol', () {
    final tutor = GemmaTutor(german: true);
    tutor.respond('Karikatur');
    final reply = tutor.respond('Da ist der deutsche Michel mit Mütze');
    expect(reply.text.toLowerCase(), contains('michel'));
    expect(reply.text.toLowerCase(), contains('mütze'));
  });
}
