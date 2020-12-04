import 'package:BetaFish/provider/scanProvider.dart';
import 'package:BetaFish/widget/bndBox.dart';
import 'package:BetaFish/widget/camera.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;

class ScanScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    ScanProvider _scanProvider = new ScanProvider();
    _scanProvider.init();
    return ChangeNotifierProvider(
      create: (context) => _scanProvider,
      child: Scaffold(
        body: Consumer<ScanProvider>(
          builder: (context, value, child) => (value.cameraController == null)
              ? Container()
              : Stack(
                  children: [
                    Camera(value.availableCamera, value.model,
                        value.setRecognitions, value.cameraController),
                    (value.imageHeight == null)
                        ? Container()
                        : BndBox(
                            value.recognitions == null
                                ? []
                                : value.recognitions,
                            math.max(value.imageHeight.toInt(),
                                value.imageWidth.toInt()),
                            math.min(value.imageHeight.toInt(),
                                value.imageWidth.toInt()),
                            MediaQuery.of(context).size.height,
                            MediaQuery.of(context).size.width,
                            value.model),
                  ],
                ),
        ),
      ),
    );
  }
}

//  Column(children: [
//     AspectRatio(
//       aspectRatio: 3 / 4,
//       child: CameraPreview(value.cameraController),
//     ),
//     value.text()
//   ])
