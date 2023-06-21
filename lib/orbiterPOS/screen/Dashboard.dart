import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
//import 'package:flutter_pos_printer_platform/flutter_pos_printer_platform.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:orbiterplus/model/model.dart';
import 'package:orbiterplus/orbiterPOS/model/AppModel.dart';
import 'package:orbiterplus/orbiterPOS/screen/ActualSales.dart';
import 'package:orbiterplus/orbiterPOS/screen/Login.dart';
import 'package:orbiterplus/orbiterPOS/screen/OrbiterWeb.dart';
import 'package:orbiterplus/orbiterPOS/screen/ShoppingCart.dart';
import 'package:orbiterplus/orbiterPOS/screen/SuspendedSales.dart';
import 'package:orbiterplus/orbiterPOS/utils/AppSizes.dart';
import 'package:orbiterplus/orbiterPOS/utils/AppStrings.dart';
import 'package:orbiterplus/orbiterPOS/utils/AppColors.dart';
import 'package:orbiterplus/orbiterPOS/utils/AppConstant.dart';
import 'package:orbiterplus/orbiterPOS/utils/AppDataGenerator.dart';
import 'package:orbiterplus/orbiterPOS/utils/AppImages.dart';
import 'package:orbiterplus/main.dart';
import 'package:orbiterplus/main/utils/AppWidget.dart';
import 'package:orbiterplus/orbiterPOS/utils/AppNumbers.dart';
import 'package:orbiterplus/orbiterPOS/utils/OrbiterHelpers.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

import 'CustomersWidget.dart';

class GroceryDashBoardScreen extends StatefulWidget {
  static String tag = '/DashBoardScreen';
  final OrbiterHelper orbiter;

  GroceryDashBoardScreen(this.orbiter);

  @override
  _GroceryDashBoardScreenState createState() => _GroceryDashBoardScreenState();
}

class _GroceryDashBoardScreenState extends State<GroceryDashBoardScreen> with SingleTickerProviderStateMixin {

  //List<Product> mProductList = [];
  List<Product> products = [];

  late bool showGrid;

  //Variables for managing search
  late TextEditingController searchController;
  late FocusNode focusNode;
  int iSortBy = -1;

  //Variable for capturing barcode text
  String barcode = "";

  bool isFirstTime = true;
  String searchText = "";
  Widget searchResults = Container();

  late OrbiterHelper orbiter;
  //late ShoppingCartModel shoppingCart;

  late Menus menus;
  int business_id = -1;

  void runSearch({String args = ""}) {
    //List<Product> mList = [];
    //var results = searchResult(grocery_lbl_search_empty, grocery_light_gray_color);

    //if (args!.isNotEmpty) {
    try{
      var query = (Product()
          .select()
          .business_id.equals(business_id));

      if (args.isNotEmpty)
      {
        query = query.and
            .name
            .startsWith(args)
            .or
            .sku.equals(args)
            .or
            .description
            .startsWith(args)
            .or
            .custom_field1
            .contains(args)
            .or
            .manufacturer
            .startsWith(args);
      }

      if (args.isEmptyOrNull){
        query = query.and.stock.greaterThan(0).top(20);
      }

      switch (iSortBy) {
        case 1:
          query = query.orderByDesc("dateAdded");
          break;
        case 2:
          query = query.orderBy("name");
          break;
        case 3:
          query = query.orderByDesc("name");
          break;
        default:
          query = query.orderByDesc("dateAdded");
          break;
      }

      (() async => products = (await query.toList(preload: true).whenComplete(() => setState(() => null)))).call();
    }
    catch(e){
      print(e.toString());
    }
  }

  @override
  void initState() {
      super.initState();
      changeStatusColor(app_colorAppbar);

      searchController = TextEditingController();
      focusNode  = FocusNode();
      showGrid = false;
      orbiter = widget.orbiter;

      if (orbiter.LoggedInUser != null){
        business_id = (orbiter.LoggedInUser!.business_id?? -1);
      }

      //storeMemberItems().then((value) => mProductList = value);
      setState(() {
        runSearch(args: searchText);

      });

      //shoppingCart = Provider.of<ShoppingCartModel>(context, listen: false);
    }

  //bool _disposed = false;
  @override
  void dispose() {
    // Clean up the focus node when the Form is disposed.
    focusNode.dispose();
    //customerController.dispose();
    super.dispose();
    //_disposed = true;
    changeStatusColor(app_colorAppbar);
  }

  @override
  Widget build(BuildContext context) {
    var width = MediaQuery.of(context).size.width;
    var height = MediaQuery.of(context).size.height;
    var textScale = width < max_width? text_scale_factor : MediaQuery.of(context).textScaleFactor;
    width = width <= max_width? width : max_width; //restrict width to the specified maximum

      Future<bool> addToCart(Product product) async{
        TextEditingController qtyController;
        List<TextEditingController> _qtyControllers = [];
        Sale_item sale_item = Sale_item(productId: product.id, quantity: 1.0);
        List<double> dQuantities = []; //for variable products
        bool isAdded = true;

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
                                            if (orbiter.validateProductQuantity(product,dQuantity)){
                                              setState(() {
                                                try {
                                                  dQuantity = val.toDouble();
                                                  sale_item.quantity = dQuantity;
                                                  Provider.of<ShoppingCartModel>(context, listen: false).add(
                                                      sale_item);
                                                  isAdded = true;
                                                }
                                                catch (e) {
                                                  print(e.toString());
                                                }
                                                finally {
                                                  Navigator.pop(context);
                                                }
                                              });
                                            }
                                          },
                                        ),
                                      ),
                                      15.width,
                                      const Icon(
                                          Icons.add_circle_outline, size: 40,
                                        color: grocery_icon_color).onTap(() {
                                          double qty = qtyController.value.text.toDouble() + 1.0;

                                          if (orbiter.validateProductQuantity(product,qty)){
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
                                                          textScaleFactor: textScale,
                                                          style: boldTextStyle(
                                                              size: textSizeMedium
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
                                                            textScaleFactor: textScale,
                                                            style: boldTextStyle(
                                                                size: textSizeMedium
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
                                Notify.toast(message: "Added Successfully",
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

        return isAdded;
      }

      Widget productDetails(Product model){
        String getPrice(){
          String priceText = "";

          if (model.product_type == 'single'){
            priceText = currency.format(orbiter.getProductPrice(model));
          }
          else if (model.product_type == 'variable'){
            double min = 0, max = 0;
            if (model.plVariations != null && model.plVariations!.isNotEmpty) {
              var lst = model.plVariations!.toList();
              lst.sort((a, b) => a.price!.compareTo(b.price!));
              min = orbiter.getVariationPrice(lst.first);
              max = orbiter.getVariationPrice(lst.last);
            }

            priceText = "${currency.format(min)} - ${currency.format(max)}";
          }

          return priceText;
        }

        if (showGrid) {
          return GestureDetector(
            onTap: (){
              try{
                addToCart(model);
              }
              catch(e){
                print(e.toString());
              }
            },
            child:
            Column(
              children: [
                Expanded(
                  flex: 3,
                  //child:Image.network(model.img!, height: 200, fit: BoxFit.fitHeight).paddingAll(spacing_control),
                  child: commonCacheImageWidget(model.img, 80, fit: BoxFit.contain),//.paddingAll(spacing_control),
                ),
                Expanded(
                  flex: 4,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(model.name!, maxLines: 2, softWrap: true, overflow: TextOverflow.ellipsis, style: boldTextStyle(size: textSizeMedium.toInt()), textScaleFactor: textScale,),
                      Text(model.description!, maxLines: 2, softWrap: true, overflow: TextOverflow.ellipsis, style: primaryTextStyle(size: textSizeSMedium.toInt()), textScaleFactor: textScale),
                      //Text(model.composition, maxLines: 4, softWrap: true, overflow: TextOverflow.ellipsis, style: boldTextStyle(size: textSizeLarge.toInt())).paddingAll(spacing_control),
                    ],
                  ),
                ),
                Expanded(flex: 3,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: <Widget>[
                      Expanded( flex: 5, child: Text(getPrice(), textScaleFactor: textScale, style: primaryTextStyle(size: textSizeSMedium.toInt(), fontFamily: fontBold)),),
                  Expanded( flex: 5, child: TextButton.icon(onPressed: null,
                        style: ButtonStyle(backgroundColor: MaterialStateProperty.resolveWith((states) => (orbiter.getQuantity(model.stock) > orbiter.getQuantity(model.alert)? grocery_textGreenColor : (orbiter.getQuantity(model.stock) > 0.0? grocery_color_yellow : grocery_textRedColor))),
                            padding: MaterialStateProperty.resolveWith((states) => const EdgeInsets.symmetric(horizontal: spacing_control_half, vertical: spacing_control_half),)),
                        //padding: ,
                        icon: const Icon(Icons.bookmark, color: grocery_color_white,size: textSizeSmall),
                        label: Text("${(orbiter.getQuantity(model.stock) > 0? orbiter.formatQuantity(orbiter.getQuantity(model.stock)) : grocery_out_of_stock)}", textScaleFactor: textScale, style: primaryTextStyle(size: textSizeSMedium.toInt(), color: grocery_color_white, fontFamily: fontBold)),
                      )),
                    ],
                  ),)

              ],
            )
          );
        }
        else{
          return GestureDetector(
            onTap: (){
              try{
                addToCart(model);
              }
              catch(e){
                print(e.toString());
              }
            },
            child:  Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  flex:2,
                  //alignment: Alignment.centerLeft,
                  //child: ImageManager.fetchImage("${model.id}", model.img).paddingAll(spacing_control),
                  child: commonCacheImageWidget(model.img, 60, fit: BoxFit.contain).paddingAll(spacing_control_half),
                  //child: Image.network(model.img!, height: 100, fit: BoxFit.fitHeight).paddingAll(spacing_control),

                ),
                Expanded(
                  flex: 5,
                  child:
                  IntrinsicHeight(
                      child:
                      Column(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                              flex: 0,
                              child:
                              Text(model.name!, maxLines: 1, softWrap: false, overflow: TextOverflow.ellipsis, style: boldTextStyle(size: textSizeNormal.toInt()), textScaleFactor: textScale)),
                          Expanded(
                              flex: 0,
                              child:
                              Text(model.description!, maxLines: 3, softWrap: true, overflow: TextOverflow.ellipsis, style: primaryTextStyle(size: textSizeMedium.toInt()), textScaleFactor: textScale)),
                          //Text(model.composition, maxLines: 4, softWrap: true, overflow: TextOverflow.ellipsis, style: boldTextStyle(size: textSizeLarge.toInt())).paddingAll(spacing_control),
                        ],
                      )),
                ),
                Expanded(
                  flex: 3,
                  child: IntrinsicHeight(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      //mainAxisSize: MainAxisSize.max,
                      children: <Widget>[
                        Expanded( flex: 1, child: Text(getPrice(), style:primaryTextStyle(size: textSizeMedium.toInt(), fontFamily: fontBold), textScaleFactor: textScale),),
                        Expanded(flex: 0, child: TextButton.icon(onPressed: null,
                          style: ButtonStyle(backgroundColor: MaterialStateProperty.resolveWith((states) => (orbiter.getQuantity(model.stock) > orbiter.getQuantity(model.alert)? grocery_textGreenColor : (orbiter.getQuantity(model.stock) > 0? grocery_color_yellow : grocery_textRedColor))),
                              padding: MaterialStateProperty.resolveWith((states) => const EdgeInsets.symmetric(horizontal: spacing_control_half, vertical: spacing_control_half),)),
                          //padding: ,
                          icon: const Icon(Icons.bookmark, color: grocery_color_white,),
                          label: Text("${(orbiter.getQuantity(model.stock) > 0? orbiter.formatQuantity(orbiter.getQuantity(model.stock)) : grocery_out_of_stock)}", textScaleFactor: textScale,  style: primaryTextStyle(size: textSizeSMedium.toInt(), color: grocery_color_white, fontFamily: fontRegular)),
                        )),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }

      }

      Widget storeDeal(Product model, int pos) {
        return GestureDetector(
          onTap: () {
            try{
              addToCart(model);
            }
            catch(e){
              print(e.toString());
            }
          },
          child: Container(
            decoration: boxDecorationWithShadow(
              boxShadow: defaultBoxShadow(),
              borderRadius: BorderRadius.circular(8),
              backgroundColor: context.cardColor,
            ),
            margin: const EdgeInsets.all(spacing_standard),
            padding: const EdgeInsets.symmetric(horizontal: spacing_standard_new, vertical: spacing_standard_new),
            child: productDetails(model),
          ),
        );
      }

      if (orbiter.searchTerm.isNotEmpty){
        //searchController.text = orbiter.searchTerm;
        setState(() {
          searchController.text = orbiter.searchTerm;
          //runSearch(args: orbiter.searchTerm);

        });
      }

      /*Widget searchResult(String text, Color color){
        return Container(
            width: width * 0.90,
            height: height * 0.60,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                //commonCachedNetworkImage(Grocery_ic_Search, fit: BoxFit.fitHeight, height: 170),
                Text(text, style: boldTextStyle(size: textSizeXLarge.toInt(), color: color)),
              ],
            )
        );
      }*/

      /*Widget showProductList(List<Product> mList) {
        //var vars = Variation().select().toList(preload: true);
        if (showGrid == true){
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            scrollDirection: Axis.vertical,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, childAspectRatio: 2.5),
            itemCount: mList.length,
            itemBuilder: (context, index) {
              return storeDeal(mList[index], index);
            },
          );
        }
        else{
          return ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            scrollDirection: Axis.vertical,
            itemCount: mList.length,
            itemBuilder: (context, index) {
              return storeDeal(mList[index], index);
            },
          );
        }
      }*/

      /*Widget runSearch({String? args}) {
        //List<Product> mList = [];
        var results = searchResult(grocery_lbl_search_empty, grocery_light_gray_color);

        //if (args!.isNotEmpty) {
          try{
            var query = (Product()
                .select()
                .business_id.equals(business_id));

            if (args!.isNotEmpty)
            {
              query = query.and
                .name
                .startsWith(args)
                .or
                .sku.equals(args)
                .or
                .description
                .startsWith(args)
                .or
                .custom_field1
                .contains(args)
                .or
                .manufacturer
                .startsWith(args);
            }

            if (args!.isEmptyOrNull){
              query = query.top(20);
            }

            switch (iSortBy) {
              case 1:
                query = query.orderByDesc("dateAdded");
                break;
              case 2:
                query = query.orderBy("name");
                break;
              case 3:
                query = query.orderByDesc("name");
                break;
              default:
                query = query.orderByDesc("dateAdded");
                break;
            }

            query.toList().then((value) => products = value).whenComplete((){
              if (products.isNotEmpty) {
                try{
                  setState((){
                    results = showProductList(products);
                  });
                }
                catch(e){
                  print(e.toString());
                }
              }
              else{
                try{
                  setState((){
                    results = searchResult(grocery_lbl_no_match_found, grocery_light_gray_color);
                  });
                }
                catch(e){
                  print(e.toString());
                }
              }
            });
          }
          catch(e){
            print(e.toString());
          }
        return results;
      }*/

      AlertDialog sortDialog = AlertDialog(
        //titlePadding: EdgeInsets.all(spacing_standard_new),
        titlePadding: const EdgeInsets.all(spacing_standard_new),
        contentPadding: const EdgeInsets.only(left: spacing_standard, right: spacing_standard, bottom: spacing_standard),
        actionsPadding: const EdgeInsets.all(spacing_standard_new),
        actionsAlignment: MainAxisAlignment.center,
        backgroundColor: context.cardColor,
        shape: const RoundedRectangleBorder(
            borderRadius:
            BorderRadius.all(Radius.circular(20.0))),
        title: SizedBox(
          width: (width * 0.3),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
               Align(alignment: Alignment.centerLeft, child: Text(grocery_sort_by_label, textScaleFactor: textScale,),),
              Align(alignment: Alignment.centerRight, child: const Icon(Icons.close, size: textSizeNormal).onTap((){Navigator.pop(context);}),),
            ],
          ),
        ),
        content: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                //crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  RadioListTile<int>(
                    controlAffinity: ListTileControlAffinity.trailing,
                    title: Text(grocery_sort_by_recent, textScaleFactor: textScale,),
                    value: 1,
                    groupValue: iSortBy,
                    onChanged: (val) =>
                        setState(() =>
                        iSortBy = val!),
                  ),
                  RadioListTile<int>(
                    controlAffinity: ListTileControlAffinity.trailing,
                    title: Text(grocery_sort_by_title_asc, textScaleFactor: textScale,),
                    value: 2,
                    groupValue: iSortBy,
                    toggleable: true,
                    onChanged: (val) =>
                        setState(() =>
                        iSortBy = val!),
                  ),
                  RadioListTile<int>(
                    controlAffinity: ListTileControlAffinity.trailing,
                    title: Text(grocery_sort_by_title_desc, textScaleFactor: textScale,),
                    value: 3,
                    groupValue: iSortBy,
                    toggleable: true,
                    enableFeedback: true,
                    onChanged: (val) =>
                        setState(() => iSortBy = val!),
                  ),
                ],
              );
            }),
        actions: [
          Center(
            child: TextButton(child: Text(grocery_sort_by_action, style: TextStyle(color: grocery_colorPrimary_light, fontSize: textSizeLarge, fontFamily: fontSemiBold), textScaleFactor: textScale,),onPressed: (){
              setState(() {
                try{
                  //searchResults = runSearch(args: searchText);
                  runSearch(args: searchText);
                }
                catch(e){
                  print(e.toString());
                }

                Navigator.pop(context);
              });
              Notify.toast(message: "Sorted Successfully", type: MessageType.Success);
            },),
          )
        ],
      );

      () async {
        try{
          var listClick = [
            GroceryDashBoardScreen(orbiter),
            CustomersWidget(orbiter),
            SuspendedSales(orbiter),
            ActualSales(orbiter),
          ];

          menus = Menus(orbiter, listClick);
        }
        catch(e){
          print(e.toString());
        }

      }.call();


      final menu = TextButton.icon(
        onPressed: () {
          setState(() {
            try{
              menus.launch(context);
            }
            catch(e){
              print(e.toString());
            }
          });
        },
        icon: const Icon(Icons.grid_view_rounded, color: grocery_textColorPrimary, size: appTitleSize),
        label:  Text('Menu', style: TextStyle(color: grocery_textColorPrimary, fontSize: appTitleSize), textScaleFactor: textScale,),
      );

      isFirstTime = (orbiter.isFirstTime?? true);
      //searchResults = searchResult(grocery_lbl_search_empty, grocery_light_gray_color);

      //if (isFirstTime == true){
      if (false){
        return OrbiterWebApp(web_address: "https://" +  app_base_url + "/business/register",orbiter: orbiter);
      }
      else if (orbiter.isLoggedIn == true && orbiter.LoggedInUser != null && orbiter.LoggedInUser!.username!.isNotEmpty){
        /*setState(() {
          searchResults = showProductList(products);
        });*/

        /*setState(() {
          try{
            //searchResults = runSearch(args: searchText);
            runSearch(args: searchText);
          }
          catch(e){
            print(e.toString());
          }
        });*/

        return
          Scaffold(
            appBar: AppBar(
              title: Padding(padding: EdgeInsets.only(left: width * 0.10), child: Text("Products", style: TextStyle(color: blackColor, fontSize: appTitleSize), textScaleFactor: textScale,)),
              leadingWidth: 100.0,
              leading: menu,
              elevation: 0.0,
              scrolledUnderElevation: 5.0,
            ),
            body: SingleChildScrollView(
              //padding: const EdgeInsets.only(left: spacing_standard, right: spacing_standard_new),
              child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Align(alignment: Alignment.topCenter,
                          heightFactor: 1.1,
                          child:
                        Container(
                          width: width * 0.95,
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: grocery_lightGrey, width: 2)
                          ),
                          child: Container(
                              //padding: const EdgeInsets.all(spacing_control_half),
                              child: IntrinsicHeight( child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: <Widget>[
                                    Expanded(flex: 9, child: TextFormField(
                                      controller: searchController,
                                      textInputAction: TextInputAction.search,
                                      style: primaryTextStyle(color: grocery_textColorPrimary, fontFamily: fontRegular, size: textSizeNormal.toInt()),
                                      decoration: InputDecoration(
                                        constraints: BoxConstraints(maxWidth: width * 0.95),
                                        prefixIcon: const Icon(Icons.search, color: grocery_lightGrey, size: textSizeLarge),
                                        border: InputBorder.none,
                                        hintText: grocery_lbl_search_hint,
                                        hintStyle: primaryTextStyle(color: grocery_lightGrey, size: textSizeSMedium.toInt()),
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
                                        searchText = val;
                                        orbiter.searchTerm = searchText;
                                        /*setState(() {
                                          searchResults = runSearch(args: val);
                                        });*/
                                      },
                                      onFieldSubmitted: (p){
                                        setState(() {
                                          //searchResults = runSearch(args: searchText);
                                          runSearch(args: searchText);
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
                    //10.height,
                    Container(
                      width: width * 0.90,
                      child: AppBar(
                        automaticallyImplyLeading: false,
                        primary: false,
                        centerTitle: false,
                        elevation: 0.00,
                        leadingWidth: 100,
                        leading: Container(),
                          /*Align(alignment: Alignment.center,
                            child: Text("${products.length} ${(products.length == 1? "Product" : "Products")}", style: primaryTextStyle(color: grocery_textColorPrimary, fontFamily: fontRegular, size: appTitleSize.toInt()), textScaleFactor: 0.85,),
                          )*/
                        actions: <Widget>[
                          IconButton(icon: Icon((showGrid? Icons.list : Icons.grid_view)), color: grocery_textColorPrimary, iconSize: textSizeXXLarge, onPressed: (){
                            setState((){
                              showGrid = (!showGrid);
                            });
                          },),
                          IntrinsicHeight(//alignment: Alignment.center,
                            child: VerticalDivider(
                              indent: 10.0,
                              endIndent: 10.0,
                              color: grocery_light_gray_color,
                              thickness: 2,
                            ),
                          ),
                          TextButton.icon(icon: const Icon(Icons.sort, color: grocery_textColorPrimary, size: textSizeXLarge),
                              label: Text("Sort By", style: TextStyle(color: grocery_textColorPrimary, fontSize: appTitleSize, fontFamily: fontSemiBold), textScaleFactor: textScale,),
                              onPressed: (){
                                showDialog<void>(context: context, builder: (BuildContext builder) => sortDialog, barrierDismissible: false, );
                              }
                          ),
                        ],
                      ),
                    ),
                    //20.height,
                    SizedBox(
                      width: width * 0.85,
                      child:
                      Column(
                          children:
                          <Widget>[
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              scrollDirection: Axis.vertical,
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  childAspectRatio: 0.75,
                              ),
                              itemCount: products.length,
                              itemBuilder: (context, index) {
                                return storeDeal(products[index], index);
                              },
                            ).visible(showGrid == true && products.isNotEmpty),
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              scrollDirection: Axis.vertical,
                              itemCount: products.length,
                              itemBuilder: (context, index) {
                                return storeDeal(products[index], index);
                              },
                            ).visible(showGrid == false && products.isNotEmpty),
                            Container(
                                width: width * 0.95,
                                height: height * 0.60,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(grocery_lbl_no_match_found, style: boldTextStyle(size: textSizeNormal.toInt(), color: grocery_light_gray_color)),
                                  ],
                                )
                            ).visible(products.isEmpty),
                          ]
                      ),
                    ),
                  ]
              ),
            ),
            floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
            floatingActionButton: Container(
              width: width * 0.20,
              height: width * 0.20,
              margin: const EdgeInsets.only(bottom: spacing_standard_new, right: spacing_standard_new),
              child: FittedBox(
                child: Stack(
                  alignment: const Alignment(1.4, -1.0),
                  children: [
                    FloatingActionButton(
                      onPressed: () {
                        //orbiter.shoppingCart = cart;
                        ShoppingCart(orbiter).launch(context);
                      },
                      child: Icon(Icons.shopping_bag, color: grocery_icon_blue_dark,),
                      backgroundColor: grocery_icon_blue,
                    ),
                    Consumer<ShoppingCartModel>(
                        builder: (context, cart, child) => Container(             // This the Badge
                      child: Center(
                        child: Text('${cart.Count}', style: TextStyle(color: grocery_color_cart_counter, fontSize: textSizeSMedium)),
                      ),
                      padding: EdgeInsets.all(3),
                      constraints: BoxConstraints(minHeight: 24, minWidth: 24),
                      decoration: BoxDecoration( // This controls the shadow
                        boxShadow: [
                          BoxShadow(
                              spreadRadius: 1,
                              blurRadius: 5,
                              color: grocery_lightGrey)
                        ],
                        borderRadius: BorderRadius.circular(16),
                        color: grocery_color_cart_counter_bg,  // The color of the Badge
                      ),
                    ).visible(cart.isNotEmpty)),
                  ],
                ),
              ),
            ),
          );
      }
      else{
        return AppLogin(orbiter: orbiter);
      }
  }
}

//class Menus extends StatelessWidget{
class Menus extends StatefulWidget {

  final listClick;
  final OrbiterHelper orbiter;

  Menus(this.orbiter, this.listClick);

  @override
  _MenusState createState() => _MenusState();
}

class _MenusState extends State<Menus> {
  final DateTime today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

  int iProdCount = 0, iCustCount = 0, iSuspCount = 0, iTodayCount = 0;
  late String _ProductCount = "", _CustomerCount = "", _SuspendedCount = "", _TodayCount = "";
  bool _disposed = false;

  late ShoppingCartModel shoppingCart;

  @override
  void dispose() {
    super.dispose();
    changeStatusColor(app_colorAppbar);
    _disposed = true;
  }

  void setCounters(){
    int business_id = -1;
    if (widget.orbiter.LoggedInUser != null){
      business_id = (widget.orbiter.LoggedInUser!.business_id?? -1);
    }
    () async {
        iProdCount = (await Product().select().business_id.equals(business_id).toCount());
        iCustCount = (await Customer().select().name.not.equals('Walk-In Customer').and.business_id.equals(business_id).toCount());
        iSuspCount = (await Sale().select().business_id.equals(business_id).and.status.equals('draft').toCount());
        iTodayCount = (await Sale().select().business_id.equals(business_id).and.status.equals('final').and.dateAdded
            .greaterThanOrEquals(today)
            .toCount());
      }.call().then((_) => setCountText());
  }

  void setCountText(){
    if (!_disposed){
      setState(() {
        _ProductCount = "${formatInteger.format(iProdCount)}" +  (iProdCount == 1? orb_menu_product : orb_menu_products);
        _CustomerCount = "${formatInteger.format(iCustCount)}" +  (iCustCount == 1? orb_menu_customer : orb_menu_customers);
        _SuspendedCount = "${formatInteger.format(iSuspCount)}" +  (iSuspCount == 1? orb_menu_suspended_sale : orb_menu_suspended_sales);
        _TodayCount = "${formatInteger.format(iTodayCount)}" +  (iTodayCount == 1? orb_menu_sale : orb_menu_sales);
      });
    }
  }

  @override
  void initState() {
    try{
      super.initState();
      shoppingCart = Provider.of<ShoppingCartModel>(context, listen: false);
      setCounters();

    }
    catch(e){
      print(e.toString());
    }
  }


  //variable to check if the app is syncing
  bool isSyncing = false;
  void hideProgress(){
    setState((){
      isSyncing = false;
    });
  }

  List<IconData> listImage = [
    Icons.layers,
    Icons.group,
    Icons.archive,
    Icons.insert_chart,
  ];

  var listText = [
    grocery_menu_products,
    grocery_menu_customers,
    grocery_menu_suspended,
    grocery_menu_sales,
  ];

  var listIconBGColor = [
    grocery_icon_blue,
    grocery_icon_purple,
    grocery_icon_orange,
    grocery_icon_green,
  ];

  var listBGColor = [
    grocery_icon_blue_bg,
    grocery_icon_purple_bg,
    grocery_icon_orange_bg,
    grocery_icon_green_bg,
  ];

  var listIconColor = [
    grocery_icon_blue_dark,
    grocery_icon_purple_dark,
    grocery_icon_orange_dark,
    grocery_icon_green_dark,
  ];

  var listSubtext = [];


  @override
  Widget build(BuildContext context) {
    var width = MediaQuery.of(context).size.width;
    var height = MediaQuery.of(context).size.height;
    var textScale = width < 600? 0.85 : MediaQuery.of(context).textScaleFactor;

    String greeting() {
      var hour = DateTime.now().toUtc().add(Duration(hours: 1)).hour;
      if (hour < 12) {
        return grocery_greeting_morning;
      }
      if (hour < 16) {
        return grocery_greeting_afternoon;
      }
      return grocery_greeting_evening;
    }

    String period() {
      var hour = DateTime.now().toUtc().add(Duration(hours: 1)).hour;

      if (hour < 16) {
        return "day";
      }
      return "night";
    }

    Future<bool> isConnected() async => await Connectivity().checkConnectivity().then((value) {
        var connectivityResult = value;
        if ((connectivityResult == ConnectivityResult.mobile) || (connectivityResult == ConnectivityResult.wifi)) {
          return true;
        }
        else{
          return false;
        }
      });

    //() async{
      try{

        setState(() {
          setCounters();
        });

        listSubtext = [
          _ProductCount,
          _CustomerCount,
          _SuspendedCount,
          _TodayCount,
        ];

      }
      catch(e){
        print(e.toString());
      }
    //}.call();

    menuCard({Color? backgroundColor, String? subject, amount}) {
      ThemeData themeData = Theme.of(context);
      return Card(
        clipBehavior: Clip.antiAliasWithSaveLayer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(spacing_control),
        ),
        child: Container(
          color: backgroundColor,
          height: spacing_xxLarge,
          child: Container(
            padding:
            EdgeInsets.only(bottom: spacing_standard, left: spacing_standard),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(subject!,
                    style: primaryTextStyle()),
                Text("$amount",
                    style: primaryTextStyle()),
              ],
            ),
          ),
        ),
      );
    }

    Widget mMenuOption(var icon, var value, Widget tag, Color iconColor, Color iconBGColor, Color bgColor, {var subtext = ""}) {
      //var width = MediaQuery.of(context).size.width;
      return GestureDetector(
        onTap: () {
          Navigator.pop(context);
          tag.launch(context);
        },
        child: Container(
          decoration: boxDecorationWithShadow(
            boxShadow: defaultBoxShadow(shadowColor: grocery_lightGrey, offset: Offset(-0.5, 3.5)),
            borderRadius: BorderRadius.circular(spacing_xlarge),
            backgroundColor: context.cardColor,
          ),
          margin: EdgeInsets.only(top: spacing_middle, right: spacing_middle),
          //padding: EdgeInsets.all(spacing_standard_new),
          padding: EdgeInsets.symmetric(horizontal: spacing_standard_new, vertical: spacing_standard),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              Container(
                padding: EdgeInsets.symmetric(vertical: spacing_standard, horizontal: spacing_standard),
                decoration: boxDecoration(
                  radius: spacing_xxxLarge,
                  bgColor: appStore.isDarkModeOn ? scaffoldDarkColor : iconBGColor,
                ),
                child: Icon(icon, color: iconColor, size: height * 0.040,),
              ),
              Align(alignment: Alignment.bottomLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(subtext?? "", style: primaryTextStyle(color:  grocery_Color_black, size: textSizeSMedium.toInt(),), textScaleFactor: textScale),
                    Text(value, style: primaryTextStyle(color:  iconColor, size: textSizeMedium.toInt(), fontFamily: fontBold), textScaleFactor: textScale),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    /*AlertDialog settingsDialog = AlertDialog(
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
        width: (width * 0.3),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Align(alignment: Alignment.centerLeft, child: Text(grocery_default_printer_label),),
            Align(alignment: Alignment.centerRight, child: const Icon(Icons.close, size: textSizeLarge).onTap((){Navigator.pop(context);}),),
          ],
        ),
      ),
      content: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              //crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    scrollDirection: Axis.vertical,
                    itemCount: printers.length,
                    itemBuilder: (context, index) {
                      return RadioListTile<int>(
                        controlAffinity: ListTileControlAffinity.trailing,
                        title: Text("${printers[index].name} (${printers[index].address})"),
                        value: 2,
                        groupValue: iPrinter,
                        toggleable: true,
                        onChanged: (val) =>
                            setState(() =>
                            iPrinter = val!),
                      );
                    }
                ).visible(printers.isNotEmpty),
                Container(
                  child: Text("No Printers Found").visible(printers.isEmpty),
                )
              ],
            );
          }),
      actions: [
        Center(
          child: StatefulBuilder(builder: (context, setState){
            return TextButton(child: const Text(grocery_sort_by_action, style: TextStyle(color: grocery_colorPrimary_light, fontSize: textSizeLarge, fontFamily: fontSemiBold),),onPressed: (){
              setState(() => Navigator.pop(context));
              Notify.toast(message: "Default Printer Set", type: MessageType.Success);
            });
          }),
        )
      ],
    );*/

    String getVersion() {
      String result = "";

      //defaultCon

      PackageInfo.fromPlatform().then((PackageInfo packageInfo) {
        String packageName = "com.orbiterplus.com", appName = "OrbiterPlus", version = "", buildNumber = "";

        appName = packageInfo.appName;
        packageName = packageInfo.packageName;
        version = packageInfo.version;
        buildNumber = packageInfo.buildNumber;

        result = "$appName $packageName V$version B$buildNumber";
      });

      return result;
    }

    String appVersion = getVersion();

    return Scaffold(
      //backgroundColor: grocery_disabled_button_color,
      appBar: AppBar(
        elevation: 0.00,
        leading: TextButton.icon(
          onPressed: () {finish(context);},
          icon: Icon(Icons.close, color: grocery_textColorPrimary, size: appTitleIconSize),
          label: Text('Close', textScaleFactor: textScale, style: TextStyle(color: grocery_textColorPrimary, fontSize: appTitleSize),),
        ),
        leadingWidth: 100,
        actions: <Widget>[
          Stack(children: [
            TextButton.icon(
              onPressed: () async {
                if (await isConnected() != false) {
                  Notify.showLoading();
                  try {
                    (await syncProducts(widget.orbiter)
                        .whenComplete(() async {
                      (await syncCustomers(widget.orbiter)
                          .whenComplete(() async {
                        (await syncSales(widget.orbiter).whenComplete(() =>
                            Notify.hideLoading()));
                        Notify.hideLoading();
                      }));
                    }));
                  }
                  catch(e){
                    Notify.toast(message: e.toString(), type: MessageType.Alert);
                    print(e.toString());
                  }
                  finally{
                    Notify.hideLoading();
                  }
                  Notify.toast(message: "Data Synced Successfully", type: MessageType.Success);
                }
                else{
                  Notify.toast(message: "No Internet Connection", type: MessageType.Alert);
                }
                //finish(context);
              },
              icon: Icon(Icons.recycling_rounded, color: grocery_textBlueColor, size: textSizeNormal),
              label: Text('Sync Data', textScaleFactor: textScale, style: TextStyle(color: grocery_textBlueColor, fontSize: appTitleSize)),
            ).paddingRight(spacing_standard),
            /*isSyncing?
            Center( child: CircularProgressIndicator(color: app_colorPrimary, strokeWidth: 5.0)).paddingSymmetric(vertical: spacing_standard_new, horizontal: spacing_standard_new,)//.paddingLeft(spacing_xxLarge)
                : Container()
            ,*/
          ]),
          TextButton.icon(
            onPressed: () {
              try{
                Notify.showLoading();
                widget.orbiter.isLoggedIn = false;
                widget.orbiter.LoggedInUser = User();
                shoppingCart.removeAll();
                //MyApp().launch(context, isNewTask: true);
                Navigator.of(context).pushAndRemoveUntil(
                  // the new route
                  MaterialPageRoute(
                    builder: (BuildContext context) => GroceryDashBoardScreen(OrbiterHelper()),
                  ),

                  // this function should return true when we're done removing routes
                  // but because we want to remove all other screens, we make it
                  // always return false
                      (Route route) => false,
                );
              }
              catch(e){
                print(e.toString());
              }
              finally{
                Notify.hideLoading();
              }
            },
            icon: Icon(Icons.logout, color: grocery_textRedColor, size: appTitleIconSize),
            label: Text('Logout', textScaleFactor: textScale, style: TextStyle(color: grocery_textRedColor, fontSize: appTitleSize)),
          ),
          // add more IconButton
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              //width: width * 0.95,
              padding: EdgeInsets.all(spacing_standard),
              child:
              Container(
                //padding: EdgeInsets.symmetric(vertical: spacing_control, horizontal: spacing_control),
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage(period() == "night"? grocery_greeting_pm_bg : grocery_greeting_am_bg),
                    fit: BoxFit.fill,
                    alignment: Alignment.center,
                      scale: 0.45,
                  ),
                ),
                child:
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Container(
                            padding: EdgeInsets.only(top: spacing_standard_new, left: spacing_standard_new),
                            child:
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("Hey, ", textScaleFactor: textScale, style: primaryTextStyle(color:  period() == "night"? grocery_color_white : grocery_Color_black, size: textSizeNormal.toInt())),
                              Text((widget.orbiter.LoggedInUser != null? (widget.orbiter.LoggedInUser!.firstname?? 'Cashier') : 'Cashier'), textScaleFactor: textScale, style: primaryTextStyle(color:  period() == "night"? grocery_color_white : grocery_Color_black, size: textSizeNormal.toInt(), fontFamily: fontBold )),
                            ],
                          )//.paddingOnly(top: spacing_standard, left: spacing_standard_new),
                        ).paddingOnly(top: spacing_standard_new, left: spacing_standard, bottom: spacing_standard_new),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Container(
                          height: height * 0.10,
                          child: Align(alignment: Alignment.topLeft, child: Text(greeting(), textScaleFactor: (textScale - 0.10), style: primaryTextStyle(color: period() == "night"? grocery_color_white : grocery_Color_black, size: textSizeNormal.toInt(), fontFamily: fontBold))).paddingOnly(top: spacing_control, left: spacing_xlarge)
                          )//.paddingOnly(left: spacing_standard, bottom: spacing_control),
                      ],
                    ),
                  ],
                ),
              ),
            ),//.paddingOnly(top: width * 0.03, bottom: width * 0.10, left: width * 0.03, right: width * 0.03),
            GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.25,
                mainAxisSpacing: spacing_control_half,
                crossAxisSpacing: spacing_control_half,
              ),
              //padding: EdgeInsets.all(0),
              itemCount: listImage.length,
              shrinkWrap: true,
              physics: ClampingScrollPhysics(),
              itemBuilder: (context, index) {
                return mMenuOption(listImage[index], listText[index], widget.listClick[index], listIconColor[index],listIconBGColor[index], listBGColor[index], subtext: listSubtext[index]).paddingLeft(spacing_standard_new);
              },
            ),
            Align(
              alignment: Alignment.bottomCenter,
              heightFactor: 0.65,
              child: commonCacheImageWidget(pillometer_full_logo, height * 0.35),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              heightFactor: 0.15,
              child: Text("${appVersion}"),
            ),
          ],
        ),
      ),
    );
  }
}
