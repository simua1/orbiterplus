package com.fixhire.orbiterplus;

import java.io.IOException;
import java.io.InputStream;
import java.nio.ByteBuffer;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.Iterator;
import java.util.List;

import android.annotation.SuppressLint;
import android.app.Activity;
import android.app.PendingIntent;
import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothDevice;
import android.bluetooth.BluetoothManager;
import android.bluetooth.BluetoothProfile;
import android.content.Context;
import android.content.Intent;
import android.content.res.AssetManager;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.Matrix;
import android.graphics.Paint;
import android.graphics.Bitmap.Config;

import com.lvrenyang.io.Pos;
import com.lvrenyang.io.USBPrinting;
//import com.lvrenyang.io.BLEPrinting;
import com.lvrenyang.io.BTPrinting;
import org.json.JSONObject;

import android.hardware.usb.UsbDevice;
import android.hardware.usb.UsbManager;
import android.media.Image;
import android.os.Build;
import android.widget.Toast;

import androidx.annotation.RequiresApi;

import kotlin.UByteArray;


public class Printing extends Activity {
    static Pos pos = new Pos();
    static BTPrinting mBt = new BTPrinting();

    @RequiresApi(api = Build.VERSION_CODES.HONEYCOMB_MR1)
    @androidx.annotation.RequiresPermission(value = "android.permission.BLUETOOTH_CONNECT")
    public static Boolean BTConnect(Context ctx){

        final BluetoothManager btManager = (BluetoothManager) ctx.getSystemService(Context.BLUETOOTH_SERVICE);
        int[] states = {BluetoothProfile.STATE_CONNECTED, BluetoothProfile.STATE_CONNECTING, BluetoothProfile.STATE_DISCONNECTED, BluetoothProfile.STATE_DISCONNECTING};

        //HashMap<String, BluetoothDevice> deviceList = (HashMap<String, BluetoothDevice>)btManager.getAdapter().getBondedDevices();
        List<BluetoothDevice> deviceList = btManager.getDevicesMatchingConnectionStates(BluetoothProfile.GATT, states);
        Iterator<BluetoothDevice> deviceIterator = deviceList.iterator();
        if (deviceList.size() > 0) {
            while (deviceIterator.hasNext()) { // Here is if not while, indicating that I only want to support one device
                final BluetoothDevice device = deviceIterator.next();

                PendingIntent mPermissionIntent = PendingIntent
                        .getBroadcast(ctx,0, new Intent(
                                        ctx.getApplicationInfo().packageName),
                                0);

                if (!mBt.IsOpened()){
                    try{
                        return mBt.Open(device.getAddress(), ctx);
                    }
                    catch(Exception e){
                        return false;
                    }
                }
                else{
                    return mBt.IsOpened();
                }
            }
        }
        return false; //If we got here, something went wrong
    }

    static USBPrinting usb = new USBPrinting();
    @RequiresApi(api = Build.VERSION_CODES.HONEYCOMB_MR1)
    @androidx.annotation.RequiresPermission(value = "android.permission.USB_CONNECT")
    public static Boolean USBConnect(Context ctx){
        final UsbManager mUsbManager = (UsbManager) ctx.getSystemService(Context.USB_SERVICE);

        HashMap<String, UsbDevice> deviceList = mUsbManager.getDeviceList();
        Iterator<UsbDevice> deviceIterator = deviceList.values().iterator();

        if (deviceList.size() > 0) {
            while (deviceIterator.hasNext()) { // Here is if not while, indicating that I only want to support one device
                final UsbDevice device = deviceIterator.next();

                if (device.getProductId() == 33054 && device.getVendorId() == 4070){
                    PendingIntent mPermissionIntent = PendingIntent
                            .getBroadcast(ctx,0, new Intent(
                                            ctx.getApplicationInfo().packageName),
                                    0);

                    if (!mUsbManager.hasPermission(device)) {
                        mUsbManager.requestPermission(device, mPermissionIntent);
                    }

                    if (mUsbManager.hasPermission(device)) {
                        if (!usb.IsOpened()){
                            //try{
                            boolean status = usb.Open(mUsbManager, device, ctx);
                            /*if (status){
                                Toast.makeText(ctx, "Printer \"" + device.getProductName() +"\" Connected Successfully", Toast.LENGTH_LONG).show();
                            }*/

                            return status;
                            /*}
                            catch(Exception e){
                                return false;
                            }*/
                        }
                        else{
                            return usb.IsOpened();
                        }
                    }
                    break;
                }
            }
        }

        return false; //If we got here, something went wrong
    }

    public static Boolean USBDisconnect(){
        if (usb.IsOpened()){
            try{
                usb.Close();
                return true;
            }
            catch(Exception e){
                return false;
            }
        }
        else{
            return usb.IsOpened();
        }
    }

    public static Boolean BTDisconnect(){
        if (mBt.IsOpened()){
            try{
                mBt.Close();
                return true;
            }
            catch(Exception e){
                return false;
            }
        }
        else{
            return mBt.IsOpened();
        }
    }

    @SuppressLint("MissingPermission")
    @RequiresApi(api = Build.VERSION_CODES.HONEYCOMB_MR1)
    //@androidx.annotation.RequiresPermission(value = "android.permission.USB_CONNECT, android.permission.BLUETOOTH_CONNECT")
    public static int PrintTicket(Context ctx, int nPrintWidth, boolean bCutter, boolean bDrawer, boolean bBeeper, int nCount,
                                  int nCompressMethod, String logo, String businessName, String footer, String copyright, String trnxid, String paymentMethod,
                                  String totalAmount, String amountReceived, String changeGiven, String salesTax, String salesDiscount,
                                  String trnxStatus, String trnxDate, String customer
                                , List<String> items) {
        int bPrintResult = -8;
        Bitmap logoImage = getImageFromAssetsFile(ctx, logo);

        if (pos.GetIO().IsOpened()){
            byte[] status = new byte[1];

            if (pos.POS_RTQueryStatus(status, 3, 1000, 2)) {

                if ((status[0] & 0x08) == 0x08)   //Determine whether the cutter is abnormal
                    return bPrintResult = -2;

                if ((status[0] & 0x40) == 0x40)   //Determine whether the print head is within the normal value range
                    return bPrintResult = -3;


                if (pos.POS_RTQueryStatus(status, 2, 1000, 2)) {

                    if ((status[0] & 0x04) == 0x04)    //Determine whether the cover is normal
                        return bPrintResult = -6;
                    if ((status[0] & 0x20) == 0x20) {   //Determine if there is no paper
                        return bPrintResult = -5;
                    } else {
                        for (int i = 0; i < nCount; i++) {
                            if (!pos.GetIO().IsOpened())
                                break;

                            pos.POS_Reset();
                            pos.POS_FeedLine();
                            if (logoImage != null) {
                                pos.POS_S_Align(1);
                                pos.POS_PrintPicture(logoImage, (nPrintWidth/2), 1, nCompressMethod);
                                pos.POS_S_Align(0);
                            }

                            pos.POS_TextOut(businessName + "\r\n", 0, 14, 1, 1, 0, 0);

                            pos.POS_FeedLine();
                            pos.POS_S_Align(2);
                            pos.POS_TextOut(customer + "\r\n", 0, 0, 0, 0, 0, 0);
                            pos.POS_TextOut(trnxDate + "\r\n", 0, 0, 0, 0, 0, 0);
                            pos.POS_TextOut(trnxStatus + "\r\n", 0, 0, 0, 0, 0, 0);
                            pos.POS_TextOut(paymentMethod + "\r\n", 0, 0, 0, 0, 0, 0);
                            pos.POS_TextOut("REF #: \t" + trnxid + "\r\n", 0, 0, 0, 0, 0, 0);

                            pos.POS_FeedLine();
                            pos.POS_S_Align(0);
                            for(int ix = 0; ix < items.size(); ix++){
                                pos.POS_TextOut((ix + 1) + ". " + items.get(ix) + "\r\n", 0, 0, 0, 0, 0, 0);
                            }
                            pos.POS_FeedLine();

                            pos.POS_S_Align(2);
                            pos.POS_TextOut(salesTax + "\r\n", 0, 0, 0, 0, 0, 0);
                            pos.POS_TextOut(salesDiscount + "\r\n", 0, 0, 0, 0, 0, 0);
                            pos.POS_TextOut(totalAmount + "\r\n", 1, 0, 0, 0, 0, 0x08);
                            pos.POS_TextOut(amountReceived + "\r\n", 1, 0, 0, 0, 0, 0);
                            pos.POS_TextOut(changeGiven + "\r\n", 1, 0, 0, 0, 0, 0);

                            pos.POS_FeedLine();

                            pos.POS_S_Align(1);
                            pos.POS_S_SetBarcode(trnxid, 0, 69, 2, 50, 0, 0x02);
                            pos.POS_FeedLine();
                            pos.POS_TextOut(footer + "\r\n", 1, 0, 0, 0, 0, 0);
                            pos.POS_FeedLine();
                            pos.POS_TextOut(copyright + "\r\n", 1, 0, 0, 0, 0, 0);
                            pos.POS_FeedLine();
                            pos.POS_FeedLine();
                            pos.POS_FeedLine();

                        }

                        if (bBeeper)
                            pos.POS_Beep(1, 5);
                        if (bCutter && nCount == 1)
                            pos.POS_FullCutPaper();
                        if (bDrawer)
                            pos.POS_KickDrawer(0, 100);


                        /*if (nCount == 1) {
                            *//*try {
                                Thread.currentThread();
                                Thread.sleep(500);
                            } catch (InterruptedException e) {
                                e.printStackTrace();
                            }*//*

                            //if (pos.POS_RTQueryStatus(status, 1, 1000, 2)) {
                            if (pos.POS_RTQueryStatus(status, 1, 500, 2)) {
                                if ((status[0] & 0x80) == 0x80) {

                                    try {
                                        Thread.currentThread();
                                        Thread.sleep(3000);
                                    } catch (InterruptedException e) {
                                        e.printStackTrace();
                                    }

                                    //if (pos.POS_RTQueryStatus(status, 2, 1000, 2)) {
                                    if (pos.POS_RTQueryStatus(status, 2, 500, 2)) {
                                        if ((status[0] & 0x20) == 0x20)    //Out of paper during printing
                                            return bPrintResult = -9;
                                        if ((status[0] & 0x04) == 0x04)    //Open the paper compartment cover during printing
                                            return bPrintResult = -10;
                                    } else {
                                        return bPrintResult = -11;         //Query failed
                                    }


                                    //if (pos.POS_RTQueryStatus(status, 4, 1000, 2)) {
                                    if (pos.POS_RTQueryStatus(status, 4, 500, 2)) {
                                        if ((status[0] & 0x08) == 0x08) {
                                            if (pos.POS_RTQueryStatus(status, 1, 1000, 2)) {
                                                if ((status[0] & 0x80) == 0x80)     //Paper is almost out and not picked up
                                                    return bPrintResult = 2;
                                                else
                                                    return bPrintResult = 1;
                                            }
                                        }
                                        else {
                                            //if (pos.POS_RTQueryStatus(status, 1, 1000, 2)) {
                                            if (pos.POS_RTQueryStatus(status, 1, 500, 2)) {
                                                if ((status[0] & 0x80) == 0x80) {
                                                    return bPrintResult = 3;
                                                } else
                                                    return bPrintResult = 0;
                                            } else
                                                return bPrintResult = -11;
                                        }
                                    } else {
                                        return bPrintResult = -11;         //Query failed
                                    }

                                } else {
                                    try {
                                        Thread.currentThread();
                                        Thread.sleep(3000);
                                    } catch (InterruptedException e) {
                                        e.printStackTrace();
                                    }

                                    if (pos.POS_RTQueryStatus(status, 2, 1000, 2)) {
                                        if ((status[0] & 0x20) == 0x20) {
                                            return bPrintResult = -9;                //Out of paper during printing
                                        }

                                        if ((status[0] & 0x04) == 0x04) {
                                            return bPrintResult = -10;                //Open the paper compartment cover during printing
                                        } else {
                                            return bPrintResult = -1;
                                        }


                                    } else {
                                        return bPrintResult = -11;         //Query failed
                                    }
                                }

                            }
                            else {
                                return bPrintResult = -11;
                            }
                        } else {
                            if (pos.POS_RTQueryStatus(status, 1, 1000, 2)) {
                                if ((status[0] & 0x80) == 0x80) {

                                    try {
                                        Thread.currentThread();
                                        Thread.sleep(3000);
                                    } catch (InterruptedException e) {
                                        e.printStackTrace();
                                    }

                                    if (pos.POS_RTQueryStatus(status, 2, 1000, 2)) {
                                        if ((status[0] & 0x20) == 0x20)    //Out of paper during printing
                                            return bPrintResult = -9;
                                        if ((status[0] & 0x04) == 0x04)    //Open the paper compartment cover during printing
                                            return bPrintResult = -10;
                                    } else {
                                        return bPrintResult = -11;         //Query failed
                                    }


                                    if (pos.POS_RTQueryStatus(status, 4, 1000, 2)) {
                                        if ((status[0] & 0x08) == 0x08) {
                                            if (pos.POS_RTQueryStatus(status, 1, 1000, 2)) {
                                                if ((status[0] & 0x80) == 0x80)     //Paper is almost out and not picked up
                                                    return bPrintResult = 2;
                                                else
                                                    return bPrintResult = 1;
                                            }
                                        } else {
                                            if (pos.POS_RTQueryStatus(status, 1, 1000, 2)) {
                                                if ((status[0] & 0x80) == 0x80) {
                                                    return bPrintResult = 3;
                                                } else
                                                    return bPrintResult = 0;
                                            } else
                                                return bPrintResult = -11;
                                        }
                                    } else {
                                        return bPrintResult = -11;         //Query failed
                                    }
                                } else {
                                    try {
                                        Thread.currentThread();
                                        Thread.sleep(3000);
                                    } catch (InterruptedException e) {
                                        e.printStackTrace();
                                    }

                                    if (pos.POS_RTQueryStatus(status, 2, 1000, 2)) {
                                        if ((status[0] & 0x20) == 0x20) {
                                            return bPrintResult = -9;                //Out of paper during printing
                                        }

                                        if ((status[0] & 0x04) == 0x04) {
                                            return bPrintResult = -10;                //Open the paper compartment cover during printing
                                        } else {
                                            return bPrintResult = -1;
                                        }
                                    } else {
                                        return bPrintResult = -11;         //Query failed
                                    }
                                }
                            } else {
                                return bPrintResult = -11;
                            }
                        }*/
                    }
                }
                else {
                    return bPrintResult = -8;           //Query failed
                }
            }
            else {
                return bPrintResult = -8;          //Query failed
            }
        }

        return bPrintResult;
    }

    public static String ResultCodeToString(int code) {
        switch (code) {
            case 3:
                return "There is an uncollected receipt at the paper outlet, please take it out in time";
            case 2:
                return "The paper will run out and there is an uncollected receipt at the paper outlet, please pay attention to replace the paper roll and take away the receipt in time";
            case 1:
                return "The paper is almost out, please pay attention to replace the paper roll";
            case 0:
                return "Successful";
            case -1:
                return "The receipt is not printed, please check for paper jams";
            case -2:
                return "The cutter is abnormal, please remove it manually";
            case -3:
                return "The print head is too hot, please wait for the printer to cool down";
            case -4:
                return "The printer is offline";
            case -5:
                return "The printer is out of paper";
            case -6:
                return "cover open";
            case -7:
                return "Real-time status query failed";
            case -8:
                return "The status query failed, please check whether the communication port is connected normally";
            case -9:
                return "Out of paper during printing, please check the document integrity";
            case -10:
                return "The top cover is opened during printing, please print again";
            case -11:
                return "The connection is interrupted, please confirm whether the printer is connected";
            case -12:
                return  "Please take away the printed receipt before printing!";
            case -13:
            default:
                return "unknown error";
        }
    }

    /**
     * Read pictures from Assets
     */
    public static Bitmap getImageFromAssetsFile(Context ctx, String fileName) {
        Bitmap image = null;
        AssetManager am = ctx.getResources().getAssets();
        try {
            InputStream is = am.open(fileName);
            image = BitmapFactory.decodeStream(is);
            is.close();
        } catch (IOException e) {
            e.printStackTrace();
        }
        return image;
    }

    public static Bitmap getTestImage1(int width, int height)
    {
        Bitmap bitmap = Bitmap.createBitmap(width, height, Config.ARGB_8888);
        Canvas canvas = new Canvas(bitmap);
        Paint paint = new Paint();

        paint.setColor(Color.WHITE);
        canvas.drawRect(0, 0, width, height, paint);

        paint.setColor(Color.BLACK);
        for(int i = 0; i < 8; ++i)
        {
            for(int x = i; x < width; x += 8)
            {
                for(int y = i; y < height; y += 8)
                {
                    canvas.drawPoint(x, y, paint);
                }
            }
        }
        return bitmap;
    }

    public static Bitmap getTestImage2(int width, int height)
    {
        Bitmap bitmap = Bitmap.createBitmap(width, height, Config.ARGB_8888);
        Canvas canvas = new Canvas(bitmap);
        Paint paint = new Paint();

        paint.setColor(Color.WHITE);
        canvas.drawRect(0, 0, width, height, paint);

        paint.setColor(Color.BLACK);
        for(int y = 0; y < height; y += 4)
        {
            for(int x = y%32; x < width; x += 32)
            {
                canvas.drawRect(x, y, x+4, y+4, paint);
            }
        }
        return bitmap;
    }

    public static class TaskTest implements Runnable
    {
        Pos pos = null;
        USBPrinting usb = null;
        UsbManager usbManager = null;
        UsbDevice usbDevice = null;
        Context context = null;

        public TaskTest(Pos pos, USBPrinting usb, UsbManager usbManager, UsbDevice usbDevice, Context context)
        {
            this.pos = pos;
            this.usb = usb;
            this.usbManager = usbManager;
            this.usbDevice = usbDevice;
            this.context = context;
            pos.Set(usb);
        }

        @Override
        public void run() {
            // TODO Auto-generated method stub
            for(int i = 0; i < 1000; ++i)
            {
                long beginTime = System.currentTimeMillis();
                if(usb.Open(usbManager,usbDevice,context))
                {
                    long endTime = System.currentTimeMillis();
                    pos.POS_S_Align(0);
                    pos.POS_S_TextOut(i+ "\t" + "Open\tUsedTime:" + (endTime - beginTime) + "\r\n", 0, 0, 0, 0, 0);
                    beginTime = System.currentTimeMillis();
                    int ticketResult = pos.POS_TicketSucceed(i, 30000);
                    endTime = System.currentTimeMillis();
                    pos.POS_S_TextOut(i+ "\t" + "Ticket\tUsedTime:" + (endTime - beginTime) + "\t" + (ticketResult == 0 ? "Succeed" : "Failed") +  "\r\n", 0, 0, 0, 0, 0);
                    pos.POS_FullCutPaper();
                    usb.Close();
                }
            }
        }
    }
}


