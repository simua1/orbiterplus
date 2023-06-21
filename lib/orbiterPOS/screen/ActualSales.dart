import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:orbiterplus/model/model.dart';
import 'package:orbiterplus/orbiterPOS/model/AppModel.dart';
import 'package:orbiterplus/orbiterPOS/utils/AppStrings.dart';
import 'package:orbiterplus/orbiterPOS/utils/AppColors.dart';
import 'package:orbiterplus/orbiterPOS/utils/AppConstant.dart';
import 'package:orbiterplus/orbiterPOS/utils/OrbiterHelpers.dart';

class ActualSales extends StatefulWidget {
  final OrbiterHelper orbiter;

  const ActualSales(this.orbiter);

  @override
  ActualSalesState createState() => ActualSalesState();
}

class ActualSalesState extends State<ActualSales> {
  List<Sale> sales = [];
  int business_id = -1;

  String empty_string = "Loading...";

  /*bool isDisposed = false;
  @override
  void dispose() {
    super.dispose();
    isDisposed = true;
  }*/

  @override
  void initState() {
    super.initState();
    if (widget.orbiter.LoggedInUser != null){
      business_id = (widget.orbiter.LoggedInUser!.business_id?? -1);
    }

    (() async => sales = (await Sale().select().business_id.equals(business_id).and.status.equals('final').orderByDesc('dateAdded').toList(preload: true).whenComplete(() => setState(() => empty_string = (sales.length <=0? grocery_empty_sales_label: "" ))))).call();

  }

  @override
  Widget build(BuildContext context) {
    var width = MediaQuery.of(context).size.width;
    var height = MediaQuery.of(context).size.height;
    var textScale = width < max_width? text_scale_factor : MediaQuery.of(context).textScaleFactor;
    width = width <= max_width? width : max_width; //restrict width to the specified maximum

   /* (() async => sales = (await Sale().select().business_id.equals(business_id).and.status.equals('final').toList(preload: true))).call();*/

    Widget ActualSale(Sale model, int index, ) {

      return Container(
        width: width * 0.90,
        padding: EdgeInsets.symmetric(
            horizontal: spacing_standard, vertical: spacing_control),
        margin: EdgeInsets.all(spacing_control),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              flex: 4,
              child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(((!model.title.isEmptyOrNull)
                            ? model.title.toString()
                            : "$orbiter_sale_ref ${model.unique_id}"),
                            style: primaryTextStyle(
                                size: textSizeNormal.toInt()),textScaleFactor: textScale),
                        spacing_large
                            .toInt()
                            .width,
                        Text("$orbiter_sale_ref ${model.unique_id}",
                            style: primaryTextStyle(
                                size: textSizeNormal.toInt()), textScaleFactor: textScale).visible(
                            !model.title.isEmptyOrNull),
                      ],),
                    //spacing_middle.toInt().height,
                    Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Expanded(
                          flex: 1,
                          child: Text("${model.plSale_items!.length} ${(model.plSale_items!.length == 1? "Item" : "Items")}",
                              style: primaryTextStyle(
                                  size: textSizeMedium.toInt()),textScaleFactor: textScale),
                        ),
                        Expanded(
                          flex: 4,
                          child: Text("${DateFormatter(model.dateAdded!).longdate}",
                              style: primaryTextStyle(
                                  size: textSizeMedium.toInt(),
                                  color: grocery_darkGrey),textScaleFactor: textScale),
                        ),
                        Expanded(
                          flex: 1,
                          child: IconButton(
                            iconSize: textSizeXLarge,
                            tooltip: 'Print Receipt',
                            icon: Icon(Icons.print), onPressed: () { (() async {
                            try{
                              await widget.orbiter.printReceipt(model);
                            }
                            catch (e, s){
                              print(s.toString());
                            }
                          }).call(); },

                          ),
                        ),
                    ],)
                  ]),
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
        //toolbarHeight: .0,
        title: Padding(padding: EdgeInsets.only(left: spacing_standard_new,), child: Text(grocery_actual_title, style: TextStyle(color: blackColor, fontSize: textSizeNormal), textScaleFactor: textScale,)),
        elevation: 0.0,
        scrolledUnderElevation: 5.0,
        actions: [
          Padding(padding: EdgeInsets.only(right: spacing_standard_new, ),
            child: Container(),
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
                    Text(empty_string, style: boldTextStyle(size: textSizeNormal.toInt(), color: grocery_lightGrey), textScaleFactor: textScale),
                  ],
                )
            ).visible(sales.isEmpty),
            spacing_standard_new.toInt().height,ListView.builder(
              scrollDirection: Axis.vertical,
              itemCount: sales.length,
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                return ActualSale(sales[index], index);
              },
            ),
          ],
        ),
      ),
    ).paddingOnly(top: spacing_large);
  }
}