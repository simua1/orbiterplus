import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:orbiterplus/main.dart';
import 'package:orbiterplus/main/utils/AppWidget.dart';
import 'package:orbiterplus/model/model.dart';
import 'package:orbiterplus/orbiterPOS/model/AppModel.dart';
import 'package:orbiterplus/orbiterPOS/utils/AppStrings.dart';
import 'package:orbiterplus/orbiterPOS/utils/AppColors.dart';
import 'package:orbiterplus/orbiterPOS/utils/AppConstant.dart';
import 'package:orbiterplus/orbiterPOS/utils/AppImages.dart';
import 'package:orbiterplus/orbiterPOS/utils/OrbiterHelpers.dart';


class CustomersWidget extends StatefulWidget {
  final OrbiterHelper orbiter;

  const CustomersWidget(this.orbiter, {super.key});

  @override
  CustomersState createState() => CustomersState();
}

class CustomersState extends State<CustomersWidget> {
  List<Customer> customers = [];
  late GlobalKey<FormState> _formKey;
  late TextEditingController searchController;
  late FocusNode focusNode;
  List<Customer> mList = [];
  String? searchText = "";
  int business_id = -1;

  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    changeStatusColor(appStore.isDarkModeOn ? scaffoldDarkColor : white);
    searchController = TextEditingController();
    focusNode  = FocusNode();
    _formKey = GlobalKey<FormState>();
    if (widget.orbiter.LoggedInUser != null){
      business_id = (widget.orbiter.LoggedInUser!.business_id?? -1);
    }

    (() async => runSearch(args: searchText)).call();

  }


  @override
  void dispose() {
    super.dispose();
    _disposed = true;
  }

  Future<List<Customer>> runSearch({String? args}) async{

    if (!args.isEmptyOrNull){
      customers = (await Customer().select()
          .business_id.equals(business_id)
          .and.name.not.equals('Walk-In Customer')
        .and
        .startBlock
          .name.startsWith(args)
          .or.firstname.startsWith(args)
          .or.firstname.startsWith(args)
          .or.middleName.startsWith(args)
          .or.surname.startsWith(args)
          .or.mobile.startsWith(args)
          .or.phone.startsWith(args)
      .endBlock
          .orderBy('name').toList());
    }else{
      customers = (await Customer().select().business_id.equals(business_id).and.name.not.equals('Walk-In Customer').orderBy('name').toList());
    }

    setState(()=>null);


    /*customers = (args.isEmptyOrNull? customers : customers.where((c) =>
    c.firstname!.toLowerCase().startsWith(args.toString().toLowerCase()) ||
        c.middleName!.toLowerCase().startsWith(args.toString().toLowerCase()) ||
        c.surname!.toLowerCase().startsWith(args.toString().toLowerCase()) ||
        c.mobile!.toLowerCase().startsWith(args.toString().toLowerCase()) ||
        c.phone!.toLowerCase().startsWith(args.toString().toLowerCase())
    )).toList();*/

    return customers;
  }

  @override
  Widget build(BuildContext context) {
    var width = MediaQuery.of(context).size.width;
    var height = MediaQuery.of(context).size.height;
    var textScale = width < 600? 0.85 : MediaQuery.of(context).textScaleFactor;
    width = width <= 685? width : 685; //restrict width to 685

    (() async => runSearch(args: searchText)).call();

    Future<Customer?> createCustomer() async {
      Customer customer = Customer();
      TextEditingController prefix = TextEditingController(), firstname = TextEditingController(),
          middleName = TextEditingController(), surname = TextEditingController(),
          phone = TextEditingController(), mobile = TextEditingController(), address = TextEditingController();

      showDialog<void>(context: context, barrierDismissible: false, builder: (BuildContext builder) =>
          AlertDialog(
            titlePadding: EdgeInsets.all(spacing_standard_new),
            contentPadding: EdgeInsets.only(left: spacing_standard_new, right: spacing_standard_new, bottom: spacing_standard_new),
            actionsPadding: EdgeInsets.all(spacing_standard),
            actionsAlignment: MainAxisAlignment.center,
            backgroundColor: context.cardColor,
            shape: RoundedRectangleBorder(
                borderRadius:
                BorderRadius.all(Radius.circular(15.0))),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(
                  width: (width * 0.65),
                  child: Align(alignment: Alignment.centerLeft,
                    child: Text(grocery_customer_form_title, maxLines: 1, softWrap: false, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: textSizeNormal), textScaleFactor: textScale),),
                ),
                /*Align(alignment: Alignment.centerRight,
                  child:
                  TextButton.icon(onPressed: ()=> Navigator.pop(builder),
                      icon: Icon(Icons.delete, size: textSizeLarge, color: grocery_color_red,),
                      label: Text(grocery_customer_delete_button, style: TextStyle(fontSize: textSizeLarge, color: grocery_color_red))),),*/
              ],
            ),
            content: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  //mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /***Prefix and Firstname***/
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Expanded(
                          flex: 3,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(grocery_customer_prefix_label, style: TextStyle(fontSize: textSizeMedium), textScaleFactor: textScale),
                              Padding(padding: EdgeInsets.all(spacing_control)),
                              TextFormField(
                                controller: prefix,
                                autofocus: false,
                                textInputAction: TextInputAction.done,
                                style: primaryTextStyle(fontFamily: fontRegular, size: textSizeMedium.toInt()),
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: grocery_icon_purple_bg,
                                  contentPadding: EdgeInsets.all(spacing_control),
                                  border: InputBorder.none,
                                ),
                                maxLength: 10,
                                keyboardType: TextInputType.text,
                                textAlign: TextAlign.left,
                                autovalidateMode: AutovalidateMode.onUserInteraction,
                                validator: (val){
                                  if (val == null || val.isEmpty) {
                                    return '$grocery_customer_prefix_label $grocery_validation_required_text';
                                  }
                                  else if(val.length > 10){
                                    return '$grocery_customer_prefix_label $grocery_validation_too_long';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                        Padding(padding: EdgeInsets.all(spacing_control)),
                        Expanded(
                          flex: 9,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(grocery_customer_firstname_label, style: TextStyle(fontSize: textSizeMedium), textScaleFactor: textScale),
                              Padding(padding: EdgeInsets.all(spacing_control)),
                              TextFormField(
                                  controller: firstname,
                                  autofocus: false,
                                  textInputAction: TextInputAction.done,
                                  style: primaryTextStyle(fontFamily: fontRegular, size: textSizeMedium.toInt()),
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: grocery_icon_purple_bg,
                                    contentPadding: EdgeInsets.all(spacing_control),
                                    border: InputBorder.none,
                                  ),
                                  maxLength: 20,
                                  keyboardType: TextInputType.text,
                                  textAlign: TextAlign.left,
                                  autovalidateMode: AutovalidateMode.onUserInteraction,
                                  validator: (val){
                                    if (val == null || val.isEmpty) {
                                      return '$grocery_customer_firstname_label $grocery_validation_required_text';
                                    }
                                    else if(val.length > 20){
                                      return '$grocery_customer_firstname_label $grocery_validation_too_long';
                                    }
                                    return null;
                                  }
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Padding(padding: EdgeInsets.all(spacing_control)),
                    /***Middle Name and Surname***/
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Expanded(
                          flex: 6,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(grocery_customer_middlename_label, style: TextStyle(fontSize: textSizeSmall, height: 2.25), textScaleFactor: textScale),
                              Padding(padding: EdgeInsets.all(spacing_control_half)),
                              TextFormField(
                                  controller: middleName,
                                  autofocus: false,
                                  textInputAction: TextInputAction.done,
                                  style: primaryTextStyle(fontFamily: fontRegular, size: textSizeMedium.toInt()),
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: grocery_icon_purple_bg,
                                    contentPadding: EdgeInsets.all(spacing_control),
                                    border: InputBorder.none,
                                  ),
                                  maxLength: 20,
                                  keyboardType: TextInputType.text,
                                  textAlign: TextAlign.left,
                                  autovalidateMode: AutovalidateMode.onUserInteraction,
                                  validator: (val){
                                    if(val!.length > 20){
                                      return '$grocery_customer_middlename_label $grocery_validation_too_long';
                                    }
                                    return null;
                                  }
                              ),
                            ],
                          ),
                        ),
                        Padding(padding: EdgeInsets.all(spacing_control)),
                        Expanded(
                          flex: 6,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(grocery_customer_surname_label, style: TextStyle(fontSize: textSizeMedium), textScaleFactor: textScale),
                              Padding(padding: EdgeInsets.all(spacing_control)),
                              TextFormField(
                                  controller: surname,
                                  autofocus: false,
                                  textInputAction: TextInputAction.done,
                                  style: primaryTextStyle(fontFamily: fontRegular, size: textSizeMedium.toInt()),
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: grocery_icon_purple_bg,
                                    contentPadding: EdgeInsets.all(spacing_control),
                                    border: InputBorder.none,
                                  ),
                                  maxLength: 20,
                                  keyboardType: TextInputType.text,
                                  textAlign: TextAlign.left,
                                  autovalidateMode: AutovalidateMode.onUserInteraction,
                                  validator: (val){
                                    if (val == null || val.isEmpty) {
                                      return '$grocery_customer_surname_label $grocery_validation_required_text';
                                    }
                                    else if(val.length > 20){
                                      return '$grocery_customer_surname_label $grocery_validation_too_long';
                                    }
                                    return null;
                                  }
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Padding(padding: EdgeInsets.all(spacing_control)),
                    /***Phone and Mobile Numbers***/
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        //Phone Number
                        Expanded(
                          flex: 6,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(grocery_customer_phone_label, style: TextStyle(fontSize: textSizeMedium), textScaleFactor: textScale),
                              Padding(padding: EdgeInsets.all(spacing_control)),
                              TextFormField(
                                  controller: phone,
                                  autofocus: false,
                                  textInputAction: TextInputAction.done,
                                  style: primaryTextStyle(fontFamily: fontRegular, size: textSizeMedium.toInt()),
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: grocery_icon_purple_bg,
                                    contentPadding: EdgeInsets.all(spacing_control),
                                    border: InputBorder.none,
                                  ),
                                  maxLength: 14,
                                  keyboardType: TextInputType.phone,
                                  textAlign: TextAlign.left,
                                  autovalidateMode: AutovalidateMode.onUserInteraction,
                                  validator: (val){
                                    if (val == null || val.isEmpty) {
                                      return '$grocery_customer_phone_label $grocery_validation_required_text';
                                    }
                                    else if(val.isNotEmpty && (!val.startsWith("234") && !val.startsWith("+234") && !val.startsWith("0"))){
                                      return '$grocery_customer_phone_label $grocery_validation_invalid_text';
                                    }
                                    else if(val.isNotEmpty && val.startsWith("+234") && val.length != 14){
                                      return '$grocery_customer_phone_label $grocery_validation_invalid_text';
                                    }
                                    else if(val.isNotEmpty && val.startsWith("234") && val.length != 13){
                                      return '$grocery_customer_phone_label $grocery_validation_invalid_text';
                                    }
                                    else if(val.isNotEmpty && val.startsWith("0") && val.length != 11){
                                      return '$grocery_customer_phone_label $grocery_validation_invalid_text';
                                    }
                                    return null;
                                  }
                              ),
                            ],
                          ),
                        ),
                        Padding(padding: EdgeInsets.all(spacing_control)),
                        //Mobile Number
                        Expanded(
                          flex: 6,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(grocery_customer_mobile_label, style: TextStyle(fontSize: textSizeMedium), textScaleFactor: textScale),
                              Padding(padding: EdgeInsets.all(spacing_control)),
                              TextFormField(
                                  controller: mobile,
                                  autofocus: false,
                                  textInputAction: TextInputAction.next,
                                  style: primaryTextStyle(fontFamily: fontRegular, size: textSizeMedium.toInt()),
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: grocery_icon_purple_bg,
                                    contentPadding: EdgeInsets.all(spacing_control),
                                    border: InputBorder.none,
                                  ),
                                  maxLength: 14,
                                  keyboardType: TextInputType.phone,
                                  textAlign: TextAlign.left,
                                  autovalidateMode: AutovalidateMode.onUserInteraction,
                                  validator: (val){
                                    if(val!.isNotEmpty && (!val.startsWith("234") && !val.startsWith("+234") && !val.startsWith("0"))){
                                      return '$grocery_customer_mobile_label $grocery_validation_invalid_text';
                                    }
                                    else if(val.isNotEmpty && val.startsWith("+234") && val.length != 14){
                                      return '$grocery_customer_mobile_label $grocery_validation_invalid_text';
                                    }
                                    else if(val.isNotEmpty && val.startsWith("234") && val.length != 13){
                                      return '$grocery_customer_mobile_label $grocery_validation_invalid_text';
                                    }
                                    else if(val.isNotEmpty && val.startsWith("0") && val.length != 11){
                                      return '$grocery_customer_mobile_label $grocery_validation_invalid_text';
                                    }
                                    return null;
                                  }
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Padding(padding: EdgeInsets.all(spacing_control)),
                    /***Address starts here***/
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(grocery_customer_address_title_label, style: boldTextStyle(size: textSizeMedium.toInt()), textScaleFactor: textScale),
                        Padding(padding: EdgeInsets.all(spacing_control)),
                      ],
                    ),
                    Padding(padding: EdgeInsets.all(spacing_control)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Expanded(
                          flex: 1,
                          child: Column(
                            //mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(grocery_customer_address_label, style: TextStyle(fontSize: textSizeMedium), textScaleFactor: textScale),
                              Padding(padding: EdgeInsets.all(spacing_standard)),
                              TextFormField(
                                  controller: address,
                                  autofocus: false,
                                  textInputAction: TextInputAction.done,
                                  style: primaryTextStyle(fontFamily: fontRegular, size: textSizeMedium.toInt()),
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: grocery_icon_purple_bg,
                                    contentPadding: EdgeInsets.all(spacing_control),
                                    border: InputBorder.none,
                                  ),
                                  maxLength: 100,
                                  keyboardType: TextInputType.streetAddress,
                                  textAlign: TextAlign.left,
                                  autovalidateMode: AutovalidateMode.onUserInteraction,
                                  validator: (val){
                                    if(val!.length > 100){
                                      return '$grocery_customer_address_label $grocery_validation_too_long';
                                    }
                                    return null;
                                  }
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  TextButton(child:Text(grocery_customer_cancel_button, style: TextStyle(color: grocery_darkGrey, fontSize: textSizeMedium, fontFamily: fontSemiBold), textScaleFactor: textScale,),
                    onPressed: (){
                      Navigator.pop(builder);
                  },),
                  Padding(padding: EdgeInsets.all(spacing_control)),
                  TextButton(child:Text(grocery_customer_save_button, style: TextStyle(color: grocery_colorPrimary_light, fontSize: textSizeMedium, fontFamily: fontSemiBold), textScaleFactor: textScale,),
                    onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      //List<Customer> customers = [];
                      //customers = (await Customer().select().name.not.equals('Walk-In Customer').toList());
                      customer.prefix = prefix.value.text;
                      customer.firstname = firstname.value.text;
                      customer.middleName = middleName.value.text;
                      customer.surname = surname.value.text;
                      customer.business_id = business_id;
                      customer.name =
                          firstname.value.text + " " + middleName.value.text +
                              " " + surname.value.text;
                      customer.phone = phone.value.text;
                      customer.mobile = mobile.value.text;
                      customer.shippingAddress = address.value.text;
                      customer.status = 'active';
                      customer.isSynced = false;
                      //customer.isActive = true;
                      customer.dateAdded = DateTime.now().toUtc();

                      customers.add(customer);

                      (await Customer().upsertAll(
                          customers, exclusive: true,
                          noResult: true,
                          continueOnError: true));

                      if (!_disposed) {
                        setState(() {
                              () async {
                            customers = (await Customer()
                                .select().name.not.equals('Walk-In Customer').orderByDesc('name')
                            /*.isActive
                              .equals(true)*/
                                .toList());
                          }.call();
                        });
                      }

                      Navigator.pop(builder);
                      Notify.toast(message: "Customer Added Successfully",
                          type: MessageType.Success);
                    }
                  },),
                ],
              )
            ],
          )
      );
      return customer;
    }

    Future<Customer?> editCustomer(int pos) async {
      Customer model = customers[pos];

      TextEditingController prefix = TextEditingController(text: model.prefix), firstname = TextEditingController(text: model.firstname),
          middleName = TextEditingController(text: model.middleName), surname = TextEditingController(text: model.surname),
          phone = TextEditingController(text: model.phone), mobile = TextEditingController(text: model.mobile), address = TextEditingController(text: model.addressLine1);

      showDialog<void>(context: context, barrierDismissible: false, builder: (BuildContext builder) =>
          AlertDialog(
            titlePadding: EdgeInsets.all(spacing_standard_new),
            contentPadding: EdgeInsets.only(left: spacing_standard_new, right: spacing_standard_new, bottom: spacing_standard_new),
            actionsPadding: EdgeInsets.all(spacing_standard),
            actionsAlignment: MainAxisAlignment.center,
            backgroundColor: context.cardColor,
            shape: RoundedRectangleBorder(
                borderRadius:
                BorderRadius.all(Radius.circular(15.0))),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(
                  width: (width * 0.65),
                  child: const Align(alignment: Alignment.centerLeft,
                    child: Text(grocery_customer_form_title, maxLines: 1, softWrap: false, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: textSizeNormal)),),
                ),
                /*Align(alignment: Alignment.centerRight,
                  child:
                  TextButton.icon(onPressed: ()=> Navigator.pop(builder),
                      icon: Icon(Icons.delete, size: textSizeLarge, color: grocery_color_red,),
                      label: Text(grocery_customer_delete_button, style: TextStyle(fontSize: textSizeLarge, color: grocery_color_red))),),*/
              ],
            ),
            content: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  //mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /***Prefix and Firstname***/
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Expanded(
                          flex: 3,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(grocery_customer_prefix_label, style: TextStyle(fontSize: textSizeMedium), textScaleFactor: textScale),
                              Padding(padding: EdgeInsets.all(spacing_control)),
                              TextFormField(
                                controller: prefix,
                                autofocus: false,
                                textInputAction: TextInputAction.done,
                                style: primaryTextStyle(fontFamily: fontRegular, size: textSizeMedium.toInt()),
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: grocery_icon_purple_bg,
                                  contentPadding: EdgeInsets.all(spacing_control),
                                  border: InputBorder.none,
                                ),
                                maxLength: 10,
                                keyboardType: TextInputType.text,
                                textAlign: TextAlign.left,
                                autovalidateMode: AutovalidateMode.onUserInteraction,
                                validator: (val){
                                  if (val == null || val.isEmpty) {
                                    return '$grocery_customer_prefix_label $grocery_validation_required_text';
                                  }
                                  else if(val.length > 10){
                                    return '$grocery_customer_prefix_label $grocery_validation_too_long';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                        Padding(padding: EdgeInsets.all(spacing_control)),
                        Expanded(
                          flex: 9,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(grocery_customer_firstname_label, style: TextStyle(fontSize: textSizeMedium), textScaleFactor: textScale),
                              Padding(padding: EdgeInsets.all(spacing_control)),
                              TextFormField(
                                  controller: firstname,
                                  autofocus: false,
                                  textInputAction: TextInputAction.done,
                                  style: primaryTextStyle(fontFamily: fontRegular, size: textSizeMedium.toInt()),
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: grocery_icon_purple_bg,
                                    contentPadding: EdgeInsets.all(spacing_control),
                                    border: InputBorder.none,
                                  ),
                                  maxLength: 20,
                                  keyboardType: TextInputType.text,
                                  textAlign: TextAlign.left,
                                  autovalidateMode: AutovalidateMode.onUserInteraction,
                                  validator: (val){
                                    if (val == null || val.isEmpty) {
                                      return '$grocery_customer_firstname_label $grocery_validation_required_text';
                                    }
                                    else if(val.length > 20){
                                      return '$grocery_customer_firstname_label $grocery_validation_too_long';
                                    }
                                    return null;
                                  }
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Padding(padding: EdgeInsets.all(spacing_control)),
                    /***Middle Name and Surname***/
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Expanded(
                          flex: 6,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(grocery_customer_middlename_label, style: TextStyle(fontSize: textSizeSmall, height: 2.25), textScaleFactor: textScale),
                              Padding(padding: EdgeInsets.all(spacing_control_half)),
                              TextFormField(
                                  controller: middleName,
                                  autofocus: false,
                                  textInputAction: TextInputAction.done,
                                  style: primaryTextStyle(fontFamily: fontRegular, size: textSizeMedium.toInt()),
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: grocery_icon_purple_bg,
                                    contentPadding: EdgeInsets.all(spacing_control),
                                    border: InputBorder.none,
                                  ),
                                  maxLength: 20,
                                  keyboardType: TextInputType.text,
                                  textAlign: TextAlign.left,
                                  autovalidateMode: AutovalidateMode.onUserInteraction,
                                  validator: (val){
                                    if(val!.length > 20){
                                      return '$grocery_customer_middlename_label $grocery_validation_too_long';
                                    }
                                    return null;
                                  }
                              ),
                            ],
                          ),
                        ),
                        Padding(padding: EdgeInsets.all(spacing_control)),
                        Expanded(
                          flex: 6,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(grocery_customer_surname_label, style: TextStyle(fontSize: textSizeMedium), textScaleFactor: textScale),
                              Padding(padding: EdgeInsets.all(spacing_control)),
                              TextFormField(
                                  controller: surname,
                                  autofocus: false,
                                  textInputAction: TextInputAction.done,
                                  style: primaryTextStyle(fontFamily: fontRegular, size: textSizeMedium.toInt()),
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: grocery_icon_purple_bg,
                                    contentPadding: EdgeInsets.all(spacing_control),
                                    border: InputBorder.none,
                                  ),
                                  maxLength: 20,
                                  keyboardType: TextInputType.text,
                                  textAlign: TextAlign.left,
                                  autovalidateMode: AutovalidateMode.onUserInteraction,
                                  validator: (val){
                                    if (val == null || val.isEmpty) {
                                      return '$grocery_customer_surname_label $grocery_validation_required_text';
                                    }
                                    else if(val.length > 20){
                                      return '$grocery_customer_surname_label $grocery_validation_too_long';
                                    }
                                    return null;
                                  }
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Padding(padding: EdgeInsets.all(spacing_control)),
                    /***Phone and Mobile Numbers***/
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        //Phone Number
                        Expanded(
                          flex: 6,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(grocery_customer_phone_label, style: TextStyle(fontSize: textSizeMedium), textScaleFactor: textScale),
                              Padding(padding: EdgeInsets.all(spacing_control)),
                              TextFormField(
                                  controller: phone,
                                  autofocus: false,
                                  textInputAction: TextInputAction.done,
                                  style: primaryTextStyle(fontFamily: fontRegular, size: textSizeMedium.toInt()),
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: grocery_icon_purple_bg,
                                    contentPadding: EdgeInsets.all(spacing_control),
                                    border: InputBorder.none,
                                  ),
                                  maxLength: 14,
                                  keyboardType: TextInputType.phone,
                                  textAlign: TextAlign.left,
                                  autovalidateMode: AutovalidateMode.onUserInteraction,
                                  validator: (val){
                                    if (val == null || val.isEmpty) {
                                      return '$grocery_customer_phone_label $grocery_validation_required_text';
                                    }
                                    else if(val.isNotEmpty && (!val.startsWith("234") && !val.startsWith("+234") && !val.startsWith("0"))){
                                      return '$grocery_customer_phone_label $grocery_validation_invalid_text';
                                    }
                                    else if(val.isNotEmpty && val.startsWith("+234") && val.length != 14){
                                      return '$grocery_customer_phone_label $grocery_validation_invalid_text';
                                    }
                                    else if(val.isNotEmpty && val.startsWith("234") && val.length != 13){
                                      return '$grocery_customer_phone_label $grocery_validation_invalid_text';
                                    }
                                    else if(val.isNotEmpty && val.startsWith("0") && val.length != 11){
                                      return '$grocery_customer_phone_label $grocery_validation_invalid_text';
                                    }
                                    return null;
                                  }
                              ),
                            ],
                          ),
                        ),
                        Padding(padding: EdgeInsets.all(spacing_control)),
                        //Mobile Number
                        Expanded(
                          flex: 6,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(grocery_customer_mobile_label, style: TextStyle(fontSize: textSizeMedium), textScaleFactor: textScale),
                              Padding(padding: EdgeInsets.all(spacing_control)),
                              TextFormField(
                                  controller: mobile,
                                  autofocus: false,
                                  textInputAction: TextInputAction.next,
                                  style: primaryTextStyle(fontFamily: fontRegular, size: textSizeMedium.toInt()),
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: grocery_icon_purple_bg,
                                    contentPadding: EdgeInsets.all(spacing_control),
                                    border: InputBorder.none,
                                  ),
                                  maxLength: 14,
                                  keyboardType: TextInputType.phone,
                                  textAlign: TextAlign.left,
                                  autovalidateMode: AutovalidateMode.onUserInteraction,
                                  validator: (val){
                                    if(val!.isNotEmpty && (!val.startsWith("234") && !val.startsWith("+234") && !val.startsWith("0"))){
                                      return '$grocery_customer_mobile_label $grocery_validation_invalid_text';
                                    }
                                    else if(val.isNotEmpty && val.startsWith("+234") && val.length != 14){
                                      return '$grocery_customer_mobile_label $grocery_validation_invalid_text';
                                    }
                                    else if(val.isNotEmpty && val.startsWith("234") && val.length != 13){
                                      return '$grocery_customer_mobile_label $grocery_validation_invalid_text';
                                    }
                                    else if(val.isNotEmpty && val.startsWith("0") && val.length != 11){
                                      return '$grocery_customer_mobile_label $grocery_validation_invalid_text';
                                    }
                                    return null;
                                  }
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Padding(padding: EdgeInsets.all(spacing_control)),
                    /***Address starts here***/
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(grocery_customer_address_title_label, style: boldTextStyle(size: textSizeMedium.toInt()), textScaleFactor: textScale),
                        Padding(padding: EdgeInsets.all(spacing_control)),
                      ],
                    ),
                    Padding(padding: EdgeInsets.all(spacing_control)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Expanded(
                          flex: 1,
                          child: Column(
                            //mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(grocery_customer_address_label, style: TextStyle(fontSize: textSizeMedium), textScaleFactor: textScale),
                              Padding(padding: EdgeInsets.all(spacing_standard)),
                              TextFormField(
                                  controller: address,
                                  autofocus: false,
                                  textInputAction: TextInputAction.done,
                                  style: primaryTextStyle(fontFamily: fontRegular, size: textSizeMedium.toInt()),
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: grocery_icon_purple_bg,
                                    contentPadding: EdgeInsets.all(spacing_control),
                                    border: InputBorder.none,
                                  ),
                                  maxLength: 100,
                                  keyboardType: TextInputType.streetAddress,
                                  textAlign: TextAlign.left,
                                  autovalidateMode: AutovalidateMode.onUserInteraction,
                                  validator: (val){
                                    if(val!.length > 100){
                                      return '$grocery_customer_address_label $grocery_validation_too_long';
                                    }
                                    return null;
                                  }
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  TextButton(child:Text(grocery_customer_cancel_button, style: TextStyle(color: grocery_darkGrey, fontSize: textSizeNormal, fontFamily: fontSemiBold), textScaleFactor: textScale,),
                    onPressed: (){
                      Navigator.pop(builder);
                  },),
                  Padding(padding: EdgeInsets.all(spacing_standard_new)),
                  TextButton(child:Text(grocery_customer_save_button, style: TextStyle(color: grocery_colorPrimary_light, fontSize: textSizeNormal, fontFamily: fontSemiBold), textScaleFactor: textScale,),
                    onPressed: (){
                    if (_formKey.currentState!.validate()) {
                      setState((){
                        model.prefix = prefix.value.text;
                        model.firstname = firstname.value.text;
                        model.middleName = middleName.value.text;
                        model.surname = surname.value.text;
                        model.name =
                            firstname.value.text + " " + middleName.value.text +
                                " " + surname.value.text;
                        model.phone = phone.value.text;
                        model.mobile = mobile.value.text;
                        model.addressLine1 = address.value.text;

                        try{
                          model.save();
                          setState(() => Notify.toast(message: "Customer Updated Successfully", type: MessageType.Success));
                        }
                        catch (e){
                          print(e.toString());
                        }
                        finally{
                          Navigator.pop(builder);
                        }
                      });
                    }
                  },),
                ],
              )
            ],
          )
      );

      return model;
    }

    Widget CustomerWidget(Customer model, int index, ) {

      return Align(
        alignment: Alignment.topCenter,
        child: GestureDetector(
          onTap: () => editCustomer(index),
        child: Container(
          width: width * 0.95,
          //height: height * 0.11,
          padding: EdgeInsets.symmetric(
              horizontal: spacing_standard_new, vertical: spacing_standard_new),
          margin: EdgeInsets.all(spacing_control),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                flex: 2,
                child: commonCachedNetworkImage(grocery_customer_holder, fit: BoxFit.contain, height: 55),
              ),
              Expanded(
                flex: 8,
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                    Text(model.name!, style: primaryTextStyle(size: textSizeNormal.toInt()), textScaleFactor: textScale,),
                      spacing_control.toInt().height,
                      Text("${model.phone}",
                          style: primaryTextStyle(
                              size: textSizeMedium.toInt()), textScaleFactor: textScale,),
                    ]),
              ),
              Expanded(
                flex: 1,
                child: IntrinsicHeight(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    //mainAxisSize: MainAxisSize.max,
                    children: <Widget>[
                      StatefulBuilder(
                          builder: (ctx, setState)
                          {
                            return Expanded(child: Icon(Icons.chevron_right));}), //Icon(Icons.more_vert)),
                    ],
                  ),
                ).paddingAll(spacing_standard),
              ),
            ],
          ),
        ),
      ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        iconTheme: appIconTheme,
        actionsIconTheme: appIconTheme,
        //centerTitle: true,
        //toolbarHeight: 100.0,
        title: Text(grocery_menu_customers, style: TextStyle(color: blackColor, fontSize: textSizeNormal), textScaleFactor: textScale),
        elevation: 0.0,
        scrolledUnderElevation: 5.0,
        actions: [
          Padding(padding: EdgeInsets.only(right: spacing_standard ),
            child: TextButton.icon(onPressed: createCustomer, icon: Icon(Icons.person_add, color: blackColor, size: textSizeNormal), label: Text(grocery_customer_add_button, style: TextStyle(color: blackColor, fontSize: textSizeMedium), textScaleFactor: textScale),),
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Align(alignment: Alignment.topCenter, child:
                Container(
                  width: width * 0.90,
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: grocery_lightGrey, width: 2)
                  ),
                  child: Container(
                      padding: const EdgeInsets.all(spacing_standard),
                      child: IntrinsicHeight( child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Expanded(flex: 5, child: TextFormField(
                              controller: searchController,
                              textInputAction: TextInputAction.search,
                              style: primaryTextStyle(color: grocery_textColorPrimary, fontFamily: fontRegular, size: textSizeNormal.toInt()),
                              decoration: InputDecoration(
                                constraints: BoxConstraints(maxWidth: width * 0.70),
                                prefixIcon: const Icon(Icons.search, color: grocery_lightGrey, size: textSizeNormal),
                                border: InputBorder.none,
                                hintText: grocery_customer_search_hint,
                                hintStyle: primaryTextStyle(color: grocery_lightGrey, size: textSizeSMedium.toInt()),
                              ),
                              keyboardType: TextInputType.text,
                              textAlign: TextAlign.start,
                              //autofocus: true,
                              focusNode: focusNode,
                              onTap: (){
                                focusNode.requestFocus();
                                searchController.selectAll();
                              },
                              onChanged: (p){
                                searchText = p;
                              },
                              //onSaved: (p){runSearch(args: p);},
                              onFieldSubmitted: (p){
                                if (!_disposed) {
                                  setState(() {
                                    (() async => runSearch(args: searchText)).call();
                                  });
                                }
                              },
                            ),),
                            //Expanded(flex: 3, child: SizedBox()),
                          ]
                      ))
                  ),
                ),//.paddingAll(50),
                ),
              ],
            ),
            customers.isEmpty?
            Container(
                width: width * 0.90,
                height: height * 0.60,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(grocery_lbl_no_match_found, style: boldTextStyle(size: textSizeNormal.toInt(), color: grocery_lightGrey)),
                  ],
                )
            ) :
            ListView.builder(
              scrollDirection: Axis.vertical,
              itemCount: customers.length,
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                return CustomerWidget(customers[index], index);
              },
            ),
          ],
        ),
      ),
    ).paddingOnly(top: spacing_standard_new);
  }
}