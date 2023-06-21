// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_session_manager/flutter_session_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nb_utils/nb_utils.dart';

import 'package:orbiterplus/main.dart';
import 'package:orbiterplus/model/model.dart';
import 'package:orbiterplus/orbiterPOS/model/AppModel.dart';
import 'package:orbiterplus/orbiterPOS/utils/AppDataGenerator.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    bool isFirstTime = true;

    try {
      final SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
      isFirstTime = sharedPreferences.getBool("ISFIRSTTIME")?? true;
      if (isFirstTime){
        sharedPreferences.setBool("ISFIRSTTIME", false);
        SessionManager().set("ISFIRSTTIME", true);
      }
    } catch (e) {

    }
    const MethodChannel platform = MethodChannel('orbiterplus.fixhire.com/printing');
    final OrbiterHelper orbiter = OrbiterHelper();
    // Build our app and trigger a frame.
    await tester.pumpWidget( MyApp());

    // Verify that our counter starts at 0.
    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);

    // Tap the '+' icon and trigger a frame.
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    // Verify that our counter has incremented.
    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
  });
}
