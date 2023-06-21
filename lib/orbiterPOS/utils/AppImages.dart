import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:orbiterplus/main/utils/AppConstant.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:nb_utils/nb_utils.dart';

const Grocery_ic_DeliveryBoy = "$BaseUrl/images/grocery/Grocery_ic_DeliveryBoy.png";
const Grocery_ic_CheckMark = "images/grocery/Grocery_ic_CheckMark.png";
const Grocery_ic_Profile = "$BaseUrl/images/grocery/Grocery_ic_Profile.jpg";
const Grocery_ic_Dollar = "images/grocery/Grocery_ic_Dollar.png";
const Grocery_ic_Lock = "images/grocery/Grocery_ic_Lock.png";
const Grocery_ic_DeliveryTruck = "images/grocery/Grocery_ic_DeliveryTruck.png";
const Grocery_ic_User = "images/grocery/Grocery_ic_User.png";
const Grocery_ic_Logout = "images/grocery/Grocery_ic_Logout.png";
const Grocery_ic_Home = "images/grocery/Grocery_ic_Home.png";
const Grocery_ic_bag = "images/grocery/Grocery_ic_bag.png";
const Grocery_ic_Android = "images/grocery/Grocery_ic_Android.jpg";
const Grocery_ic_Search = "images/grocery/App_ic_Search.png";

const grocery_ic_visa = "images/grocery/visa.png";
const grocery_ic_masterCard = "$BaseUrl/images/grocery/masterCard.png";

const grocery_ic_shop = "images/grocery/grocery_ic_shop.png";
const grocery_ic_outline_favourite = "images/grocery/grocery_ic_outline_favourite.png";
const grocery_ic_grocery = "images/grocery/grocery_ic_grocery.png";
const grocery_ic_liquor = "images/grocery/grocery_ic_liquor.png";
const grocery_ic_chilled = "images/grocery/grocery_ic_chilled.png";
const grocery_ic_pharmacy = "images/grocery/grocery_ic_pharmacy.png";
const grocery_ic_frozen = "images/grocery/grocery_ic_frozen.png";
const grocery_ic_vegetables = "images/grocery/grocery_ic_vegetables.png";
const grocery_ic_meat = "images/grocery/grocery_ic_meat.png";
const grocery_ic_fish = "images/grocery/grocery_ic_fish.png";
const grocery_ic_homeware = "images/grocery/grocery_ic_homeware.png";
const grocery_ic_fruit = "images/grocery/grocery_ic_fruit.png";
const grocery_ic_user1 = "$BaseUrl/images/grocery/grocery_ic_user1.png";
const grocery_ic_user2 = "$BaseUrl/images/grocery/grocery_ic_user2.png";
const grocery_ic_user3 = "$BaseUrl/images/grocery/grocery_ic_user3.png";
const grocery_ic_ampiclox = "images/grocery/products/drugs/ampiclox.png";
const grocery_ic_astymin = "images/grocery/products/drugs/astymin.png";
const grocery_ic_emzolyn = "images/grocery/products/drugs/emzolyn.png";
const grocery_ic_jawaron = "images/grocery/products/drugs/jawaron.png";
const grocery_ic_obron = "images/grocery/products/drugs/obron.png";
const grocery_ic_persen = "images/grocery/products/drugs/persen.png";
const grocery_ic_jointace = "images/grocery/products/drugs/jointace.png";
const grocery_ic_osteocare = "images/grocery/products/drugs/osteocare.png";
const grocery_ic_xanax = "images/grocery/products/drugs/xanax.png";
const grocery_ic_pronatal = "images/grocery/products/drugs/pronatal.png";
const grocery_ic_strefen = "images/grocery/products/drugs/strefen.png";
const grocery_ic_ventolin = "images/grocery/products/drugs/ventolin.png";
const grocery_ic_bg_drinks = "$BaseUrl/images/grocery/grocery_ic_bg_drinks.jpg";
const grocery_logo = "$BaseUrl/images/grocery/grocery_logo.png";
const orbiter_ic_logo = "images/orbiter_ic_logo_bluebg.png";
const orbiter_full_logo = "images/orbiter_ic_logo_bluebg.png";
const pillometer_ic_logo = "images/pillometer_ic_icon_dark_bg.png";
const pillometer_full_logo = "images/pillometer_logo.png";
const grocery_greeting_bg = "images/greetings_bg.png";
const grocery_greeting_am_bg = "images/greetings_am_bg.png";
const grocery_greeting_pm_bg = "images/greetings_pm_bg.png";
const grocery_customer_holder = "images/customer.png";
const grocery_product_holder = "images/products/product_placeholder.png";

abstract class ImageManager{
  static File? _downloaded;

  static void _fetchImage(key, url) async {
    final file = await DefaultCacheManager().getSingleFile(url, key: key);
    _downloaded = file;
  }

  static Widget fetchImage(key, url) {
    _fetchImage(key, url);

    Widget networkImg;

    if (_downloaded == null) {
      networkImg = Image.asset(grocery_product_holder, height: 150, fit: BoxFit.fitHeight);
    } else {
      networkImg = Image.file(_downloaded!, height: 150, fit: BoxFit.fitHeight);
    }
    return networkImg;
  }
}

Widget commonCachedNetworkImage(
    String? url, {
      double? height,
      double? width,
      BoxFit? fit,
      AlignmentGeometry? alignment,
      bool usePlaceholderIfUrlEmpty = true,
      double? radius,
      Color? color,
    }) {
  if (url!.validate().isEmpty) {
    return placeHolderWidget(height: height, width: width, fit: fit, alignment: alignment, radius: radius);
  } else if (url.validate().startsWith('http')) {
    return CachedNetworkImage(
      imageUrl: url,
      height: height,
      width: width,
      fit: fit,
      color: color,
      alignment: alignment as Alignment? ?? Alignment.center,
      errorWidget: (_, s, d) {
        return placeHolderWidget(height: height, width: width, fit: fit, alignment: alignment, radius: radius);
      },
      placeholder: (_, s) {
        if (!usePlaceholderIfUrlEmpty) return SizedBox();
        return placeHolderWidget(height: height, width: width, fit: fit, alignment: alignment, radius: radius);
      },
    );
  } else {
    return Image.asset(url, height: height, width: width, fit: fit, alignment: alignment ?? Alignment.center).cornerRadiusWithClipRRect(radius ?? defaultRadius);
  }
}

Widget placeHolderWidget({double? height, double? width, BoxFit? fit, AlignmentGeometry? alignment, double? radius}) {
  //return Image.asset('images/app/placeholder.jpg', height: height, width: width, fit: fit ?? BoxFit.cover, alignment: alignment ?? Alignment.center).cornerRadiusWithClipRRect(radius ?? defaultRadius);
  return Image.asset('images/placeholder.png', height: height, width: width, fit: fit ?? BoxFit.fitHeight, alignment: alignment ?? Alignment.center).cornerRadiusWithClipRRect(radius ?? defaultRadius);
}

InputDecoration buildInputDecoration(String name, {Widget? prefixIcon}) {
  return InputDecoration(
    prefixIcon: prefixIcon,
    hintText: name,
    hintStyle: primaryTextStyle(),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0), borderSide: BorderSide(color: grey, width: 0.5)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0), borderSide: BorderSide(color: grey, width: 0.5)),
  );
}
