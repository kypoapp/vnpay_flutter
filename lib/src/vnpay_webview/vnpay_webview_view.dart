import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import '../widgets/loading_widget.dart';
import 'vnpay_webview_controller.dart';

class VNPayWebViewView extends StatefulWidget {
  final String redirectUrl;
  final String schemeReturn;
  final List<String> listCheckReturn;
  final Future Function()? onPaymentSuccess;
  final Function(String? code, String? messsage)? onPaymentError;
  final Function(String? message)? onShowDialogError;

  const VNPayWebViewView(
      {Key? key,
      required this.redirectUrl,
      required this.schemeReturn,
      required this.listCheckReturn,
      this.onPaymentSuccess,
      this.onPaymentError,
      this.onShowDialogError})
      : super(key: key);

  @override
  State<VNPayWebViewView> createState() => _VNPayWebViewWidgetState();
}

class _VNPayWebViewWidgetState extends State<VNPayWebViewView> {
  late VNPayWebViewController controller;

  final GlobalKey webViewKey = GlobalKey();
  InAppWebViewGroupOptions options = InAppWebViewGroupOptions(
      crossPlatform: InAppWebViewOptions(
          useShouldOverrideUrlLoading: true,
          mediaPlaybackRequiresUserGesture: false,
          preferredContentMode: UserPreferredContentMode.MOBILE,
          userAgent: (Platform.isIOS)
              ? "Mozilla/5.0 (iPhone; CPU iPhone OS 15_1_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.1 Mobile/15E148 Safari/604.1"
              : "",
          cacheEnabled: false),
      android: AndroidInAppWebViewOptions(
        useHybridComposition: true,
      ),
      ios: IOSInAppWebViewOptions(allowsInlineMediaPlayback: true));

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    controller = VNPayWebViewController(
      schemeReturn: widget.schemeReturn,
      listCheckReturn: widget.listCheckReturn,
      onPaymentSuccess: widget.onPaymentSuccess,
      onPaymentError: widget.onPaymentError,
      onShowDialogError: widget.onShowDialogError,
    );
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    controller.dispose();
  }

  double progress = 0;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        InAppWebView(
          key: webViewKey,
          initialUrlRequest: URLRequest(url: Uri.parse(widget.redirectUrl)),
          initialOptions: options,
          // ignore: prefer_expression_function_bodies
          androidOnPermissionRequest: (controller, origin, resources) async {
            return PermissionRequestResponse(resources: resources, action: PermissionRequestResponseAction.GRANT);
          },
          // ignore: prefer_expression_function_bodies
          onReceivedServerTrustAuthRequest: (InAppWebViewController controller, URLAuthenticationChallenge challenge) async {
            return ServerTrustAuthResponse(action: ServerTrustAuthResponseAction.PROCEED);
          },
          shouldOverrideUrlLoading: controller.shouldOverrideUrlLoading,
          onLoadStop: (controller, uri) {},
          onProgressChanged: (ct, progress) {
            setState(() {
              this.progress = progress / 100;
            });
          },
        ),
        progress < 1.0 ? LinearProgressIndicator(value: progress) : Container(),
      ],
    );
    // return WebView(
    //   javascriptMode: JavascriptMode.unrestricted,
    //   initialUrl: widget.redirectUrl,
    //   backgroundColor: Colors.white,
    //   userAgent: (Platform.isIOS)
    //       ? "Mozilla/5.0 (iPhone; CPU iPhone OS 15_1_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.1 Mobile/15E148 Safari/604.1"
    //       : "",
    //   navigationDelegate: controller.navigationDelegate,
    //   onPageFinished: (value) {
    //     controller.isLoading.value = false;
    //   },
    //   onProgress: (value) {
    //     // controller.viewState.value = ViewState.loading;
    //   },
    //   onPageStarted: (value) {
    //     print("onPageStarted $value");
    //   },
    // );
  }
}
