import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Wraps any child widget and overlays an animated "No Internet" bar
/// whenever connectivity is lost.
class NoInternetWrapper extends StatefulWidget {
  final Widget child;
  const NoInternetWrapper({super.key, required this.child});

  @override
  State<NoInternetWrapper> createState() => _NoInternetWrapperState();
}

class _NoInternetWrapperState extends State<NoInternetWrapper> {
  bool _hasInternet = true;
  StreamSubscription<List<ConnectivityResult>>? _sub;

  @override
  void initState() {
    super.initState();

    // connectivity_plus's streaming API is not fully supported on web.
    // On web, the browser handles network state — we skip the listener.
    if (!kIsWeb) {
      _sub = Connectivity().onConnectivityChanged.listen((results) {
        final connected = results.any((r) => r != ConnectivityResult.none);
        if (mounted && connected != _hasInternet) {
          setState(() => _hasInternet = connected);
        }
      });

      Connectivity().checkConnectivity().then((results) {
        if (mounted) {
          setState(() {
            _hasInternet = results.any((r) => r != ConnectivityResult.none);
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        AnimatedPositioned(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOutBack,
          bottom: _hasInternet ? -120 : 0, // Slide up from bottom
          left: 0,
          right: 0,
          child: Material(
            elevation: 8,
            color: Colors.redAccent,
            child: SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.wifi_off_rounded, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text(
                      "No internet connection",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
