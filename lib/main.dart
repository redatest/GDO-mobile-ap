import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const GdoMobileApp());
}

class GdoMobileApp extends StatelessWidget {
  const GdoMobileApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GDO-MT',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFEA580C)),
        useMaterial3: true,
      ),
      home: const GdoHomePage(),
    );
  }
}

class GdoHomePage extends StatefulWidget {
  const GdoHomePage({super.key});

  @override
  State<GdoHomePage> createState() => _GdoHomePageState();
}

class _GdoHomePageState extends State<GdoHomePage> {
  HttpServer? _server;
  WebViewController? _controller;
  String? _startupError;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _startLocalApplication();
  }

  Future<void> _startLocalApplication() async {
    try {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      server.listen(_serveAsset);
      _server = server;

      final controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(const Color(0xFFF2F7F8))
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageStarted: (_) {
              if (mounted) setState(() => _loading = true);
            },
            onPageFinished: (_) {
              if (mounted) setState(() => _loading = false);
            },
            onWebResourceError: (error) {
              if (error.isForMainFrame == true && mounted) {
                setState(() {
                  _startupError = 'Erreur de chargement : ${error.description}';
                  _loading = false;
                });
              }
            },
            onNavigationRequest: (request) {
              final uri = Uri.tryParse(request.url);
              if (uri != null &&
                  (uri.host == '127.0.0.1' || uri.host == 'localhost')) {
                return NavigationDecision.navigate;
              }
              return NavigationDecision.prevent;
            },
          ),
        );

      _controller = controller;
      await controller.loadRequest(
        Uri.parse('http://127.0.0.1:${server.port}/'),
      );
      if (mounted) setState(() {});
    } catch (error) {
      if (mounted) {
        setState(() {
          _startupError = 'Impossible de démarrer GDO-MT : $error';
          _loading = false;
        });
      }
    }
  }

  Future<void> _serveAsset(HttpRequest request) async {
    final response = request.response;
    try {
      var path = Uri.decodeComponent(request.uri.path);
      if (path.isEmpty || path == '/') path = '/index.html';
      if (path.contains('..') || path.contains('\\\\')) {
        response.statusCode = HttpStatus.badRequest;
        await response.close();
        return;
      }

      final assetPath = 'assets/gdo${path}';
      final data = await rootBundle.load(assetPath);

      // HttpHeaders.contentType attend un objet ContentType.
      // Headers.set(), lui, attend une valeur texte : lui passer ContentType
      // déclenche "unexpected type for header name content-type".
      response.headers.contentType = _contentType(path);
      response.headers.set(HttpHeaders.cacheControlHeader, 'no-cache');
      response.headers.set('X-Content-Type-Options', 'nosniff');

      response.add(data.buffer.asUint8List(
        data.offsetInBytes,
        data.lengthInBytes,
      ));
    } on FlutterError {
      response.statusCode = HttpStatus.notFound;
      response.headers.contentType = ContentType.text;
      response.write('404 - Ressource GDO-MT introuvable');
    } catch (error) {
      response.statusCode = HttpStatus.internalServerError;
      response.headers.contentType = ContentType.text;
      response.write('Erreur locale : $error');
    } finally {
      await response.close();
    }
  }

  ContentType _contentType(String path) {
    final extension = path.split('.').last.toLowerCase();
    switch (extension) {
      case 'html':
        return ContentType.html;
      case 'js':
      case 'mjs':
        return ContentType('text', 'javascript', charset: 'utf-8');
      case 'css':
        return ContentType('text', 'css', charset: 'utf-8');
      case 'json':
        return ContentType.json;
      case 'svg':
        return ContentType('image', 'svg+xml');
      case 'png':
        return ContentType('image', 'png');
      case 'jpg':
      case 'jpeg':
        return ContentType('image', 'jpeg');
      case 'webp':
        return ContentType('image', 'webp');
      case 'woff':
        return ContentType('font', 'woff');
      case 'woff2':
        return ContentType('font', 'woff2');
      default:
        return ContentType.binary;
    }
  }

  Future<bool> _handleBack() async {
    final controller = _controller;
    if (controller != null && await controller.canGoBack()) {
      await controller.goBack();
      return false;
    }
    return true;
  }

  @override
  void dispose() {
    _server?.close(force: true);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop && await _handleBack() && mounted) {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF2F7F8),
        body: SafeArea(
          child: Stack(
            children: [
              if (controller != null)
                WebViewWidget(controller: controller),
              if (_loading)
                const Align(
                  alignment: Alignment.topCenter,
                  child: LinearProgressIndicator(
                    minHeight: 2,
                    color: Color(0xFFEA580C),
                    backgroundColor: Colors.transparent,
                  ),
                ),
              if (_startupError != null)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline,
                            size: 44, color: Colors.red),
                        const SizedBox(height: 12),
                        const Text('GDO-MT ne peut pas démarrer',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text(_startupError!, textAlign: TextAlign.center),
                        const SizedBox(height: 18),
                        FilledButton(
                          onPressed: () {
                            setState(() {
                              _startupError = null;
                              _loading = true;
                            });
                            _controller?.reload();
                          },
                          child: const Text('Réessayer'),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
