import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:orbiterplus/model/model.dart';
import 'package:orbiterplus/orbiterPOS/model/AppModel.dart';
import 'package:orbiterplus/orbiterPOS/utils/AppStrings.dart';
import 'package:orbiterplus/orbiterPOS/utils/AppColors.dart';
import 'package:orbiterplus/orbiterPOS/utils/AppConstant.dart';
import 'package:orbiterplus/orbiterPOS/utils/AppNumbers.dart';
import 'package:orbiterplus/main.dart';
import 'package:orbiterplus/main/utils/AppWidget.dart';
import 'package:provider/provider.dart';

import '../utils/AppDataGenerator.dart';
import '../utils/OrbiterHelpers.dart';
import 'Dashboard.dart';

class AppCheckOut extends StatefulWidget {
  static String tag = '/GroceryCheckOut';
  final OrbiterHelper orbiter;

  const AppCheckOut(this.orbiter);

  @override
  AppCheckOutState createState() => AppCheckOutState();
}

class AppCheckOutState extends State<AppCheckOut> {
  late ShoppingCartModel shoppingCart;
  List<Sale> actualSales = [];
  List<Sale> suspendedSales = [];
  List<Customer> customers = [];

  late FocusNode focusNode;
  var selectedCustomer;
  late PaymentMethod paymentMethod;
  late PaymentMethod otherPaymentMethod;
  late TextEditingController customerController;
  late double amountReceived;

  late GlobalKey<FormState> _formKey;
  late int business_id;



  @override
  void initState() {
    super.initState();
    if (widget.orbiter.LoggedInUser != null){
      business_id = (widget.orbiter.LoggedInUser!.business_id?? -1);
    }
    shoppingCart = Provider.of<ShoppingCartModel>(context, listen: false);
    changeStatusColor(appStore.isDarkModeOn ? scaffoldDarkColor : white);

    (() async => suspendedSales = (await Sale().select().business_id.equals(business_id).and.status.equals('draft').toList(preload: true).whenComplete(() => setState(() => null)))).call();
    (() async => actualSales = (await Sale().select().business_id.equals(business_id).and.status.equals('final').toList(preload: true).whenComplete(() => setState(() => null)))).call();
    (() async => customers = (await Customer().select().business_id.equals(business_id).toList())).call();

    focusNode  = FocusNode();
    paymentMethod = PaymentMethod.Cash;
    otherPaymentMethod = PaymentMethod.Other;
    amountReceived = 0.00;

    _formKey = GlobalKey<FormState>();
  }

  @override
  void dispose() {
    // Clean up the focus node when the Form is disposed.
    focusNode.dispose();
    //customerController.dispose();
    super.dispose();
    changeStatusColor(app_colorPrimary);
  }

  @override
  Widget build(BuildContext context) {
    var width = MediaQuery.of(context).size.width;
    var height = MediaQuery.of(context).size.height;
    var textScale = width < max_width? text_scale_factor : MediaQuery.of(context).textScaleFactor;
    width = width <= max_width? width : max_width; //restrict width to the specified maximum

    double balCash = 0.0;

    customerController = TextEditingController(text: (selectedCustomer != null? selectedCustomer.name : grocery_checkout_walkin_customer));

    void finalizeSale() {

      Notify.showLoading();

      Sale sale = Sale();
      sale.business_id = business_id;
      sale.dateAdded = DateTime.now().toUtc();
      sale.status = 'final';
      sale.paymentMethod = paymentMethod.name;
      if (paymentMethod.name == 'Cash'){
        sale.changeGiven = balCash;
      }
      else{
        sale.changeGiven = 0.0;
      }

      sale.amountReceived = amountReceived;

      if (selectedCustomer != null) {
        sale.customerId = selectedCustomer.id;
      }
      else{
        (() async{
          Customer().select().business_id.equals(business_id).and.name.equals('Walk-In Customer').top(1).toSingle().then((it) {
            if (it != null){
              sale.customerId = it!.id;
            }
            else{
              sale.customerId = null;
            }
          });
        }).call();
      }

      sale.totalAmount = shoppingCart.Total;
      sale.taxId = widget.orbiter.LoggedInUser!.tax1_id;
      sale.discount = shoppingCart.Discount;
      sale.taxLabel =  shoppingCart.sTaxLabel;
      sale.discountLabel = shoppingCart.sDiscountLabel;
      sale.amountBeforeTax = shoppingCart.Amount;
      sale.taxAmount = shoppingCart.Tax;

      try{

        shoppingCart.items.toList().forEach((element) {
          if (widget.orbiter.validateProductQuantity(element.plProduct!, element.quantity) != true){
            return;
          }
        });

        () async {
          (await sale.save()
          .then((sale_id) {
            sale.id = sale_id;
            shoppingCart.items.toList().forEach((element) {
              Sale_item si = Sale_item();
              si.saleId = sale_id;
              si.productId = element.productId;
              si.quantity = element.quantity;
              if (element.plProduct!.product_type == "variable"){
                si.variationId = element.variationId;
              }
              (() async => await si.save().then((obj) async{
                //Update the quantities
                (await Sale_item().select().saleId.equals(sale_id).toList(preload: true, loadParents: true)).forEach((item) async {
                  if (item != null){
                    if (item.plVariation != null){
                      Variation v = item.plVariation!;
                      v.stock = ((v.stock?? 0.0) - item.quantity!);
                      await v.save();
                    }
                    else if (item.plProduct != null){
                      Product p = item.plProduct!;
                      p.stock = ((p.stock?? 0.0) - item.quantity!);
                      await p.save();
                    }
                  }
                });
              })).call();
            });
          })
          .whenComplete(() {
            shoppingCart.removeAll();
            (() async {
              try{
                await widget.orbiter.printReceipt(sale);
              }
              catch (e, s){
                print(s.toString());
              }
            }).call();

            (() async {
              try{
                await syncSales(widget.orbiter);
              }
              catch (e, s){
                print(s.toString());
              }
              finally{
                Notify.hideLoading();
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (BuildContext context) => GroceryDashBoardScreen(widget.orbiter),
                  ),
                  (Route route) => false,
                );
              }
            }).call();
          }));
        }.call();
      }
      catch (e, s){
        print(s.toString());
      }
    }

    void suspendSale() {
      Sale sale = Sale();
      sale.business_id = business_id;
      //sale.dateAdded = DateTime.now();
      sale.status = 'draft';
      //sale.paymentMethod = paymentMethod.text;
      //sale.amountReceived = amountReceived;
      //sale.changeGiven = balLeft;
      /*if (selectedCustomer != null)
        sale.customerId = selectedCustomer.id;*/
      sale.totalAmount = shoppingCart.Total;
      //sale.taxId = shoppingCart.Tax.id;
      sale.discount = shoppingCart.Discount;
      sale.taxLabel =  shoppingCart.sTaxLabel;
      sale.discountLabel = shoppingCart.sDiscountLabel;
      List<Sale_item> sale_items = [];
      shoppingCart.items.forEach((element) {
        Sale_item si = Sale_item();
        si.productId = element.productId;
        si.quantity = element.quantity;
        if (element.plProduct!.product_type == "variable"){
          si.variationId = element.variationId;
        }

        sale_items.add(si);
      });

      try{
        //actualSales.add(sale);
        sale.save().then((it) {
          sale_items.forEach((si) {
            si.saleId = it;
            si.save();
          });
        });
        shoppingCart.removeAll();
      }
      catch (e, s){
        print(s.toString());
      }
      finally{
        //Navigator.of(context).popAndPushNamed('/DashBoardScreen', arguments: widget.orbiter);
        //Navigator.of(context).pop();
        //Navigator.of(context).pushNamed('/DashBoardScreen', arguments: widget.orbiter);
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (BuildContext context) => GroceryDashBoardScreen(widget.orbiter),
          ),
              (Route route) => false,
        );
      }
    }

    Future<Customer?> createCustomer() async {
      Customer? model;
      TextEditingController prefix = TextEditingController(), firstname = TextEditingController(),
          middleName = TextEditingController(), surname = TextEditingController(),
          phone = TextEditingController(), mobile = TextEditingController(), address = TextEditingController();

      showDialog<void>(context: context, barrierDismissible: false, builder: (BuildContext ctx) =>
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
                    child:  Align(alignment: Alignment.centerLeft,
                      child: Text(grocery_customer_form_title, maxLines: 1, softWrap: false, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: textSizeNormal), textScaleFactor: textScale),),
                  ),
                  /*Align(alignment: Alignment.centerRight,
                  child:
                  TextButton.icon(onPressed: ()=> Navigator.pop(ctx),
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
                  TextButton(child:Text(grocery_customer_cancel_button, style: TextStyle(color: grocery_darkGrey, fontSize: textSizeNormal, fontFamily: fontSemiBold), textScaleFactor: textScale,),onPressed: (){
                    setState((){
                      Navigator.pop(ctx);
                    });
                  },),
                  Padding(padding: EdgeInsets.all(spacing_standard_new)),
                  TextButton(child:Text(grocery_customer_save_button, style: TextStyle(color: grocery_colorPrimary_light, fontSize: textSizeNormal, fontFamily: fontSemiBold), textScaleFactor: textScale,),onPressed: (){
                    if (_formKey.currentState!.validate()) {
                      var customer = Customer();
                      //customer.id = item['id'];
                      customer.prefix = prefix.value.text;
                      customer.firstname = firstname.value.text;
                      customer.middleName = middleName.value.text;
                      customer.surname = surname.value.text;
                      customer.business_id = business_id;
                      customer.name = firstname.value.text + " " + middleName.value.text + " " + surname.value.text;
                      customer.phone = phone.value.text;
                      customer.mobile = mobile.value.text;
                      customer.addressLine1 = address.value.text;
                      customer.shippingAddress = address.value.text;
                      customer.status = 'active';
                      customer.isSynced = false;
                      customer.dateAdded = DateTime.now().toUtc();

                    Navigator.pop(ctx);

                      (() async => (await customer.upsert())).call();

                      setState(() {
                        selectedCustomer = customer;
                      });
                      Notify.toast(message: "Customer Added Successfully", type: MessageType.Success);
                    }
                  },),
                ],
              )
            ],
          )
      );
      return model;
    }


    Future<Customer?> cashPayment() async {
      Customer? model;
      TextEditingController amount = TextEditingController();
      GlobalKey<FormState> amountForm = GlobalKey<FormState>();

      showDialog<void>(context: context, barrierDismissible: false, builder: (BuildContext ctx) =>
          AlertDialog(
            titlePadding: EdgeInsets.all(spacing_standard_new),
            contentPadding: EdgeInsets.only(top: spacing_standard_new, left: spacing_standard_new, right: spacing_standard_new),
            //actionsPadding: EdgeInsets.all(spacing_control),
            actionsAlignment: MainAxisAlignment.spaceAround,
            backgroundColor: context.cardColor,
            shape: RoundedRectangleBorder(
                borderRadius:
                BorderRadius.all(Radius.circular(15.0))),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(
                  width: (width * 0.55),
                  child: Align(alignment: Alignment.centerLeft,
                    child: Text(grocery_checkout_cash_payment_title, maxLines: 1, softWrap: false, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: textSizeNormal), textScaleFactor: textScale),),
                ),
              ],
            ),
            content: IntrinsicHeight(
              child: SingleChildScrollView(
                child: Form(
                key: amountForm,
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /***Total Payable Amount***/
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Column(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(grocery_checkout_total_payable_label, style: TextStyle(fontSize: textSizeMedium), textScaleFactor: textScale),
                            spacing_standard_new.toInt().height,
                            Text("${currency.format(shoppingCart.Total)}", style: boldTextStyle(fontFamily: fontBold, size: textSizeMedium.toInt()), textScaleFactor: textScale),
                          ],
                        ),
                      ],
                    ),
                    /***Cash Collected***/
                    Padding(padding: EdgeInsets.all(spacing_standard)),
                    StatefulBuilder(builder: (newContext, newState){
                      return Column(
                          children: <Widget>[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Expanded(
                                  flex: 10,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.max,
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(grocery_checkout_cash_collected_label, style: TextStyle(fontSize: textSizeMedium), textScaleFactor: textScale),
                                      spacing_standard_new.toInt().height,
                                      TextFormField(
                                        controller: amount,
                                        autofocus: true,
                                        textInputAction: TextInputAction.done,
                                        style: primaryTextStyle(fontFamily: fontMedium, size: textSizeMedium.toInt()),
                                        decoration: InputDecoration(
                                          hintStyle: TextStyle(color: grocery_lightGrey),
                                          hintText: grocery_checkout_cash_collected_hint,
                                          filled: true,
                                          fillColor: grocery_icon_purple_bg,
                                          contentPadding: EdgeInsets.all(spacing_standard),
                                          border: InputBorder.none,
                                          prefix: Text("NGN", style: primaryTextStyle(color: grocery_darkGrey, fontFamily: fontMedium, size: textSizeMedium.toInt()), textScaleFactor: textScale).paddingRight(spacing_standard),
                                        ),
                                        maxLength: 50,
                                        keyboardType: TextInputType.number,
                                        textAlign: TextAlign.left,
                                        autovalidateMode: AutovalidateMode.onUserInteraction,
                                        inputFormatters: [ NumericTextFormatter()],
                                        validator: (val){
                                          if(!(val!.replaceAll(',','').isDigit())){
                                            return '$grocery_checkout_cash_collected_label $grocery_validation_invalid_text';
                                          }
                                          return null;
                                        },
                                        onFieldSubmitted: (val){
                                          if (amountForm.currentState!.validate()) {
                                            setState(() {
                                              finalizeSale();
                                            });
                                          }
                                        },
                                        onChanged: (val){
                                          newState((){
                                            amountReceived = double.parse(val.replaceAll(',',''));
                                            double balance = (amountReceived - shoppingCart.Total);
                                            balCash = (balance != null? balance : 0.00);
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            Divider(
                              indent: 10.0,
                              endIndent: 10.0,
                              thickness: 1,
                            ),
                            /***Change To Return***/
                            Row(
                              mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(grocery_checkout_change_label, style: TextStyle(fontSize: textSizeMedium), textScaleFactor: textScale),
                                spacing_standard_new.toInt().width,
                                Text("${currency.format(balCash)}", style: boldTextStyle(fontFamily: fontBold, size: textSizeMedium.toInt()), textScaleFactor: textScale),
                              ],
                            ),
                          ]
                      );
                    }),
                    Padding(padding: EdgeInsets.all(spacing_control)),
                  ],
                ),
              ),),
            ),
            actions: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  TextButton(child:Text(grocery_customer_cancel_button, style: TextStyle(color: grocery_darkGrey, fontSize: textSizeNormal, fontFamily: fontSemiBold), textScaleFactor: textScale,),onPressed: (){
                    setState((){
                      Navigator.pop(ctx);
                    });
                  },),
                  Padding(padding: EdgeInsets.all(spacing_standard)),
                  TextButton(child:Text(grocery_checkout_button_label, style: TextStyle(color: grocery_colorPrimary_light, fontSize: textSizeNormal, fontFamily: fontSemiBold), textScaleFactor: textScale,),onPressed: (){
                    if (amountForm.currentState!.validate()) {
                      setState(() {
                        finalizeSale();
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

    Future<Customer?> splitPayment() async {
      Customer? model;
      TextEditingController amount = TextEditingController();
      GlobalKey<FormState> amountForm = GlobalKey<FormState>();

      showDialog<void>(context: context, barrierDismissible: false, builder: (BuildContext ctx) =>
          AlertDialog(
            titlePadding: EdgeInsets.all(spacing_standard_new),
            contentPadding: EdgeInsets.only(top: spacing_standard_new, left: spacing_standard_new, right: spacing_standard_new),
            //actionsPadding: EdgeInsets.all(spacing_control),
            actionsAlignment: MainAxisAlignment.spaceAround,
            backgroundColor: context.cardColor,
            shape: RoundedRectangleBorder(
                borderRadius:
                BorderRadius.all(Radius.circular(15.0))),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(
                  width: (width * 0.55),
                  child: Align(alignment: Alignment.centerLeft,
                    child: Text(grocery_checkout_split_payment_title, maxLines: 1, softWrap: false, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: textSizeNormal), textScaleFactor: textScale),),
                ),
              ],
            ),
            content: IntrinsicHeight(
              child: SingleChildScrollView(
                child: Form(
                key: amountForm,
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /***Total Payable Amount***/
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Column(
                          mainAxisSize: MainAxisSize.max,
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(grocery_checkout_total_payable_label, style: TextStyle(fontSize: textSizeMedium), textScaleFactor: textScale),
                            spacing_standard_new.toInt().height,
                            Text("${currency.format(shoppingCart.Total)}", style: boldTextStyle(fontFamily: fontBold, size: textSizeMedium.toInt()), textScaleFactor: textScale),
                          ],
                        ),
                      ],
                    ),
                    /***Cash Collected***/
                    Padding(padding: EdgeInsets.all(spacing_control)),
                    StatefulBuilder(builder: (newContext, newState){
                      return Column(
                          children: <Widget>[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Expanded(
                                  flex: 10,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(grocery_checkout_cash_collected_label, style: TextStyle(fontSize: textSizeMedium), textScaleFactor: textScale),
                                      spacing_standard_new.toInt().height,
                                      TextFormField(
                                        controller: amount,
                                        autofocus: true,
                                        textInputAction: TextInputAction.done,
                                        style: primaryTextStyle(fontFamily: fontMedium, size: textSizeMedium.toInt()),
                                        decoration: InputDecoration(
                                          hintStyle: TextStyle(color: grocery_lightGrey),
                                          hintText: grocery_checkout_cash_collected_hint,
                                          filled: true,
                                          fillColor: grocery_icon_purple_bg,
                                          contentPadding: EdgeInsets.all(spacing_large),
                                          border: InputBorder.none,
                                          prefix: Text("NGN", style: primaryTextStyle(color: grocery_darkGrey, fontFamily: fontMedium, size: textSizeMedium.toInt()), textScaleFactor: textScale).paddingRight(spacing_standard_new),
                                        ),
                                        maxLength: 50,
                                        keyboardType: TextInputType.number,
                                        textAlign: TextAlign.left,
                                        autovalidateMode: AutovalidateMode.onUserInteraction,
                                        inputFormatters: [ NumericTextFormatter()],
                                        validator: (val){
                                          if(!(val!.replaceAll(',','').isDigit())){
                                            return '$grocery_checkout_cash_collected_label $grocery_validation_invalid_text';
                                          }
                                          return null;
                                        },
                                        onChanged: (val){
                                          newState((){
                                            amountReceived = double.parse(val.replaceAll(',',''));
                                            double balance = (shoppingCart.Total - amountReceived);
                                            balCash = (balance != null? balance : 0.00);
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            //Padding(padding: EdgeInsets.all(spacing_standard)),
                            Divider(
                              indent: 10.0,
                              endIndent: 10.0,
                              thickness: 1,
                            ),
                            /***Change To Return***/
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(grocery_checkout_balance_label, style: TextStyle(fontSize: textSizeMedium), textScaleFactor: textScale),
                                spacing_standard_new.toInt().width,
                                Text("${currency.format(balCash)}", style: boldTextStyle(fontFamily: fontBold, size: textSizeMedium.toInt()), textScaleFactor: textScale),
                              ],
                            ),
                          ]
                      );
                    }),
                   // Padding(padding: EdgeInsets.all(spacing_standard)),
                  ],
                ),
              ),),
            ),
            actions: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  TextButton(child:Text(grocery_customer_cancel_button, style: TextStyle(color: grocery_darkGrey, fontSize: textSizeNormal, fontFamily: fontSemiBold), textScaleFactor: textScale,),onPressed: (){
                    setState((){
                      paymentMethod = PaymentMethod.Other;
                      Navigator.pop(ctx);
                    });
                  },),
                  Padding(padding: EdgeInsets.all(spacing_standard)),
                  TextButton(child:Text(grocery_checkout_button_label, style: TextStyle(color: grocery_colorPrimary_light, fontSize: textSizeNormal, fontFamily: fontSemiBold), textScaleFactor: textScale,),onPressed: (){
                    if (amountForm.currentState!.validate()) {
                      //setState(() {
                        finalizeSale();
                      //});
                    }
                  },),
                ],
              )
            ],
          )
      );
      return model;
    }

    Future<Customer?> otherPayments() async {
      Customer? model;
      const tileColor = grocery_icon_purple_bg;
      const tileFontSize = textSizeXLarge;
      const tilePadding = spacing_large;
      const tileSpacing = spacing_standard_new;

      showDialog<void>(context: context, barrierDismissible: false, builder: (BuildContext ctx) =>
          AlertDialog(
            titlePadding: EdgeInsets.all(spacing_standard),
            contentPadding: EdgeInsets.only(left: spacing_standard, right: spacing_standard, bottom: spacing_standard),
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
                  //width: (width * 0.70),
                  child: Align(alignment: Alignment.centerLeft,
                    child: Text(grocery_checkout_other_payments_title, maxLines: 1, softWrap: true, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: textSizeNormal), textScaleFactor: textScale),),
                ),
              ],
            ),
            content: IntrinsicHeight(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListTile(
                        contentPadding: EdgeInsets.symmetric(horizontal: spacing_standard_new),
                        tileColor: tileColor,
                        shape: RoundedRectangleBorder(
                            borderRadius:
                            BorderRadius.all(Radius.circular(15.0))),
                        title: Text("${PaymentMethod.Transfer.text}", style: TextStyle(fontSize: textSizeMedium), textScaleFactor: textScale),
                        onTap: () => setState(() {
                          //otherPaymentMethod = PaymentMethod.Transfer;
                          paymentMethod = PaymentMethod.Transfer;
                          Navigator.pop(ctx);
                          finalizeSale();
                        })
                    ),
                    Padding(padding: EdgeInsets.all(spacing_control)),
                    ListTile(
                        contentPadding: EdgeInsets.symmetric(horizontal: spacing_standard_new),
                        tileColor: tileColor,
                        shape: RoundedRectangleBorder(
                            borderRadius:
                            BorderRadius.all(Radius.circular(20.0))),
                        title: Text("${PaymentMethod.Credit.text}", style: TextStyle(fontSize: textSizeMedium), textScaleFactor: textScale),
                        onTap: () => setState(() {
                          //otherPaymentMethod = PaymentMethod.Credit;
                          paymentMethod = PaymentMethod.Credit;
                          Navigator.pop(ctx);
                          finalizeSale();
                        })
                    ),
                    Padding(padding: EdgeInsets.all(spacing_control)),
                    ListTile(
                        contentPadding: EdgeInsets.symmetric(horizontal: spacing_standard_new),
                        tileColor: tileColor,
                        shape: RoundedRectangleBorder(
                            borderRadius:
                            BorderRadius.all(Radius.circular(15.0))),
                        title: Text("${PaymentMethod.Cheque.text}", style: TextStyle(fontSize: textSizeMedium), textScaleFactor: textScale),
                        onTap: () => setState(() {
                          //otherPaymentMethod = PaymentMethod.Cheque;
                          paymentMethod = PaymentMethod.Cheque;
                          Navigator.pop(ctx);
                          finalizeSale();
                        })
                    ),
                    Padding(padding: EdgeInsets.all(spacing_control)),
                    ListTile(
                        contentPadding: EdgeInsets.symmetric(horizontal: spacing_standard_new),
                        tileColor: tileColor,
                        shape: RoundedRectangleBorder(
                            borderRadius:
                            BorderRadius.all(Radius.circular(15.0))),
                        title: Text("${PaymentMethod.SplitCardCash.text}", style: TextStyle(fontSize: textSizeMedium), textScaleFactor: textScale),
                        onTap: () => setState(() {
                          //otherPaymentMethod = PaymentMethod.SplitCardCash;
                          paymentMethod = PaymentMethod.SplitCardCash;
                          Navigator.pop(ctx);
                          splitPayment();
                        })
                    ),
                    Padding(padding: EdgeInsets.all(spacing_control)),
                    ListTile(
                        contentPadding: EdgeInsets.symmetric(horizontal: spacing_standard_new),
                        tileColor: tileColor,
                        shape: RoundedRectangleBorder(
                            borderRadius:
                            BorderRadius.all(Radius.circular(15.0))),
                        title: Text("${PaymentMethod.SplitTransferCash.text}", style: TextStyle(fontSize: textSizeMedium), textScaleFactor: textScale),
                        onTap: () => setState(() {
                          //otherPaymentMethod = PaymentMethod.SplitTransferCash;
                          paymentMethod = PaymentMethod.SplitTransferCash;
                          Navigator.pop(ctx);
                          splitPayment();
                        })
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
                  TextButton(child:Text(grocery_customer_cancel_button, style: TextStyle(color: grocery_darkGrey, fontSize: textSizeNormal, fontFamily: fontRegular), textScaleFactor: textScale,),onPressed: (){
                    setState((){
                      Navigator.pop(ctx);
                    });
                  },),
                ],
              )
            ],
          )
      );
      return model;
    }

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: Padding(padding: EdgeInsets.only(left: spacing_standard_new,), child: Text(grocery_checkout_title_label, style: TextStyle(color: blackColor, fontSize: textSizeMedium), textScaleFactor: textScale)),
          elevation: 0.0,
          scrolledUnderElevation: 5.0,
          /*actions: [
            Padding(padding: EdgeInsets.only(right: spacing_xxLarge, ),
                child:TextButton.icon(
                  onPressed: (){
                    setState((){});
                  },
                  label: Text(grocery_checkout_customer_button_label, style: TextStyle(fontSize: textSizeLarge, color: grocery_Color_black, )),
                  icon: Icon(Icons.search, size: textSizeLarge, color: grocery_Color_black,),
                ).visible(shoppingCart.isNotEmpty)
            )
          ],*/
        ),
        body: SingleChildScrollView(
          child:Column(
          children: [
            Container(
              child: Column(
                children: [
                  Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Align(alignment: Alignment.topCenter, child:
                    Container(
                      width: width * 0.85,
                      child:
                      Column( children:
                      [
                        Container(
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: grocery_lightGrey, width: 2)
                          ),
                          padding: const EdgeInsets.all(spacing_control),
                          margin: const EdgeInsets.all(spacing_control),
                          child: IntrinsicHeight( child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: <Widget>[
                                Expanded(flex: 8,
                                  child:
                                  TypeAheadField(
                                    minCharsForSuggestions: 2,
                                    hideOnEmpty: true,
                                    textFieldConfiguration: TextFieldConfiguration(
                                      autofocus: false,
                                      focusNode: focusNode,
                                      onTap: () async {
                                        await Future.delayed(const Duration(milliseconds: 300)).then((_){
                                          FocusScope.of(context).unfocus();
                                          FocusScope.of(context).requestFocus(focusNode);
                                          customerController.selectAll();
                                        });
                                      },
                                      controller: customerController,
                                      textInputAction: TextInputAction.none,
                                      style: primaryTextStyle(color: grocery_textColorPrimary, fontFamily: fontRegular, size: textSizeSMedium.toInt()),
                                      decoration: InputDecoration(
                                        contentPadding: EdgeInsets.symmetric(horizontal: spacing_standard),
                                        constraints: BoxConstraints(maxWidth: width * 0.95),
                                        //prefixIcon: const Icon(Icons.search, color: grocery_lightGrey, size: textSizeLarge),
                                        border: InputBorder.none,
                                        hintStyle: primaryTextStyle(color: grocery_lightGrey, size: textSizeMedium.toInt()),
                                        hintText: grocery_checkout_customer_hint,
                                        label: Text(grocery_checkout_customer_label, textScaleFactor: textScale),
                                        suffix: GestureDetector(
                                            onTap: () {
                                              selectedCustomer = null;
                                              customerController.clear();
                                              focusNode.requestFocus();
                                              customerController.selectAll();
                                            },
                                            child: Icon(Icons.cancel_rounded, size: textSizeXLarge)
                                        ).visible((customerController.text != grocery_checkout_walkin_customer && customerController.text.isNotEmpty)),
                                      ),
                                      keyboardType: TextInputType.text,
                                      textAlign: TextAlign.start,
                                    ),
                                    suggestionsCallback: (pattern) async {
                                      String lower_pattern = pattern.toLowerCase();

                                      if (!lower_pattern.isEmptyOrNull && lower_pattern != grocery_checkout_walkin_customer){
                                        return customers.where((e) => ((e.firstname != null && e.firstname!.toLowerCase().startsWith(lower_pattern)) || (e.middleName != null && e.middleName!.toLowerCase().startsWith(lower_pattern)) || (e.surname != null && e.surname!.toLowerCase().startsWith(lower_pattern))));
                                      }
                                      else{
                                        return [];
                                      }
                                    },
                                    itemBuilder: <BuildContext, Customer>(context, customer) {
                                      return ListTile(
                                        key: UniqueKey(),
                                        leading: Icon(Icons.person),
                                        title: Text(customer.name, textScaleFactor: textScale, softWrap: false),
                                        subtitle: Text('${customer.addressLine1?? ''}', textScaleFactor: textScale),
                                      );
                                    },
                                    onSuggestionSelected: (suggestion) {
                                      selectedCustomer = (suggestion as Customer);
                                    },
                                  )
                                  ,
                                ),
                                Expanded(flex: 1, child: VerticalDivider(
                                  color: grocery_light_gray_color,
                                  thickness: 3,
                                ),),//Text("|", style: primaryTextStyle(color: grocery_light_gray_color, fontFamily: fontRegular, size: textSizeXXLarge.toInt()),).paddingLeft(width * 0.08),),
                                Expanded(flex: 1, child: IconButton(padding: EdgeInsets.only(right: spacing_standard_new), icon: const Icon(Icons.person_add_alt_rounded),  color: grocery_textColorPrimary, iconSize: textSizeLarge, onPressed:  (){
                                  setState(() {
                                    (() async => await createCustomer()).call();
                                  });
                                  },)
                                ),
                              ]
                          ),),
                        ),
                        Container(
                          padding: const EdgeInsets.all(spacing_control),
                          margin: const EdgeInsets.only(left: spacing_control, right: spacing_control),
                          child: StatefulBuilder(
                              builder: (context, setState) {
                                return Column(
                                  mainAxisSize: MainAxisSize.max,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(grocery_checkout_payments_label, style: TextStyle(fontSize: textSizeNormal), textScaleFactor: textScale),
                                    spacing_standard.toInt().height,
                                    RadioListTile<PaymentMethod>(
                                      contentPadding: EdgeInsets.symmetric(horizontal: spacing_standard),
                                      tileColor: grocery_icon_purple_bg,
                                      selectedTileColor: grocery_icon_purple,
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                          BorderRadius.all(Radius.circular(15.0))),
                                      controlAffinity: ListTileControlAffinity.trailing,
                                      title: Row( children: [Icon(Icons.payments_outlined, color: grocery_icon_green_dark, size: textSizeMedium).rotate(angle: 75), spacing_standard_new.toInt().width,
                                        Text("${PaymentMethod.Cash.name}", style: TextStyle(fontSize: textSizeMedium), textScaleFactor: textScale)]),
                                      value: PaymentMethod.Cash,
                                      groupValue: paymentMethod,
                                      onChanged: (val) {
                                        setState(() {
                                          paymentMethod = val!;
                                          otherPaymentMethod = PaymentMethod.Other;
                                          //otherPayments.call();
                                        });
                                      }
                                    ),
                                    spacing_standard.toInt().height,
                                    RadioListTile<PaymentMethod>(
                                        contentPadding: EdgeInsets.symmetric(horizontal: spacing_standard),
                                      tileColor: grocery_icon_purple_bg,
                                      selectedTileColor: grocery_icon_purple,
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                          BorderRadius.all(Radius.circular(15.0))),
                                      controlAffinity: ListTileControlAffinity.trailing,
                                      title: Row( children: [Icon(Icons.payment_rounded, color: grocery_DarkBlue_Color, size: textSizeMedium), spacing_standard_new.toInt().width,
                                        Text("${PaymentMethod.Card.name}", style: TextStyle(fontSize: textSizeMedium), textScaleFactor: textScale)]),
                                      value: PaymentMethod.Card,
                                      groupValue: paymentMethod,
                                        onChanged: (val) {
                                          setState(() {
                                            paymentMethod = val!;
                                            otherPaymentMethod = PaymentMethod.Other;
                                          });
                                        }
                                    ),
                                    spacing_standard.toInt().height,
                                    RadioListTile<PaymentMethod>(
                                        contentPadding: EdgeInsets.symmetric(horizontal: spacing_standard),
                                      tileColor: grocery_icon_purple_bg,
                                      selectedTileColor: grocery_icon_purple,
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                          BorderRadius.all(Radius.circular(15.0))),
                                      controlAffinity: ListTileControlAffinity.trailing,
                                      title: Row( children: [Icon(Icons.check_box_outlined, color: grocery_color_red, size: textSizeNormal), spacing_standard_new.toInt().width,
                                        Text("${PaymentMethod.Other.name}", style: TextStyle(fontSize: textSizeMedium), textScaleFactor: textScale)]),
                                      value: PaymentMethod.Other,
                                      groupValue: paymentMethod,
                                      onChanged: (val) {
                                        setState(() {
                                          paymentMethod = val!;
                                        });
                                      }
                                    ),
                                    //spacing_standard.toInt().height,
                                    Divider(
                                      indent: 20.0,
                                      endIndent: 10.0,
                                      thickness: 1,
                                    ),
                                    10.height,
                                    Text("$grocery_selected_payment_method_label ${(paymentMethod != PaymentMethod.Other? paymentMethod.text : otherPaymentMethod.text)}", style: TextStyle(fontSize: textSizeNormal), textScaleFactor: textScale),

                                  ],
                                );
                              }),
                        )
                      ])
                      ,
                    ),
                    ),
                  ],
                ),
                ]
              ),
            ),
          ]
        ),),
        bottomNavigationBar: BottomAppBar(
          child:
          IntrinsicHeight(
            child: Align(
              alignment: Alignment.topCenter,
              child: Container(
                width: width * 0.99,
                height: height * 0.35,
                padding: EdgeInsets.all(spacing_standard),
                child: Column(
                      children: [
                        Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child:Column(
                                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.start,
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                          Text("$grocery_checkout_subtotal_label", style: secondaryTextStyle(color: (shoppingCart.isNotEmpty? grocery_darkGrey : grocery_lightGrey), size: textSizeSMedium.toInt()), textScaleFactor: textScale),
                                          spacing_standard.toInt().width,
                                          Text("${currency.format(shoppingCart.SubTotal)} (${shoppingCart.Count} $grocery_checkout_count_label)", style: secondaryTextStyle(color: (shoppingCart.isNotEmpty? grocery_darkGrey : grocery_lightGrey), fontFamily: fontRegular, size: textSizeMedium.toInt()), textScaleFactor: textScale),
                                        ],
                                      ),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.start,
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                          Text("$grocery_lbl_tax ${shoppingCart.sTaxLabel}:", style: secondaryTextStyle(color: (shoppingCart.isNotEmpty? grocery_darkGrey : grocery_lightGrey), size: textSizeMedium.toInt()), textScaleFactor: textScale),
                                          spacing_standard.toInt().width,
                                          Text("${currency.format(shoppingCart.Tax)}", style: secondaryTextStyle(color: (shoppingCart.isNotEmpty? grocery_darkGrey : grocery_lightGrey), fontFamily: fontRegular, size: textSizeMedium.toInt()), textScaleFactor: textScale),
                                        ],
                                      ),
                                      Row(//Discount Starts Here
                                        mainAxisAlignment: MainAxisAlignment.start,
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        children: [
                                          Text("$grocery_lbl_discount ${shoppingCart.sDiscountLabel}:", style: secondaryTextStyle(color: (shoppingCart.isNotEmpty? grocery_darkGrey : grocery_lightGrey), size: textSizeMedium.toInt()), textScaleFactor: textScale),
                                          spacing_standard.toInt().width,
                                          Text("${currency.format(shoppingCart.Discount)}", style: secondaryTextStyle(color: (shoppingCart.isNotEmpty? grocery_darkGrey : grocery_lightGrey), fontFamily: fontRegular, size: textSizeMedium.toInt()), textScaleFactor: textScale),
                                        ],
                                      ),
                                    ]
                                ),
                              ),
                              SizedBox(
                                height: height * 0.11,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text("$grocery_checkout_total_label", style: boldTextStyle(color: (shoppingCart.isNotEmpty? grocery_darkGrey : grocery_lightGrey), fontFamily: fontBold, size: textSizeMedium.toInt()), textScaleFactor: textScale),
                                    spacing_standard.toInt().height,
                                    Text("${currency.format(shoppingCart.Total)}", style: boldTextStyle(color: (shoppingCart.isNotEmpty? grocery_Color_black : grocery_lightGrey), fontFamily: fontBold, size: textSizeNormal.toInt()), textScaleFactor: textScale),
                                  ],
                                ),
                              ),
                            ]),
                        Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children:[
                              10.height,
                              Divider(
                                indent: 20.0,
                                endIndent: 10.0,
                                thickness: 1,
                              ),
                              10.height,
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  Expanded(child: AppButton(
                                    //color: ,
                                    elevation: 4.0,
                                    disabledColor: grocery_disabled_button_color,
                                    enabled: shoppingCart.isNotEmpty,
                                    child: Text(grocery_suspend_button_label, style: boldTextStyle(color: (shoppingCart.isNotEmpty? grocery_color_red : grocery_darkGrey) , size: textSizeNormal.toInt()), textScaleFactor: textScale),
                                    shapeBorder: RoundedRectangleBorder(
                                        side: BorderSide(color: grocery_color_red),
                                        borderRadius:
                                        BorderRadius.all(Radius.circular(8.0))),
                                    onTap: () {
                                      setState((){
                                        /*suspendedSales.add(SaleModel("${Random(1234567801).nextInt(1334567810)}",
                                            "",DateTime.now(), shoppingCart.items.toList(), status: SaleStatus.suspended));
                                        shoppingCart.removeAll();
                                        //shoppingCart.notifyListeners();
                                        //Navigator.of(context).popUntil((r) => r.isFirst);
                                        Navigator.of(context).popAndPushNamed('/DashBoardScreen', arguments: widget.orbiter);*/

                                        suspendSale();

                                        Notify.toast(message: grocery_suspend_successful, type: MessageType.Success);
                                      });
                                    },
                                    padding: EdgeInsets.symmetric(horizontal: (width * 0.02), vertical: spacing_standard_new),
                                    margin: EdgeInsets.all(spacing_control),
                                  )),
                                  Expanded(child: AppButton(
                                    color: app_colorPrimary,
                                    elevation: 4.0,
                                    disabledColor: grocery_disabled_button_color,
                                    enabled: shoppingCart.isNotEmpty,
                                    child: Text(grocery_checkout_button_label, style: boldTextStyle(color: (shoppingCart.isNotEmpty? white : grocery_darkGrey) , size: textSizeNormal.toInt()), textScaleFactor: textScale),
                                    shapeBorder: RoundedRectangleBorder(
                                        borderRadius:
                                        BorderRadius.all(Radius.circular(8.0))),
                                    onTap: () {
                                      if (paymentMethod == PaymentMethod.Other && otherPaymentMethod == PaymentMethod.Other){
                                        otherPayments.call();
                                      }
                                      else if (otherPaymentMethod == PaymentMethod.SplitCardCash || otherPaymentMethod == PaymentMethod.SplitTransferCash){
                                        //Show the split payment popup
                                        splitPayment.call();
                                      }
                                      else if (paymentMethod == PaymentMethod.Cash){
                                        //Show the cash payment popup
                                        cashPayment.call();
                                      }
                                      else{
                                        setState(() {
                                          finalizeSale();
                                        });
                                      }
                                    },
                                    padding: EdgeInsets.symmetric(horizontal: (width * 0.02), vertical: spacing_standard_new),
                                    margin: EdgeInsets.all(spacing_control),
                                  )),
                                ],
                              ),
                              Padding(padding: EdgeInsets.only(bottom: spacing_standard))
                            ]),
                      ]
                  )
              ),
            ),
          ),
        ),
      ),
    );
  }
}
