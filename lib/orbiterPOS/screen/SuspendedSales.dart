import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:orbiterplus/orbiterPOS/model/AppModel.dart';
import 'package:orbiterplus/orbiterPOS/screen/ShoppingCart.dart';
import 'package:orbiterplus/orbiterPOS/utils/AppStrings.dart';
import 'package:orbiterplus/orbiterPOS/utils/AppColors.dart';
import 'package:orbiterplus/orbiterPOS/utils/AppConstant.dart';
import 'package:orbiterplus/orbiterPOS/utils/OrbiterHelpers.dart';
import 'package:provider/provider.dart';

import '../../model/model.dart';

class SuspendedSales extends StatefulWidget {
  final OrbiterHelper orbiter;

  const SuspendedSales(this.orbiter);

  @override
  SuspendedSalesState createState() => SuspendedSalesState();
}

class SuspendedSalesState extends State<SuspendedSales> {
  late bool deleting;
  List<Sale> suspendedSales = [];
  //late List<Customer> customers;
  int business_id = -1;

  String empty_string = "Loading...";

  @override
  void initState() {
    super.initState();
    if (widget.orbiter.LoggedInUser != null){
      business_id = (widget.orbiter.LoggedInUser!.business_id?? -1);
    }
    //(() async => customers = (await Customer().select().business_id.equals(business_id).toList())).call();
    //shoppingCart = Provider.of<ShoppingCartModel>(context, listen: false);

    deleting = false;
  }

  /*bool isDisposed = false;
  @override
  void dispose() {
    super.dispose();
    isDisposed = true;
  }*/

  @override
  Widget build(BuildContext context) {
    var width = MediaQuery.of(context).size.width;
    var height = MediaQuery.of(context).size.height;
    var textScale = width < max_width? text_scale_factor : MediaQuery.of(context).textScaleFactor;
    width = width <= max_width? width : max_width; //restrict width to the specified maximum

    if (deleting == false){
      (() async => suspendedSales = (await Sale().select().business_id.equals(business_id).and.status.equals('draft').toList(preload: true).whenComplete(() => setState(() => empty_string = (suspendedSales.length <=0? grocery_empty_sales_label: "" ))))).call();
    }

    List<int> selectedIndexes = [];

    void suspendSale() {
      Sale sale = Sale();
      sale.business_id = business_id;
      //sale.dateAdded = DateTime.now();
      sale.status = 'draft';
      //sale.paymentMethod = paymentMethod.text;
      //sale.amountReceived = amountReceived;
      //sale.changeGiven = changeLeft;
      /*if (selectedCustomer != null)
        sale.customerId = selectedCustomer.id;*/
      sale.totalAmount = Provider.of<ShoppingCartModel>(context, listen: false).Total;
      //sale.taxId = shoppingCart.Tax.id;
      sale.discount = Provider.of<ShoppingCartModel>(context, listen: false).Discount;
      sale.taxLabel =  Provider.of<ShoppingCartModel>(context, listen: false).sTaxLabel;
      sale.discountLabel = Provider.of<ShoppingCartModel>(context, listen: false).sDiscountLabel;
      List<Sale_item> sale_items = [];
      Provider.of<ShoppingCartModel>(context, listen: false).items.forEach((element) {
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
        Provider.of<ShoppingCartModel>(context, listen: false).removeAll();
      }
      catch (e, s){
        print(s.toString());
      }
    }

    Future confirmDelete(BuildContext ctx, Sale model) async {
      WidgetsBinding?.instance?.addPostFrameCallback((_) {
        showDialog<void>(context: ctx, barrierDismissible: true, builder: (BuildContext builder) =>
            AlertDialog(
              titlePadding: EdgeInsets.all(spacing_large),
              contentPadding: EdgeInsets.all(spacing_large),
              actionsPadding: EdgeInsets.all(spacing_large),
              actionsAlignment: MainAxisAlignment.center,
              backgroundColor: context.cardColor,
              shape: RoundedRectangleBorder(
                  borderRadius:
                  BorderRadius.all(Radius.circular(15.0))),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SizedBox(
                    width: (width * 0.60),
                    child: Align(alignment: Alignment.centerLeft,
                      child: Text("${((!model.title.isEmptyOrNull)
                          ? "${model.title.toString()} (${model.unique_id})"
                          : "$orbiter_sale_ref  ${model.unique_id}")}", maxLines: 1, softWrap: false, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: textSizeNormal), textScaleFactor: textScale,),),
                  ),
                  Align(alignment: Alignment.centerRight, child: Icon(Icons.close, size: textSizeLarge).onTap((){Navigator.pop(context);}),),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                //crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(grocery_lbl_remove_confirmation, maxLines: 3, softWrap: true, overflow: TextOverflow.fade, style: primaryTextStyle(size: textSizeNormal.toInt()), textScaleFactor: textScale,),
                  //16.height,
                ],
              ),
              actions: [
                AppButton(
                  elevation: 4.0,
                  disabledColor: grocery_disabled_button_color,
                  shapeBorder: RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius.all(Radius.circular(15.0))),
                  padding: EdgeInsets.symmetric(horizontal: spacing_standard_new, vertical: spacing_standard_new),
                  child: Text("$grocery_lbl_remove_no".toUpperCase(), style: boldTextStyle(), textScaleFactor: textScale,),
                  onTap: () {
                    Navigator.pop(ctx);
                  },
                ),
                16.width,
                AppButton(
                  elevation: 4.0,
                  disabledColor: grocery_disabled_button_color,
                  shapeBorder: RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius.all(Radius.circular(15.0))),
                  padding: EdgeInsets.symmetric(horizontal: spacing_standard_new, vertical: spacing_standard_new),
                  color: grocery_Red_Color,
                  child: Text(grocery_lbl_remove_yes.toUpperCase(), style: boldTextStyle(color: Colors.white), textScaleFactor: textScale,),
                  onTap: () {
                    setState((){
                      (() async => await model.delete(true).then((value) => setState(() => null)).whenComplete(() {

                        Navigator.pop(ctx);
                        Notify.toast(
                            message: "Transaction Removed Successfully",
                            type: MessageType.Success);
                      })).call();
                    });
                  },
                ),
              ],
            )
        );
      });
    }

    Future<bool?> editSuspendedItem(BuildContext ctx, Sale model, int pos) async {
      String sTitle = suspendedSales[pos].title != null? suspendedSales[pos].title.toString() : "";

      TextEditingController titleController = TextEditingController(text: "$sTitle");
      WidgetsBinding?.instance?.addPostFrameCallback((_) {
        showDialog(context: ctx,
            barrierDismissible: false,
            builder: (BuildContext builder) =>
                AlertDialog(
                  titlePadding: EdgeInsets.all(spacing_standard_new),
                  contentPadding: EdgeInsets.only(left: spacing_standard,
                      right: spacing_standard,
                      bottom: spacing_standard),
                  actionsPadding: EdgeInsets.all(spacing_standard_new),
                  actionsAlignment: MainAxisAlignment.center,
                  backgroundColor: context.cardColor,
                  shape: RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius.all(Radius.circular(20.0))),
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SizedBox(
                        width: (width * 0.60),
                        child: Align(alignment: Alignment.center,
                          //child: Text("Updating ${model.id}", maxLines: 1, softWrap: false, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: textSizeLarge)),),
                          child: Text(
                            sale_specify_title, maxLines: 2,
                              softWrap: false,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: textSizeNormal), textScaleFactor: textScale,),),
                      ),
                      Align(alignment: Alignment.centerRight,
                        child: Icon(Icons.close, size: textSizeLarge).onTap(() {
                          Navigator.pop(builder);
                        }),),
                    ],
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          spacing_control.toInt().width,
                          Container(
                            padding: EdgeInsets.all(spacing_standard),
                            width: context.width() * 0.65,
                            decoration: boxDecorationWithShadow(
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(spacing_control),
                                topRight: Radius.circular(spacing_control),
                                bottomRight: Radius.circular(spacing_control),
                                bottomLeft: Radius.circular(spacing_control),
                              ),
                              boxShadow: defaultBoxShadow(),
                              backgroundColor: context.cardColor,
                            ),
                            child: TextFormField(
                              controller: titleController,
                              autofocus: false,
                              maxLength: 25,
                              textInputAction: TextInputAction.none,
                              style: primaryTextStyle(size: textSizeMedium.toInt()),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: grocery_icon_purple_bg,
                                contentPadding: EdgeInsets.all(spacing_control),
                                border: InputBorder.none,
                              ),
                              keyboardType: TextInputType.text,
                              textAlign: TextAlign.left,
                              onFieldSubmitted: (val) {
                                //setState((){
                                sTitle = val;
                                //});
                              },
                            ),
                          ),
                          spacing_control.toInt().width,
                        ],
                      ),
                      spacing_control.toInt().height,
                    ],
                  ),
                  actions: [
                    Center(
                      child: TextButton(child: Text(grocery_sort_by_action,
                        style: TextStyle(color: grocery_colorPrimary_light,
                            fontSize: textSizeNormal,
                            fontFamily: fontSemiBold),), onPressed: () {
                        model.title = titleController.text;
                        model.save();
                        //suspendedSales.notifyListeners();
                        Navigator.pop(builder);
                        Notify.toast(message: "Updated Successfully",
                            type: MessageType.Success);
                      },),
                    )
                  ],
                )
        );
      });
    }

    Widget SuspendedSale(Sale model, int index, ) {

      return Container(
        width: width * 0.95,
        padding: EdgeInsets.symmetric(
            horizontal: spacing_standard, vertical: spacing_standard),
        margin: EdgeInsets.all(spacing_standard),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              flex: 6,
              child: Column(
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.max,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(((!model.title.isEmptyOrNull)
                            ? model.title.toString()
                            : "$orbiter_sale_ref  ${model.unique_id}"),
                            style: primaryTextStyle(
                                size: textSizeMedium.toInt()), softWrap: true, textScaleFactor: textScale),
                        spacing_standard
                            .toInt()
                            .width,
                        Text("$orbiter_sale_ref ${model.unique_id}",
                            style: primaryTextStyle(
                                size: textSizeSMedium.toInt()), softWrap: true, textScaleFactor: textScale).visible(
                            !model.title.isEmptyOrNull),
                      ],),
                    spacing_middle
                        .toInt()
                        .height,
                    Row(children: [
                      Text("${model!.plSale_items!.length} ${(model.plSale_items!.length == 1? "Item" : "Items")}",
                          style: primaryTextStyle(
                              size: textSizeMedium.toInt()), textScaleFactor: textScale),
                      spacing_large
                          .toInt()
                          .width,
                      Text("${(model!.dateAdded != null? DateFormatter(model!.dateAdded!).longdate : "")}",
                          style: primaryTextStyle(
                              size: textSizeMedium.toInt(),
                              color: grocery_darkGrey),textScaleFactor: textScale),
                    ],)
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
                        builder: (context, setState)
                        {
                          return Expanded(
                            child:
                            Checkbox(
                              value: selectedIndexes.contains(index),
                              onChanged: (bool? _b) {
                                setState(() {
                                  if (selectedIndexes.contains(index)) {
                                    selectedIndexes.remove(index); // unselect
                                  } else {
                                    selectedIndexes.add(index); // select
                                  }
                                });
                              },
                            ),
                          ).visible(deleting);
                        }),
                    Expanded(child: PopupMenuButton(
                        shape: RoundedRectangleBorder(
                            borderRadius:
                            BorderRadius.all(
                                Radius.circular(15))),
                        itemBuilder: (ctx) =>
                        <PopupMenuEntry>[
                          PopupMenuItem(
                            key: UniqueKey(),
                            onTap: () async {
                              await confirmDelete(ctx, suspendedSales[index]);
                            },
                            padding: EdgeInsets.symmetric(
                                horizontal: spacing_standard_new,
                                vertical: spacing_standard_new),
                            value: "${model.id}",
                            child: Text(grocery_popup_delete_label,style: primaryTextStyle(size: textSizeMedium.toInt()),textScaleFactor: textScale),
                          ),
                          PopupMenuItem(
                            key: UniqueKey(),
                            onTap: () async{
                              await editSuspendedItem(ctx, model, index);
                            },
                            padding: EdgeInsets.symmetric(
                                horizontal: spacing_standard_new,
                                vertical: spacing_standard_new),
                            value: "${model.id}",
                            child: Text(grocery_popup_rename_label,style: primaryTextStyle(size: textSizeMedium.toInt()),textScaleFactor: textScale),
                          ),
                        ])).visible(!deleting), //Icon(Icons.more_vert)),
                  ],
                ),
              ),//.paddingAll(spacing_control),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        iconTheme: appIconTheme,
        actionsIconTheme: appIconTheme,
        //centerTitle: true,
        //toolbarHeight: 20.0,
        title: Text(grocery_suspended_title, style: TextStyle(color: blackColor, fontSize: textSizeMedium)),
        elevation: 0.0,
        scrolledUnderElevation: 5.0,
        actions: [
          Padding(padding: EdgeInsets.only(right: spacing_standard_new, ),
            child:
            TextButton(
              onPressed: (){
                setState((){
                  deleting = true;
                });
              },
              child: Text("Clear", style: primaryTextStyle(size: textSizeMedium.toInt()), textScaleFactor: textScale,),
              //icon: null,//Icon(Icons.delete_forever, size: appActionSize, color: grocery_textRedColor,),
            ).visible(suspendedSales.isNotEmpty && !deleting),
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.max,
          children: [
            Container(
                width: width * 0.90,
                height: height * 0.60,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    //commonCachedNetworkImage(Grocery_ic_Search, fit: BoxFit.fitHeight, height: 170),
                    Text(empty_string, style: boldTextStyle(size: textSizeMedium.toInt(), color: grocery_lightGrey), textScaleFactor: textScale),
                  ],
                )
            ).visible(suspendedSales.isEmpty),
            //spacing_standard_new.toInt().height,
            ListView.builder(
              scrollDirection: Axis.vertical,
              itemCount: suspendedSales.length,
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                return SuspendedSale(suspendedSales[index], index).onTap((){
                  setState((){
                    if (Provider.of<ShoppingCartModel>(context, listen: false).isNotEmpty){
                      suspendSale();
                    }
                    Sale sale = suspendedSales[index];
                    (() async => await Future.forEach((await Sale_item().select().saleId.equals(sale.id).toList(preload: true, loadParents: true)), (sale_item) async {
                    /*(await Product().getById(e.productId, preload: true).then((product){
                      if ((product) != null){
                        Sale_item sale_item = Sale_item(productId: product.id, quantity: e.quantity!, variationId: e.variationId);
                        shoppingCart.add(sale_item);
                      }
                    }));*/
                      Provider.of<ShoppingCartModel>(context, listen: false).add(sale_item);
                  }).whenComplete((){
                    sale.delete(true);
                    Navigator.pop(context);
                    ShoppingCart(widget.orbiter).launch(context);
                  })).call();
                  });
                });
              },
            ),
            //16.height,
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(child: Text("Cancel", style: TextStyle(fontSize: textSizeMedium),textScaleFactor: textScale,), onPressed: (){
                  setState((){
                    deleting = false;
                  });
                },),
                spacing_standard.toInt().width,
                TextButton(child: Text("Done", style: TextStyle(fontSize: textSizeMedium),textScaleFactor: textScale), onPressed: () async{
                    await Future.forEach(selectedIndexes, (idx) async => await suspendedSales[idx].delete(true)).then((value) => setState(() => null)).whenComplete((){
                        Notify.toast(
                        message: "Transactions Removed Successfully",
                        type: MessageType.Success);
                    deleting = false;
                  });
                },),
              ],
            ).paddingRight(100).visible(deleting)
          ],
        ),
      ),
    );
  }
}