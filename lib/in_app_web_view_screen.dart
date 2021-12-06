import 'dart:collection';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:url_launcher/url_launcher.dart';

class MyChromeSafariBrowser extends ChromeSafariBrowser {
  @override
  void onOpened() {}

  @override
  void onCompletedInitialLoad() {}

  @override
  void onClosed() {}
}

class InAppWebViewScreen extends StatefulWidget {
  const InAppWebViewScreen({
    Key? key,
  }) : super(key: key);
  static const routeName = '/InAppWebViewScreen';
  @override
  _InAppWebViewScreenState createState() => _InAppWebViewScreenState();
}

class _InAppWebViewScreenState extends State<InAppWebViewScreen> {
  final GlobalKey webViewKey = GlobalKey();
  InAppWebViewController? webViewController;

  InAppWebViewGroupOptions options = InAppWebViewGroupOptions(
    crossPlatform: InAppWebViewOptions(
      useShouldOverrideUrlLoading: true,
      mediaPlaybackRequiresUserGesture: false,
    ),
    android: AndroidInAppWebViewOptions(
      useHybridComposition: true,
    ),
    ios: IOSInAppWebViewOptions(
      allowsInlineMediaPlayback: true,
    ),
  );

  late PullToRefreshController pullToRefreshController;

  double progress = 0;
  bool anyError = false;
  Future<void> openBrowser(String url) async {
    final ChromeSafariBrowser browser = MyChromeSafariBrowser();
    await browser.open(
      url: Uri.parse(url),
      options: ChromeSafariBrowserClassOptions(
        android: AndroidChromeCustomTabsOptions(
            addDefaultShareMenuItem: false, keepAliveEnabled: true),
        ios: IOSSafariOptions(
            dismissButtonStyle: IOSSafariDismissButtonStyle.CLOSE,
            presentationStyle: IOSUIModalPresentationStyle.OVER_FULL_SCREEN),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    if (Platform.isAndroid) {}
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
    String url = ModalRoute.of(context)!.settings.arguments as String;
    return Scaffold(
      appBar: AppBar(
        title: const Text("Title"),
        actions: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_rounded),
            onPressed: () {
              webViewController?.goBack();
            },
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios_rounded),
            onPressed: () {
              webViewController?.goForward();
            },
          ),
          IconButton(
            icon: const Icon(
              Icons.refresh,
            ),
            onPressed: () async {
              webViewController?.reload();
            },
          )
        ],
      ),
      floatingActionButton: ElevatedButton(
        // shape: RoundedRectangleBorder(
        //   borderRadius: BorderRadius.circular(30),
        // ),
        style: ElevatedButton.styleFrom(
          fixedSize: Size(MediaQuery.of(context).size.width * .5, 60),
          primary: Theme.of(context).primaryColor,
        ),
        // backgroundColor: Colors.blue,
        child: Row(
          children: const [
            Flexible(child: Text("Click here to open chrome with same url")),
            Icon(Icons.public),
          ],
        ),
        onPressed: () async {
          await openBrowser(url);
        },
      ),
      body: SafeArea(
        child: anyError
            ? const Center(
                child: Text('Some Error Happened! Try Again'),
              )
            : Column(
                children: <Widget>[
                  Expanded(
                    child: Stack(
                      children: [
                        InAppWebView(
                          key: webViewKey,
                          initialUrlRequest: URLRequest(url: Uri.parse(url)),
                          initialUserScripts:
                              UnmodifiableListView<UserScript>([]),
                          initialOptions: options,
                          pullToRefreshController: pullToRefreshController,
                          onWebViewCreated: (controller) {
                            webViewController = controller;
                          },
                          onLoadStart: (controller, uri) {
                            setState(() {
                              url = uri.toString();
                              anyError = false;
                            });
                          },
                          androidOnPermissionRequest:
                              (controller, origin, resources) async {
                            return PermissionRequestResponse(
                              resources: resources,
                              action: PermissionRequestResponseAction.GRANT,
                            );
                          },
                          shouldOverrideUrlLoading:
                              (controller, navigationAction) async {
                            Uri uri = navigationAction.request.url!;

                            if (![
                              "http",
                              "https",
                              "file",
                              "chrome",
                              "data",
                              "javascript",
                              "about"
                            ].contains(uri.scheme)) {
                              if (await canLaunch(url)) {
                                // Launch the App
                                await launch(
                                  url,
                                );
                                // and cancel the request
                                return NavigationActionPolicy.CANCEL;
                              }
                            }

                            return NavigationActionPolicy.ALLOW;
                          },
                          onLoadStop: (controller, uri) async {
                            pullToRefreshController.endRefreshing();
                            print('Loaded $uri');
                            setState(
                              () {
                                url = uri.toString();
                              },
                            );
                          },
                          onLoadError: (controller, uri, code, message) async {
                            pullToRefreshController.endRefreshing();
                            await openBrowser(uri.toString());
                            print('$code $message');
                            setState(() {
                              anyError = true;
                            });
                          },
                          onProgressChanged: (controller, progress) {
                            if (progress == 100) {
                              pullToRefreshController.endRefreshing();
                            }
                            setState(
                              () {
                                this.progress = progress / 100;
                              },
                            );
                          },
                          onUpdateVisitedHistory:
                              (controller, uri, androidIsReload) {
                            setState(() {
                              url = uri.toString();
                            });
                          },
                        ),
                        progress < 1.0
                            ? Container(
                                color: Colors.black.withOpacity(0.5),
                                height: MediaQuery.of(context).size.height,
                                width: MediaQuery.of(context).size.width,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    CircularProgressIndicator(
                                      value: progress,
                                      color: Colors.blue,
                                      backgroundColor: Colors.white,
                                    ),
                                    Text(
                                      (progress * 100).floor().toString() + '%',
                                      style: const TextStyle(
                                          color: Colors.white, fontSize: 50),
                                    ),
                                  ],
                                ),
                              )
                            : Container(),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
