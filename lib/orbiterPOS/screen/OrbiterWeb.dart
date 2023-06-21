import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:nb_utils/nb_utils.dart';
import 'package:orbiterplus/main.dart';
import 'package:orbiterplus/main/utils/AppTheme.dart';
import 'package:orbiterplus/orbiterPOS/model/AppModel.dart';
import 'package:orbiterplus/orbiterPOS/screen/Dashboard.dart';
import 'package:orbiterplus/orbiterPOS/utils/AppConstant.dart';
//import 'package:webview_flutter/webview_flutter.dart';

class OrbiterWebApp extends StatefulWidget {

  final String web_address;
  final OrbiterHelper orbiter;

  OrbiterWebApp({super.key, this.web_address = "https://" + app_base_url, required this.orbiter});


  @override
  OrbiterWebAppState createState() => OrbiterWebAppState();

}

class OrbiterWebAppState extends State<OrbiterWebApp> {
  final GlobalKey webViewKey = GlobalKey();

  InAppWebViewController? webViewController;
  InAppWebViewGroupOptions options = InAppWebViewGroupOptions(
      crossPlatform: InAppWebViewOptions(
        verticalScrollBarEnabled: false,
        horizontalScrollBarEnabled: false,
        clearCache: true,
        cacheEnabled: false,
        transparentBackground: true,
        disableVerticalScroll: true,
        disableHorizontalScroll: true,
        disableContextMenu: true,
        supportZoom: false,
        //userAgent: 'Mozilla/5.0 (Linux; Android 6.0; Nexus 5 Build/MRA58N) ' + 'AppleWebKit/537.36 (KHTML, like Gecko) Chrome/62.0.3202.94Mobile Safari/537.36',
        userAgent: 'Mozilla/5.0 (Linux; Android 6.0.1; Nexus 10 Build/MOB31T) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/67.0.3396.87 Safari/537.36',
        preferredContentMode: UserPreferredContentMode.RECOMMENDED,
        useShouldOverrideUrlLoading: true,
        mediaPlaybackRequiresUserGesture: false,
      ),
      android: AndroidInAppWebViewOptions(
        useHybridComposition: true,
      ),
      ios: IOSInAppWebViewOptions(
        allowsInlineMediaPlayback: true,
      ));

  late PullToRefreshController pullToRefreshController;
  late String url;
  double progress = 0;
  final urlController = TextEditingController();

  @override
  void initState() {
    super.initState();
    this.url = widget.web_address;

    pullToRefreshController = PullToRefreshController(
      options: PullToRefreshOptions(
        color: Colors.blue,
      ),
      onRefresh: () async {
        if (Platform.isAndroid) {
          webViewController?.reload();
        } else if (Platform.isIOS) {
          webViewController?.loadUrl(
              urlRequest: URLRequest(url: await webViewController?.getUrl()));
        }
      },
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return SafeArea(
        child: Scaffold(
          /*appBar: AppBar(
            title: Text('Pillometer'),
            //automaticallyImplyLeading: false,
            leadingWidth: width * 0.30,
            elevation: 0.00,
            leading: Align(alignment: Alignment.centerLeft,
              child: TextButton.icon(icon: Icon(Icons.home_outlined), label: Text("Return"), onPressed: () {
                Navigator.pop(context);
                GroceryDashBoardScreen(orbiter, productList ).launch(context);
                }, )
              ,).paddingLeft(spacing_standard_new),
          ),*/
            body:
            Stack(
                children: <Widget>[
                  InAppWebView(
                    key: webViewKey,
                    initialUrlRequest:
                    URLRequest(url: Uri.parse(widget.web_address)),
                    initialOptions: options,
                    pullToRefreshController: pullToRefreshController,
                    onWebViewCreated: (controller) {
                      webViewController = controller;
                    },
                    onLoadStart: (controller, url) {
                      setState(() {
                        this.url = url.toString();
                        urlController.text = this.url;
                      });
                    },
                    androidOnPermissionRequest: (controller, origin, resources) async {
                      return PermissionRequestResponse(
                          resources: resources,
                          action: PermissionRequestResponseAction.GRANT);
                    },

                    onLoadStop: (controller, url) async {
                      pullToRefreshController.endRefreshing();
                      setState(() {
                        this.url = url.toString();
                        urlController.text = this.url;
                      });
                    },
                    onLoadError: (controller, url, code, message) {
                      pullToRefreshController.endRefreshing();
                    },
                    onProgressChanged: (controller, progress) {
                      if (progress == 100) {
                        pullToRefreshController.endRefreshing();
                      }
                      setState(() {
                        this.progress = progress / 100;
                        urlController.text = this.url;
                      });
                    },
                    onUpdateVisitedHistory: (controller, url, androidIsReload) {
                      setState(() {
                        this.url = url.toString();
                        urlController.text = this.url;
                      });
                    },
                    onConsoleMessage: (controller, consoleMessage) {
                      print(consoleMessage);
                    },
                  ),
                  progress < 1.0
                      ? LinearProgressIndicator(value: progress)
                      : Container(),
                ]

            )
        )
    );
  }
}