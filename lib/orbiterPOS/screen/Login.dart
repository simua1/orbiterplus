import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:orbiterplus/model/model.dart';
import 'package:orbiterplus/orbiterPOS/model/AppModel.dart';
import 'package:orbiterplus/orbiterPOS/utils/AppStrings.dart';
import 'package:orbiterplus/orbiterPOS/utils/AppColors.dart';
import 'package:orbiterplus/orbiterPOS/utils/AppConstant.dart';
import 'package:orbiterplus/orbiterPOS/utils/AppImages.dart';
import 'package:orbiterplus/orbiterPOS/utils/AppWidget.dart';
import 'package:orbiterplus/main.dart';
import 'package:orbiterplus/main/utils/AppWidget.dart';
import 'package:orbiterplus/orbiterPOS/utils/OrbiterHelpers.dart';
import 'package:provider/provider.dart';

import 'AddNumber.dart';
import 'Dashboard.dart';
import 'ForgotPassword.dart';
import 'OrbiterWeb.dart';
import 'package:http/http.dart' as http;

// ignore: must_be_immutable
class AppLogin extends StatefulWidget {
  static String tag = '/AppLogin';
  bool? isSignIn;
  bool? isSignUp;
  final OrbiterHelper orbiter;

  AppLogin({this.isSignIn = true, this.isSignUp = false, required this.orbiter});

  @override
  _AppLoginState createState() => _AppLoginState();
}

class _AppLoginState extends State<AppLogin> {
  bool isHidden = true;
  final GlobalKey<FormState> _formKey = new GlobalKey<FormState>();
  TextEditingController pwdController = TextEditingController(), usrController = TextEditingController();
  String username = "", password = "", errorMessage = "";

  @override
  void dispose() {
    super.dispose();
    changeStatusColor(app_colorAppbar);
  }

  @override
  void initState() {
    super.initState();
    init();
  }

  init() async {
    //changeStatusColor(appStore.isDarkModeOn ? scaffoldDarkColor : app_colorAppbar);
    /*if (widget.isSignIn == true) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        showDialog<void>(context: context,
          builder: (BuildContext builder) => showRoleDialog(context),
          barrierDismissible: false,);
       });
    }*/
  }

  void togglePasswordView() {
    setState(() {
      isHidden = !isHidden;
    });
  }

  @override
  Widget build(BuildContext context) {
    var width = MediaQuery.of(context).size.width;
    var height = MediaQuery.of(context).size.height;
    var textScale = width < max_width? text_scale_factor : MediaQuery.of(context).textScaleFactor;
    width = width <= max_width? width : max_width; //restrict width to the specified maximum

    final signIn = SafeArea(
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: width * 0.025, vertical: height * 0.025),
          alignment: Alignment.topCenter,
          constraints: BoxConstraints(
              maxWidth: width * 0.95,
              maxHeight: height * 0.95),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Center(
                heightFactor: 0.25,
                child: commonCacheImageWidget(pillometer_full_logo, height * 0.55),
              ),
              Center(
                //heightFactor: 0.35,
                child: text(
                  grocery_lbl_sigIn_App,
                  fontSize: textSizeXLarge,
                  fontFamily: fontBold,
                ),
              ),

              spacing_standard_new.toInt().height,
              /*text(
                grocery_lbl_sigIn_subtext,
                fontSize: textSizeSMedium,
                fontFamily: fontRegular,
                textColor: grocery_darkGrey,
                isLongText: true,
              ),
              spacing_xxLarge.toInt().height,*/
              text(
                grocery_lbl_username,
                textColor: grocery_textColorSecondary,
                fontSize: textSizeLargeMedium,
              ),
              TextFormField(
                autocorrect: false,
                controller: usrController,
                onChanged: (val){
                  username = val;
                },
                decoration: InputDecoration(
                    hintText: grocery_hint_username,
                    contentPadding: EdgeInsets.symmetric(horizontal: spacing_standard_new),
                    border: OutlineInputBorder(
                        borderSide: BorderSide(color: app_colorPrimary)
                    )
                ),
                keyboardType: TextInputType.text,
              ),
              spacing_xlarge.toInt().height,
              text(
                grocery_lbl_password,
                textColor: grocery_textColorSecondary,
                fontSize: textSizeLargeMedium,
              ),
              TextFormField(
                controller: pwdController,
                onChanged: (val){
                  password = val;
                },
                obscureText: isHidden,
                autocorrect: false,
                decoration: InputDecoration(
                    hintText: grocery_hint_password,
                    suffix: InkWell(
                      onTap: togglePasswordView,  /// This is Magical Function
                      child: Icon(
                        isHidden ? Icons.visibility : Icons.visibility_off,
                      ),
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: spacing_standard_new),
                    border: OutlineInputBorder(
                        borderSide: BorderSide(color: app_colorPrimary)
                    )
                ),
              ),
              spacing_xlarge.toInt().height,
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  text(
                    errorMessage,
                    textColor: grocery_textRedColor,
                    maxLine: 2,
                    fontSize: textSizeNormal,
                  ).paddingOnly(bottom: spacing_standard).visible(errorMessage.isNotEmpty),
                  /*text(
                "$grocery_lbl_Forgot_password?",
                fontSize: textSizeLargeMedium,
                fontFamily: fontMedium,
              ).onTap(() {
                GroceryForgotPassword(orbiter: widget.orbiter).launch(context);
              }),*/
                ],
              ).paddingSymmetric(horizontal: spacing_control_half),

              Stack(
                  children: <Widget>[
                    OrbiterButton(
                      textContent: grocery_lbl_Sign_In,
                      onPressed: (() {

                        /*username = usrController.value.toString();
                        password = pwdController.value.toString();*/
                        setState(() {
                          errorMessage = "";
                          if (username.isEmptyOrNull || password.isEmptyOrNull){
                            errorMessage = "Please specify Username and Password";
                          }
                          else {
                                () async {
                              /***First check if the user is already stored in the database.***/
                              /*var obj = (await User().select().toList());
                          obj.forEach((element) => element.delete());*/

                              User? user = (await User().select().username.equals(username).and.password.equals(password).toSingle());
                              try{
                                Notify.showLoading();
                                if (user == null || DateTime.now().toUtc().add(Duration(hours: 1)).isAfter(user.access_token_expiry!)) {
                                  //Get Access Token from the Api:
                                  var params = {'grant_type': 'password',
                                    'client_id': '3',
                                    'client_secret': 'xwCyAOu7M1PhWriMuKnD66i3HEstLMniX4vcC5g8',
                                    'username': username,
                                    'password': password,
                                    'scope': ''};

                                  var url = Uri.https(app_base_url, 'oauth/token');

                                  var resp =
                                  (await http.post(url, body: params)
                                      //.whenComplete(() => Notify.hideLoading())
                                      .timeout(Duration(seconds: 60), onTimeout: () {
                                        setState((){
                                          Notify.toast(message: 'Request Timed Out', type: MessageType.Alert);
                                        });

                                    return http.Response("{'error_description': 'Request Timed Out'}", 408);
                                  }).onError((error, stackTrace) {
                                    setState((){
                                      Notify.toast(message: error.toString(), type: MessageType.Alert);
                                    });

                                    return http.Response("{'error_description': ${error.toString()}}", 403);
                                  }));

                                  Map<String, dynamic> response = jsonDecode(resp.body);
                                  if (resp.statusCode == 200 && resp.body != ""){
                                    user = User();
                                    errorMessage = "";
                                    widget.orbiter.isLoggedIn = true;
                                    user.username = username;
                                    user.password = password;
                                    user.access_token = response['access_token'];
                                    user.refresh_token = response['refresh_token'];
                                    user.access_token_expiry = DateTime.now().add(Duration(seconds: response['expires_in']));

                                    /***Get the Logged On User Details ***/
                                    //params = {'per_page': '-1',};
                                    var headers = {'Content-Type': 'application/json', 'Accept': 'application/json', 'Authorization': 'Bearer ' + user.access_token! };

                                    var url = Uri.https(app_base_url, 'connector/api/user/loggedin');
                                    var resp = (await http.get(url, headers: headers));

                                    var result = jsonDecode(resp.body);
                                    var userData = result['data'];
                                    /***Store the User Details ***/
                                    user.id = userData['id'];
                                    user.firstname = (userData['first_name']?? '').toString();
                                    user.surname = (userData['last_name']?? '').toString();
                                    user.email = (userData['email']?? '').toString();
                                    user.user_type = (userData['user_type']?? '').toString();
                                    user.max_sales_discount_percent = double.parse(userData['max_sales_discount_percent']?? '0.0').toDouble();
                                    user.allow_login = (userData['allow_login']?? '').toString();
                                    user.status = (userData['status']?? '').toString();

                                    /***Get the Business Details ***/
                                    url = Uri.https(app_base_url, 'connector/api/business-details');
                                    resp = (await http.get(url, headers: headers));
                                    result = jsonDecode(resp.body);
                                    var bizData = result['data'];
                                    /***Store the Biz Details ***/
                                    user.business_name = (bizData['name']?? '').toString();
                                    user.business_id = (bizData['id']?? '0');
                                    /*user.tax1_label = (bizData['tax_label_1']?? '').toString();
                                    double tax1 = double.parse(bizData['tax_number_1']?? '0.0').toDouble();
                                    user.tax1_amount = tax1;
                                    user.tax2_label = (bizData['tax_label_2']?? '').toString();
                                    user.tax2_amount = double.parse(bizData['tax_number_2']?? '0.0').toDouble();*/

                                    url = Uri.https(app_base_url, 'connector/api/tax');
                                    resp = (await http.get(url, headers: headers));
                                    result = jsonDecode(resp.body);
                                    var taxData = result['data'];
                                    var taxIds = (await Tax().select().business_id.equals(user.business_id).toListPrimaryKey());
                                    List<Tax> taxes = [];
                                    for (var item in taxData) {
                                      Tax tax = Tax();
                                      tax.name = item['name'];
                                      tax.id = item['id'];
                                      tax.business_id = user.business_id;
                                      if (taxIds.contains(item['id'])){
                                        tax.dateUpdated = DateTime.now().toUtc();
                                      }
                                      else{
                                        tax.dateAdded = DateTime.now().toUtc();
                                      }
                                      tax.dateSynced = DateTime.now().toUtc();
                                      tax.isSynced = true;
                                      tax.amount = double.parse(item['amount']?? '0.0').toDouble();
                                      //tax.isActive = true;
                                      taxes.add(tax);
                                    }
                                    Tax().upsertAll(taxes);
                                    //user.plTaxs = taxes;

                                    /***Get the Tax Details from the database ***/
                                    for (int i = 0; i < taxes.length; i++){
                                      if (i == 0){
                                        user.tax1_id = taxes[i].id;
                                        user.tax1_label = taxes[i].name;
                                        user.tax1_amount = taxes[i].amount?? 0.0;
                                      }

                                      if (i == 1){
                                        user.tax2_id = taxes[i].id;
                                        user.tax2_label = taxes[i].name;
                                        user.tax2_amount = taxes[i].amount?? 0.0;
                                      }
                                    }

                                    user.logo = (bizData['logo']?? '').toString();
                                    user.sell_price_tax = bizData['sell_price_tax'];

                                    /***Location Specific Details***/
                                    url = Uri.https(app_base_url, 'connector/api/business-location');
                                    resp = (await http.get(url, headers: headers));
                                    result = jsonDecode(resp.body);
                                    var locData = result['data'];
                                    var locIds = (await Location().select().business_id.equals(user.business_id).toListPrimaryKey());
                                    List<Location> locations = [];
                                    for (var item in locData) {
                                      Location location = Location();
                                      location.id = item['id'];
                                      location.location_id = item['location_id'];
                                      location.business_id = user.business_id;
                                      location.name = item['name'];
                                      location.address = item['landmark'];
                                      location.country = item['country'];
                                      location.state = item['state'];
                                      location.city = item['city'];
                                      location.mobile = item['mobile'];
                                      location.phone = item['alternate_number'];
                                      location.email = item['email'];
                                      location.website = item['website'];
                                      location.custom_field1 = item['custom_field1'];
                                      location.custom_field2 = item['custom_field2'];
                                      location.custom_field3 = item['custom_field3'];
                                      location.custom_field4 = item['custom_field4'];
                                      location.featured_products = json.encode(item['featured_products']);
                                      location.payment_methods = json.encode(item['payment_methods']);
                                      if (locIds.contains(item['id'])){
                                        location.dateUpdated = DateTime.now().toUtc();
                                      }
                                      else{
                                        location.dateAdded = DateTime.now().toUtc();
                                      }
                                      location.dateSynced = DateTime.now().toUtc();
                                      location.isSynced = true;
                                      //location.isActive = true;
                                      locations.add(location);
                                    }
                                    user.plLocations = locations;
                                    //Location().upsertAll(locations);

                                    var location = locations[0];//(await Location().select(columnsToSelect: ["id"]).business_id.equals(user.business_id).toSingleOrDefault());
                                    user.default_location_id = location.id;

                                    var userid = (await user.upsert());
                                    if(userid != null && userid > 1){
                                      widget.orbiter.LoggedInUser = (await User().getById(userid, preload: true));
                                      widget.orbiter.TaxRate = (user.tax1_amount?? 0.0);
                                      Provider.of<ShoppingCartModel>(context, listen: false).orbiter = widget.orbiter;
                                      GroceryDashBoardScreen(widget.orbiter).launch(context);
                                    }else{
                                      setState((){
                                        Notify.hideLoading();
                                        errorMessage = "Authentication Failed";
                                      });
                                    }
                                  }
                                  else{
                                    setState((){
                                      Notify.hideLoading();
                                      errorMessage = login_error;//response['error_description'];
                                    });
                                  }
                                }
                                else{
                                  errorMessage = "";
                                  widget.orbiter.isLoggedIn = true;
                                  widget.orbiter.LoggedInUser = user;
                                  widget.orbiter.TaxRate = (user.tax1_amount?? 0.0);
                                  widget.orbiter.InlineTax = (user.sell_price_tax?? "");
                                  Provider.of<ShoppingCartModel>(context, listen: false).orbiter = widget.orbiter;
                                  GroceryDashBoardScreen(widget.orbiter).launch(context);
                                }
                              }
                              catch(ex){
                                print(ex.toString());
                              }
                              finally{
                                Notify.hideLoading();
                              }
                            }.call();
                          }
                        });
                      }),
                    ).paddingSymmetric(vertical: spacing_large),
                    /*isLoading
                        ? Center( child: CircularProgressIndicator(color: grocery_light_gray_color)).paddingSymmetric(vertical: spacing_large, )
                        : Container(),*/
                  ]),
              /*Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              text(
                "Don't have an account?",
                textColor: grocery_textColorPrimary,
                fontSize: textSizeLargeMedium,
                fontFamily: fontBold,
              ),
              text(
                "Sign Up",
                textColor: widget.isSignUp == true ?  grocery_textColorPrimary : grocery_textBlueColor,
                fontSize: textSizeLargeMedium,
                fontFamily: fontBold,
              ).onTap(() {
                setState(() {
                  OrbiterWebApp(web_address: "https://" + app_base_url + "/business/register", orbiter: widget.orbiter,).launch(context);
                });
              })
            ],
          )*/
            ],
          ),
        ));

    String selectedRole = app_role_type_cashier;

    AlertDialog showRoleDialog(BuildContext context)
    {
      var width = context.width();

      return AlertDialog(
        //titlePadding: EdgeInsets.all(spacing_xlarge),
        titlePadding: const EdgeInsets.all(spacing_xlarge),
        contentPadding: const EdgeInsets.only(left: spacing_xxxLarge, right: spacing_xxxLarge, bottom: spacing_xlarge),
        actionsPadding: const EdgeInsets.all(spacing_xlarge),
        actionsAlignment: MainAxisAlignment.center,
        backgroundColor: context.cardColor,
        shape: const RoundedRectangleBorder(
            borderRadius:
            BorderRadius.all(Radius.circular(20.0))),
        title: SizedBox(
          width: (width * 0.7),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Align(alignment: Alignment.centerLeft, child: Text(app_login_as, textScaleFactor: textScale),),
              /*Align(alignment: Alignment.centerRight, child: const Icon(Icons.close, size: textSizeLarge).onTap((){Navigator.pop(context);}),),*/
            ],
          ),
        ),
        content: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                //crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  RadioListTile<String>(
                    controlAffinity: ListTileControlAffinity.trailing,
                    title: Text(app_role_type_cashier, textScaleFactor: textScale),
                    value: app_role_type_cashier,
                    groupValue: selectedRole,
                    activeColor: app_colorPrimary,
                    onChanged: (val) =>
                        setState(() =>
                        selectedRole = val!
                        ),
                  ),
                  RadioListTile<String>(
                    controlAffinity: ListTileControlAffinity.trailing,
                    title: Text(app_role_type_admin, textScaleFactor: textScale,),
                    value: app_role_type_admin,
                    groupValue: selectedRole,
                    activeColor: app_colorPrimary,
                    onChanged: (val) =>
                        setState(() =>
                        selectedRole = val!
                        ),
                  ),
                  RadioListTile<String>(
                    controlAffinity: ListTileControlAffinity.trailing,
                    title: Text(app_role_type_accountant, textScaleFactor: textScale),
                    value: app_role_type_accountant,
                    groupValue: selectedRole,
                    activeColor: app_colorPrimary,
                    onChanged: (val) =>
                        setState(() =>
                        selectedRole = val!),
                  ),
                  RadioListTile<String>(
                    controlAffinity: ListTileControlAffinity.trailing,
                    title: Text(app_role_type_storekeeper, textScaleFactor: textScale),
                    value: app_role_type_storekeeper,
                    groupValue: selectedRole,
                    activeColor: app_colorPrimary,
                    onChanged: (val) =>
                        setState(() =>
                        selectedRole = val!),
                  ),
                ],
              );
            }),
        actions: [
          Center(
            child: TextButton(child: Text(grocery_lbl_Sign_In, style: TextStyle(color: grocery_colorPrimary_light, fontSize: textSizeLarge, fontFamily: fontSemiBold), textScaleFactor: textScale,),onPressed: (){
              setState(() {
                Navigator.pop(context);
                if (selectedRole != app_role_type_cashier){
                  OrbiterWebApp(orbiter: widget.orbiter).launch(context);
                }
              });
              //Notify.toast(message: "Sorted Successfully", type: MessageType.Success);
            },),
          )
        ],
      );
    }

    return SafeArea(
      child: Scaffold(
        body: SingleChildScrollView(
          child: Center(
            //crossAxisAlignment: CrossAxisAlignment.end,
            //mainAxisAlignment: MainAxisAlignment.end,
            child: Container(
              width: width * 0.60,
              padding: EdgeInsets.only(top: spacing_xxxLarge),
              decoration: boxDecorationWithRoundedCorners(
                //borderRadius: BorderRadius.only(bottomLeft: Radius.circular(24), bottomRight: Radius.circular(24)),
                //boxShadow: defaultBoxShadow(),
                backgroundColor: context.cardColor,
              ),
              //child: widget.isSignUp! ? signUp : signIn,
              child: signIn,
            ),
          ),
        ),
      ),
    );

  }
}
