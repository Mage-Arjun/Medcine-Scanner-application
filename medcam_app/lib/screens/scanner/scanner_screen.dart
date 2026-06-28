import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:medcam_app/models/medicine.dart';
import 'package:medcam_app/providers/history_provider.dart';
import 'package:medcam_app/providers/scan_provider.dart';
import 'package:medcam_app/providers/shared_providers.dart';
import 'package:medcam_app/screens/result/result_sheet.dart';
import 'package:medcam_app/theme/app_theme.dart';
import 'package:medcam_app/widgets/viewfinder.dart';
import 'package:medcam_app/widgets/glass_card.dart';
import 'package:medcam_app/models/history_entry.dart';
import 'package:uuid/uuid.dart';
import 'package:google_fonts/google_fonts.dart';

class ScannerScreen extends ConsumerStatefulWidget {
  const ScannerScreen({super.key});

  @override
  ConsumerState<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends ConsumerState<ScannerScreen>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool _cameraError = false;
  TextRecognizer? _textRecognizer;
  bool _isProcessing = false;

  String _detectedText = '';
  String _stableText = '';
  int _stableCount = 0;
  Timer? _stabilityTimer;

  double _currentZoom = 1.0;
  double _zoomBase = 1.0;
  double _minZoom = 1.0;
  double _maxZoom = 1.0;

  String _debugStatus = 'initializing...';
  int _frameCount = 0;

  final _textController = TextEditingController();
  bool _showTextInput = false;
  int _scanStep = 0;
  List<OcrBlock>? _ocrBlocks;
  late AnimationController _stepController;

  static const _scanSteps = [
    'Reading Medicine',
    'Detecting Text',
    'Matching Database',
    'Medicine Found',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _stepController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _initCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopImageStream();
    _textRecognizer?.close();
    _stabilityTimer?.cancel();
    _textController.dispose();
    _stepController.dispose();
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final ctrl = _cameraController;
    if (ctrl == null || !ctrl.value.isInitialized) return;

    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _stopImageStream();
      ctrl.pausePreview();
    } else if (state == AppLifecycleState.resumed) {
      ctrl.resumePreview();
      _startImageStream();
    }
  }

  Future<void> _initCamera() async {
    final cameras = ref.read(camerasProvider);
    if (cameras.isEmpty) {
      setState(() => _cameraError = true);
      return;
    }

    final ctrl = CameraController(
      cameras.first,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    try {
      await ctrl.initialize();
      _minZoom = await ctrl.getMinZoomLevel();
      _maxZoom = await ctrl.getMaxZoomLevel();
      _currentZoom = 2.0.clamp(_minZoom, _maxZoom);
      if (!mounted) {
        ctrl.dispose();
        return;
      }
      setState(() {
        _cameraController = ctrl;
        _isCameraInitialized = true;
      });
      _textRecognizer = TextRecognizer();
      _startImageStream();
    } catch (e) {
      if (mounted) {
        setState(() => _cameraError = true);
      }
      ctrl.dispose();
    }
  }

  void _startImageStream() {
    try {
      _cameraController?.startImageStream(_processCameraImage);
      debugPrint('[MEDCAM] Image stream started');
      _updateStatus('stream active');
    } catch (e) {
      debugPrint('[MEDCAM] startImageStream failed: $e');
      _updateStatus('stream error: $e');
    }
  }

  void _stopImageStream() {
    final ctrl = _cameraController;
    if (ctrl == null) return;
    unawaited(ctrl.stopImageStream().catchError((_) {}));
  }

  Future<void> _processCameraImage(CameraImage image) async {
    if (_isProcessing || !mounted || _textRecognizer == null) return;
    _isProcessing = true;
    _frameCount++;

    try {
      final inputImage = _buildInputImage(image);
      if (inputImage == null) {
        debugPrint('[MEDCAM] _buildInputImage returned null');
        _updateStatus('buildInputImage null');
        return;
      }

      if (_frameCount % 15 == 0) {
        debugPrint('[MEDCAM] Processing frame #$_frameCount: ${image.width}x${image.height}');
        _updateStatus('processing frame #$_frameCount');
      }

      final result = await _textRecognizer!.processImage(inputImage);
      if (!mounted) return;

      // Filter blocks to only those within the circular viewport
      final imgW = image.width.toDouble();
      final imgH = image.height.toDouble();
      final vpCx = imgW / 2;
      final vpCy = imgH / 2;
      final vpRadius = (imgW < imgH ? imgW : imgH) * 0.35;
      final blocks = result.blocks.where((b) {
        final rect = b.boundingBox;
        final dx = rect.center.dx - vpCx;
        final dy = rect.center.dy - vpCy;
        return (dx * dx + dy * dy) <= vpRadius * vpRadius;
      }).toList();
      final text = blocks.map((b) => b.text).join('\n').trim();
      debugPrint('[MEDCAM] Frame #$_frameCount detected: "${text.length > 50 ? '${text.substring(0, 50)}...' : text}" (${text.length} chars, ${blocks.length} blocks in viewport)');

      if (text.length >= 3) {
        final firstLine = text.split('\n').firstWhere(
          (l) => l.trim().length >= 3,
          orElse: () => text,
        ).trim();

        _stableCount++;
        if (_stableCount >= 3 && _stableText.isEmpty) {
          debugPrint('[MEDCAM] Text stable for $_stableCount frames: "$firstLine"');
          setState(() => _stableText = firstLine);
          _stabilityTimer?.cancel();
          _stabilityTimer = Timer(const Duration(seconds: 1), () {
            if (mounted) HapticFeedback.lightImpact();
          });
        }
        if (mounted) {
          setState(() {
            _detectedText = firstLine;
            _debugStatus = 'detected: $firstLine';
          });
        }
      } else if (mounted && text.isEmpty) {
        _stableCount = 0;
        setState(() {
          _detectedText = '';
          _debugStatus = 'no text in frame';
        });
      }
    } catch (e) {
      debugPrint('[MEDCAM] processImage error: $e');
      _updateStatus('error: ${e.toString().length > 60 ? '${e.toString().substring(0, 60)}...' : e}');
    } finally {
      _isProcessing = false;
    }
  }

  void _updateStatus(String msg) {
    if (mounted) setState(() => _debugStatus = msg);
  }

  InputImage? _buildInputImage(CameraImage image) {
    debugPrint('[MEDCAM] Frame: planes=${image.planes.length}, '
        'size=${image.width}x${image.height}, '
        'bpr=${image.planes.map((p) => p.bytesPerRow)}');

    // Convert YUV_420_888 (3 planes with stride) → NV21 (Y + interleaved VU)
    final nv21 = _yuv420toNv21(image);

    final metadata = InputImageMetadata(
      size: Size(image.width.toDouble(), image.height.toDouble()),
      rotation: InputImageRotation.rotation0deg,
      format: InputImageFormat.nv21,
      bytesPerRow: image.width,
    );

    debugPrint('[MEDCAM] NV21 built: ${image.width}x${image.height}, bytes=${nv21.length}');
    return InputImage.fromBytes(bytes: nv21, metadata: metadata);
  }

  Uint8List _yuv420toNv21(CameraImage image) {
    final width = image.width;
    final height = image.height;
    final yStride = image.planes[0].bytesPerRow;
    final uvStride = image.planes[1].bytesPerRow;

    final ySize = width * height;
    final uvSize = width * height ~/ 2;
    final nv21 = Uint8List(ySize + uvSize);

    // Copy Y plane (strip stride padding)
    final yPlane = image.planes[0].bytes;
    var dest = 0;
    for (int row = 0; row < height; row++) {
      final srcStart = row * yStride;
      nv21.setRange(dest, dest + width, yPlane, srcStart);
      dest += width;
    }

    // Interleave V and U (NV21: V first, then U)
    final uPlane = image.planes[1].bytes;
    final vPlane = image.planes[2].bytes;

    for (int row = 0; row < height ~/ 2; row++) {
      for (int col = 0; col < width ~/ 2; col++) {
        final uvIndex = row * uvStride + col;
        nv21[dest++] = vPlane[uvIndex];
        nv21[dest++] = uPlane[uvIndex];
      }
    }

    return nv21;
  }

  Future<void> _searchText(String text) async {
    if (text.trim().isEmpty) return;

    HapticFeedback.mediumImpact();
    setState(() {
      _showTextInput = true;
      _textController.text = text;
    });
    _submitText();
  }

  Future<void> _submitText() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    HapticFeedback.mediumImpact();

    for (int i = 0; i < _scanSteps.length - 1; i++) {
      setState(() => _scanStep = i);
      await Future.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;
    }

    final userBlock = OcrBlock(text: text, confidence: 1.0);
    final blocks = _ocrBlocks != null ? [..._ocrBlocks!, userBlock] : [userBlock];
    ref.read(scanProvider.notifier).setOcrBlocks(blocks);
    await ref.read(scanProvider.notifier).identify();

    final state = ref.read(scanProvider);
    if (state.response != null && state.response!.results.isNotEmpty && mounted) {
      final result = state.response!.results.first;

      setState(() => _scanStep = _scanSteps.length - 1);
      await Future.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;

      final entry = HistoryEntry.fromResult(
        id: const Uuid().v4(),
        result: result,
        source: 'scan',
        query: text,
      );
      ref.read(historyProvider.notifier).add(entry);

      _textController.clear();
      if (!mounted) return;
      setState(() {
        _showTextInput = false;
        _scanStep = 0;
        _detectedText = '';
        _stableText = '';
        _stableCount = 0;
      });

      HapticFeedback.heavyImpact();

      if (!mounted) return;
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => ResultSheet(result: result),
      );
    } else if (state.error != null && mounted) {
      setState(() => _scanStep = 0);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${state.error}')),
      );
    } else if (mounted) {
      setState(() => _scanStep = 0);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No results found. Try a different text.'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scanState = ref.watch(scanProvider);

    return Stack(
      children: [
        if (_showTextInput)
          _buildTextInput(scanState)
        else
          _buildScanner(scanState),
        if (scanState.isProcessing) _buildProcessingOverlay(),
      ],
    );
  }

  Widget _buildScanner(ScanState scanState) {
    final screenSize = MediaQuery.of(context).size;
    final vpSize = screenSize.shortestSide * 0.72;

    if (_cameraError) {
      return _buildCameraError();
    }

    return Column(
      children: [
        Expanded(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Camera viewport + viewfinder + zoom buttons
                GestureDetector(
                  onScaleStart: (_) => _zoomBase = _currentZoom,
                  onScaleUpdate: (details) {
                    final z = (_zoomBase * details.scale).clamp(_minZoom, _maxZoom);
                    if (z != _currentZoom) {
                      _cameraController?.setZoomLevel(z);
                      setState(() => _currentZoom = z);
                    }
                  },
                  child: SizedBox(
                    width: vpSize,
                    height: vpSize,
                    child: Stack(
                      clipBehavior: Clip.hardEdge,
                      children: [
                        // Camera preview clipped to circle
                        if (_isCameraInitialized && _cameraController != null)
                          ClipOval(
                            child: OverflowBox(
                              alignment: Alignment.center,
                              minWidth: vpSize,
                              minHeight: vpSize,
                              maxWidth: vpSize * 2,
                              maxHeight: vpSize * 2,
                              child: CameraPreview(_cameraController!),
                            ),
                          )
                        else
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.bgRaised,
                            ),
                            child: const Center(
                              child: CircularProgressIndicator(strokeWidth: 3),
                            ),
                          ),

                        // Viewfinder ring overlay
                        Viewfinder(
                          size: vpSize,
                          isScanning: scanState.isProcessing,
                          primaryColor: Theme.of(context).colorScheme.primary,
                        ),

                        // Zoom pill buttons
                        Positioned(
                          right: 12,
                          bottom: 12,
                          child: _buildZoomButtons(),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                // Detected text chip or helper text
                if (_detectedText.isNotEmpty)
                  _buildDetectedTextChip()
                else
                  Text(
                    'point camera at medicine text',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 12,
                      color: AppColors.inkMuted,
                      letterSpacing: 0.8,
                    ),
                  ),
                const SizedBox(height: AppSpacing.sm),
                // Debug status indicator
                AnimatedOpacity(
                  opacity: _debugStatus.contains('error') ? 1.0 : 0.5,
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    _debugStatus,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 9,
                      color: _debugStatus.contains('error')
                          ? Colors.redAccent
                          : AppColors.inkFaint,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        _buildBottomBar(),
      ],
    );
  }

  Widget _buildZoomButtons() {
    final brightness = Theme.of(context).brightness;
    final levels = [2.0];

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: levels.map((level) {
        final isActive = _currentZoom >= level - 0.1 && _currentZoom < level + 0.1;
        final isAvailable = level <= _maxZoom;

        return Padding(
          padding: const EdgeInsets.only(left: 4),
          child: GestureDetector(
            onTap: isAvailable
                ? () {
                    HapticFeedback.lightImpact();
                    _cameraController?.setZoomLevel(level);
                    setState(() => _currentZoom = level);
                  }
                : null,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isActive
                    ? AppColors.primary(brightness)
                    : Colors.black26,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isActive
                      ? AppColors.primary(brightness)
                      : Colors.white38,
                  width: 1,
                ),
              ),
              child: Text(
                '${level.toInt()}×',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isActive ? Colors.white : Colors.white70,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDetectedTextChip() {
    final brightness = Theme.of(context).brightness;
    return GestureDetector(
      onTap: () => _searchText(_stableText.isNotEmpty ? _stableText : _detectedText),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.primary(brightness),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.text_snippet_rounded,
                size: 18,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'DETECTED',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary(brightness),
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _stableText.isNotEmpty ? _stableText : _detectedText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: AppColors.inkMuted,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    final brightness = Theme.of(context).brightness;
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.xxxl,
        AppSpacing.lg,
        AppSpacing.xxxl,
        MediaQuery.of(context).padding.bottom + AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Show search button when text is detected, else fallback capture
          if (_stableText.isNotEmpty)
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: () => _searchText(_stableText),
                icon: const Icon(Icons.search_rounded, size: 22),
                label: Text(
                  'SEARCH "${_stableText.length > 20 ? '${_stableText.substring(0, 20)}...' : _stableText}"',
                  style: const TextStyle(fontSize: 15, letterSpacing: 0.5),
                  overflow: TextOverflow.ellipsis,
                ),
                style: ElevatedButton.styleFrom(
                  elevation: 6,
                  shadowColor: AppColors.primary(brightness).withValues(alpha: 0.3),
                ),
              ),
            )
          else
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: null,
                icon: const Icon(Icons.camera_alt_rounded, size: 22),
                label: Text(
                  'WAITING FOR TEXT...',
                  style: const TextStyle(fontSize: 15, letterSpacing: 0.5),
                ),
                style: ElevatedButton.styleFrom(
                  elevation: 6,
                  shadowColor: AppColors.primary(brightness).withValues(alpha: 0.3),
                ),
              ),
            ),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed: () {
                HapticFeedback.lightImpact();
                _stopImageStream();
                setState(() {
                  _showTextInput = true;
                  _textController.text = _stableText;
                });
              },
              icon: const Icon(Icons.edit_rounded, size: 20),
              label: const Text(
                'ENTER MANUALLY',
                style: TextStyle(fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraError() {
    final brightness = Theme.of(context).brightness;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.primaryFaint(brightness),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.videocam_off_rounded,
                color: AppColors.primary(brightness),
                size: 36,
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            Text(
              'Camera Unavailable',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Please grant camera permission in Settings\nto scan medicines',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textMuted(brightness),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xxl),
            ElevatedButton.icon(
              onPressed: () => _initCamera(),
              icon: const Icon(Icons.refresh_rounded, size: 20),
              label: const Text('RETRY'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextInput(ScanState scanState) {
    final brightness = Theme.of(context).brightness;

    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.primaryFaint(brightness),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.edit_note_rounded,
                  color: AppColors.primary(brightness),
                  size: 36,
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              Text(
                'Enter Medicine Details',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Type the name, dosage, or any text from packaging',
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xxxl),
              GlassCard(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: TextField(
                  controller: _textController,
                  autofocus: true,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    color: AppColors.text(brightness),
                  ),
                  decoration: const InputDecoration(
                    hintText: 'e.g. Dolo 650',
                    prefixIcon: Icon(Icons.medication_rounded, size: 20),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _submitText(),
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        _textController.clear();
                        setState(() => _showTextInput = false);
                      },
                      child: const Text('BACK'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: scanState.isProcessing ? null : _submitText,
                      child: scanState.isProcessing
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('SEARCH'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProcessingOverlay() {
    final brightness = Theme.of(context).brightness;
    final primary = AppColors.primary(brightness);
    return Container(
      color: AppColors.bgBase.withValues(alpha: 0.92),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 1500),
                builder: (_, value, _) {
                  return Transform.scale(
                    scale: 0.8 + (value * 0.2),
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: primary.withValues(alpha: 0.1),
                        border: Border.all(
                          color: primary.withValues(alpha: value * 0.5),
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        Icons.document_scanner_rounded,
                        color: primary.withValues(alpha: value),
                        size: 36,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: AppSpacing.xxxl),
              ...List.generate(_scanSteps.length, (index) {
                final isActive = index == _scanStep;
                final isComplete = index < _scanStep;
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isComplete
                              ? primary
                              : isActive
                                  ? primary.withValues(alpha: 0.2)
                                  : AppColors.bgRaised,
                          border: Border.all(
                            color: isComplete
                                ? primary
                                : isActive
                                    ? primary
                                    : AppColors.border,
                            width: 1.5,
                          ),
                        ),
                        child: isComplete
                            ? const Icon(Icons.check_rounded, size: 14, color: AppColors.bgBase)
                            : isActive
                                ? SizedBox(
                                    width: 12,
                                    height: 12,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: primary,
                                    ),
                                  )
                                : null,
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Text(
                        _scanSteps[index],
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                          color: isActive
                              ? primary
                              : isComplete
                                  ? AppColors.ink
                                  : AppColors.inkFaint,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
