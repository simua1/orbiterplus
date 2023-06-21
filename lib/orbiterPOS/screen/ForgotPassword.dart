import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:orbiterplus/orbiterPOS/model/AppModel.dart';
import 'package:orbiterplus/orbiterPOS/utils/AppStrings.dart';
import 'package:orbiterplus/orbiterPOS/utils/AppColors.dart';
import 'package:orbiterplus/orbiterPOS/utils/AppConstant.dart';
import 'package:orbiterplus/orbiterPOS/utils/AppWidget.dart';
import 'package:orbiterplus/main/utils/AppWidget.dart';

import 'VerifyNumber.dart';

class GroceryForgotPassword extends StatefulWidget {
  static String tag = '/GroceryForgotPassword';

  final OrbiterHelper orbiter;

  const GroceryForgotPassword({super.key, required this.orbiter});

  @override
  _GroceryForgotPasswordState createState() => _GroceryForgotPasswordState();
}

class _GroceryForgotPasswordState extends State<GroceryForgotPassword> {
  @override
  Widget build(BuildContext context) {
    var width = MediaQuery.of(context).size.width;
    changeStatusColor(app_colorPrimary);

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size(double.infinity, 70),
        child: title(grocery_lbl_Forgot_password, app_colorPrimary, grocery_color_white, context),
      ),
      body: SingleChildScrollView(
        child: Container(
          width: width,
          decoration: boxDecorationWithRoundedCorners(
            borderRadius: BorderRadius.only(bottomLeft: Radius.circular(24), bottomRight: Radius.circular(24)),
            boxShadow: defaultBoxShadow(),
            backgroundColor: context.cardColor,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              SizedBox(height: spacing_standard),
              text(grocery_lbl_Reset_Password, fontSize: textSizeLarge, fontFamily: fontBold).paddingOnly(top: spacing_standard_new, left: spacing_standard_new, right: spacing_standard_new),
              text(
                grocery_lbl_enter_email_for_reset_password,
                textColor: grocery_textColorSecondary,
                fontSize: textSizeLargeMedium,
              ).paddingOnly(left: spacing_standard_new, right: spacing_standard_new),
              SizedBox(height: spacing_standard_new),
              EditText(
                text: grocery_lbl_Email_Address,
                isPassword: false,
                keyboardType: TextInputType.emailAddress,
              ).paddingAll(spacing_standard_new),
              Align(
                alignment: Alignment.centerRight,
                child: FittedBox(
                  child: OrbiterButton(
                    textContent: grocery_lbl_send,
                    onPressed: (() {
                      GroceryVerifyNumber(orbiter: widget.orbiter).launch(context);
                    }),
                  ).paddingOnly(right: spacing_standard_new, bottom: spacing_standard_new),
                ).paddingOnly(top: spacing_standard_new, bottom: spacing_standard_new),
              )
            ],
          ),
        ),
      ),
    );
  }
}
