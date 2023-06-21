package com.fixhire.orbiterplus

import android.annotation.SuppressLint
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.os.Build
import androidx.annotation.NonNull
import androidx.annotation.RequiresApi
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "orbiterplus.fixhire.com/printing"

    @SuppressLint("MissingPermission")
    @RequiresApi(Build.VERSION_CODES.HONEYCOMB_MR1)
    @androidx.annotation.RequiresPermission(value = "android.permission.USB_CONNECT, android.permission.BLUETOOTH_CONNECT")
    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
                call, result ->
            if (call.method == "PrintReceipt"){
                var ctx = this.context
                var nPrintWidth = call.argument<Int>("printWidth")
                var bCutter = call.argument<Boolean>("cutPaper")
                var bDrawer = call.argument<Boolean>("openDrawer")
                var bBeeper = call.argument<Boolean>("beep")
                var nCount = call.argument<Int>("copyCount")
                var nCompressMethod = call.argument<Int>("nCompressMethod")
                var logo  = call.argument<String>("logo")
                var businessName = call.argument<String>("businessName")
                var footer  = call.argument<String>("footer")
                var copyright  = call.argument<String>("copyright")
                var trnxid  = call.argument<String>("trnxid")
                var paymentMethod  = call.argument<String>("paymentMethod")
                var totalAmount  = call.argument<String>("totalAmount")
                var amountReceived  = call.argument<String>("amountReceived")
                var changeGiven  = call.argument<String>("changeGiven")
                var salesTax  = call.argument<String>("salesTax")
                var salesDiscount  = call.argument<String>("salesDiscount")
                var status  = call.argument<String>("status")
                var trnxDate  = call.argument<String>("trnxDate")
                var customer  = call.argument<String>("customer")
                var items  = call.argument<List<String>>("items")

                if (!Printing.pos.GetIO().IsOpened()){
                    if (Printing.USBConnect(ctx)) {
                        Printing.pos.Set(Printing.usb)
                    }
                    else if (Printing.BTConnect(ctx)){
                        Printing.pos.Set(Printing.mBt)
                    }
                }

                var code = Printing.PrintTicket(ctx, nPrintWidth!!,
                    bCutter!!, bDrawer!!, bBeeper!!, nCount!!, nCompressMethod!!,
                    logo, businessName, footer, copyright, trnxid, paymentMethod, totalAmount, amountReceived,
                    changeGiven, salesTax, salesDiscount, status, trnxDate, customer, items, )

                var res = Printing.ResultCodeToString(code)
                if (res.length > 0) {
                    result.success(res);
                } else {
                    result.error("UNAVAILABLE", "No Such Code", null)
                }
            }
            else if (call.method == "Connect"){
                var ctx = this.context
                try{
                    if (Printing.USBConnect(ctx)) {
                        Printing.pos.Set(Printing.usb)
                        result.success(true)
                    }
                    else if (Printing.BTConnect(ctx)){
                        Printing.pos.Set(Printing.mBt)
                        result.success(true);
                    } else {
                        result.error("UNAVAILABLE", "Failed to Connect", null)
                    }
                }
                catch (ex: Exception){
                    print(ex.stackTrace)
                }
            }
            else if (call.method == "Disconnect"){
                try{
                    if (Printing.USBDisconnect()) {
                        result.success(true);
                    } else {
                        result.error("UNAVAILABLE", "Failed to Disconnect", null)
                    }

                    if (Printing.BTDisconnect()) {
                        result.success(true);
                    } else {
                        result.error("UNAVAILABLE", "Failed to Disconnect", null)
                    }
                }
                catch (ex: Exception){
                    print(ex.stackTrace)
                }
            }
            else {
                result.notImplemented()
            }
        }
    }
}