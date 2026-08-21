import 'package:flutter/material.dart';
import 'package:path_drawing/path_drawing.dart';

class SvgClipper extends CustomClipper<Path> {
  final String svgPathData;

  const SvgClipper({required this.svgPathData});

  @override
  Path getClip(Size size) {
    final Path rawPath = parseSvgPathData(svgPathData);

    // Get the bounding box of the parsed SVG path to calculate its original dimensions
    final Rect bounds = rawPath.getBounds();

    final double svgWidth = bounds.width == 0 ? 1.0 : bounds.width;
    final double svgHeight = bounds.height == 0 ? 1.0 : bounds.height;

    // Scale precisely to fit the provided widget Size bounds from the raw path data
    final double scaleX = size.width / svgWidth;
    final double scaleY = size.height / svgHeight;

    // Use Matrix4 to handle scaling and translation cleanly
    final Matrix4 matrix = Matrix4.identity()
      ..scaleByDouble(scaleX, scaleY, 1.0, 1.0)
      ..translateByDouble(-bounds.left, -bounds.top, 0.0, 1.0);

    return rawPath.transform(matrix.storage);
  }

  @override
  bool shouldReclip(covariant SvgClipper oldClipper) {
    return oldClipper.svgPathData != svgPathData;
  }
}

class MultiPathCardClipper extends CustomClipper<Path> {
  final List<String> svgElements;

  const MultiPathCardClipper({required this.svgElements});

  @override
  Path getClip(Size size) {
    final Path combinedPath = Path();

    for (final element in svgElements) {
      if (element.trim().isNotEmpty) {
        final Path parsedPath = parseSvgPathData(element);
        combinedPath.addPath(parsedPath, Offset.zero);
      }
    }

    final Rect bounds = combinedPath.getBounds();
    final double svgWidth = bounds.width == 0 ? 1.0 : bounds.width;
    final double svgHeight = bounds.height == 0 ? 1.0 : bounds.height;

    final double scaleX = size.width / svgWidth;
    final double scaleY = size.height / svgHeight;

    // Fix: Translate origin to top-left of SVG bounds first, then scale to container size
    final Matrix4 matrix = Matrix4.identity()
      ..scaleByDouble(scaleX, scaleY, 1.0, 1.0)
      ..translateByDouble(-bounds.left, -bounds.top, 0.0, 1.0);

    return combinedPath.transform(matrix.storage);
  }

  @override
  bool shouldReclip(covariant MultiPathCardClipper oldClipper) {
    return oldClipper.svgElements != svgElements;
  }
}
