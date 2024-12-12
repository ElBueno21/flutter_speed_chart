import 'package:flutter/material.dart';

class PlotBand {
  final DateTime startValue;
  final DateTime endValue;
  final Color color;
  final double opacity;
  final double totalDurSec;
  final double totalVol;
  final String units;

  const PlotBand({
    required this.startValue,
    required this.endValue,
    required this.color,
    this.opacity = 0.3,
    this.totalDurSec = 0.0,
    this.totalVol = 0.0,
    this.units = '',
  });

  bool isValid() =>
      startValue.isBefore(endValue) || startValue.isAtSameMomentAs(endValue);
}
