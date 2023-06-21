import 'dart:collection';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:orbiterplus/model/model.dart';
import 'package:orbiterplus/orbiterPOS/utils/AppStrings.dart';

import 'package:orbiterplus/orbiterPOS/utils/AppNumbers.dart';
import 'package:orbiterplus/orbiterPOS/utils/OrbiterHelpers.dart';

enum SaleStatus{
  completed(grocery_sale_status_completed),
  pending(grocery_sale_status_pending),
  suspended(grocery_sale_status_suspended),
  returned(grocery_sale_status_returned),
  paid(grocery_sale_status_paid);

  const SaleStatus(this.text);

  final String text;
}

class NotificationModel {
  var name = "";
  var duration = "";
  var description = "";

  NotificationModel(this.name, this.duration, this.description);
}


class ShoppingCartModel with ChangeNotifier {
  /// Internal, private state of the cart.
  final List<Sale_item> _items = [];
  final sDiscountType = "Percent";
  double dDiscountVal = 0.0;
  OrbiterHelper orbiter = OrbiterHelper();

  ShoppingCartModel();

  /// An unmodifiable view of the items in the cart.
  UnmodifiableListView<Sale_item> get items => UnmodifiableListView(_items);
  
  double get SubTotal => _items.sumByDouble((itm) => ((orbiter.getPrice(itm)) * itm.quantity!) );
  double get Discount => (dDiscountVal != 0? ((sDiscountType == "Percent")? (SubTotal * (dDiscountVal/100)) : (SubTotal - dDiscountVal)) :  dDiscountVal);
  double get Amount => (SubTotal - Discount);
  double get Tax => ((orbiter.TaxRate != 0 && orbiter.InlineTax != 'includes')? (Amount * (orbiter.TaxRate/100)): 0.0);

  double get Total => (Amount + Tax);

  int get Count => _items.length;
  bool get isNotEmpty => (_items.length > 0);
  bool get isEmpty => (_items.length <= 0);
  String get sDiscountLabel => ((sDiscountType == "Percent")? "(${dDiscountVal}%)": "");
  String get sTaxLabel => ((orbiter.TaxRate>0 && orbiter.InlineTax != 'includes')? "(${orbiter.TaxRate}%)": "");

  /// Adds [item] to cart. This and [removeAll] are the only ways to modify the
  /// cart from the outside.
  void add(Sale_item item) {

    var itm = _items.firstWhereOrNull((it) => (it.productId == item.productId && (it.variationId == item.variationId || (item.variationId == null || item.variationId == -1))));
    if (itm == null){
      (() async => item.plProduct = await Product().getById(item.productId, preload: true)).call();
      _items.add(item);
    }else{
      itm.quantity = item.quantity;
    }

    // This call tells the widgets that are listening to this model to rebuild.
    this.notifyListeners();
  }

  void remove(Sale_item item) {
    _items.remove(item);
    // This call tells the widgets that are listening to this model to rebuild.
    this.notifyListeners();
  }

  void replace(Sale_item item, int index) {
    _items[index] = item;
    // This call tells the widgets that are listening to this model to rebuild.
    this.notifyListeners();
  }

  /// Removes all items from the cart.
  void removeAll() {
    _items.clear();
    // This call tells the widgets that are listening to this model to rebuild.
    this.notifyListeners();
  }

  int progress = 0;
  bool isLoading = false;
  void start() {
    isLoading = true;
    // This call tells the widgets that are listening to this model to rebuild.
    this.notifyListeners();
  }
  void stop() {
    isLoading = false;
    // This call tells the widgets that are listening to this model to rebuild.
    this.notifyListeners();
  }
}

enum PaymentMethod{
  Cash(grocery_payment_cash_label),
  Card(grocery_payment_card_label),
  Credit(grocery_payment_credit_label),
  Transfer(grocery_payment_transfer_label),
  Cheque(grocery_payment_cheque_label),
  SplitCardCash(grocery_payment_split_card_label),
  SplitTransferCash(grocery_payment_split_transfer_label),
  Other(grocery_checkout_other_payments_title);

  const PaymentMethod(this.text);
  final String text;
}

extension TextEditingControllerExt on TextEditingController {
  void selectAll() {
    if (text.isEmpty) return;
    selection = TextSelection(baseOffset: 0, extentOffset: text.length);
  }
}

class NumericTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    } else if (newValue.text.compareTo(oldValue.text) != 0) {
        final int selectionIndexFromTheRight =
          newValue.text.length - newValue.selection.end;
      final f = NumberFormat("#,###.##");
      final number =
      double.parse(newValue.text.replaceAll(f.symbols.GROUP_SEP, ''));
      final newString = f.format(number);
      return TextEditingValue(
        text: newString,
        selection: TextSelection.collapsed(
            offset: newString.length - selectionIndexFromTheRight),
      );
    } else {
      return newValue;
    }
  }
}

class OrbiterHelper{
  MethodChannel platform  = MethodChannel('orbiterplus.fixhire.com/printing');
  bool? isLoggedIn = false;
  User? LoggedInUser = User();
  String? modelName;
  bool? isFirstTime = true;
  double TaxRate = 0.0;
  String InlineTax = "";
  String searchTerm = "";

  OrbiterHelper(
      {this.modelName,
      this.isFirstTime,
      this.LoggedInUser});

  /*double getPrice(Sale_item saleItem){
    double _price = 0.0;

    if (saleItem.plProduct!.product_type == 'variable' && saleItem.plProduct!.plVariations != null && saleItem.variationId != null){
      var variation =  saleItem.plProduct!.plVariations!.firstWhere((element) => element.id == saleItem.variationId);
      _price = (variation != null && variation!.price != null? variation!.price : 0.0)!;
    }

    return _price;
  }*/



  double getPrice(Sale_item sale_item){
    double _price = 0.0;

    if (sale_item.plProduct!.product_type == 'variable' && sale_item.plProduct!.plVariations != null && sale_item.variationId != null){
      var variation =  sale_item.plProduct!.plVariations!.firstWhere((element) => element.id == sale_item.variationId);
      _price = (variation != null && variation!.price != null? variation!.price : 0.0)!;
    }
    else{
      _price = (sale_item.plProduct!.price?? 0.0);
    }

    if (InlineTax == 'includes'){
      _price += (TaxRate != 0? (_price * (TaxRate/100)): TaxRate);
    }

    return _price;
  }

  double getProductPrice(Product product){
    double _price = 0.0;

    _price = (product.price?? 0.0);

    if (InlineTax == 'includes'){
      _price += (TaxRate != 0? (_price * (TaxRate/100)): TaxRate);
    }

    return _price;
  }

  double getVariationPrice(Variation variation){
    double _price = 0.0;

    _price = (variation != null && variation.price != null? variation.price : 0.0)!;

    if (InlineTax == 'includes'){
      _price += (TaxRate != 0? (_price * (TaxRate/100)): TaxRate);
    }

    return _price;
  }

  bool validateProductQuantity(Product product, qty){
    if (product.stock! >= qty){
      return true;
    }
    else{
      Notify.toast(message: "Quantity exceeds current stock",
          type: MessageType.Alert);
      return false;
    }
  }

  bool validateVariationQuantity(Variation variation, qty){
    if (variation.stock! >= qty){
      return true;
    }
    else{
      Notify.toast(message: "Quantity exceeds current stock",
          type: MessageType.Alert);
      return false;
    }
  }

  String getTitle(Sale_item sale_item){
    String _title = "";

    if (sale_item.plProduct!.product_type == 'variable' && sale_item.plProduct!.plVariations != null && sale_item.variationId != null){
      var variation =  sale_item.plProduct!.plVariations!.firstWhere((element) => element.id == sale_item.variationId);
      _title = (variation != null && variation!.name != null? variation!.name : "")!;
    }

    return _title;
  }

  Future<bool?> printReceipt(Sale sale) async{
    //try {
      int printWidth = 384;
      bool cutPaper = false;
      var openDrawer = false;
      var beep = false;
      var copyCount = 1;
      var nCompressMethod = 0;
      List<String> items = [];

      sale = (await Sale().getById(sale.id, preload: true)?? sale);

      if (sale != null && sale.plSale_items != null) {
        (await Sale_item().select().saleId.equals(sale.id).toList(preload: true, loadParents: true)).forEach((item) {
          items.add(
              "${item.plProduct!.name } ${ ((item.plVariation != null && item.plProduct!.product_type == 'variable')? ' (' + item.plVariation!.name! + ') ' : '')} \r\n${(item.plProduct!.product_type == 'variable' ? currency2.format(getPrice(item)) : currency2.format(item.plProduct!.price))} x ${item.quantity} = ${currency2.format((item.quantity! * ((item!.plProduct!.product_type == 'variable' ? getPrice(item) : item!.plProduct!.price) ?? 0.0)))}");
        });

        String? logoUrl = this.LoggedInUser!.logo;
        String? businessName = this.LoggedInUser!.business_name; //;

      await platform.invokeMethod('PrintReceipt', <String, dynamic>{
        'printWidth': printWidth,
        'cutPaper': cutPaper,
        'openDrawer': openDrawer,
        'beep': beep,
        'copyCount': copyCount,
        'nCompressMethod': nCompressMethod,
        'logo': logoUrl,
        'businessName': businessName,
        'footer': grocery_receipt_footer,
        'copyright': grocery_receipt_copyright,
        'trnxid': "${sale.unique_id}",
        'totalAmount':
            "$grocery_receipt_total ${currency2.format(sale.totalAmount)}",
        'amountReceived':
            "$grocery_receipt_amount_received ${currency2.format(sale.amountReceived)}",
        'changeGiven':
            "$grocery_receipt_change_label ${currency2.format(sale.changeGiven)}",
        'salesTax':
            "$grocery_receipt_tax ${sale.taxLabel} ${(sale.taxAmount != null? currency2.format(sale.taxAmount) : "")}",
        'salesDiscount':
            "$grocery_receipt_discount ${sale.discountLabel} ${currency2.format(sale.discount)}",
        'status': "$grocery_receipt_status ${sale.status}",
        'paymentMethod':
            "$grocery_selected_payment_method_label ${sale.paymentMethod}",
        'trnxDate':
            "$grocery_receipt_date ${DateFormatter(sale.dateAdded!).shortdate}",
        'customer':
            "$grocery_receipt_customer ${(sale.plCustomer != null ? sale.plCustomer!.name : grocery_checkout_walkin_customer)}",
        'items': items,
      });
    }
    /*} on PlatformException catch (e) {
      _message = "Failed Execute Method: '${e.stacktrace}'.";
    }
    catch (e) {
      _message = e.toString();
    }*/
  }

  double getQuantity(dynamic arg){
    return arg.toString().toDouble();
  }

  String formatQuantity(double arg){
    String val = "";
    if ((arg % 1) == 0){
      val = formatInteger.format(arg);
    }
    else{
      val = formatDecimal.format(arg);
    }
    return val;
  }
}

