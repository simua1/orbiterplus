import 'dart:convert';

import 'package:nb_utils/nb_utils.dart';
import 'package:orbiterplus/model/model.dart';
import 'package:orbiterplus/orbiterPOS/model/AppModel.dart';
import 'package:http/http.dart' as http;
import 'package:orbiterplus/orbiterPOS/utils/AppConstant.dart';

Future<void> syncProducts(OrbiterHelper orbiter) async {
  int business_id = -1;
  if (orbiter.LoggedInUser != null){
    business_id = (orbiter.LoggedInUser!.business_id?? -1);
    //var r = Product().select().business_id.equals(business_id).delete(true);
  }
  /*final bool isInitialized = await OrbiterDbModel().initializeDB();
  if (isInitialized == true){*/
     Map<String, dynamic> params = {'per_page': '-1'};
    var headers = {'Content-Type': 'application/json', 'Accept': 'application/json', 'Authorization': 'Bearer ' + orbiter.LoggedInUser!.access_token! };

    var url = Uri.https(app_base_url, 'connector/api/product', params);
    var resp = (await http.get(url, headers: headers));
    var result = jsonDecode(resp.body);
    var data = result['data'];
    List<Product> products = [];
    //(await Product().select().business_id.equals(business_id).delete(true));
    //(await Variation().select().delete(true));
    List<int> keys = (await Product().select().business_id.equals(business_id).toListPrimaryKey());
    List<int> vkeys = (await Variation().select().toListPrimaryKey());
    for (var item in data) {
      if (item['id']
          .toString()
          .isInt
          && (keys.length <= 0 || !keys.contains(item['id']))
      ) {
        var product = Product();
        product.id = item['id'];
        if (business_id > 0){
          product.business_id = business_id;
        }
        product.name = item['name'];
        product.unit_name =  (item['unit'] != null? (item['unit']['unit_name']?? 'Unit(s)') : 'Unit(s)');//item['unit']
        product.product_type = item['type'];
        String description = (item['product_description']?? '').toString();
        //strip html tags
        RegExp exp = RegExp(
            r"<[^>]*>",
            multiLine: true,
            caseSensitive: true
        );

        description = description.replaceAll(exp, "");

        product.description = description;
        product.manufacturer = (item['brand'] != null? item['brand']['name'] : '').toString();
        product.img = (item['image_url']?? '').toString();
        product.custom_field1 = (item['product_custom_field1']?? '').toString();
        product.custom_field2 = (item['product_custom_field2']?? '').toString();
        product.custom_field3 = (item['product_custom_field3']?? '').toString();
        product.custom_field4 = (item['product_custom_field4']?? '').toString();
        var p_variations = item['product_variations'];

        List<Variation> variations = [];
        double _stocks = 0.0;
        for(var items in p_variations){
          for(var variation in items['variations']){
            int _id = int.parse((variation['id']?? -1).toString());
            Variation v = Variation();
            v.id = _id;

            v.sub_sku = variation['sub_sku'];
            v.name = variation['name'];
            v.price = double.parse((variation['default_sell_price']?? 0.0).toString());

            product.price = (p_variations.length == 1? v.price : ((product.price?? 0.0) + (v.price?? 0.0)));

            v.variation_id = _id;
            v.productId = product.id;
            var v_locations = variation['variation_location_details'];
            if (v_locations.isNotEmpty && v_locations.length > 0){
              var v_location = v_locations[0];
              v.unit_name = product.unit_name;
              v.stock = double.parse(((v_location != null && v_location['qty_available'] != null)? v_location['qty_available'] : 0.0).toString());
              _stocks += (v.stock?? 0.0);//increment the total stock for the product
            }

            //v.expiry_period = variation['product_id'];
            variations.add(v);
          }
        }
        //product.plVariations = variations;
        product.stock = _stocks;

        //var selling_price = var2['sell_price_inc_tax'];
        //product.price = double.parse(selling_price);
        product.alert = double.parse((item['alert_quantity']?? 0.0).toString());
        product.sku = item['sku']?? '';

        //product.stock = var2['variation_location_details'].length > 0? double.parse(var2['variation_location_details'][0]['qty_available']).toDouble() : 0;
        product.dateAdded = DateTime.now().toUtc();
        //product.save();
        var vres;
        vres = Variation().upsertAll(variations, exclusive: true, noResult: false, continueOnError: false);
        products.add(product);
      }
      else if (item['id']
          .toString()
          .isInt && keys.contains(item['id'])){
        var product = (await Product().select().id.equals(item['id']).toSingleOrDefault());
        //product.id = item['id'];
        product.name = item['name'];
        String description = (item['product_description']?? '').toString();
        //strip html tags
        RegExp exp = RegExp(
            r"<[^>]*>",
            multiLine: true,
            caseSensitive: true
        );

        description = description.replaceAll(exp, "");

        product.description = description;
        product.manufacturer = (item['brand'] != null? item['brand']['name'] : '').toString();
        product.img = (item['image_url']?? '').toString();
        product.custom_field1 = (item['product_custom_field1']?? '').toString();
        product.custom_field2 = (item['product_custom_field2']?? '').toString();
        product.custom_field3 = (item['product_custom_field3']?? '').toString();
        product.custom_field4 = (item['product_custom_field4']?? '').toString();

        var p_variations = item['product_variations'];

        List<Variation> variations = [];
        double _stocks = 0.0;
        for(var items in p_variations){
          for(var variation in items['variations']){
            int _id = int.parse((variation['id']?? -1).toString());
            Variation v = (await product.getVariations()!.id.equals(_id).toSingleOrDefault());
            if (v == null || v.id == null){
              v = Variation();
              v.id = _id;
            }

            v.sub_sku = variation['sub_sku'];
            v.name = variation['name'];
            v.price = double.parse((variation['default_sell_price']?? 0.0).toString());

            product.price = double.parse((p_variations.length == 1? v.price : ((product.price?? 0.0) + (v.price?? 0.0))).toString());

            v.variation_id = _id;
            v.productId = product.id;
            var v_locations = variation['variation_location_details'];
            if (v_locations.isNotEmpty && v_locations.length > 0){
              var v_location = v_locations[0];
              v.unit_name = (v_location != null? (v_location['unit_name']?? 'Pcs') : 'Pcs');
              v.stock = double.parse(((v_location != null && v_location['qty_available'] != null)? v_location['qty_available'] : 0.0).toString());
              _stocks += (v.stock?? 0.0);//increment the total stock for the product
            }

            //v.expiry_period = variation['product_id'];
            variations.add(v);
          }
        }
        product.plVariations = variations;
        product.stock = _stocks;
        product.alert = double.parse((item['alert_quantity']?? 0.0).toString());
        product.sku = item['sku']?? '';

        product.dateUpdated = DateTime.now().toUtc();
        //product.save();
        products.add(product);
      }
    }
    var res;
    res = Product().upsertAll(products, exclusive: true, noResult: false, continueOnError: false);
    vkeys = (await Variation().select().toListPrimaryKey());
  //}
}

Future<void> syncCustomers(OrbiterHelper orbiter) async {
  int business_id = -1;
  if (orbiter.LoggedInUser != null){
    business_id = (orbiter.LoggedInUser!.business_id?? -1);
  }
  /*final bool isInitialized = await OrbiterDbModel().initializeDB();
  if (isInitialized == true){*/
    const Map<String, dynamic> params = {'per_page': '-1', 'type': 'customer'};
    var headers = {'Content-Type': 'application/json', 'Accept': 'application/json', 'Authorization': 'Bearer ' + orbiter.LoggedInUser!.access_token! };

    var url = Uri.https(app_base_url, 'connector/api/contactapi', params);
    var resp = (await http.get(url, headers: headers));
    var result = jsonDecode(resp.body);
    var data = result['data'];
    List<Customer> customers = [];
    for (var item in data) {
      if (item['id']
          .toString()
          .isInt) {
        var customer = Customer();
        customer.id = item['id'];
        if (orbiter.LoggedInUser!= null){
          customer.business_id = orbiter.LoggedInUser!.business_id;
        }
        customer.prefix = item['prefix'];
        customer.name = item['name'];
        customer.firstname = item['first_name'];
        customer.middleName = item['middle_name'];
        customer.surname = item['last_name'];
        customer.phone = item['landline'];
        customer.mobile = item['mobile'];
        customer.email = item['email'];
        customer.addressLine1 = item['address_line_1'];
        customer.addressLine2 = item['address_line_2'];
        customer.city = item['city'];
        customer.state = item['state'];
        customer.shippingAddress = item['shipping_address'];
        customer.status = item['contact_status'];
        customer.dateAdded = DateTime.now().toUtc();
        customer.isSynced = true;
        customers.add(customer);
      }
    }
    if (customers.isNotEmpty)
      Customer().upsertAll(customers, exclusive: true, noResult: true, continueOnError: true);

    for (Customer customer in (await Customer().select().business_id.equals(business_id).isSynced.equals(false).toList())){
      List<Map<String, dynamic>> data = [];

        data.add({
          'type': 'customer',
          //customer.id = item['id'];
          'prefix': customer.prefix,
          'name': customer.name,
          'first_name': customer.firstname,
          'middle_name': customer.middleName,
          'last_name': customer.surname,
          'landline': customer.phone,
          'mobile': customer.mobile,
          'email': customer.email,
          'address_line_1': customer.addressLine1,
          'address_line_2': customer.addressLine2,
          'city': customer.city,
          'state': customer.state,
          'shipping_address': customer.shippingAddress,
          'contact_status': customer.status,});

      var body = json.encode(data);

      var headers = {'Content-Type': 'application/json', 'Accept': 'application/json', 'Authorization': 'Bearer ' + orbiter.LoggedInUser!.access_token! };

      var url = Uri.https(app_base_url, 'connector/api/sell');
      var resp = await http.post(url, headers: headers, body: body);
      var result = json.decode(resp.body);
      var customerid = result["id"];
      customer.id = customerid;
      customer.isSynced = true;
      customer.dateSynced= DateTime.now().toUtc();
      customer.upsert();

    }
  //}
}

Future<List<Sale>> syncSales(OrbiterHelper orbiter) async{
  int business_id = -1;
  int? taxid = -1;
  if (orbiter.LoggedInUser != null){
    business_id = (orbiter.LoggedInUser!.business_id?? -1);
    taxid = (orbiter.LoggedInUser!.tax1_id?? null);
  }

  //final sales = orbiter.actualSales;
  List<Sale> sales = (await Sale().select().business_id.equals(business_id).and.status.equals('final').and.isSynced.not.equals(true).toList(preload: true, loadParents: true));
  final List<Sale> mList = [];
  if (sales.length > 0){

    List<Map<String, dynamic>> entries = [];

    sales!.forEach((sale) {
      List<Map<String, String>> products = [];
      List<Map<String, String>> payments = [];

      if (sale.plSale_items != null) {
        sale.plSale_items!.forEach((itm) {
          Product p = (itm.plProduct ?? Product());
          products.add({
            'product_id': (p != null ? p.id.toString() : ''),
            'variation_id': itm.variationId.toString(),
            'quantity': itm.quantity.toString(),
            'unit_price': (p != null ? p.price.toString() : '0.0'),
            'tax_rate_id': (taxid != null ? taxid!.toString() : ''),
          });
        });
      }

      switch(sale.paymentMethod.toString()){
        case "Cash":
        case "PaymentMethod.Cash":
          payments.add({
            'amount': ((sale.amountReceived?? 0.0)).toString(),
            'method': 'cash',
          });
          break;
        case "Card":
        case "PaymentMethod.Card":
          payments.add({
            'amount': ((sale.totalAmount?? 0.0)).toString(),
            'method': 'card',
          });
          break;
        case "Transfer":
        case "PaymentMethod.Transfer":
          payments.add({
            'amount': ((sale.totalAmount?? 0.0)).toString(),
            'method': 'bank_transfer',
          });
          break;
        case "Cheque":
        case "PaymentMethod.Cheque":
          payments.add({
            'amount': ((sale.totalAmount?? 0.0)).toString(),
            'method': 'cheque',
          });
          break;
        case "Credit":
        case "PaymentMethod.Credit":
          payments.add({
            'amount': ((sale.totalAmount?? 0.0)).toString(),
            'method': 'custom_pay_1',
          });
          break;
        case "SplitCardCash":
        case "PaymentMethod.SplitCardCash":
          payments.add({
            'amount': ((sale.amountReceived?? 0.0)).toString(),
            'method': 'cash',
          });
          payments.add({
            'amount': ((sale.totalAmount?? 0.0) - (sale.amountReceived?? 0.0)).toString(),
            'method': 'card',
          });
          break;
        case "SplitTransferCash":
        case "PaymentMethod.SplitTransferCash":
          payments.add({
            'amount': ((sale.amountReceived?? 0.0)).toString(),
            'method': 'cash',
          });
          payments.add({
            'amount': ((sale.totalAmount?? 0.0) - (sale.amountReceived?? 0.0)).toString(),
            'method': 'bank_transfer',
          });
          break;
        default:
          payments.add({
            'amount': ((sale.totalAmount?? 0.0)).toString(),
            'method': 'other',
          });
          break;
      }

      entries.add({'business_id': sale.business_id.toString(), 'location_id': orbiter.LoggedInUser!.default_location_id, 'contact_id': sale.customerId,
        'status': sale.status.toString(),
        /*'round_off_amount': sale.amountReceived.toString(),*/
        'change_return': sale.changeGiven.toString(),
        /*'tax_rate_id': (taxid != null? taxid.toString() : ''),*/
        'products': products, 'payments': payments});

      sale!.isSynced = true;
      sale!.dateUpdated = DateTime.now().toUtc();
    });
    Map<String, dynamic> data =  {'sells': entries};

    var body = json.encode(data);

    var headers = {'Content-Type': 'application/json', 'Accept': 'application/json', 'Authorization': 'Bearer ' + orbiter.LoggedInUser!.access_token! };

    var url = Uri.https(app_base_url, 'connector/api/sell');
    var resp = await http.post(url, headers: headers, body: body);
    var result = json.decode(resp.body);
    var lst = result[0];

    (() async => Sale().upsertAll(sales, continueOnError: false)).call();

  }
  /*for (var sale in lst){
    if (sale['id'].toString().isInt){
      List<CartItemModel> cartItems = [];

      for (var lineItem in sale['sell_lines']){
        cartItems.add(CartItemModel(
            ProductModel(),//<---Fix this
            double.parse(lineItem['quantity']).toInt()
        ));
      }

      SaleModel itm = SaleModel(
          sale['id'],
          "",
          sale['transaction_date'],
          cartItems,
          status: sale['payment_status'],
          totalAmount: sale['total_before_tax'],
          tax: sale['tax_amount'],
          taxLabel: sale['tax_amount'],
          discount: sale['tax_amount'],
          discountLabel: sale['tax_amount'],
          paymentMethod: PaymentMethod.Transfer);//<--- Fix This.
      mList.add(itm);
    }
  }*/

  return mList;
}

