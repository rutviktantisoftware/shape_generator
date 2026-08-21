import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'svg_to_path_converter.dart';

enum ViewMode { code, preview, split }

/// Interactive SVG to Flutter CustomClipper Code Generator Screen.
/// Optimized for mobile: All controls moved to AppBar PopupMenuButton (`more_vert`),
/// leaving full vertical space for the Editor & Shape Preview.
class SvgCodeGeneratorScreen extends StatefulWidget {
  const SvgCodeGeneratorScreen({super.key});

  @override
  State<SvgCodeGeneratorScreen> createState() => _SvgCodeGeneratorScreenState();
}

class _SvgCodeGeneratorScreenState extends State<SvgCodeGeneratorScreen> {
  final TextEditingController _svgInputController = TextEditingController();
  String _generatedCode = '';
  bool _isResponsive = true;
  ScaleStrategy _scaleStrategy = ScaleStrategy.scaleFactors;
  ViewMode _viewMode = ViewMode.code; // Default to Code view mode

  // Color choices for Live Preview container
  Color _previewColor = const Color(0xFF2196F3);
  bool _useGradient = true;

  // Custom preview container dimensions (width & height sliders)
  double _customWidth = 320.0;
  double _customHeight = 200.0;
  bool _useOriginalSvgDimensions = false;

  // Preset sample SVG path for testing
  final String _sampleSvgPath =
      '<path fill-rule="evenodd" clip-rule="evenodd" d="M366.406 0C369.148 0 371.769 1.12546 373.657 3.11328L379.251 9.00293C381.016 10.8613 382 13.3268 382 15.8896V277.016C382 279.381 381.162 281.67 379.634 283.476L371.186 293.46C369.286 295.705 366.493 297 363.552 297H308.5V305C308.5 310.799 303.799 315.5 298 315.5H80C74.201 315.5 69.5 310.799 69.5 305V297H18.7188C15.8198 297 13.0634 295.742 11.1641 293.552L2.44531 283.499C0.868288 281.681 0.000102734 279.354 0 276.947V16.1953C6.44458e-05 13.6896 0.940488 11.2749 2.63574 9.42969L8.32812 3.23438C10.2219 1.17322 12.8933 7.62939e-06 15.6924 0H366.406Z" fill="#0063F9"/>';

  @override
  void initState() {
    super.initState();
    _svgInputController.text = _sampleSvgPath;
    _updateSvgDimensions();
    _generateCode();
  }

  @override
  void dispose() {
    _svgInputController.dispose();
    super.dispose();
  }

  void _updateSvgDimensions() {
    final Size size = SvgToPathConverter.getSvgDimensions(
      _svgInputController.text,
    );
    setState(() {
      _customWidth = size.width.clamp(80.0, 500.0);
      _customHeight = size.height.clamp(40.0, 400.0);
    });
  }

  void _generateCode() {
    final input = _svgInputController.text.trim();
    if (input.isEmpty) {
      setState(() {
        _generatedCode = '// Please enter SVG code or path string on the left.';
      });
      return;
    }

    final code = SvgToPathConverter.generateFlutterCode(
      svgInput: input,
      isResponsive: _isResponsive,
      scaleStrategy: _scaleStrategy,
    );

    setState(() {
      _generatedCode = code;
    });
  }

  void _copyToClipboard() {
    if (_generatedCode.trim().isEmpty) return;
    Clipboard.setData(ClipboardData(text: _generatedCode));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Generated CustomClipper code copied to clipboard!'),
        backgroundColor: Color(0xFFFF2D55),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _loadSampleSvg() {
    _svgInputController.text = _sampleSvgPath;
    _updateSvgDimensions();
    _generateCode();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Sample SVG path loaded!'),
        backgroundColor: Colors.blueAccent,
        duration: Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1724), // Dark background
      appBar: AppBar(
        title: const Text(
          'SVG Generator',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        backgroundColor: const Color(0xFF0A0F1D),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          // Copy Code Icon Quick Action
          IconButton(
            onPressed: _copyToClipboard,
            tooltip: 'Copy Code',
            icon: const Icon(Icons.copy_rounded, color: Colors.white, size: 20),
          ),

          // PopupMenuButton (`more_vert`) containing all actions & options
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            color: const Color(0xFF1A263B),
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            onSelected: (value) {
              switch (value) {
                case 'pick_svg':
                  _loadSampleSvg();
                  break;
                case 'generate':
                  _generateCode();
                  break;
                case 'copy':
                  _copyToClipboard();
                  break;
                case 'toggle_responsive':
                  setState(() {
                    _isResponsive = !_isResponsive;
                    if (!_isResponsive) {
                      _scaleStrategy = ScaleStrategy.none;
                    } else if (_scaleStrategy == ScaleStrategy.none) {
                      _scaleStrategy = ScaleStrategy.scaleFactors;
                    }
                  });
                  _generateCode();
                  break;
                case 'mode_code':
                  setState(() => _viewMode = ViewMode.code);
                  break;
                case 'mode_preview':
                  setState(() => _viewMode = ViewMode.preview);
                  break;
                case 'mode_split':
                  setState(() => _viewMode = ViewMode.split);
                  break;
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'pick_svg',
                child: Row(
                  children: [
                    Icon(
                      Icons.file_upload_outlined,
                      color: Colors.white70,
                      size: 18,
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Pick SVG File',
                      style: TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'generate',
                child: Row(
                  children: [
                    Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.white70,
                      size: 18,
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Generate Code',
                      style: TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'toggle_responsive',
                child: Row(
                  children: [
                    Icon(
                      _isResponsive
                          ? Icons.check_box_outlined
                          : Icons.check_box_outline_blank,
                      color: _isResponsive
                          ? const Color(0xFFFF2D55)
                          : Colors.white70,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Responsive Mode',
                      style: TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const PopupMenuDivider(height: 1),
              const PopupMenuItem<String>(
                value: 'mode_code',
                child: Row(
                  children: [
                    Icon(Icons.code, color: Colors.white70, size: 18),
                    SizedBox(width: 10),
                    Text(
                      'View: Code Only',
                      style: TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'mode_preview',
                child: Row(
                  children: [
                    Icon(
                      Icons.visibility_outlined,
                      color: Colors.white70,
                      size: 18,
                    ),
                    SizedBox(width: 10),
                    Text(
                      'View: Live Preview',
                      style: TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const PopupMenuItem<String>(
                value: 'mode_split',
                child: Row(
                  children: [
                    Icon(
                      Icons.splitscreen_rounded,
                      color: Colors.white70,
                      size: 18,
                    ),
                    SizedBox(width: 10),
                    Text(
                      'View: Split View',
                      style: TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final bool isWide = constraints.maxWidth > 750;
              return isWide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(flex: 5, child: _buildInputPane()),
                        const SizedBox(width: 8),
                        Expanded(flex: 6, child: _buildRightPane()),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(flex: 4, child: _buildInputPane()),
                        const SizedBox(height: 8),
                        Expanded(flex: 5, child: _buildRightPane()),
                      ],
                    );
            },
          ),
        ),
      ),
    );
  }

  /// Left Pane: SVG Code Input
  Widget _buildInputPane() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF162032),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF2A3A52), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFF1A263B),
              borderRadius: BorderRadius.vertical(top: Radius.circular(6)),
            ),
            child: const Text(
              'Enter SVG Code Here',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: TextField(
              controller: _svgInputController,
              maxLines: null,
              expands: true,
              style: const TextStyle(
                color: Colors.white,
                fontFamily: 'monospace',
                fontSize: 12,
                height: 1.4,
              ),
              decoration: const InputDecoration(
                contentPadding: EdgeInsets.all(12),
                border: InputBorder.none,
                hintText: '<svg ...> or <path d="..." /> or M10 20 L30 40 Z',
                hintStyle: TextStyle(color: Colors.white30, fontSize: 12),
              ),
              onChanged: (_) {
                _updateSvgDimensions();
                _generateCode();
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Right Pane: Header Bar with Expanded Text + View Switcher
  Widget _buildRightPane() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF162032),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF2A3A52), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Bar with View Toggle Tabs
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: const BoxDecoration(
              color: Color(0xFF1A263B),
              borderRadius: BorderRadius.vertical(top: Radius.circular(6)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _viewMode == ViewMode.code
                        ? 'Generated Code'
                        : _viewMode == ViewMode.preview
                        ? 'Live Shape Preview'
                        : 'Code & Preview',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 6),

                // View Switcher Buttons (Code / Live Preview / Split)
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F1724),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildViewTabButton(
                        label: 'Code',
                        icon: Icons.code,
                        mode: ViewMode.code,
                      ),
                      _buildViewTabButton(
                        label: 'Preview',
                        icon: Icons.visibility_outlined,
                        mode: ViewMode.preview,
                      ),
                      _buildViewTabButton(
                        label: 'Split',
                        icon: Icons.splitscreen_rounded,
                        mode: ViewMode.split,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Content Area based on selected View Mode
          Expanded(
            child: _viewMode == ViewMode.code
                ? _buildCodeDisplay()
                : _viewMode == ViewMode.preview
                ? _buildLiveShapePreview()
                : Column(
                    children: [
                      Expanded(flex: 5, child: _buildLiveShapePreview()),
                      const Divider(color: Color(0xFF2A3A52), height: 1),
                      Expanded(flex: 4, child: _buildCodeDisplay()),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewTabButton({
    required String label,
    required IconData icon,
    required ViewMode mode,
  }) {
    final isSelected = _viewMode == mode;
    return GestureDetector(
      onTap: () => setState(() => _viewMode = mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFF2D55) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 13,
              color: isSelected ? Colors.white : Colors.white60,
            ),
            const SizedBox(width: 3),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white60,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Displays generated CustomClipper code with Scale Mode selector bar
  Widget _buildCodeDisplay() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Scale Strategy Choice Chips
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          color: const Color(0xFF141D2B),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                const Text(
                  'Scale Mode: ',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 4),
                _buildScaleChip('Matrix Scale (Auto)', ScaleStrategy.matrix),
                const SizedBox(width: 4),
                _buildScaleChip(
                  'Scale Factors (scaleX/Y)',
                  ScaleStrategy.scaleFactors,
                ),
                const SizedBox(width: 4),
                _buildScaleChip('Size Ratios', ScaleStrategy.normalizedRatio),
                const SizedBox(width: 4),
                _buildScaleChip('Fixed', ScaleStrategy.none),
              ],
            ),
          ),
        ),
        const Divider(color: Color(0xFF2A3A52), height: 1),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: SelectableText(
              _generatedCode.isEmpty
                  ? '// Generated CustomClipper code will appear here...'
                  : _generatedCode,
              style: const TextStyle(
                color: Color(0xFF64D2FF), // Cyan syntax color
                fontFamily: 'monospace',
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScaleChip(String label, ScaleStrategy strategy) {
    final isSelected = _scaleStrategy == strategy;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: const Color(0xFFFF2D55),
      backgroundColor: const Color(0xFF1A263B),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.white70,
        fontSize: 10,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _scaleStrategy = strategy;
            _isResponsive = strategy != ScaleStrategy.none;
          });
          _generateCode();
        }
      },
    );
  }

  /// Renders visual shape live with overflow-proof responsive controls
  Widget _buildLiveShapePreview() {
    final input = _svgInputController.text.trim();
    final Size naturalSize = SvgToPathConverter.getSvgDimensions(input);

    final double displayWidth = _useOriginalSvgDimensions
        ? naturalSize.width
        : _customWidth;
    final double displayHeight = _useOriginalSvgDimensions
        ? naturalSize.height
        : _customHeight;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(10.0),
      child: Column(
        children: [
          // Row 1: Color picker & Gradient Toggle
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Color: ',
                  style: TextStyle(color: Colors.white70, fontSize: 11),
                ),
                _buildColorDot(const Color(0xFF2196F3)),
                _buildColorDot(const Color(0xFFFF2D55)),
                _buildColorDot(const Color(0xFF4CAF50)),
                _buildColorDot(const Color(0xFFFF9800)),
                _buildColorDot(const Color(0xFF9C27B0)),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () => setState(() => _useGradient = !_useGradient),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _useGradient
                          ? const Color(0xFF2A3A52)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF2A3A52)),
                    ),
                    child: Text(
                      _useGradient ? 'Gradient: ON' : 'Gradient: OFF',
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Row 2: Dimension Presets Choice Chips
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 6,
            runSpacing: 6,
            children: [
              ChoiceChip(
                label: Text(
                  'Original SVG (${naturalSize.width.toStringAsFixed(0)}×${naturalSize.height.toStringAsFixed(0)})',
                ),
                selected: _useOriginalSvgDimensions,
                selectedColor: const Color(0xFFFF2D55),
                backgroundColor: const Color(0xFF1A263B),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                labelStyle: TextStyle(
                  color: _useOriginalSvgDimensions
                      ? Colors.white
                      : Colors.white70,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                onSelected: (selected) {
                  setState(() {
                    _useOriginalSvgDimensions = selected;
                  });
                },
              ),
              ChoiceChip(
                label: const Text('Custom Dimensions'),
                selected: !_useOriginalSvgDimensions,
                selectedColor: const Color(0xFFFF2D55),
                backgroundColor: const Color(0xFF1A263B),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                labelStyle: TextStyle(
                  color: !_useOriginalSvgDimensions
                      ? Colors.white
                      : Colors.white70,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                onSelected: (selected) {
                  setState(() {
                    _useOriginalSvgDimensions = !selected;
                  });
                },
              ),
            ],
          ),

          // Custom Dimension Sliders (Width & Height)
          if (!_useOriginalSvgDimensions) ...[
            const SizedBox(height: 6),
            Column(
              children: [
                Row(
                  children: [
                    SizedBox(
                      width: 65,
                      child: Text(
                        'W: ${displayWidth.toStringAsFixed(0)}px',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    Expanded(
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 3,
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 6,
                          ),
                        ),
                        child: Slider(
                          value: _customWidth,
                          min: 80.0,
                          max: 500.0,
                          activeColor: const Color(0xFFFF2D55),
                          inactiveColor: Colors.white24,
                          onChanged: (val) =>
                              setState(() => _customWidth = val),
                        ),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    SizedBox(
                      width: 65,
                      child: Text(
                        'H: ${displayHeight.toStringAsFixed(0)}px',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    Expanded(
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 3,
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 6,
                          ),
                        ),
                        child: Slider(
                          value: _customHeight,
                          min: 40.0,
                          max: 400.0,
                          activeColor: const Color(0xFFFF2D55),
                          inactiveColor: Colors.white24,
                          onChanged: (val) =>
                              setState(() => _customHeight = val),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
          const SizedBox(height: 8),

          // Active Dimension Label Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFF1A263B),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF2A3A52)),
            ),
            child: Text(
              'Size: ${displayWidth.toStringAsFixed(1)} W × ${displayHeight.toStringAsFixed(1)} H (px)',
              style: const TextStyle(
                color: Color(0xFF64D2FF),
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Live Clipped Shape Display Box
          Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: displayWidth,
              height: displayHeight,
              decoration: BoxDecoration(
                color: const Color(0xFF0F1724),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white24, width: 1.5),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black45,
                    blurRadius: 8,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: ClipPath(
                clipper: DynamicSvgClipper(svgInput: input),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  decoration: BoxDecoration(
                    color: _useGradient ? null : _previewColor,
                    gradient: _useGradient
                        ? LinearGradient(
                            colors: [
                              _previewColor,
                              _previewColor.withAlpha(160),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      input.isEmpty
                          ? 'Enter SVG path to preview'
                          : 'Clipped Container',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorDot(Color color) {
    final isSelected = _previewColor == color;
    return GestureDetector(
      onTap: () => setState(() => _previewColor = color),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        width: 18,
        height: 18,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: isSelected ? Border.all(color: Colors.white, width: 2) : null,
        ),
      ),
    );
  }
}
