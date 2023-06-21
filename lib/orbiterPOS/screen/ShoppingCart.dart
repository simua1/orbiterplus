import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:orbiterplus/orbiterPOS/model/AppModel.dart';
import 'package:orbiterplus/orbiterPOS/screen/CheckOut.dart';
import 'package:orbiterplus/orbiterPOS/screen/Dashboard.dart';
import 'package:orbiterplus/orbiterPOS/utils/AppStrings.dart';
import 'package:orbiterplus/orbiterPOS/utils/AppColors.dart';
import 'package:orbiterplus/orbiterPOS/utils/AppNumbers.dart';
import 'package:orbiterplus/orbiterPOS/utils/OrbiterHelpers.dart';
import 'package:provider/provider.dart';

import '../../model/model.dart';
import '../utils/AppConstant.dart';

class ShoppingCart extends StatefulWidget {
  final OrbiterHelper orbiter;

  ShoppingCart(this.orbiter);

  @override
  ShoppingCartState createState() => ShoppingCartState();
}

class ShoppingCartState extends State<ShoppingCart> {
  //late ShoppingCartModel shoppingCart;
  late List<Sale> suspendedSales;
  late List<Customer> customers;
  late int business_id;

  //Variables for managing search
  late TextEditingController searchController;
  late FocusNode focusNode;

  late OrbiterHelper orbiter;

  @override
  void initState() {

    super.initState();

    orbiter = widget.orbiter;
    if (orbiter.LoggedInUser != null){
      business_id = (orbiter.LoggedInUser!.business_id?? -1);
    }
    //shoppingCart = Provider.of<ShoppingCartModel>(context, listen: false);//widget.orbiter.shoppingCart;
    (() async => suspendedSales = (await Sale().select().business_id.equals(business_id).and.status.equals('draft').toList())).call();
    (() async => customers = (await Customer().select().business_id.equals(business_id).toList())).call();

    searchController = TextEditingController();
    focusNode  = FocusNode();
  }

  @override
  Widget build(BuildContext context) {
    var width = MediaQuery.of(context).size.width;
    var height = MediaQuery.of(context).size.height;
    var textScale = width < max_width? text_scale_factor : MediaQuery.of(context).textScaleFactor;
    width = width <= max_width? width : max_width; //restrict width to the specified maximum

    if (orbiter.searchTerm.isNotEmpty){
      setState(() {
        searchController.text = orbiter.searchTerm;
      });
    }



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
      finally{
        Navigator.of(context).popAndPushNamed('/DashBoardScreen', arguments: widget.orbiter);
      }
    }

    Widget slideToEdit() {
      return Container(
        color: grocery_blue_Color,
        child: Align(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              SizedBox(
                width: 20,
              ),
              Icon(
                Icons.edit,
                color: Colors.white,
              ),
              Text(
                " Edit",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.left,
              ),
            ],
          ),
          alignment: Alignment.centerLeft,
        ),
      );
    }

    Widget slideToDelete() {
      return Container(
        color: grocery_Red_Color,
        child: Align(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              Icon(
                Icons.delete,
                color: Colors.white,
              ),
              Text(
                " Delete",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.right,
              ),
              SizedBox(
                width: 20,
              ),
            ],
          ),
          alignment: Alignment.centerRight,
        ),
      );
    }

    Future<bool> removeFromCart(Sale_item model) async {
      bool isDeleted = false;
      await showDialog<void>(context: context, barrierDismissible: true, builder: (BuildContext builder) =>
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
                    child: Text("${model.plProduct!.name}", maxLines: 1, softWrap: false, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: textSizeNormal), textScaleFactor: textScale,),),
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
                  isDeleted = false;
                  Navigator.pop(context);
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
                    Provider.of<ShoppingCartModel>(context, listen: false).remove(model);
                    //shoppingCart.notifyListeners();
                    isDeleted = true;
                    Navigator.pop(context);
                    Notify.toast(message: "Item Removed Successfully", type: MessageType.Success);
                  });
                },
              ),
            ],
          )
      );
      return isDeleted;
    }

    Future<bool> _editCartItem(Sale_item model, int pos) async {
      double dQuantity = model.quantity?? 0.0;
      bool isEdited = false;

      TextEditingController qtyController = TextEditingController(text: "$dQuantity");

      showDialog<void>(context: context, barrierDismissible: false, builder: (BuildContext builder) =>
          AlertDialog(
            titlePadding: const EdgeInsets.all(spacing_standard_new),
            contentPadding: const EdgeInsets.all(spacing_standard_new),
            actionsPadding: const EdgeInsets.all(spacing_standard_new),
            actionsAlignment: MainAxisAlignment.center,
            backgroundColor: context.cardColor,
            shape: RoundedRectangleBorder(
                borderRadius:
                BorderRadius.all(Radius.circular(20.0))),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(
                  width: (width * 0.34),
                  child: Align(alignment: Alignment.center,
                    child: Text("${model.plProduct!.name}", maxLines: 1, softWrap: false, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: textSizeLarge)),),
                ),
                Align(alignment: Alignment.centerRight, child: Icon(Icons.close, size: textSizeLarge).onTap((){Navigator.pop(builder);}),),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              //crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Align(alignment: Alignment.centerLeft, child: Text(grocery_quantity_sub_title),),
                  ],
                ),
                16.height,
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Icon(Icons.remove_circle_outline, size: 50, color: grocery_icon_color).onTap((){
                      setState((){
                        dQuantity = qtyController.value.text.toDouble();
                        if (dQuantity >0){
                          dQuantity -=1;
                          qtyController.text = "$dQuantity";
                          //qtyController.value = TextEditingValue(text: "$iQuantity");
                        }
                      });
                    }),
                    24.width,
                    //Text("1", style: boldTextStyle(size: 18)),
                    Container(
                      padding: EdgeInsets.all(spacing_standard_new),
                      width: context.width() * 0.20,
                      decoration: boxDecorationWithShadow(
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(spacing_middle),
                          topRight: Radius.circular(spacing_middle),
                          bottomRight: Radius.circular(spacing_middle),
                          bottomLeft: Radius.circular(spacing_middle),
                        ),
                        boxShadow: defaultBoxShadow(),
                        backgroundColor: context.cardColor,
                      ),
                      child: TextFormField(
                        controller: qtyController,
                        autofocus: false,
                        textInputAction: TextInputAction.done,
                        style: primaryTextStyle(fontFamily: fontMedium, size: 28),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                        ),
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        onFieldSubmitted: (val){
                          if (orbiter.validateProductQuantity(model.plProduct!,dQuantity)) {
                            setState(() {
                              dQuantity = val.toDouble();
                              model.quantity = dQuantity;
                              Provider.of<ShoppingCartModel>(
                                  context, listen: false).replace(model, pos);
                              //shoppingCart.notifyListeners();
                              Navigator.pop(builder);
                            });
                          }
                        },
                      ),
                    ),
                    24.width,
                    Icon(Icons.add_circle_outline, size: 50, color: grocery_icon_color).onTap((){
                      double qty = qtyController.value.text.toDouble() + 1.0;

                      if (orbiter.validateProductQuantity(model.plProduct!,qty)) {
                        setState(() {
                          dQuantity = qty;
                          qtyController.text = "$dQuantity";
                        });
                      }
                    }),
                  ],
                ),
                16.height,
              ],
            ),
            actions: [
              Center(
                child: TextButton(child:Text(grocery_sort_by_action, style: TextStyle(color: grocery_colorPrimary_light, fontSize: textSizeLarge, fontFamily: fontSemiBold),),onPressed: (){
                  setState((){
                    dQuantity = qtyController.value.text.toDouble();
                    model.quantity = dQuantity;
                    Provider.of<ShoppingCartModel>(context, listen: false).replace(model, pos);
                    //shoppingCart.notifyListeners();
                    Navigator.pop(context);
                  });
                  Notify.toast(message: "Updated Successfully", type: MessageType.Success);
                },),
              )
            ],
          )
      );
      return isEdited;
    }

    Future<bool> editCartItem(Sale_item model, int pos) async{
      TextEditingController qtyController;
      List<TextEditingController> _qtyControllers = [];
      Sale_item sale_item = model;//Sale_item(productId: product.id, quantity: 1.0);
      Product product = sale_item.plProduct!;
      List<double> dQuantities = []; //for variable products
      bool isEdited = false;

      int dummyCount = 0;
      int varCount = 0;

      bool isVariableProduct = (product.product_type == "variable");

      void openDialog() {
        if (Provider.of<ShoppingCartModel>(context, listen: false) != null) {
          if (isVariableProduct != true){
            sale_item =
                Provider.of<ShoppingCartModel>(context, listen: false).items.firstWhere((it) => it.productId ==
                    product.id,
                    orElse: () => Sale_item(productId: product.id, quantity: 1.0));
          }
          else{
            product.plVariations!.forEach((v) {
              Sale_item sale_item =
              Provider.of<ShoppingCartModel>(context, listen: false).items.firstWhere((it) => it.productId ==
                  product.id && it.variationId == v.id,
                  orElse: () => Sale_item(productId: product.id, quantity: 0.0));

              dQuantities.add(sale_item.quantity?? 0.0);
              _qtyControllers.add(TextEditingController(text: "${sale_item.quantity}"));
            });
          }
        }
        else {
          sale_item = Sale_item(productId: product.id, quantity: 1.0);
          if(isVariableProduct){
            product.plVariations!.forEach((v) {
              dQuantities.add(0);
              _qtyControllers.add(TextEditingController(text: "0.0"));
            });
          }
          else{

          }
        }

        double dQuantity = ((sale_item.quantity?? 0.0) > 0.0 ? (sale_item.quantity?? 1.0) : 1.0);
        qtyController = TextEditingController(text: "$dQuantity");

        showDialog<void>(context: context,
            barrierDismissible: false,
            builder: (BuildContext builder) =>
                AlertDialog(
                  titlePadding: const EdgeInsets.all(spacing_standard_new),
                  contentPadding: const EdgeInsets.all(spacing_standard_new),
                  actionsPadding: const EdgeInsets.all(spacing_standard_new),
                  actionsAlignment: MainAxisAlignment.center,
                  backgroundColor: context.cardColor,
                  shape: const RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius.all(Radius.circular(15.0))),
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SizedBox(
                        width: (width * 0.60),
                        child: Align(alignment: Alignment.center,
                          child: Text(product.name!, maxLines: 1,
                              softWrap: false,
                              overflow: TextOverflow.ellipsis,
                              textScaleFactor: textScale,
                              style: const TextStyle(
                                  fontSize: textSizeNormal)),),
                      ),
                      Align(alignment: Alignment.centerRight,
                        child: const Icon(Icons.close, size: appTitleSize)
                            .onTap(() {
                          Navigator.pop(context);
                        }),),
                    ],
                  ),
                  content: StatefulBuilder(
                      builder: (context, setState) {
                        if (product.stock! > 0 && product.plVariations != null) {
                          if (dummyCount > 0) {
                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              //crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment
                                      .center,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.max,
                                  children:  [
                                    Text(
                                      //textAlign: TextAlign.center,
                                      maxLines: 2,
                                      textScaleFactor: textScale,
                                      grocery_quantity_sub_title, style: primaryTextStyle(
                                        fontFamily: fontRegular, size: textSizeMedium.toInt()),),
                                  ],
                                ),
                                16.height,
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    const Icon(
                                        Icons.remove_circle_outline, size: 40,
                                        color: grocery_icon_color).onTap(() {
                                      setState(() {
                                        dQuantity =
                                            qtyController.value.text.toDouble();
                                        if (dQuantity > 0.0) {
                                          dQuantity -= 1.0;
                                          qtyController.value =
                                              TextEditingValue(
                                                  text: "$dQuantity");
                                        }
                                      });
                                    }),
                                    15.width,
                                    //Text("1", style: boldTextStyle(size: 18)),
                                    Container(
                                      padding: const EdgeInsets.all(
                                          spacing_standard_new),
                                      width: width * 0.35,
                                      decoration: boxDecorationWithShadow(
                                        borderRadius: const BorderRadius.only(
                                          topLeft: Radius.circular(
                                              spacing_middle),
                                          topRight: Radius.circular(
                                              spacing_middle),
                                          bottomRight: Radius.circular(
                                              spacing_middle),
                                          bottomLeft: Radius.circular(
                                              spacing_middle),
                                        ),
                                        boxShadow: defaultBoxShadow(),
                                        backgroundColor: context.cardColor,
                                      ),
                                      child: TextFormField(
                                        controller: qtyController,
                                        autofocus: false,
                                        textInputAction: TextInputAction.done,
                                        style: primaryTextStyle(
                                            fontFamily: fontMedium, size: textSizeNormal.toInt()),
                                        decoration: const InputDecoration(
                                          //prefixIcon: Icon(Icons.search, color: grocery_color_white),
                                          border: InputBorder.none,
                                        ),
                                        keyboardType: TextInputType.number,
                                        textAlign: TextAlign.center,
                                        onFieldSubmitted: (val) {
                                          setState(() {
                                            try {
                                              dQuantity = val.toDouble();
                                              sale_item.quantity = dQuantity;
                                              Provider.of<ShoppingCartModel>(context, listen: false).add(
                                                  sale_item);
                                              isEdited = true;
                                            }
                                            catch (e) {
                                              print(e.toString());
                                            }
                                            finally {
                                              Navigator.pop(context);
                                            }
                                          });
                                        },
                                      ),
                                    ),
                                    15.width,
                                    const Icon(
                                        Icons.add_circle_outline, size: 40,
                                        color: grocery_icon_color).onTap(() {
                                          double qty = qtyController.value.text.toDouble() + 1.0;
                                      if (orbiter.validateProductQuantity(model.plProduct!,qty)) {
                                        setState(() {
                                          dQuantity = qty;
                                          qtyController.text = "$dQuantity";
                                        });
                                      }
                                    }),
                                  ],
                                ),
                                16.height,
                              ],
                            );
                          }
                          else if (dummyCount == 0 && varCount > 0) {
                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              //crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment
                                      .start,
                                  children: const [
                                    Align(alignment: Alignment.centerLeft,
                                      child: Text(
                                          grocery_quantity_sub_title),),
                                  ],
                                ),
                                16.height,
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment
                                      .start,
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: <Widget>[
                                    SizedBox(
                                      width: (width * 0.60),
                                      height: (height * 0.30),
                                      child: ListView.builder(
                                          shrinkWrap: true,
                                          physics: const NeverScrollableScrollPhysics(),
                                          scrollDirection: Axis.vertical,
                                          itemCount: (product.plVariations !=
                                              null ? product.plVariations!
                                              .length : 0),
                                          itemBuilder: (context, index) {
                                            /*if (orbiter.shoppingCart != null) {
                                                cartItems[index] =
                                                    orbiter.shoppingCart!.items.firstWhere((it) => it.product.id ==
                                                        model.id,
                                                        orElse: () {
                                                          return CartItemModel(model, iQuantities.sumBy((p0) => p0));
                                                        });
                                              }
                                              else {
                                                cartItems.add(CartItemModel(model, iQuantities.sumBy((p0) => p0), variants: ));
                                              }*/
                                            return ListTile(
                                              contentPadding: EdgeInsets.only(
                                                top: spacing_standard_new,
                                                bottom: spacing_standard_new,),
                                              leading: Row(
                                                  mainAxisSize: MainAxisSize
                                                      .min,
                                                  mainAxisAlignment: MainAxisAlignment
                                                      .start,
                                                  children: <Widget>[
                                                    Text("${product
                                                        .plVariations![index]
                                                        .name} @ ${currency
                                                        .format(orbiter.getVariationPrice(product
                                                        .plVariations![index])) }",
                                                        textScaleFactor: (textScale - 0.10),
                                                        style: boldTextStyle(
                                                            size: textSizeLarge
                                                                .toInt(),
                                                            fontFamily: fontRegular)),
                                                    TextButton.icon(
                                                      onPressed: null,
                                                      style: ButtonStyle(
                                                          backgroundColor: MaterialStateProperty
                                                              .resolveWith((
                                                              states) =>
                                                          (orbiter.getQuantity(product
                                                              .plVariations![index]
                                                              .stock) >
                                                              orbiter.getQuantity(
                                                                  product.alert)
                                                              ? grocery_textGreenColor
                                                              : (orbiter.getQuantity(
                                                              product
                                                                  .plVariations![index]
                                                                  .stock) > 0.0
                                                              ? grocery_color_yellow
                                                              : grocery_textRedColor))),
                                                          padding: MaterialStateProperty
                                                              .resolveWith((
                                                              states) =>
                                                          const EdgeInsets
                                                              .symmetric(
                                                              horizontal: spacing_standard,
                                                              vertical: spacing_standard),)),
                                                      //padding: ,
                                                      icon: const Icon(
                                                        Icons.bookmark,
                                                        color: grocery_color_white,),
                                                      label: Text(
                                                          "${(orbiter.getQuantity(
                                                              product
                                                                  .plVariations![index]
                                                                  .stock) > 0.0
                                                              ? orbiter.formatQuantity(
                                                              product
                                                                  .plVariations![index]
                                                                  .stock!)
                                                              : grocery_out_of_stock)}",
                                                          textScaleFactor: (textScale - 0.10),
                                                          style: boldTextStyle(
                                                              size: textSizeNormal
                                                                  .toInt(),
                                                              color: grocery_color_white,
                                                              fontFamily: fontRegular)),
                                                    ).paddingLeft(
                                                        spacing_standard_new),
                                                  ]),
                                              trailing: Row(
                                                mainAxisSize: MainAxisSize
                                                    .max,
                                                mainAxisAlignment: MainAxisAlignment
                                                    .start,

                                                children: <Widget>[
                                                  const Icon(Icons
                                                      .remove_circle_outline,
                                                      size: 40,
                                                      color: grocery_icon_color)
                                                      .onTap(() {
                                                    setState(() {
                                                      dQuantities[index] =
                                                          _qtyControllers[index].value
                                                              .text.toDouble();

                                                      if (dQuantities[index] > 0.0) {
                                                        dQuantities[index] -= 1.0;
                                                        _qtyControllers[index].value =
                                                            TextEditingValue(
                                                                text: "${dQuantities[index]}");
                                                      }
                                                    });
                                                  }).paddingRight(
                                                      spacing_standard_new),
                                                  //Text("1", style: boldTextStyle(size: 18)),
                                                  Container(
                                                    padding: const EdgeInsets
                                                        .all(
                                                        spacing_standard_new),
                                                    //const EdgeInsets.only(left: spacing_standard_new, right: spacing_standard_new),
                                                    //margin: const EdgeInsets.all(spacing_standard_new),
                                                    width: width * 0.08,
                                                    decoration: boxDecorationWithShadow(
                                                      borderRadius: const BorderRadius
                                                          .only(
                                                        topLeft: Radius
                                                            .circular(
                                                            spacing_middle),
                                                        topRight: Radius
                                                            .circular(
                                                            spacing_middle),
                                                        bottomRight: Radius
                                                            .circular(
                                                            spacing_middle),
                                                        bottomLeft: Radius
                                                            .circular(
                                                            spacing_middle),
                                                      ),
                                                      boxShadow: defaultBoxShadow(),
                                                      backgroundColor: context
                                                          .cardColor,
                                                    ),
                                                    child: TextFormField(
                                                      controller: _qtyControllers[index],
                                                      autofocus: false,
                                                      textInputAction: TextInputAction
                                                          .done,
                                                      style: primaryTextStyle(
                                                          fontFamily: fontMedium,
                                                          size: 20),
                                                      decoration: const InputDecoration(
                                                        border: InputBorder
                                                            .none,
                                                      ),
                                                      keyboardType: TextInputType
                                                          .number,
                                                      textAlign: TextAlign
                                                          .center,
                                                      /*onFieldSubmitted: (val) {
                                                          setState(() {
                                                            try {
                                                              iQuantity =
                                                                  val.toInt();
                                                              cartItem
                                                                  .quantity =
                                                                  iQuantity;
                                                              orbiter
                                                                  .shoppingCart!
                                                                  .add(
                                                                  cartItem);
                                                              isAdded = true;
                                                            }
                                                            catch (e) {
                                                              print(e
                                                                  .toString());
                                                            }
                                                            finally {
                                                              Navigator.pop(
                                                                  context);
                                                            }
                                                          });
                                                        },*/
                                                    ),
                                                  ),
                                                  const Icon(Icons
                                                      .add_circle_outline,
                                                      size: 40,
                                                      color: grocery_icon_color)
                                                      .onTap(() {
                                                    setState(() {
                                                      dQuantities[index] =
                                                          _qtyControllers[index].value
                                                              .text.toDouble() + 1.0;
                                                      _qtyControllers[index].text =
                                                      "${dQuantities[index]}";
                                                    });
                                                  }).paddingLeft(
                                                      spacing_standard_new),
                                                ],
                                              ),
                                              /*controlAffinity: ListTileControlAffinity.trailing,
                                          value: model.plVariations![index].id!,
                                          groupValue: variation_id,
                                          toggleable: true,
                                          onChanged: (val) =>
                                              setState(() =>
                                              variation_id = val!),*/
                                            );
                                          }
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            );
                          }
                          else {
                            return Column(
                              mainAxisSize: MainAxisSize.min,
                              //crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment
                                      .start,
                                  children: const [
                                    Align(alignment: Alignment.centerLeft,
                                      child: Text(grocery_product_out_stock,
                                          style: TextStyle(
                                              color: grocery_Red_Color,
                                              fontSize: textSizeNormal)),),
                                  ],
                                )
                              ],
                            );
                          }
                        }
                        else {
                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            //crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Align(alignment: Alignment.centerLeft,
                                    child: Text(grocery_product_out_stock,
                                        style: TextStyle(
                                            color: grocery_Red_Color,
                                            fontSize: textSizeNormal)),),
                                ],
                              ),
                              16.height,
                            ],
                          );
                        }
                      }),
                  actions: <Widget>[
                    if (product.stock! > 0)
                      Center(
                        child: TextButton(
                          child: const Text(grocery_sort_by_action,
                            style: TextStyle(
                                color: grocery_colorPrimary_light,
                                fontSize: textSizeLarge,
                                fontFamily: fontSemiBold),), onPressed: () {
                          setState(() {
                            try {
                              //orbiter.shoppingCart = orbiter.shoppingCart?? ShoppingCartModel(0.0, (orbiter.LoggedInUser!.tax1_amount?? 0.0),);
                              if (product.product_type == "variable"){
                                for (int ix = 0; ix < product.plVariations!.length; ix++){
                                  if (dQuantities[ix] > 0){
                                    Sale_item sale_item = Sale_item(productId: product.id, quantity: dQuantities[ix], variationId: product.plVariations![ix].id);
                                    Provider.of<ShoppingCartModel>(context, listen: false).add(sale_item);
                                  }
                                }
                              }
                              else{
                                dQuantity = qtyController.value.text.toDouble();
                                sale_item.quantity = dQuantity;
                                Provider.of<ShoppingCartModel>(context, listen: false).add(sale_item);
                              }
                              Notify.toast(message: "Updated Successfully",
                                  type: MessageType.Success);
                            }
                            catch (e) {
                              print(e.toString());
                            }
                            finally {
                              Navigator.pop(context);
                            }
                          });
                        },),
                      )
                  ],
                )
        );
      }

      product.getVariations()!.name.equals("DUMMY").toCount().then((val) => dummyCount = val).whenComplete(() => (dummyCount > 0? openDialog(): null));
      product.getVariations()!.toCount().then((val) => varCount = val).whenComplete(() => (dummyCount == 0 && varCount > 0? openDialog(): null));

      return isEdited;
    }

    Widget Cart(Sale_item model, int pos, ) {
      return Slidable(
        key: UniqueKey(),
        // The start action pane is the one at the left or the top side.
        startActionPane: ActionPane(
          // A motion is a widget used to control how the pane animates.
          motion: const ScrollMotion(),

          // All actions are defined in the children parameter.
          children:  [
            // A SlidableAction can have an icon and/or a label.
            SlidableAction(
              key: UniqueKey(),
              flex: 1,
              backgroundColor: grocery_Red_Color,
              foregroundColor: Colors.white,
              icon: Icons.delete,
              autoClose: true,
              label: 'Delete',
              onPressed: (context) => removeFromCart(model),
            ),
          ],
        ),

        // The end action pane is the one at the right or the bottom side.
        endActionPane: ActionPane(
          motion: ScrollMotion(),
          children: [
            SlidableAction(
              key: UniqueKey(),
              flex: 1,
              backgroundColor: grocery_blue_Color,
              foregroundColor: Colors.white,
              autoClose: true,
              icon: Icons.edit,
              label: 'Edit',
              onPressed: (context) async => await editCartItem(model, pos),
            ),
          ],
        ),
        child:
        Align(
          alignment: Alignment.topCenter,
          child: Container(
            width: width * 0.80,
            height: height * 0.13,
            decoration: boxDecorationWithShadow(
              borderRadius: BorderRadius.circular(8),
              boxShadow: defaultBoxShadow(),
              backgroundColor: context.cardColor,
            ),
            padding: EdgeInsets.symmetric(horizontal: spacing_control_half, vertical: spacing_control_half),
            margin: EdgeInsets.all(spacing_standard),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  flex: 3,
                  //child: commonCacheImageWidget(model.product.img, 150, fit: BoxFit.fitHeight).paddingAll(spacing_control),
                  child:Image.network(model.plProduct!.img!, height: 150, fit: BoxFit.contain, alignment: Alignment.topCenter).paddingAll(spacing_control),
                ),
                Expanded(
                  flex: 8,
                  child:
                  IntrinsicHeight(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.max,
                      children: <Widget>[
                        Expanded( flex: 6, child: Text(model.plProduct!.name!, maxLines: 3, softWrap: true, overflow: TextOverflow.ellipsis, style: primaryTextStyle(size: textSizeSMedium.toInt()), textScaleFactor: 0.95).paddingAll(spacing_control),),
                        Expanded( flex: 4, child:
                        Row(
                          children: [
                            /*Expanded(
                              flex: 3,
                              child: Text("${model.quantity} X ${currency.format(widget.orbiter.getPrice(model))}", style: primaryTextStyle(size: textSizeMedium.toInt(), fontFamily: fontRegular), textScaleFactor: (textScale - 0.10)),
                            ),
                            Expanded(
                              flex: 6,
                              child: Text("${currency.format(widget.orbiter.getPrice(model))}", style: primaryTextStyle(size: textSizeMedium.toInt(), fontFamily: fontRegular), textScaleFactor: (textScale - 0.10)),
                            ),*/
                            Text("${model.quantity} X ${currency.format(widget.orbiter.getPrice(model))}", style: primaryTextStyle(size: textSizeMedium.toInt(), fontFamily: fontRegular), textScaleFactor: (textScale - 0.10)).paddingAll(spacing_control),
                          ],
                        )
                          ,),
                      ],
                    ),
                  ).paddingAll(spacing_control),
                ),
                Expanded(
                  flex: 4,
                  child: IntrinsicHeight(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.max,
                      children: <Widget>[
                        Expanded( child: Text(currency.format((widget.orbiter.getPrice(model) * (model.quantity?? 0.0))), style: primaryTextStyle(size: textSizeMedium.toInt(), fontFamily: fontRegular), textScaleFactor: textScale).paddingAll(spacing_control),),

                      ],
                    ),
                  ).paddingAll(spacing_control),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        //centerTitle: false,
        title: Padding(padding: EdgeInsets.only(left: spacing_standard,), child: Text(grocery_cart_title_label, style: TextStyle(color: blackColor, fontSize: textSizeNormal), textScaleFactor: textScale)),
        elevation: 0.0,
        scrolledUnderElevation: 4.0,
        actions: [
          Padding(padding: EdgeInsets.only(right: spacing_standard_new, ),
              child:TextButton.icon(
                onPressed: (){
                  setState((){
                    /*suspendedSales.add(SaleModel("${Random(1234567801).nextInt(1334567810)}",
                        "",DateTime.now(), shoppingCart.items.toList(), status: SaleStatus.suspended));
                    shoppingCart.removeAll();*/
                    suspendSale();
                    //shoppingCart.notifyListeners();
                    Navigator.pop(context);
                    Notify.toast(message: grocery_suspend_successful, type: MessageType.Success);
                  });
                },
                label: Text(grocery_suspend_button_label, textScaleFactor: textScale, style: TextStyle(fontSize: textSizeNormal, color: grocery_textRedColor, )),
                icon: Icon(Icons.pause, size: textSizeNormal, color: grocery_textRedColor,),
              ).visible(Provider.of<ShoppingCartModel>(context, listen: false).isNotEmpty)
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            //10.height,
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Align(alignment: Alignment.topCenter,
                  heightFactor: 1.3,
                  child:
                  Container(
                    width: width * 0.85,
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: grocery_lightGrey, width: 2)
                    ),
                    child: Container(
                      //padding: const EdgeInsets.all(spacing_control_half),
                        child: IntrinsicHeight( child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              Expanded(flex: 8, child: TextFormField(
                                controller: searchController,
                                textInputAction: TextInputAction.search,
                                style: primaryTextStyle(color: grocery_textColorPrimary, fontFamily: fontRegular, size: textSizeNormal.toInt()),
                                decoration: InputDecoration(
                                  constraints: BoxConstraints(maxWidth: width * 0.90),
                                  prefixIcon: const Icon(Icons.search, color: grocery_lightGrey, size: textSizeLarge),
                                  border: InputBorder.none,
                                  hintText: grocery_lbl_search_hint,
                                  hintStyle: primaryTextStyle(color: grocery_lightGrey, size: textSizeSmall.toInt()),
                                ),
                                keyboardType: TextInputType.text,
                                textAlign: TextAlign.start,
                                //autofocus: true,
                                focusNode: focusNode,
                                onTap: (){
                                  focusNode.unfocus();
                                  focusNode.requestFocus();
                                  searchController.selectAll();
                                },
                                onChanged: (val){
                                  //searchText = val;
                                  /*setState(() {
                                          searchResults = runSearch(args: val);
                                        });*/
                                },
                                onFieldSubmitted: (p){
                                  setState(() {
                                    orbiter.searchTerm = p;
                                    Navigator.of(context).pushAndRemoveUntil(
                                      // the new route
                                      MaterialPageRoute(
                                        builder: (BuildContext context) => GroceryDashBoardScreen(orbiter),
                                      ),

                                      // this function should return true when we're done removing routes
                                      // but because we want to remove all other screens, we make it
                                      // always return false
                                          (Route route) => false,
                                    );
                                    //searchResults = runSearch(args: searchText);
                                    //runSearch(args: searchText);
                                  });
                                },
                              ),),
                              //Expanded(flex: 1, child: SizedBox()),
                              Expanded(flex:2, child:
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  VerticalDivider(
                                    color: grocery_light_gray_color,
                                    thickness: 1,
                                  ),
                                  IconButton(icon: const Icon(Icons.document_scanner), color: grocery_textColorPrimary, iconSize: textSizeLarge, onPressed:  (){
                                    setState(() {
                                      //await scanbarcode();
                                      focusNode.unfocus();
                                      focusNode.requestFocus();
                                      searchController.selectAll();
                                    });
                                  },
                                      padding :EdgeInsets.symmetric(horizontal: spacing_control_half))
                                ],
                              )
                                ,),
                            ]
                        ))
                    ),
                  ),
                ),
              ],
            ),
            Container(
                //width: width * 0.90,
                height: height * 0.60,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    //commonCachedNetworkImage(Grocery_ic_Search, fit: BoxFit.fitHeight, height: 170),
                    Text(grocery_empty_cart_label, style: boldTextStyle(size: textSizeNormal.toInt(), color: grocery_lightGrey), textScaleFactor: textScale,),
                  ],
                )
            ).visible(Provider.of<ShoppingCartModel>(context, listen: false).isEmpty),
            ListView.builder(
              scrollDirection: Axis.vertical,
              itemCount: Provider.of<ShoppingCartModel>(context, listen: false).Count,
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                return Cart(Provider.of<ShoppingCartModel>(context, listen: false).items[index], index);
              },
            ).visible(Provider.of<ShoppingCartModel>(context, listen: false).isNotEmpty),
            16.height,
          ],
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        child:
        IntrinsicHeight(
          child: Align(
            alignment: Alignment.topCenter,
            child: Container(
              width: width * 0.85,
              //padding: EdgeInsets.all(spacing_xxLarge),
              padding: EdgeInsets.all(spacing_large),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("$grocery_lbl_subtotal (${Provider.of<ShoppingCartModel>(context, listen: false).Count} items):", style: secondaryTextStyle(color: (Provider.of<ShoppingCartModel>(context, listen: false).isNotEmpty? grocery_darkGrey : grocery_lightGrey), size: textSizeNormal.toInt()), textScaleFactor: textScale),
                      Text("${currency.format(Provider.of<ShoppingCartModel>(context, listen: false).SubTotal)}", style: secondaryTextStyle(color: (Provider.of<ShoppingCartModel>(context, listen: false).isNotEmpty? grocery_darkGrey : grocery_lightGrey), fontFamily: fontRegular, size: textSizeNormal.toInt()), textScaleFactor: textScale),
                    ],
                  ),
                  8.height,
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("$grocery_lbl_discount ${Provider.of<ShoppingCartModel>(context, listen: false).sDiscountLabel}:", style: secondaryTextStyle(color: (Provider.of<ShoppingCartModel>(context, listen: false).isNotEmpty? grocery_darkGrey : grocery_lightGrey), size: textSizeNormal.toInt()), textScaleFactor: textScale),
                      Text("${currency.format(Provider.of<ShoppingCartModel>(context, listen: false).Discount)}", style: secondaryTextStyle(color: (Provider.of<ShoppingCartModel>(context, listen: false).isNotEmpty? grocery_darkGrey : grocery_lightGrey), fontFamily: fontRegular, size: textSizeNormal.toInt()), textScaleFactor: textScale),
                    ],
                  ),
                  8.height,
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("$grocery_lbl_tax ${Provider.of<ShoppingCartModel>(context, listen: false).sTaxLabel}:", style: secondaryTextStyle(color: (Provider.of<ShoppingCartModel>(context, listen: false).isNotEmpty? grocery_darkGrey : grocery_lightGrey), size: textSizeNormal.toInt()), textScaleFactor: textScale),
                      Text("${currency.format(Provider.of<ShoppingCartModel>(context, listen: false).Tax)}", style: secondaryTextStyle(color: (Provider.of<ShoppingCartModel>(context, listen: false).isNotEmpty? grocery_darkGrey : grocery_lightGrey), fontFamily: fontRegular, size: textSizeNormal.toInt()), textScaleFactor: textScale),
                    ],
                  ),
                  8.height,
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("$grocery_lbl_total:", style: boldTextStyle(color: (Provider.of<ShoppingCartModel>(context, listen: false).isNotEmpty? grocery_darkGrey : grocery_lightGrey), fontFamily: fontBold, size: textSizeNormal.toInt()), textScaleFactor: 0.95),
                      Text("${currency.format(Provider.of<ShoppingCartModel>(context, listen: false).Total)}", style: boldTextStyle(color: (Provider.of<ShoppingCartModel>(context, listen: false).isNotEmpty? grocery_Color_black : grocery_lightGrey), fontFamily: fontBold, size: textSizeNormal.toInt()), textScaleFactor: 0.95),
                    ],
                  ),
                  32.height,
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      16.width,
                      AppButton(
                        color: app_colorPrimary,
                        elevation: 4.0,
                        disabledColor: grocery_disabled_button_color,
                        enabled: Provider.of<ShoppingCartModel>(context, listen: false).isNotEmpty,
                        child: Text(grocery_cart_button_label, style: boldTextStyle(color: (Provider.of<ShoppingCartModel>(context, listen: false).isNotEmpty? white : grocery_darkGrey) , size: textSizeLarge.toInt()), textScaleFactor: textScale),
                        shapeBorder: RoundedRectangleBorder(
                            borderRadius:
                            BorderRadius.all(Radius.circular(16.0))),
                        onTap: () {
                          AppCheckOut(widget.orbiter).launch(context);
                        },
                        padding: EdgeInsets.symmetric(horizontal: width * 0.16, vertical: spacing_standard),
                      ),
                    ],
                  ),
                  Padding(padding: EdgeInsets.only(bottom: spacing_standard))
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}