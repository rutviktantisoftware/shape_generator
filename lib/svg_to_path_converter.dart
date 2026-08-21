import 'dart:math';
import 'package:flutter/material.dart';
import 'package:path_drawing/path_drawing.dart';

/// Strategies for scaling generated CustomClipper code to fit container size.
enum ScaleStrategy {
  /// Matrix Transform scaling: Keeps path commands clean & applies Matrix4 transform at end.
  matrix,

  /// Scale factors scaling: Computes scaleX & scaleY at top of getClip and multiplies coordinates.
  scaleFactors,

  /// Normalized ratio scaling: Formats coordinates as ratio percentage of size.width and size.height.
  normalizedRatio,

  /// Fixed dimensions: Hardcoded pixel values (non-responsive).
  none,
}

/// Class responsible for parsing SVG string inputs and generating Flutter
/// CustomClipper Dart code.
class SvgToPathConverter {
  /// Extracts path `d` attribute strings from raw SVG XML or returns the input if raw path.
  static List<String> extractPathData(String input) {
    final String trimmed = input.trim();
    if (trimmed.isEmpty) return [];

    // Check if input contains <path> or <svg> tags
    final RegExp dAttrRegExp = RegExp(r'd="([^"]+)"|d=\x27([^\x27]+)\x27', caseSensitive: false);
    final Iterable<RegExpMatch> matches = dAttrRegExp.allMatches(trimmed);

    if (matches.isNotEmpty) {
      return matches.map((m) => (m.group(1) ?? m.group(2) ?? '')).where((s) => s.trim().isNotEmpty).toList();
    }

    // If no XML attribute match, assume input is a raw path string (e.g. "M10 20 L30 40 Z")
    return [trimmed];
  }

  /// Computes the bounding Box Size (width & height) of the SVG input.
  static Size getSvgDimensions(String input) {
    final List<String> pathsData = extractPathData(input);
    if (pathsData.isEmpty) return const Size(300, 150);

    final Path combined = Path();
    for (final p in pathsData) {
      try {
        combined.addPath(parseSvgPathData(p), Offset.zero);
      } catch (_) {}
    }

    final Rect bounds = combined.getBounds();
    final double w = bounds.width <= 0 ? 300.0 : bounds.width;
    final double h = bounds.height <= 0 ? 150.0 : bounds.height;
    return Size(w, h);
  }

  /// Generates Flutter Dart code (`CustomClipper<Path>`) from SVG path data.
  static String generateFlutterCode({
    required String svgInput,
    bool isResponsive = true,
    ScaleStrategy? scaleStrategy,
    String className = 'MyCustomClipper',
  }) {
    final List<String> pathsData = extractPathData(svgInput);
    if (pathsData.isEmpty) {
      return '// Please enter valid SVG code or SVG Path data.';
    }

    final Size boundsSize = getSvgDimensions(svgInput);
    final String widthStr = boundsSize.width.toStringAsFixed(1);
    final String heightStr = boundsSize.height.toStringAsFixed(1);

    final ScaleStrategy effectiveStrategy = scaleStrategy ??
        (!isResponsive ? ScaleStrategy.none : ScaleStrategy.scaleFactors);

    final StringBuffer buffer = StringBuffer();

    buffer.writeln("import 'package:flutter/material.dart';");
    buffer.writeln();

    final actualClipperName = className.endsWith('Clipper') ? className : '${className}Clipper';

    switch (effectiveStrategy) {
      case ScaleStrategy.matrix:
        buffer.writeln('/// Responsive Scaled Shape Clipper (Auto-scales to fit any Container size via Matrix transform)');
        break;
      case ScaleStrategy.scaleFactors:
        buffer.writeln('/// Responsive Scaled Shape Clipper (Auto-scales using scale factors scaleX / scaleY)');
        break;
      case ScaleStrategy.normalizedRatio:
        buffer.writeln('/// Responsive Scaled Shape Clipper (Auto-scales using size percentage ratios)');
        break;
      case ScaleStrategy.none:
        buffer.writeln('/// Fixed Dimensions Shape Clipper (Width: $widthStr, Height: $heightStr)');
        buffer.writeln('/// Usage: Container(width: $widthStr, height: $heightStr, child: ClipPath(clipper: $actualClipperName(), ...))');
        break;
    }

    buffer.writeln('class $actualClipperName extends CustomClipper<Path> {');
    buffer.writeln('  @override');
    buffer.writeln('  Path getClip(Size size) {');

    if (effectiveStrategy == ScaleStrategy.scaleFactors) {
      buffer.writeln('    const double svgWidth = $widthStr;');
      buffer.writeln('    const double svgHeight = $heightStr;');
      buffer.writeln('    final double scaleX = size.width / svgWidth;');
      buffer.writeln('    final double scaleY = size.height / svgHeight;');
      buffer.writeln();
    }

    buffer.writeln('    Path path = Path();');

    for (int i = 0; i < pathsData.length; i++) {
      final pathVar = pathsData.length == 1 ? 'path' : 'path${i + 1}';
      if (i > 0) buffer.writeln('    Path $pathVar = Path();');
      final pathCode = _convertSvgPathToDartPathCode(
        pathsData[i],
        strategy: effectiveStrategy,
        varName: pathVar,
      );
      buffer.writeln(pathCode);
      if (i > 0) buffer.writeln('    path.addPath($pathVar, Offset.zero);');
    }

    if (effectiveStrategy == ScaleStrategy.matrix) {
      buffer.writeln();
      buffer.writeln('    // Auto-scale shape to fit any container size (small or large devices)');
      buffer.writeln('    final Rect bounds = path.getBounds();');
      buffer.writeln('    final double scaleX = size.width / (bounds.width == 0 ? 1.0 : bounds.width);');
      buffer.writeln('    final double scaleY = size.height / (bounds.height == 0 ? 1.0 : bounds.height);');
      buffer.writeln();
      buffer.writeln('    final Matrix4 matrix = Matrix4.identity()');
      buffer.writeln('      ..scaleByDouble(scaleX, scaleY, 1.0, 1.0)');
      buffer.writeln('      ..translateByDouble(-bounds.left, -bounds.top, 0.0, 1.0);');
      buffer.writeln();
      buffer.writeln('    return path.transform(matrix.storage);');
    } else {
      buffer.writeln('    return path;');
    }

    buffer.writeln('  }');
    buffer.writeln();
    buffer.writeln('  @override');
    buffer.writeln('  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => true;');
    buffer.writeln('}');

    return buffer.toString();
  }

  /// Converts single SVG path string to Dart `Path` code string using state tracking.
  static String _convertSvgPathToDartPathCode(
    String svgPathData, {
    required ScaleStrategy strategy,
    required String varName,
  }) {
    try {
      final Path parsedPath = parseSvgPathData(svgPathData);
      final Rect bounds = parsedPath.getBounds();
      final double width = max(bounds.width, 1.0);
      final double height = max(bounds.height, 1.0);

      final List<_PathCommand> rawCommands = _parseSvgPathCommands(svgPathData);
      final StringBuffer sb = StringBuffer();

      double currentX = 0.0;
      double currentY = 0.0;
      double startX = 0.0;
      double startY = 0.0;

      String _fmtNum(double val) {
        if (val.truncateToDouble() == val) {
          return val.toInt().toString();
        }
        return val.toStringAsFixed(2);
      }

      String fmtX(double val) {
        final double normX = (strategy == ScaleStrategy.scaleFactors || strategy == ScaleStrategy.normalizedRatio)
            ? (val - bounds.left)
            : val;

        switch (strategy) {
          case ScaleStrategy.matrix:
          case ScaleStrategy.none:
            return _fmtNum(val);
          case ScaleStrategy.scaleFactors:
            return normX == 0 ? '0' : '${_fmtNum(normX)} * scaleX';
          case ScaleStrategy.normalizedRatio:
            if (width <= 0) return _fmtNum(val);
            final ratio = (normX / width).toStringAsFixed(4);
            return 'size.width * $ratio';
        }
      }

      String fmtY(double val) {
        final double normY = (strategy == ScaleStrategy.scaleFactors || strategy == ScaleStrategy.normalizedRatio)
            ? (val - bounds.top)
            : val;

        switch (strategy) {
          case ScaleStrategy.matrix:
          case ScaleStrategy.none:
            return _fmtNum(val);
          case ScaleStrategy.scaleFactors:
            return normY == 0 ? '0' : '${_fmtNum(normY)} * scaleY';
          case ScaleStrategy.normalizedRatio:
            if (height <= 0) return _fmtNum(val);
            final ratio = (normY / height).toStringAsFixed(4);
            return 'size.height * $ratio';
        }
      }

      String fmtRx(double rx) {
        switch (strategy) {
          case ScaleStrategy.matrix:
          case ScaleStrategy.none:
            return _fmtNum(rx);
          case ScaleStrategy.scaleFactors:
            return rx == 0 ? '0' : '${_fmtNum(rx)} * scaleX';
          case ScaleStrategy.normalizedRatio:
            if (width <= 0) return _fmtNum(rx);
            final ratio = (rx / width).toStringAsFixed(4);
            return 'size.width * $ratio';
        }
      }

      String fmtRy(double ry) {
        switch (strategy) {
          case ScaleStrategy.matrix:
          case ScaleStrategy.none:
            return _fmtNum(ry);
          case ScaleStrategy.scaleFactors:
            return ry == 0 ? '0' : '${_fmtNum(ry)} * scaleY';
          case ScaleStrategy.normalizedRatio:
            if (height <= 0) return _fmtNum(ry);
            final ratio = (ry / height).toStringAsFixed(4);
            return 'size.height * $ratio';
        }
      }

      for (final cmd in rawCommands) {
        final char = cmd.type.toUpperCase();
        final isRelative = cmd.type != char;
        final args = cmd.args;

        switch (char) {
          case 'M':
            if (args.length >= 2) {
              if (isRelative) {
                currentX += args[0];
                currentY += args[1];
              } else {
                currentX = args[0];
                currentY = args[1];
              }
              startX = currentX;
              startY = currentY;

              final xStr = fmtX(currentX);
              final yStr = fmtY(currentY);
              sb.writeln('    $varName.moveTo($xStr, $yStr);');
            }
            break;

          case 'L':
            if (args.length >= 2) {
              if (isRelative) {
                currentX += args[0];
                currentY += args[1];
              } else {
                currentX = args[0];
                currentY = args[1];
              }
              final xStr = fmtX(currentX);
              final yStr = fmtY(currentY);
              sb.writeln('    $varName.lineTo($xStr, $yStr);');
            }
            break;

          case 'H':
            if (args.isNotEmpty) {
              if (isRelative) {
                currentX += args[0];
              } else {
                currentX = args[0];
              }
              final xStr = fmtX(currentX);
              final yStr = fmtY(currentY);
              sb.writeln('    $varName.lineTo($xStr, $yStr);');
            }
            break;

          case 'V':
            if (args.isNotEmpty) {
              if (isRelative) {
                currentY += args[0];
              } else {
                currentY = args[0];
              }
              final xStr = fmtX(currentX);
              final yStr = fmtY(currentY);
              sb.writeln('    $varName.lineTo($xStr, $yStr);');
            }
            break;

          case 'C':
            if (args.length >= 6) {
              double cX1 = isRelative ? currentX + args[0] : args[0];
              double cY1 = isRelative ? currentY + args[1] : args[1];
              double cX2 = isRelative ? currentX + args[2] : args[2];
              double cY2 = isRelative ? currentY + args[3] : args[3];
              double cX3 = isRelative ? currentX + args[4] : args[4];
              double cY3 = isRelative ? currentY + args[5] : args[5];

              currentX = cX3;
              currentY = cY3;

              final x1Str = fmtX(cX1);
              final y1Str = fmtY(cY1);
              final x2Str = fmtX(cX2);
              final y2Str = fmtY(cY2);
              final x3Str = fmtX(cX3);
              final y3Str = fmtY(cY3);

              sb.writeln('    $varName.cubicTo($x1Str, $y1Str, $x2Str, $y2Str, $x3Str, $y3Str);');
            }
            break;

          case 'Q':
            if (args.length >= 4) {
              double qX1 = isRelative ? currentX + args[0] : args[0];
              double qY1 = isRelative ? currentY + args[1] : args[1];
              double qX2 = isRelative ? currentX + args[2] : args[2];
              double qY2 = isRelative ? currentY + args[3] : args[3];

              currentX = qX2;
              currentY = qY2;

              final x1Str = fmtX(qX1);
              final y1Str = fmtY(qY1);
              final x2Str = fmtX(qX2);
              final y2Str = fmtY(qY2);

              sb.writeln('    $varName.quadraticBezierTo($x1Str, $y1Str, $x2Str, $y2Str);');
            }
            break;

          case 'A':
            if (args.length >= 7) {
              double aX = isRelative ? currentX + args[5] : args[5];
              double aY = isRelative ? currentY + args[6] : args[6];
              currentX = aX;
              currentY = aY;

              final xStr = fmtX(aX);
              final yStr = fmtY(aY);
              final rxStr = fmtRx(args[0]);
              final ryStr = fmtRy(args[1]);
              final rot = _fmtNum(args[2]);
              final large = args[3] != 0 ? 'true' : 'false';
              final sweep = args[4] != 0 ? 'true' : 'false';

              sb.writeln('    $varName.arcToPoint(Offset($xStr, $yStr), radius: Radius.elliptical($rxStr, $ryStr), rotation: $rot, largeArc: $large, clockwise: $sweep);');
            }
            break;

          case 'Z':
            currentX = startX;
            currentY = startY;
            sb.writeln('    $varName.close();');
            break;
        }
      }

      if (sb.isEmpty) {
        sb.writeln('    // Fallback:');
        sb.writeln('    $varName.addPath(parseSvgPathData("$svgPathData"), Offset.zero);');
      }

      return sb.toString();
    } catch (e) {
      return '    $varName.addPath(parseSvgPathData("$svgPathData"), Offset.zero);';
    }
  }

  /// Parse SVG path string into command structures
  static List<_PathCommand> _parseSvgPathCommands(String pathData) {
    final List<_PathCommand> commands = [];
    final RegExp tokenRegExp = RegExp(r'([a-zA-Z])|([-+]?(?:\d*\.\d+|\d+)(?:[eE][-+]?\d+)?)');
    final Iterable<RegExpMatch> matches = tokenRegExp.allMatches(pathData);

    String? currentCmd;
    List<double> args = [];

    void flushCommand() {
      final cmd = currentCmd;
      if (cmd != null) {
        commands.add(_PathCommand(cmd, List.from(args)));
        args.clear();
      }
    }

    for (final match in matches) {
      final String token = match.group(0)!;
      if (RegExp(r'^[a-zA-Z]$').hasMatch(token)) {
        flushCommand();
        currentCmd = token;
      } else {
        final double? val = double.tryParse(token);
        if (val != null) {
          args.add(val);
        }
      }
    }
    flushCommand();

    return commands;
  }
}

class _PathCommand {
  final String type;
  final List<double> args;

  _PathCommand(this.type, this.args);
}

/// Dynamic Clipper used for rendering live visual preview of SVG paths
class DynamicSvgClipper extends CustomClipper<Path> {
  final String svgInput;

  const DynamicSvgClipper({required this.svgInput});

  @override
  Path getClip(Size size) {
    try {
      final paths = SvgToPathConverter.extractPathData(svgInput);
      if (paths.isEmpty) {
        return Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
      }

      final Path combined = Path();
      for (final p in paths) {
        combined.addPath(parseSvgPathData(p), Offset.zero);
      }

      final Rect bounds = combined.getBounds();
      if (bounds.width == 0 || bounds.height == 0) return combined;

      final double scaleX = size.width / bounds.width;
      final double scaleY = size.height / bounds.height;

      final Matrix4 matrix = Matrix4.identity()
        ..scaleByDouble(scaleX, scaleY, 1.0, 1.0)
        ..translateByDouble(-bounds.left, -bounds.top, 0.0, 1.0);

      return combined.transform(matrix.storage);
    } catch (_) {
      return Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    }
  }

  @override
  bool shouldReclip(covariant DynamicSvgClipper oldClipper) =>
      oldClipper.svgInput != svgInput;
}
