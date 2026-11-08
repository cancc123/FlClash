import 'dart:io';

import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/ui/icons/icons.dart';
import 'package:fl_clash/ui/ui.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// The platforms whose WebView can hold the gateway page inside the app.
bool get xboardSupportsEmbeddedPay =>
    !kIsWeb && (Platform.isAndroid || Platform.isIOS || Platform.isMacOS);

/// The panel's payment gateway, opened inside the app: paying leaves the user
/// on a page of FlClash rather than in a browser of its own.
class XboardCheckoutPage extends StatefulWidget {
  const XboardCheckoutPage({super.key, required this.url, required this.title});

  final String url;
  final String title;

  @override
  State<XboardCheckoutPage> createState() => _XboardCheckoutPageState();
}

class _XboardCheckoutPageState extends State<XboardCheckoutPage> {
  late final WebViewController _controller;
  int _progress = 0;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (progress) {
            if (!mounted) {
              return;
            }
            setState(() => _progress = progress);
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      title: widget.title,
      iconActions: [
        IconButtonData(
          glyph: AppGlyphs.refresh,
          tooltip: context.appLocalizations.update,
          onPressed: () => _controller.reload(),
        ),
      ],
      body: Column(
        children: [
          if (_progress < 100)
            LinearProgressIndicator(value: _progress / 100)
          else
            const SizedBox.shrink(),
          Expanded(child: WebViewWidget(controller: _controller)),
        ],
      ),
    );
  }
}
