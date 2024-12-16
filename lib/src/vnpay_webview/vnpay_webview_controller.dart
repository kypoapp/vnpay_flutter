import 'dart:async';
import 'dart:io';

import 'package:app_links/app_links.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_intent_scheme_android/flutter_intent_scheme_android.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

class VNPayWebViewController {
  final String schemeReturn;
  final List<String> listCheckReturn;
  final Future Function()? onPaymentSuccess;
  final Function(String? code, String? messsage)? onPaymentError;
  final Function(String? message)? onShowDialogError;

  VNPayWebViewController({
    required this.schemeReturn,
    required this.listCheckReturn,
    this.onPaymentSuccess,
    this.onPaymentError,
    this.onShowDialogError,
  }) {
    _initAppLink();
  }

  ValueNotifier<bool> isLoading = ValueNotifier(false);

  Future<NavigationActionPolicy?> shouldOverrideUrlLoading(InAppWebViewController controller, NavigationAction navigationAction) async {
    var uri = navigationAction.request.url;
    String url = uri.toString();
    debugPrint(uri.toString());
    if (uri != null && !["http", "https", "file", "chrome", "data", "javascript", "about"].contains(uri.scheme)) {
      if (url.startsWith('intent://') && Platform.isAndroid) {
        final result = await FlutterIntentSchemeAndroid.openApp(url);
        if (!result) {
          onShowDialogError?.call("Không thể thanh toán bằng phương thức này");
        }
        return NavigationActionPolicy.CANCEL;
      } else if (url.startsWith(schemeReturn)) {
        _onCheckErrorCode(uri);
        return NavigationActionPolicy.CANCEL;
      } else if (Platform.isIOS) {
        try {
          UrlLauncherPlatform.instance.launchUrl(
            navigationAction.request.originalUrl!,
            const LaunchOptions(
              mode: PreferredLaunchMode.platformDefault,
              webViewConfiguration: InAppWebViewConfiguration(),
              webOnlyWindowName: null,
            ),
          );
        } catch (ex) {
          onShowDialogError?.call("Không thể thanh toán bằng phương thức này");
        }
        return NavigationActionPolicy.CANCEL;
      } else if (url.contains("viettelmoney://")) {
        try {
          await launchURL(url);
        } catch (ex) {
          onShowDialogError?.call("Không thể thanh toán bằng phương thức này");
        }
        return NavigationActionPolicy.CANCEL;
      }
    } else if (_checkReturnUrl(uri.toString()) || url.startsWith(schemeReturn)) {
      _onCheckErrorCode(uri!);
      return NavigationActionPolicy.ALLOW;
    }
    return NavigationActionPolicy.ALLOW;
  }

  static launchURL(String url, {bool isEncodeUri = true}) async {
    debugPrint("launchURL: $url");
    var _url = Uri.tryParse(isEncodeUri ? Uri.encodeFull(url) : url);
    if (_url != null) {
      if (!await launchUrl(_url, mode: LaunchMode.externalApplication)) throw 'Could not openURL $_url';
    } else {
      throw 'Could not openURL $url';
    }
  }

  bool _checkReturnUrl(String url) {
    for (var item in listCheckReturn) {
      if (url.contains(item)) {
        return true;
      }
    }
    return false;
  }

  _onCheckErrorCode(Uri uri) {
    var responseCode = uri.queryParameters["vnp_ResponseCode"];
    var error = {
      "07": "Trừ tiền thành công. Giao dịch bị nghi ngờ (liên quan tới lừa đảo, giao dịch bất thường).",
      "09": "Thẻ/Tài khoản của khách hàng chưa đăng ký dịch vụ InternetBanking tại ngân hàng.",
      "10": "Khách hàng xác thực thông tin thẻ/tài khoản không đúng quá 3 lần",
      "11": "Đã hết hạn chờ thanh toán. Xin quý khách vui lòng thực hiện lại giao dịch.",
      "12": "Thẻ/Tài khoản của khách hàng bị khóa.",
      "13": "Quý khách nhập sai mật khẩu xác thực giao dịch (OTP). Xin quý khách vui lòng thực hiện lại giao dịch.",
      "24": "Khách hàng hủy giao dịch.",
      "51": "Tài khoản của quý khách không đủ số dư để thực hiện giao dịch.",
      "65": "Tài khoản của Quý khách đã vượt quá hạn mức giao dịch trong ngày.",
      "75": "Ngân hàng thanh toán đang bảo trì.",
      "79": "KH nhập sai mật khẩu thanh toán quá số lần quy định. Xin quý khách vui lòng thực hiện lại giao dịch",
      "99": "Lỗi không xác định.",
    };
    if (responseCode == "00") {
      onPaymentSuccess?.call();
    } else {
      onPaymentError?.call(responseCode, error[responseCode] ?? "Lỗi không xác định");
    }
  }

  final _appLinks = AppLinks(); // AppLinks i
  StreamSubscription? _sub;

  _initAppLink() async {
    _sub = _appLinks.uriLinkStream.listen((uri) {
      _onCheckErrorCode(uri);
    });
  }

  dispose() {
    _sub?.cancel();
  }
}
