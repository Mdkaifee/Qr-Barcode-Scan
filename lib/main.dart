import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Scanner',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0F766E)),
        scaffoldBackgroundColor: const Color(0xFFF4F7F5),
      ),
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _openHome();
  }

  Future<void> _openHome() async {
    await Future<void>.delayed(const Duration(seconds: 2));
    if (!mounted) {
      return;
    }

    await Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF042F2E), Color(0xFF115E59), Color(0xFF14B8A6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: const SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(22),
                    child: Icon(
                      Icons.qr_code_scanner_rounded,
                      size: 72,
                      color: Color(0xFF115E59),
                    ),
                  ),
                ),
                SizedBox(height: 24),
                Text(
                  'Scanner',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'QR and barcode reader',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
                SizedBox(height: 28),
                SizedBox(
                  width: 36,
                  height: 36,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0F766E), Color(0xFF14B8A6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.center_focus_strong_rounded,
                      size: 44,
                      color: Colors.white,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Ready to scan',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Tap the button below to open the camera and scan any QR code or barcode.',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const ScanScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.qr_code_scanner_rounded),
                  label: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      'Scan',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
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

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );

  Barcode? _scannedBarcode;
  String? _scannedValue;
  String? _cameraError;
  bool _isStopping = false;

  @override
  void dispose() {
    unawaited(_controller.dispose());
    super.dispose();
  }

  Future<void> _handleDetection(BarcodeCapture capture) async {
    if (_isStopping || capture.barcodes.isEmpty) {
      return;
    }

    final Barcode barcode = capture.barcodes.first;
    final String? value = barcode.displayValue ?? barcode.rawValue;

    if (value == null || value.trim().isEmpty) {
      return;
    }

    setState(() {
      _isStopping = true;
      _scannedBarcode = barcode;
      _scannedValue = value;
      _cameraError = null;
    });

    try {
      await _controller.stop();
    } finally {
      if (mounted) {
        setState(() {
          _isStopping = false;
        });
      }
    }
  }

  Future<void> _scanAgain() async {
    setState(() {
      _scannedBarcode = null;
      _scannedValue = null;
      _cameraError = null;
    });

    await _controller.start();
  }

  bool get _isLink {
    final String? value = _scannedValue;
    if (value == null) {
      return false;
    }

    final Uri? uri = Uri.tryParse(value);
    return uri != null && uri.hasScheme && uri.host.isNotEmpty;
  }

  List<_ScanDetail> get _scanDetails {
    final Barcode? barcode = _scannedBarcode;
    if (barcode == null) {
      return const <_ScanDetail>[];
    }

    final details = <_ScanDetail>[
      _ScanDetail('Format', _enumLabel(barcode.format.name)),
      _ScanDetail('Detected type', _enumLabel(barcode.type.name)),
    ];

    _addDetail(details, 'Display value', barcode.displayValue);
    _addDetail(details, 'Raw value', barcode.rawValue);
    _addDetail(details, 'URL', barcode.url?.url);
    _addDetail(details, 'URL title', barcode.url?.title);
    _addDetail(details, 'Phone', barcode.phone?.number);
    _addDetail(details, 'Email', barcode.email?.address);
    _addDetail(details, 'Email subject', barcode.email?.subject);
    _addDetail(details, 'Email body', barcode.email?.body);
    _addDetail(details, 'SMS number', barcode.sms?.phoneNumber);
    _addDetail(details, 'SMS message', barcode.sms?.message);
    _addDetail(details, 'Wi-Fi SSID', barcode.wifi?.ssid);
    _addDetail(details, 'Wi-Fi password', barcode.wifi?.password);

    if (barcode.wifi != null) {
      _addDetail(
        details,
        'Wi-Fi security',
        _enumLabel(barcode.wifi!.encryptionType.name),
      );
    }

    if (barcode.geoPoint != null) {
      _addDetail(
        details,
        'Coordinates',
        '${barcode.geoPoint!.latitude}, ${barcode.geoPoint!.longitude}',
      );
    }

    return details;
  }

  void _addDetail(List<_ScanDetail> details, String label, String? value) {
    final String? cleaned = value?.trim();
    if (cleaned == null || cleaned.isEmpty) {
      return;
    }

    final bool alreadyPresent = details.any(
      (detail) => detail.label == label && detail.value == cleaned,
    );
    if (!alreadyPresent) {
      details.add(_ScanDetail(label, cleaned));
    }
  }

  String _enumLabel(String raw) {
    return raw
        .split('_')
        .map((part) {
          if (part.isEmpty) {
            return part;
          }
          return '${part[0].toUpperCase()}${part.substring(1)}';
        })
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Scan QR / Barcode')),
      body: Stack(
        children: [
          Positioned.fill(
            child: MobileScanner(
              controller: _controller,
              onDetect: (capture) {
                unawaited(_handleDetection(capture));
              },
              errorBuilder: (context, error) {
                final String message =
                    error.errorCode == MobileScannerErrorCode.permissionDenied
                    ? 'Camera permission denied. Please allow camera access to scan codes.'
                    : error.errorCode.message;

                return ColoredBox(
                  color: const Color(0xFF0F172A),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        message,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                );
              },
              overlayBuilder: (context, constraints) {
                return _ScannerOverlay(
                  size: constraints.maxWidth * 0.68,
                  borderRadius: 24,
                  cornerLength: 30,
                  cornerStroke: 5,
                  overlayColor: Colors.black.withValues(alpha: 0.42),
                  cornerColor: Colors.white,
                );
              },
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.10),
                    blurRadius: 20,
                    offset: const Offset(0, -8),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _scannedValue == null
                          ? 'Point the camera at a QR code or barcode.'
                          : _isLink
                          ? 'Scanned link'
                          : 'Scanned code',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDFA),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFF99F6E4)),
                      ),
                      child: Text(
                        _cameraError ??
                            _scannedValue ??
                            'No result yet. Tap Scan Again after a successful scan if you want to scan another code.',
                        style: theme.textTheme.bodyLarge?.copyWith(height: 1.4),
                      ),
                    ),
                    if (_scanDetails.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Scan details',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFFD1FAE5)),
                        ),
                        child: Column(
                          children: [
                            for (final detail in _scanDetails)
                              _ScanDetailRow(detail: detail),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _scanAgain,
                        child: const Padding(
                          padding: EdgeInsets.symmetric(vertical: 14),
                          child: Text(
                            'Scan Again',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScannerOverlay extends StatelessWidget {
  const _ScannerOverlay({
    required this.size,
    required this.borderRadius,
    required this.cornerLength,
    required this.cornerStroke,
    required this.overlayColor,
    required this.cornerColor,
  });

  final double size;
  final double borderRadius;
  final double cornerLength;
  final double cornerStroke;
  final Color overlayColor;
  final Color cornerColor;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _ScannerOverlayPainter(
        size: size,
        borderRadius: borderRadius,
        cornerLength: cornerLength,
        cornerStroke: cornerStroke,
        overlayColor: overlayColor,
        cornerColor: cornerColor,
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _ScannerOverlayPainter extends CustomPainter {
  const _ScannerOverlayPainter({
    required this.size,
    required this.borderRadius,
    required this.cornerLength,
    required this.cornerStroke,
    required this.overlayColor,
    required this.cornerColor,
  });

  final double size;
  final double borderRadius;
  final double cornerLength;
  final double cornerStroke;
  final Color overlayColor;
  final Color cornerColor;

  @override
  void paint(Canvas canvas, Size canvasSize) {
    final double scanSize = size.clamp(160.0, canvasSize.width - 48);
    final Rect scanRect = Rect.fromCenter(
      center: canvasSize.center(Offset.zero),
      width: scanSize,
      height: scanSize,
    );
    final RRect scanRRect = RRect.fromRectAndRadius(
      scanRect,
      Radius.circular(borderRadius),
    );

    final Path overlayPath = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & canvasSize)
      ..addRRect(scanRRect);

    canvas.drawPath(overlayPath, Paint()..color = overlayColor);

    final Paint cornerPaint = Paint()
      ..color = cornerColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = cornerStroke
      ..strokeCap = StrokeCap.round;

    final double left = scanRect.left;
    final double top = scanRect.top;
    final double right = scanRect.right;
    final double bottom = scanRect.bottom;
    final double radius = borderRadius;

    final Path corners = Path()
      ..moveTo(left + radius, top)
      ..lineTo(left + cornerLength, top)
      ..moveTo(left, top + radius)
      ..lineTo(left, top + cornerLength)
      ..moveTo(right - radius, top)
      ..lineTo(right - cornerLength, top)
      ..moveTo(right, top + radius)
      ..lineTo(right, top + cornerLength)
      ..moveTo(left + radius, bottom)
      ..lineTo(left + cornerLength, bottom)
      ..moveTo(left, bottom - radius)
      ..lineTo(left, bottom - cornerLength)
      ..moveTo(right - radius, bottom)
      ..lineTo(right - cornerLength, bottom)
      ..moveTo(right, bottom - radius)
      ..lineTo(right, bottom - cornerLength);

    canvas.drawArc(
      Rect.fromCircle(
        center: Offset(left + radius, top + radius),
        radius: radius,
      ),
      3.1415926535,
      1.5707963268,
      false,
      cornerPaint,
    );
    canvas.drawArc(
      Rect.fromCircle(
        center: Offset(right - radius, top + radius),
        radius: radius,
      ),
      -1.5707963268,
      1.5707963268,
      false,
      cornerPaint,
    );
    canvas.drawArc(
      Rect.fromCircle(
        center: Offset(left + radius, bottom - radius),
        radius: radius,
      ),
      1.5707963268,
      1.5707963268,
      false,
      cornerPaint,
    );
    canvas.drawArc(
      Rect.fromCircle(
        center: Offset(right - radius, bottom - radius),
        radius: radius,
      ),
      0,
      1.5707963268,
      false,
      cornerPaint,
    );
    canvas.drawPath(corners, cornerPaint);
  }

  @override
  bool shouldRepaint(covariant _ScannerOverlayPainter oldDelegate) {
    return oldDelegate.size != size ||
        oldDelegate.borderRadius != borderRadius ||
        oldDelegate.cornerLength != cornerLength ||
        oldDelegate.cornerStroke != cornerStroke ||
        oldDelegate.overlayColor != overlayColor ||
        oldDelegate.cornerColor != cornerColor;
  }
}

class _ScanDetail {
  const _ScanDetail(this.label, this.value);

  final String label;
  final String value;
}

class _ScanDetailRow extends StatelessWidget {
  const _ScanDetailRow({required this.detail});

  final _ScanDetail detail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 108,
            child: Text(
              detail.label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F766E),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              detail.value,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}
