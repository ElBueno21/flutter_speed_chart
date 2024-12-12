import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:speed_chart/speed_chart.dart';

class FullScreenChartForm extends StatefulWidget {
  const FullScreenChartForm({
    super.key,
    required this.title,
    required this.lineSeriesCollection,
  });

  static Route route({
    required String title,
    required List<LineSeries> lineSeriesCollection,
  }) {
    return MaterialPageRoute(
      builder: (_) => FullScreenChartForm(
        title: title,
        lineSeriesCollection: lineSeriesCollection,
      ),
    );
  }

  final String title;
  final List<LineSeries> lineSeriesCollection;

  @override
  State<FullScreenChartForm> createState() => _FullScreenChartFormState();
}

class _FullScreenChartFormState extends State<FullScreenChartForm> {
  @override
  void initState() {
    super.initState();
    setFullScreenOrientation();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvoked: (bool didPop) {
        setPreferredOrientation();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.title,
          ),
          centerTitle: true,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                SpeedLineChart(
                  lineSeriesCollection: widget.lineSeriesCollection,
                  showLegend: true,
                  showMultipleYAxises: true,
                  showScaleThumbs: true,
                  plotBands: [
                    PlotBand(
                      startValue: DateTime.parse('2022-05-16 00:51:38'),
                      endValue: DateTime.parse('2022-05-26 00:52:28'),
                      color: Colors.red,
                      opacity: 0.3,
                    ),
                    PlotBand(
                      startValue: DateTime.parse('2022-06-16 00:52:28'),
                      endValue: DateTime.parse('2022-06-26 00:53:38'),
                      color: Colors.green,
                      opacity: 0.3,
                    ),
                    PlotBand(
                      startValue: DateTime.parse('2022-07-16 00:53:38'),
                      endValue: DateTime.parse('2022-07-26 00:54:38'),
                      color: Colors.blue,
                      opacity: 0.3,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

void setPreferredOrientation() {
  double screenWidth = WidgetsBinding
      .instance.platformDispatcher.views.first.physicalSize.shortestSide;

  debugPrint('screenWidth: $screenWidth');

  if (screenWidth <= 1440) {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  } else {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
    ]);
  }
}

//  對 ipad 無作用, ipad 可以隨意旋轉
void setFullScreenOrientation() {
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeRight,
    DeviceOrientation.landscapeLeft,
  ]);
}
