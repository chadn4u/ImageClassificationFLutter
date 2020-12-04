import 'package:BetaFish/model/model.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:tflite/tflite.dart';
import 'dart:math';

class ScanProvider with ChangeNotifier {
  List<CameraDescription> _availableCamera = [];
  List<CameraDescription> get availableCamera => _availableCamera;

  CameraController _cameraController;
  CameraController get cameraController => _cameraController;
  List _recognitions;
  List get recognitions => _recognitions;

  List<Result> _outputs = List();
  double _imageHeight;
  double get imageHeight => _imageHeight;
  double _imageWidth;
  double get imageWidth => _imageWidth;

  bool _modelLoaded = false;
  bool isDetecting = false;

  String _model = ssd;
  String get model => _model;

  void init() async {
    await Tflite.loadModel(
      model: "assets/model/model_unquant.tflite",
      labels: "assets/model/labels.txt",
    ).then((value) => _modelLoaded = true);
    _availableCamera = await availableCameras();

    _cameraController =
        CameraController(_availableCamera[0], ResolutionPreset.medium);
    try {
      await _cameraController.initialize().then((value) {
        _cameraController.startImageStream((image) async {
          if (!_modelLoaded) return;
          if (isDetecting) return;
          isDetecting = true;

          _imageHeight = image.height.toDouble();
          _imageWidth = image.width.toDouble();
          notifyListeners();
          await Tflite.runModelOnFrame(
            bytesList: image.planes.map((plane) {
              return plane.bytes;
            }).toList(),
            imageHeight: image.height,
            imageWidth: image.width,
            numResults: 2,
          ).then((value) {
            if (value.isNotEmpty) {
              _outputs.clear();
              value.forEach((element) {
                _outputs.add(Result(
                    element['confidence'], element['index'], element['label']));
                print('asdasd ${_outputs.toString()}');
                _outputs.sort((a, b) => b.confidence.compareTo(a.confidence));
                isDetecting = false;
                notifyListeners();
              });
            }
          });
        });
        notifyListeners();
      });
    } on CameraException catch (e) {
      print(e);
    }
  }

  void loadModel() async {
    Tflite.close();
    await Tflite.loadModel(
      model: "assets/model/model.tflite",
      labels: "assets/model/labels.txt",
    );
  }

  Widget text() {
    Color blue = Color.fromRGBO(37, 213, 253, 1.0);
    return (_outputs.length > 0)
        ? Text(
            "${_outputs[0].label} ${(_outputs[0].confidence * 100).toStringAsFixed(0)}%",
            style: TextStyle(
              background: Paint()..color = blue,
              color: Colors.white,
              fontSize: 12.0,
            ),
          )
        : Text(
            "Detecting",
            style: TextStyle(
              background: Paint()..color = blue,
              color: Colors.white,
              fontSize: 12.0,
            ),
          );
  }

  List<Widget> renderBoxes(Size screen) {
    if (_outputs == null) return [];
    if (_imageHeight == null || _imageWidth == null) return [];

    double factorX = screen.width;
    double factorY = _imageHeight / _imageWidth * screen.width;
    Color blue = Color.fromRGBO(37, 213, 253, 1.0);
    return _recognitions.map((re) {
      return Positioned(
        left: re["rect"]["x"] * factorX,
        top: re["rect"]["y"] * factorY,
        width: re["rect"]["w"] * factorX,
        height: re["rect"]["h"] * factorY,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(8.0)),
            border: Border.all(
              color: blue,
              width: 2,
            ),
          ),
          child: Text(
            "${re["detectedClass"]} ${(re["confidenceInClass"] * 100).toStringAsFixed(0)}%",
            style: TextStyle(
              background: Paint()..color = blue,
              color: Colors.white,
              fontSize: 12.0,
            ),
          ),
        ),
      );
    }).toList();
  }

  setRecognitions(recognitions, imageHeight, imageWidth) {
    _recognitions = recognitions;
    _imageHeight = imageHeight;
    _imageWidth = imageWidth;
  }
}

class Result {
  double confidence;
  int id;
  String label;

  Result(this.confidence, this.id, this.label);

  @override
  String toString() {
    return "Result ${this.confidence} ${this.id} ${this.label}";
  }
}
