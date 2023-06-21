import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:orbiterplus/main/store/AppStore.dart';
import 'package:orbiterplus/locale/Languages.dart';
import 'package:orbiterplus/main/utils/AppTheme.dart';
import 'package:orbiterplus/orbiterPOS/model/AppModel.dart';
import 'package:orbiterplus/orbiterPOS/screen/Dashboard.dart';
import 'package:provider/provider.dart';

/// This variable is used to get dynamic colors when theme mode is changed
AppStore appStore = AppStore();

BaseLanguage? language;

void main() async {
  //Show Splash screen for nothing less than 15 seconds to display splash screen that long
  await Future.delayed(Duration(seconds: 15), () =>
      runApp(MyApp())
  );

}

class MyApp extends StatelessWidget {

  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {

    OrbiterHelper orbiter = OrbiterHelper();
        () async {
      try {
        final SharedPreferences sharedPreferences = await SharedPreferences
            .getInstance();
        orbiter.isFirstTime = sharedPreferences.getBool("ISFIRSTTIME") ?? true;
        if (orbiter.isFirstTime!) {
          sharedPreferences.setBool("ISFIRSTTIME", false);
        }

        orbiter.platform.invokeMethod('Connect');
      } catch (e, s) {
        print(s);
      }

      //try {

      /*}
    catch(e){*/
      //print(e.toString());
      //}
    }.call();

    return Observer(
      builder: (context) =>
          ChangeNotifierProvider<ShoppingCartModel>(
              create: (_) =>
                  ShoppingCartModel(),
              child: MaterialApp(
                  home: GroceryDashBoardScreen(orbiter),
                  theme: !appStore.isDarkModeOn
                      ? AppThemeData.lightTheme
                      : AppThemeData.darkTheme,
                  routes: {
                    '/DashBoardScreen': (context) => GroceryDashBoardScreen(orbiter)
                  },
                  builder: EasyLoading.init(),
              )),
    );
  }
}
