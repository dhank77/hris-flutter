import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'package:flutter_antigravity_starter_pack/core/error/app_exception.dart';
import 'package:flutter_antigravity_starter_pack/core/widgets/app_lottie.dart';
import 'package:flutter_antigravity_starter_pack/core/widgets/state_views.dart';

/// URL landing page informasi aplikasi.
final infoLandingPageUri = Uri.parse(
  'https://darkred-mule-141907.hostingersite.com/',
);

/// Kontrak builder tampilan WebView agar mudah diganti dengan fake saat widget
/// test tanpa bergantung pada platform WebView native.
typedef InfoWebViewBuilder =
    Widget Function({
      required Uri initialUri,
      required ValueChanged<int> onProgress,
      required VoidCallback onPageFinished,
      required ValueChanged<String> onError,
      required ValueChanged<Future<void> Function()> onReloadReady,
    });

/// Provider builder WebView untuk halaman Tentang & Informasi.
/// Hidup sepanjang aplikasi karena tidak menyimpan state internal.
final infoWebViewBuilderProvider = Provider<InfoWebViewBuilder>(
  (ref) =>
      ({
        required initialUri,
        required onProgress,
        required onPageFinished,
        required onError,
        required onReloadReady,
      }) => _NativeInfoWebView(
        initialUri: initialUri,
        onProgress: onProgress,
        onPageFinished: onPageFinished,
        onError: onError,
        onReloadReady: onReloadReady,
      ),
);

/// Halaman Tentang & Informasi yang menampilkan landing page melalui WebView.
class AboutInfoPage extends ConsumerStatefulWidget {
  const AboutInfoPage({super.key});

  @override
  ConsumerState<AboutInfoPage> createState() => _AboutInfoPageState();
}

class _AboutInfoPageState extends ConsumerState<AboutInfoPage> {
  int _progress = 0;
  String? _errorMessage;
  Future<void> Function()? _reloadCallback;

  Future<void> _reload() async {
    setState(() {
      _errorMessage = null;
      _progress = 0;
    });
    await _reloadCallback?.call();
  }

  @override
  Widget build(BuildContext context) {
    final buildWebView = ref.watch(infoWebViewBuilderProvider);
    final isLoading = _progress < 100 && _errorMessage == null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tentang & Informasi'),
        actions: [
          IconButton(
            key: const Key('aboutInfo.refresh'),
            tooltip: 'Muat ulang',
            onPressed: _reload,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          if (isLoading)
            LinearProgressIndicator(
              key: const Key('aboutInfo.progress'),
              value: _progress > 0 ? _progress / 100 : null,
            ),
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                buildWebView(
                  initialUri: infoLandingPageUri,
                  onProgress: (progress) {
                    if (!mounted) return;
                    setState(() => _progress = progress);
                  },
                  onPageFinished: () {
                    if (!mounted) return;
                    setState(() => _progress = 100);
                  },
                  onError: (message) {
                    if (!mounted) return;
                    setState(() => _errorMessage = message);
                  },
                  onReloadReady: (reload) {
                    _reloadCallback = reload;
                  },
                ),
                if (isLoading)
                  const IgnorePointer(
                    child: Center(
                      child: AppLottie.loading(
                        key: Key('aboutInfo.loading'),
                        size: 100,
                      ),
                    ),
                  ),
                if (_errorMessage != null)
                  Positioned.fill(
                    child: ColoredBox(
                      color: Theme.of(context).colorScheme.surface,
                      child: ErrorView(
                        error: NetworkException(_errorMessage!),
                        onRetry: _reload,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NativeInfoWebView extends StatefulWidget {
  const _NativeInfoWebView({
    required this.initialUri,
    required this.onProgress,
    required this.onPageFinished,
    required this.onError,
    required this.onReloadReady,
  });

  final Uri initialUri;
  final ValueChanged<int> onProgress;
  final VoidCallback onPageFinished;
  final ValueChanged<String> onError;
  final ValueChanged<Future<void> Function()> onReloadReady;

  @override
  State<_NativeInfoWebView> createState() => _NativeInfoWebViewState();
}

class _NativeInfoWebViewState extends State<_NativeInfoWebView> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: widget.onProgress,
          onPageFinished: (_) => widget.onPageFinished(),
          onWebResourceError: (error) {
            if (error.isForMainFrame ?? true) {
              widget.onError(
                'Gagal memuat halaman informasi (${error.description}).',
              );
            }
          },
        ),
      )
      ..loadRequest(widget.initialUri);

    widget.onReloadReady(() => _controller.reload());
  }

  @override
  Widget build(BuildContext context) {
    return WebViewWidget(controller: _controller);
  }
}
