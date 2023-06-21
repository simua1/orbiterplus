import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:intl/intl.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:orbiterplus/main/utils/AppConstant.dart';
import 'package:orbiterplus/orbiterPOS/utils/AppColors.dart';

class DateFormatter{
  late String longdate;
  late String shortdate;

  DateFormatter(DateTime date){
    if (date.timeZoneName == 'UTC'){
      date = date.toLocal();
      if (date.timeZoneName == 'GMT' && date.timeZoneOffset == Duration(hours:0)){
        date = date.add(Duration(hours:1));
      }
    }

    final dayMap = {"1": 'st', "2": 'nd', "3": 'rd'};
    final dateStr = DateFormat("MMMM, yyyy. hh:mma").format(date);
    final sdateStr = DateFormat("MMM, yyyy. hh:mma").format(date);
    String day = date.day.toString();
    this.longdate = "$day${dayMap[day.substring(day.length -1)] ?? 'th'} $dateStr";
    this.shortdate = "$day${dayMap[day.substring(day.length -1)] ?? 'th'} $sdateStr";
  }
}

abstract class Notify {

  static Future<bool?> toast({required String message, MessageType type = MessageType.Info}) {
    Fluttertoast.cancel();

    return Fluttertoast.showToast(
        msg: message,
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.TOP,
        timeInSecForIosWeb: 4,
        backgroundColor: ((type == MessageType.Success? grocery_Green_Color : (type == MessageType.Alert? grocery_Red_Color : (type == MessageType.Warning? grocery_orangeLight_Color : grocery_blue_Color)))),
        textColor: Colors.white,
        fontSize: textSizeNormal);
  }

  static showLoading({String? message}) {

    try {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (EasyLoading.isShow)
          EasyLoading.dismiss();
        EasyLoading.show(status: message, maskType: EasyLoadingMaskType.black);
      });
    }
    catch (e) {
      print(e.toString());
    }
  }

  static hideLoading(){
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      //if (EasyLoading.isShow)
        EasyLoading.dismiss();
    });
  }

}

enum MessageType {
  Success,
  Warning,
  Info,
  Alert
}