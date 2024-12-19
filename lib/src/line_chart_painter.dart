import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:speed_chart/speed_chart.dart';
import 'package:speed_chart/src/speed_line_chart.dart';
import 'package:intl/intl.dart';

class LineChartPainter extends CustomPainter {
  LineChartPainter({
    required this.lineSeriesXCollection,
    required this.longestLineSeriesX,
    required this.showTrackball,
    required this.longPressX,
    required this.leftOffset,
    required this.rightOffset,
    required this.offset,
    required this.scale,
    required this.minValue,
    required this.maxValue,
    required this.xRange,
    required this.yRange,
    required this.showMultipleYAxises,
    required this.minValues,
    required this.maxValues,
    required this.yRanges,
    required this.axisPaint,
    required this.verticalLinePaint,
    required this.plotBands,
    required this.timeZoneAbrv,
  });

  final List<LineSeriesX> lineSeriesXCollection;
  final LineSeriesX longestLineSeriesX;
  final bool showTrackball;
  final double longPressX;
  final double leftOffset;
  final double rightOffset;
  final double offset;
  final double scale;
  final double minValue;
  final double maxValue;
  final double xRange;
  final double yRange;
  final bool showMultipleYAxises;
  final List<double> minValues;
  final List<double> maxValues;
  final List<double> yRanges;
  final Paint axisPaint;
  final Paint verticalLinePaint;
  final List<PlotBand> plotBands;
  final String timeZoneAbrv;
  final TextPainter _axisLabelPainter = TextPainter(
    textAlign: TextAlign.right,
    textDirection: ui.TextDirection.ltr,
  );

  final TextPainter _tipTextPainter = TextPainter(
    textAlign: TextAlign.center,
    textDirection: ui.TextDirection.ltr,
  );

  final Paint _gridPaint = Paint()
    ..color = Colors.grey.withOpacity(0.4)
    ..strokeWidth = 1;

  final Paint _dividerPaint = Paint()
    ..color = Colors.black
    ..strokeWidth = 1.0
    ..strokeCap = StrokeCap.round
    ..style = PaintingStyle.stroke;

  int? _findClosestIndex({
    required double x,
    required double offsetX,
    required double xStep,
  }) {
    double closestDistance = double.infinity;
    int? closestIndex;

    if (longestLineSeriesX.dataList.isNotEmpty) {
      for (int i = 0; i < longestLineSeriesX.dataList.length; i++) {
        // because sthe start point of line series is in canvas.translate(offset, 0)
        // add offsetX to adjust the i-th point
        double distance = (i * xStep + offsetX - x).abs();

        if (distance < closestDistance) {
          closestDistance = distance;
          closestIndex = i;
        }
      }

      return closestIndex;
    } else {
      return null;
    }
  }

  List<Map<int, double?>> _getYByClosetIndex(int index) {
    List<Map<int, double?>> valueMapList = [];
    for (int i = 0; i < lineSeriesXCollection.length; i++) {
      LineSeriesX lineSeriesX = lineSeriesXCollection[i];
      Map<int, double?> valueMap = {};

      if (index >= lineSeriesX.dataList.length) {
        valueMap[i] = null;
      } else {
        valueMap[i] = lineSeriesX.dataList[index].y;
      }

      valueMapList.add(valueMap);
    }
    // valueMapList = [{'name': value},{'name': value}]
    return valueMapList;
  }

  String _formatDate(DateTime date) {
    return '${DateFormat('yyyy-MM-dd HH:mm:ss').format(date)} $timeZoneAbrv';
  }

  // Draw Y-Axis
  void _drawYAxis({
    required Canvas canvas,
    required Size size,
  }) {
    canvas.drawLine(
      Offset(leftOffset, 0),
      Offset(leftOffset, size.height),
      axisPaint,
    );
  }

  // Draw X-Axis
  void _drawXAxis({
    required Canvas canvas,
    required Size size,
  }) {
    canvas.drawLine(
      Offset(leftOffset, size.height),
      Offset(size.width - rightOffset, size.height), // size.width 是畫面中最右邊的位置
      axisPaint,
    );
  }

  void _drawXAxisForMultipleYAxises({
    required Canvas canvas,
    required Size size,
  }) {
    double newLeftOffset = leftOffset + 40 * (lineSeriesXCollection.length - 1);

    canvas.drawLine(
      Offset(newLeftOffset, size.height),
      Offset(size.width - rightOffset, size.height),
      axisPaint,
    );
  }

  // Draw a vertical grid line and a X-Axis label with a given point
  void _drawXLabelAndVerticalGridLine({
    required Canvas canvas,
    required Size size,
    required double scaleX,
    dynamic x,
  }) {
    String xLabel = '';
    if (x is DateTime) {
      String date = DateFormat('yyyy-MM-dd').format(x);
      String time = DateFormat('HH:mm:ss').format(x);
      xLabel = '$date\n$time';
    } else {
      xLabel = x.toString();
    }

    _axisLabelPainter.text = TextSpan(
      text: xLabel,
      style: TextStyle(
        fontSize: 12,
        color: axisPaint.color,
      ),
    );

    _axisLabelPainter.layout();

    // 如果字會超過最左邊的邊界就不畫
    if (scaleX - _axisLabelPainter.width > 0) {
      // Draw vertical grid line
      canvas.drawLine(
          Offset(scaleX, 0), Offset(scaleX, size.height), _gridPaint);

      // Draw label
      _axisLabelPainter.paint(
          canvas, Offset(scaleX - _axisLabelPainter.width, size.height));
    }
  }

  // Draw vertical grid lines and X-Axis labels
  void _drawXAxisLabelAndVerticalGridLine({
    required Canvas canvas,
    required Size size,
    required double xStep,
  }) {
    List<ValuePair> dataList = longestLineSeriesX.dataList;
    int currentLabelIndex = -1;

    for (int i = dataList.length - 1; i > 0; i--) {
      // 最後一個點優先畫出來
      if (i == dataList.length - 1) {
        currentLabelIndex = i;
        _drawXLabelAndVerticalGridLine(
          canvas: canvas,
          size: size,
          scaleX: currentLabelIndex * xStep,
          x: dataList[currentLabelIndex].x,
        );
      } else {
        double currentPointX = i * xStep;
        double previousPointX = currentLabelIndex * xStep;

        // 在畫面中每間隔 100 個單位畫一條 vertical grid line
        if (previousPointX - currentPointX > 100) {
          currentLabelIndex = i;
          _drawXLabelAndVerticalGridLine(
            canvas: canvas,
            size: size,
            scaleX: currentLabelIndex * xStep,
            x: dataList[currentLabelIndex].x,
          );
        }
      }
    }
  }

  // Draw horizontal grid lines and Y-axis labels
  void _drawYAxisLabelAndHorizontalGridLine({
    required Canvas canvas,
    required Size size,
    required double yStep,
  }) {
    int yScalePoints = 5;
    double yInterval = yRange / yScalePoints;
    for (int i = 0; i <= yScalePoints; i++) {
      double scaleY = size.height - i * yInterval * yStep;

      // Draw horizontal grid line
      canvas.drawLine(Offset(leftOffset, scaleY),
          Offset(size.width - rightOffset, scaleY), _gridPaint);

      // Draw Y-axis label
      String label = (i * yInterval + minValue).toStringAsFixed(0);
      _axisLabelPainter.text = TextSpan(
        text: label,
        style: TextStyle(
          fontSize: 12,
          color: axisPaint.color,
        ),
      );
      _axisLabelPainter.layout();
      _axisLabelPainter.paint(
          canvas,
          Offset(leftOffset - _axisLabelPainter.width - 4,
              scaleY - _axisLabelPainter.height / 2));
    }
  }

  void _drawYAxisLabelAndHorizontalGridLineForMultipleYAxises({
    required Canvas canvas,
    required Size size,
  }) {
    for (int i = 0; i < lineSeriesXCollection.length; i++) {
      LineSeriesX lineSeries = lineSeriesXCollection[i];
      double newLeftOffset = leftOffset + 40 * i;

      // Draw Y-Axis
      canvas.drawLine(
        Offset(newLeftOffset, 0),
        Offset(newLeftOffset, size.height),
        axisPaint,
      );

      int yScalePoints = 5;
      double yInterval = yRanges[i] / yScalePoints;
      double yStep = size.height / yRanges[i];
      for (int j = 0; j <= yScalePoints; j++) {
        double scaleY = size.height - j * yInterval * yStep;

        // Draw horizontal grid line
        if (i == lineSeriesXCollection.length - 1) {
          canvas.drawLine(Offset(newLeftOffset, scaleY),
              Offset(size.width - rightOffset, scaleY), _gridPaint);
        }

        // Draw Y-axis scale points
        String label = (j * yInterval + minValues[i]).toStringAsFixed(0);

        TextPainter multipleYAxisLabelPainter = TextPainter(
          textAlign: TextAlign.right,
          textDirection: ui.TextDirection.ltr,
        );

        multipleYAxisLabelPainter.text = TextSpan(
          text: label,
          style: TextStyle(
            fontSize: 12,
            color: lineSeries.color,
          ),
        );
        multipleYAxisLabelPainter.layout();
        multipleYAxisLabelPainter.paint(
            canvas,
            Offset(newLeftOffset - multipleYAxisLabelPainter.width - 2,
                scaleY - multipleYAxisLabelPainter.height / 2));
      }
    }
  }

  double _calculateTooltipDimensions({
    required Map<int, String> tips,
    required double Function(int) getIconWidth,
    required Size size,
    required double xStep,
    required int closestIndex,
  }) {
    double maxWidth = 0;
    const double padding = 16;
    const double iconTextGap = 8;

    for (MapEntry entry in tips.entries) {
      _tipTextPainter.text = TextSpan(
        text: entry.value,
        style: const TextStyle(color: Colors.black),
      );

      _tipTextPainter.layout();

      double rowWidth = _tipTextPainter.width;
      if (entry.key != -1) {
        rowWidth += getIconWidth(entry.key) + iconTextGap;
      }
      maxWidth = max(maxWidth, rowWidth);
    }
    return maxWidth + padding * 2;
  }

  void _drawTrackBall({
    required Canvas canvas,
    required Size size,
    required double xStep,
  }) {
    int nonNullValueIndex =
        longestLineSeriesX.dataList.indexWhere((element) => element.y != null);

    if (nonNullValueIndex == -1) return;

    double adjustedLongPressX = 0.0;
    if (showMultipleYAxises) {
      double newLeftOffset = 40 * (lineSeriesXCollection.length - 1);

      adjustedLongPressX = (longPressX - newLeftOffset).clamp(0.0, size.width);
    } else {
      adjustedLongPressX = longPressX.clamp(0.0, size.width);
    }

    int? closestIndex = _findClosestIndex(
      x: adjustedLongPressX,
      offsetX: offset,
      xStep: xStep,
    );

    if (closestIndex == null) return;

    // Draw vertical line

    canvas.drawLine(
      Offset((closestIndex * xStep), 0),
      Offset((closestIndex * xStep), size.height),
      verticalLinePaint,
    );

    String formatXLabel = '';

    if (longestLineSeriesX.dataList[closestIndex].x is DateTime) {
      DateTime closestDateTime =
          longestLineSeriesX.dataList[closestIndex].x as DateTime;

      formatXLabel = _formatDate(closestDateTime);
    } else {
      int closestX = longestLineSeriesX.dataList[closestIndex].x as int;

      formatXLabel = closestX.toString();
    }

    // Find matching plot bands
    List<PlotBand> matchingPlotBands = plotBands.where((band) {
      DateTime pointDateTime =
          longestLineSeriesX.dataList[closestIndex].x as DateTime;

      return (pointDateTime.isAfter(band.startValue) ||
              pointDateTime.isAtSameMomentAs(band.startValue)) &&
          (pointDateTime.isBefore(band.endValue) ||
              pointDateTime.isAtSameMomentAs(band.endValue));
    }).toList();

    // Get values and create tips

    List<Map<int, double?>> valueMapList = _getYByClosetIndex(closestIndex);
    Map<int, String> tips = {-1: formatXLabel};

    // Add line series values first (positive keys)
    for (Map<int, double?> valueMap in valueMapList) {
      MapEntry nameValueEntry = valueMap.entries.toList()[0];
      if (nameValueEntry.value != null) {
        tips[nameValueEntry.key] =
            '${lineSeriesXCollection[nameValueEntry.key].name} : ${nameValueEntry.value}';
      }
    }

    // Add plot band information last (negative keys)

    if (matchingPlotBands.isNotEmpty) {
      for (int i = 0; i < matchingPlotBands.length; i++) {
        PlotBand band = matchingPlotBands[i];
        // Format duration text
        String durationText;
        if (band.totalDurSec < 60) {
          durationText = "< 1m";
        } else {
          int durationHours = (band.totalDurSec / 3600).floor();
          int durationMinutes = ((band.totalDurSec % 3600) / 60).floor();
          durationText = "${durationHours}H ${durationMinutes}m";
        }
        tips[-2 - i] = (band.units.toString().toLowerCase() != "none")
            ? 'Irrigation: $durationText | ${band.totalVol} ${band.units}'
            : 'Irrigation: $durationText';
      }
    }

    // Calculate tooltip dimensions

    const double rowHeight = 20;
    const double padding = 16;
    const double bottomPadding = 10;
    const double iconSize = 12;
    double totalHeight = (tips.length * rowHeight) + padding + bottomPadding;
    double maxWidth = _calculateTooltipDimensions(
      tips: tips,
      getIconWidth: (key) => iconSize,
      size: size,
      xStep: xStep,
      closestIndex: closestIndex,
    );

    // Calculate tooltip position
    double textX = (closestIndex * xStep) + 10;
    double textY = size.height / 2 - totalHeight / 2;
    double lineSeriesLeftOffset = showMultipleYAxises
        ? 40.0 * (lineSeriesXCollection.length)
        : leftOffset;
    double outOfBoundWidth = (textX - 4) +
        maxWidth -
        (size.width - lineSeriesLeftOffset - rightOffset) +
        offset;
    double adjustedTextX = outOfBoundWidth > 0 ? outOfBoundWidth : 0;

    // Draw tooltip background
    Rect tooltipRect = Rect.fromLTWH(
      textX - 4 - adjustedTextX,
      textY,
      maxWidth,
      totalHeight,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(tooltipRect, const Radius.circular(4)),
      Paint()..color = Colors.white,
    );

    // Draw content
    double currentY = textY + padding / 2;

    // Draw datetime
    _tipTextPainter.text = TextSpan(
      text: tips[-1],
      style: const TextStyle(
        color: Colors.black,
        fontWeight: FontWeight.bold,
      ),
    );

    _tipTextPainter.layout();

    _tipTextPainter.paint(
        canvas, Offset(textX - adjustedTextX + padding / 2, currentY));

    currentY += rowHeight;

    // Draw divider
    canvas.drawLine(
      Offset(textX - adjustedTextX + padding / 2, currentY),
      Offset(textX - adjustedTextX + maxWidth - padding / 2, currentY),
      _dividerPaint,
    );

    currentY += rowHeight / 2;

    // Draw line series info first
    for (MapEntry entry in tips.entries.where((e) => e.key >= 0)) {
      Paint circlePaint = Paint()
        ..color = lineSeriesXCollection[entry.key].color;

      // Draw circle
      canvas.drawCircle(
        Offset(
          textX - adjustedTextX + padding / 2 + iconSize / 2,
          currentY + rowHeight / 2,
        ),
        iconSize / 2,
        circlePaint,
      );

      // Draw text
      _tipTextPainter.text = TextSpan(
        text: entry.value,
        style: const TextStyle(color: Colors.black),
      );

      _tipTextPainter.layout();
      _tipTextPainter.paint(
        canvas,
        Offset(
          textX - adjustedTextX + padding / 2 + iconSize + 8,
          currentY + (rowHeight - _tipTextPainter.height) / 2,
        ),
      );

      currentY += rowHeight;
    }

    // Draw plot bands info last
    for (MapEntry entry in tips.entries.where((e) => e.key < -1)) {
      int plotBandIndex = (-2 - entry.key).toInt();

      PlotBand plotBand = matchingPlotBands[plotBandIndex];

      // Draw square
      canvas.drawRect(
        Rect.fromLTWH(
          textX - adjustedTextX + padding / 2,
          currentY + (rowHeight - iconSize) / 2,
          iconSize,
          iconSize,
        ),
        Paint()
          ..color = plotBand.color
          ..style = PaintingStyle.fill,
      );

      // Draw text
      _tipTextPainter.text = TextSpan(
        text: entry.value,
        style: const TextStyle(color: Colors.black),
      );

      _tipTextPainter.layout();
      _tipTextPainter.paint(
        canvas,
        Offset(
          textX - adjustedTextX + padding / 2 + iconSize + 8,
          currentY + (rowHeight - _tipTextPainter.height) / 2,
        ),
      );

      currentY += rowHeight;
    }
  }

  void _drawLineSeries({
    required Canvas canvas,
    required double xStep,
    required double yStep,
  }) {
    for (LineSeriesX lineSeriesX in lineSeriesXCollection) {
      List<ValuePair> data = lineSeriesX.dataList;
      Paint linePaint = Paint()
        ..color = lineSeriesX.color
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke;

      Path linePath = Path();

      // Marker Paint
      Paint markerPaint = Paint()
        ..color = lineSeriesX.color
        ..style = PaintingStyle.fill;

      int firstIndex = data.indexWhere((element) => element.y != null);
      if (firstIndex != -1) {
        for (int i = firstIndex; i < data.length; i++) {
          double currentX = (i * xStep);
          double? currentY =
              data[i].y == null ? null : (maxValue - data[i].y!) * yStep;

          if (currentY != null) {
            // Draw a marker at each point
            canvas.drawCircle(Offset(currentX, currentY), 1.5, markerPaint);

            if (i == firstIndex) {
              linePath.moveTo(currentX, currentY);
            } else {
              linePath.lineTo(currentX, currentY);
            }
          }
        }
        canvas.drawPath(linePath, linePaint);
      }
    }
  }

  void _drawLineSeriesForMultipleYAxises({
    required Canvas canvas,
    required Size size,
    required double xStep,
  }) {
    for (int i = 0; i < lineSeriesXCollection.length; i++) {
      LineSeriesX lineSeriesX = lineSeriesXCollection[i];
      List<ValuePair> data = lineSeriesX.dataList;
      if (data.isEmpty) continue;

      double yStep = size.height / yRanges[i];

      // Line Paint
      Paint linePaint = Paint()
        ..color = lineSeriesX.color
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke;

      // Marker Paint
      Paint markerPaint = Paint()
        ..color = lineSeriesX.color
        ..style = PaintingStyle.fill;

      Path linePath = Path();

      int firstIndex = data.indexWhere((element) => element.y != null);
      if (firstIndex != -1) {
        for (int j = firstIndex; j < data.length; j++) {
          double currentX = (j * xStep);
          double? currentY =
              data[j].y == null ? null : (maxValues[i] - data[j].y!) * yStep;

          if (currentY != null) {
            // Draw marker dot at each point
            canvas.drawCircle(Offset(currentX, currentY), 1.5, markerPaint);

            if (j == firstIndex) {
              linePath.moveTo(currentX, currentY);
            } else {
              linePath.lineTo(currentX, currentY);
            }
          }
        }
        canvas.drawPath(linePath, linePaint);
      }
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    double yStep = size.height / yRange;

    if (showMultipleYAxises) {
      _drawYAxisLabelAndHorizontalGridLineForMultipleYAxises(
        canvas: canvas,
        size: size,
      );
    } else {
      _drawYAxisLabelAndHorizontalGridLine(
        canvas: canvas,
        size: size,
        yStep: yStep,
      );
    }

    // Draw Y-axis line
    _drawYAxis(
      canvas: canvas,
      size: size,
    );

    // Draw X-axis line
    if (showMultipleYAxises) {
      _drawXAxisForMultipleYAxises(
        canvas: canvas,
        size: size,
      );
    } else {
      _drawXAxis(
        canvas: canvas,
        size: size,
      );
    }

    // current (left,top) => (0,0)
    canvas.save();

    // Set up the xStep calculation
    double xStep = 0.0;

    if (showMultipleYAxises) {
      double newLeftOffset =
          leftOffset + 40 * (lineSeriesXCollection.length - 1);
      canvas.clipRect(Rect.fromPoints(Offset(newLeftOffset, 0),
          Offset(size.width - rightOffset, size.height + 40)));
      canvas.translate(newLeftOffset + offset, 0);

      // 如果沒有資料點, xRange = 0
      if (xRange == 0) {
        xStep = (size.width * scale - newLeftOffset - rightOffset - 0.5) / 1;
      } else {
        xStep = (size.width * scale - newLeftOffset - rightOffset - 0.5) /
            (xRange - 1);
      }
    } else {
      canvas.clipRect(Rect.fromPoints(Offset(leftOffset, 0),
          Offset(size.width - rightOffset, size.height + 40)));
      canvas.translate(leftOffset + offset, 0);

      // 如果沒有資料點, xRange = 0
      if (xRange == 0) {
        xStep = (size.width * scale - leftOffset - rightOffset - 0.5) / 1;
      } else {
        xStep = (size.width * scale - leftOffset - rightOffset - 0.5) /
            (xRange - 1);
      }
    }

    if (xRange != 0) {
      _drawXAxisLabelAndVerticalGridLine(
        canvas: canvas,
        size: size,
        xStep: xStep,
      );
    }

    canvas.restore();

    canvas.save();
    if (showMultipleYAxises) {
      double newLeftOffset =
          leftOffset + 40 * (lineSeriesXCollection.length - 1);
      canvas.clipRect(Rect.fromPoints(Offset(newLeftOffset, 0),
          Offset(size.width - rightOffset, size.height)));
      canvas.translate(newLeftOffset + offset, 0);
    } else {
      canvas.clipRect(Rect.fromPoints(Offset(leftOffset, 0),
          Offset(size.width - rightOffset, size.height)));
      canvas.translate(leftOffset + offset, 0);
    }

    // Draw plot bands first (they should be behind the lines)
    // Inside the paint method, update the plot band drawing code:
    for (final plotBand in plotBands) {
      if (plotBand.isValid()) {
        final paint = Paint()
          ..color = plotBand.color.withOpacity(plotBand.opacity)
          ..style = PaintingStyle.fill;

        // Get the actual data points for reference
        final List<ValuePair> dataPoints = longestLineSeriesX.dataList;

        // Find the exact position in the data series
        double startX = 0;
        double endX = 0;

        // Calculate exact positions by finding the nearest data points
        for (int i = 0; i < dataPoints.length; i++) {
          DateTime currentDate = dataPoints[i].x as DateTime;

          // Find start position
          if (currentDate.isAtSameMomentAs(plotBand.startValue) ||
              (i < dataPoints.length - 1 &&
                  currentDate.isBefore(plotBand.startValue) &&
                  (dataPoints[i + 1].x as DateTime)
                      .isAfter(plotBand.startValue))) {
            // Interpolate position if between points

            if (!currentDate.isAtSameMomentAs(plotBand.startValue) &&
                i < dataPoints.length - 1) {
              DateTime nextDate = dataPoints[i + 1].x as DateTime;
              double progress =
                  plotBand.startValue.difference(currentDate).inMilliseconds /
                      nextDate.difference(currentDate).inMilliseconds;

              startX = (i + progress) * xStep;
            } else {
              startX = i * xStep;
            }
          }

          // Find end position
          if (currentDate.isAtSameMomentAs(plotBand.endValue) ||
              (i < dataPoints.length - 1 &&
                  currentDate.isBefore(plotBand.endValue) &&
                  (dataPoints[i + 1].x as DateTime)
                      .isAfter(plotBand.endValue))) {
            // Interpolate position if between points

            if (!currentDate.isAtSameMomentAs(plotBand.endValue) &&
                i < dataPoints.length - 1) {
              DateTime nextDate = dataPoints[i + 1].x as DateTime;
              double progress =
                  plotBand.endValue.difference(currentDate).inMilliseconds /
                      nextDate.difference(currentDate).inMilliseconds;

              endX = (i + progress) * xStep;
            } else {
              endX = i * xStep;
            }
          }
        }

        // Draw the plot band using the exact positions
        canvas.drawRect(
          Rect.fromLTRB(startX, 0, endX, size.height),
          paint,
        );
      }
    }

    // Draw line series
    if (showMultipleYAxises) {
      _drawLineSeriesForMultipleYAxises(
        canvas: canvas,
        size: size,
        xStep: xStep,
      );
    } else {
      _drawLineSeries(
        canvas: canvas,
        xStep: xStep,
        yStep: yStep,
      );
    }

    if (showTrackball) {
      _drawTrackBall(
        canvas: canvas,
        size: size,
        xStep: xStep,
      );
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(LineChartPainter oldDelegate) {
    return oldDelegate.showTrackball != showTrackball ||
        oldDelegate.longPressX != longPressX ||
        oldDelegate.scale != scale ||
        oldDelegate.offset != offset;
  }
}
