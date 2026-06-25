import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:medcam_app/models/medicine.dart';
import 'package:medcam_app/providers/history_provider.dart';
import 'package:medcam_app/providers/scan_provider.dart';
import 'package:medcam_app/screens/result/result_sheet.dart';
import 'package:medcam_app/theme/app_theme.dart';
import 'package:medcam_app/widgets/viewfinder.dart';
import 'package:medcam_app/models/history_entry.dart';
import 'package:uuid/uuid.dart';
import 'package:google_fonts/google_fonts.dart';

class ScannerScreen extends ConsumerStatefulWidget {
  const ScannerScreen({super.key});

  @override
  ConsumerState<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends ConsumerState<ScannerScreen> {
  final _imagePicker = ImagePicker();
  final _textController = TextEditingController();
  bool _showTextInput = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _captureImage() async {
    setState(() => _showTextInput = false);

    final source = kIsWeb ? ImageSource.gallery : ImageSource.camera;

    XFile? image;
    try {
      image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1200,
        imageQuality: 80,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Camera error: $e')),
        );
      }
      return;
    }

    if (image == null || !mounted) return;

    ref.read(scanProvider.notifier).setCapturing(false);

    if (kIsWeb) {
      setState(() => _showTextInput = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Image captured. Enter text seen on the medicine.')),
      );
    } else {
      // Mobile: show text input for manual entry (ML Kit integration can replace this)
      setState(() => _showTextInput = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Image captured. Enter text from the medicine packaging.')),
      );
    }
  }

  Future<void> _submitText() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    final blocks = [OcrBlock(text: text, confidence: 1.0)];
    ref.read(scanProvider.notifier).setOcrBlocks(blocks);
    await ref.read(scanProvider.notifier).identify();

    final state = ref.read(scanProvider);
    if (state.response != null && state.response!.results.isNotEmpty && mounted) {
      final result = state.response!.results.first;

      // Save to history
      final entry = HistoryEntry.fromResult(
        id: const Uuid().v4(),
        result: result,
        source: 'scan',
        query: text,
      );
      ref.read(historyProvider.notifier).add(entry);

      _textController.clear();
      setState(() => _showTextInput = false);

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => ResultSheet(result: result),
      );
    } else if (state.error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${state.error}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scanState = ref.watch(scanProvider);

    return Stack(
      children: [
        // Main content
        if (!_showTextInput)
          _buildScanner(scanState)
        else
          _buildTextInput(scanState),

        // Loading overlay
        if (scanState.isProcessing)
          Container(
            color: Colors.black54,
            child: const Center(
              child: CircularProgressIndicator(color: AppColors.amberGlow),
            ),
          ),
      ],
    );
  }

  Widget _buildScanner(ScanState scanState) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(flex: 2),
          const Viewfinder(size: 260),
          const SizedBox(height: 16),
          Text(
            'align medicine within the field',
            style: GoogleFonts.ibmPlexMono(
              fontSize: 11,
              color: AppColors.inkMuted,
              letterSpacing: 0.15,
            ),
          ),
          const Spacer(flex: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: scanState.isProcessing ? null : _captureImage,
                    icon: const Icon(Icons.qr_code_scanner, size: 20),
                    label: Text(
                      kIsWeb ? 'UPLOAD IMAGE' : 'CAPTURE',
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      setState(() => _showTextInput = true);
                    },
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('ENTER MANUALLY'),
                  ),
                ),
              ],
            ),
          ),
          const Spacer(flex: 2),
        ],
      ),
    );
  }

  Widget _buildTextInput(ScanState scanState) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.edit_note, color: AppColors.amberDim, size: 48),
          const SizedBox(height: 16),
          Text(
            'enter medicine details',
            style: GoogleFonts.cormorantGaramond(
              fontSize: 20,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'type the name, dosage, or any text from packaging',
            style: GoogleFonts.ibmPlexMono(
              fontSize: 11,
              color: AppColors.inkFaint,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _textController,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'e.g. Dolo 650',
            ),
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _submitText(),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    _textController.clear();
                    setState(() => _showTextInput = false);
                  },
                  child: const Text('BACK'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: scanState.isProcessing ? null : _submitText,
                  child: scanState.isProcessing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('SEARCH'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
